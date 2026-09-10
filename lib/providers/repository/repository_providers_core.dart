/// Core repository providers: [repositoryProvider].
/// [branchProvider] and related types live in [branch_notifier.dart] to avoid circular imports.
library;

import 'dart:async';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/repositories/star_mutation_result.dart';
import 'package:diohub/providers/database_providers.dart';

import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/common/riverpod/optimistic_notifier.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_info.graphql.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/models/repositories/repository_initial_state.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub_models/models/repository/compare_result.dart';
import 'package:diohub/services/repositories/repo_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/async_notifier.dart';
import 'package:riverpod/src/providers/future_provider.dart';

final repositoryProvider = AsyncNotifierProvider.autoDispose
    .family<RepositoryNotifier, RepoInfoData, RepoRef>(RepositoryNotifier.new);

typedef RepositoryStarMutation =
    Future<StarMutationResult?> Function({
      required bool isStarred,
      required String repoNodeId,
    });

typedef RepositoryStarFeedback =
    void Function({required bool success, required String message});

/// Stable principal identity for account-scoped Star state.
///
/// The family argument intentionally remains [RepoRef] so all repository
/// surfaces share one mutation state. Watching this value makes Riverpod
/// rebuild that state when the active GitHub/GHES account changes, preventing
/// the short retain window from carrying one account's Star result into the
/// next account.
final repositoryStarAccountKeyProvider = Provider<String?>((final Ref ref) {
  return ref.watch(
    accountProvider.select(
      (final account) => account.value?.activeAccountModel?.accountKey,
    ),
  );
});

/// Localized feedback supplied by the UI at the mutation boundary.
///
/// Repository providers do not own a [BuildContext], so keeping translated
/// copy outside the provider avoids introducing a second localization path.
class RepositoryStarFeedbackMessages {
  const RepositoryStarFeedbackMessages({
    required this.starred,
    required this.unstarred,
    required this.updateFailed,
  });

  final String starred;
  final String unstarred;
  final String updateFailed;
}

/// Injectable boundary for the existing repository star mutation.
///
/// Keeping this separate from [repositoryProvider] prevents a card-level star
/// action from starting the much larger repository screen query.
final repositoryStarMutationProvider =
    Provider.family<RepositoryStarMutation, RepoRef>((
      final Ref ref,
      final RepoRef repoRef,
    ) {
      final RepositoryServices services = repoRef.services(
        ref.watch(apiClientProvider),
      );
      return ({
        required final bool isStarred,
        required final String repoNodeId,
      }) => services.changeStar(isStarred: isStarred, repoNodeId: repoNodeId);
    });

final repositoryStarFeedbackProvider = Provider<RepositoryStarFeedback>((
  final Ref ref,
) {
  return ({required final bool success, required final String message}) {
    final notification = ref.read(notificationServiceProvider);
    if (success) {
      notification.success(message);
    } else {
      notification.error(message);
    }
  };
});

/// Shared lightweight state for star controls mounted in different surfaces.
///
/// [optimisticResult] exists only while a mutation is in flight. A successful
/// mutation promotes its response to [authoritativeResult], so clearing the
/// overlay cannot expose a stale seed retained by another mounted widget.
class RepositoryStarState {
  const RepositoryStarState({
    this.optimisticResult,
    this.authoritativeResult,
    this.isMutating = false,
  });

  final StarMutationResult? optimisticResult;
  final StarMutationResult? authoritativeResult;
  final bool isMutating;

  StarMutationResult? get result => optimisticResult ?? authoritativeResult;

  bool get hasOptimisticOverlay => optimisticResult != null;
}

class RepositoryStarNotifier extends Notifier<RepositoryStarState> {
  RepositoryStarNotifier(this.arg);

  final RepoRef arg;

  @override
  RepositoryStarState build() {
    ref.watch(repositoryStarAccountKeyProvider);
    keepAliveFor(ref);
    return const RepositoryStarState();
  }

  Future<void> toggle({
    required final String repoNodeId,
    required final bool currentIsStarred,
    required final int currentCount,
    required final RepositoryStarFeedbackMessages feedbackMessages,
  }) async {
    if (state.isMutating) return;

    final String? mutationAccountKey = ref.read(
      repositoryStarAccountKeyProvider,
    );
    final RepositoryStarState previous = state;
    final bool willStar = !currentIsStarred;
    final int optimisticCount =
        currentCount + (willStar ? 1 : (currentCount > 0 ? -1 : 0));
    state = RepositoryStarState(
      optimisticResult: StarMutationResult(
        viewerHasStarred: willStar,
        stargazerCount: optimisticCount,
      ),
      authoritativeResult: previous.authoritativeResult,
      isMutating: true,
    );

    try {
      final StarMutationResult? result =
          await ref.read(repositoryStarMutationProvider(arg))(
            // RepositoryServices.changeStar expects the current state and
            // chooses add/remove from it.
            isStarred: currentIsStarred,
            repoNodeId: repoNodeId,
          );
      if (ref.read(repositoryStarAccountKeyProvider) != mutationAccountKey) {
        return;
      }
      if (result == null) throw StateError('changeStar returned null');
      state = RepositoryStarState(authoritativeResult: result);
      ref.invalidate(repoCardProvider(arg));
      ref.read(repositoryStarFeedbackProvider)(
        success: true,
        message: result.viewerHasStarred
            ? feedbackMessages.starred
            : feedbackMessages.unstarred,
      );
    } catch (error, stackTrace) {
      if (ref.read(repositoryStarAccountKeyProvider) != mutationAccountKey) {
        return;
      }
      state = previous;
      AppLogger.warning(
        'Repository star mutation failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'RepositoryStar',
      );
      ref.read(repositoryStarFeedbackProvider)(
        success: false,
        message: feedbackMessages.updateFailed,
      );
    }
  }

  /// Accepts a seed returned by an explicit authoritative refresh.
  ///
  /// An older request completing during a mutation must not replace the
  /// optimistic frame. Once the mutation settles, the next explicit refresh
  /// can replace the session value for every mounted consumer.
  void acceptAuthoritativeSeed(final StarMutationResult seed) {
    if (state.isMutating) return;
    final StarMutationResult? current = state.authoritativeResult;
    if (current?.viewerHasStarred == seed.viewerHasStarred &&
        current?.stargazerCount == seed.stargazerCount) {
      return;
    }
    state = RepositoryStarState(authoritativeResult: seed);
  }
}

final repositoryStarProvider = NotifierProvider.autoDispose
    .family<RepositoryStarNotifier, RepositoryStarState, RepoRef>(
      RepositoryStarNotifier.new,
    );

/// Lightweight provider that fetches repository data for card contexts.
final repoCardProvider = FutureProvider.autoDispose.family<RepoCardData, RepoRef>((
  final Ref ref,
  final RepoRef repoRef,
) async {
  keepAliveFor(ref);

  // Check if repositoryProvider already has data for this repo to avoid redundant fetch
  final fullRepoData = ref.read(repositoryProvider(repoRef));
  if (fullRepoData.hasValue && fullRepoData.value?.repository != null) {
    final repo = fullRepoData.value?.repository;
    if (repo != null) return repo;
  }

  // The dedicated card query avoids branch resolution and screen-only counts.
  final repository = await repoRef
      .services(ref.read(apiClientProvider))
      .fetchRepositoryCardGraphQL(refresh: false);

  return repository;
});

final compareResultProvider = FutureProvider.autoDispose
    .family<CompareResult, ({RepoRef repoRef, String base, String head})>((
      final Ref ref,
      final ({RepoRef repoRef, String base, String head}) args,
    ) async {
      return args.repoRef
          .services(ref.read(apiClientProvider))
          .getCompare(base: args.base, head: args.head);
    });

class RepositoryNotifier extends AsyncNotifier<RepoInfoData>
    with OptimisticFamilyAsyncNotifier {
  RepositoryNotifier(this.arg);
  final RepoRef arg;

  late final RepositoryServices _services = arg.services(
    ref.read(apiClientProvider),
  );

  @override
  Future<RepoInfoData> build() async {
    final String? viewer = ref.watch(
      accountProvider.select((v) => v.hasValue ? v.value?.activeAccount : null),
    );
    final String? initialRef = _initialRefFromArg(arg);
    keepAliveFor(ref);
    final data = await _services.fetchRepositoryGraphQLFull(
      initialRef: initialRef,
      viewer: viewer,
    );
    return data;
  }

  /// Derives initial ref for the repo GraphQL query from [RepoRef.location].
  static String? _initialRefFromArg(final RepoRef arg) {
    final String? branch = resolveRepoLocation(arg.location).branch;
    if (branch == null || branch.isEmpty) return null;
    return looksLikeFullSha(branch) ? null : branch;
  }

  Future<void> toggleWatch(final SubscriptionState targetState) async {
    final RepoInfo current = state.requireValue.repository!;
    final SubscriptionState? res = await optimistic(
      transform: (final RepoInfoData full) =>
          full.copyWith.repository(viewerSubscription: targetState),
      mutation: () async {
        final SubscriptionState? raw = await _services.subscribeToRepo(
          repoNodeId: current.id,
          state: targetState,
        );
        if (raw == null) throw StateError('subscribeToRepo returned null');
        return raw;
      },
      errorMessage: (_, __) => "Couldn't update watch status",
      applyResponse:
          (final RepoInfoData full, final SubscriptionState? subState) =>
              full.copyWith.repository(viewerSubscription: subState),
    );
    if (res != null) {
      final String msg = switch (targetState) {
        SubscriptionState.SUBSCRIBED => 'Watching',
        SubscriptionState.IGNORED => 'Ignoring',
        _ => 'Not watching',
      };
      ref.read(notificationServiceProvider).success(msg);
    }
  }

  Future<void> fork() async {
    await _services.forkRepo();
    final RepoInfoData full = state.requireValue;
    final RepoInfo current = full.repository!;
    state = AsyncData(
      full.copyWith.repository(forkCount: current.forkCount + 1),
    );
  }

  void patchArchived(final bool isArchived) {
    final full = state.requireValue;
    state = AsyncData(full.copyWith.repository(isArchived: isArchived));
  }

  void patchForkCount(final int Function(int) update) {
    final full = state.requireValue;
    final current = full.repository!;
    state = AsyncData(
      full.copyWith.repository(forkCount: update(current.forkCount)),
    );
  }

  Future<void> refresh() async {
    final AsyncValue<RepoInfoData> refreshed = await AsyncValue.guard(
      () => _services.fetchRepositoryGraphQLFull(refresh: true),
    );
    state = refreshed;
    final RepoInfo? repository = refreshed.value?.repository;
    if (repository != null && ref.exists(repositoryStarProvider(arg))) {
      ref
          .read(repositoryStarProvider(arg).notifier)
          .acceptAuthoritativeSeed(
            StarMutationResult(
              viewerHasStarred: repository.viewerHasStarred,
              stargazerCount: repository.stargazerCount,
            ),
          );
    }
  }

  Future<int?> createIssue(
    final String title, {
    final String? body,
    final List<String>? assigneeIds,
    final List<String>? labelIds,
    final String? milestoneId,
    final String? issueTemplate,
    final List<String>? projectIds,
  }) async {
    final String repositoryId = state.requireValue.repository!.id;
    return arg
        .issueCreation(ref.read(apiClientProvider))
        .createIssue(
          repositoryId: repositoryId,
          title: title,
          body: body != null && body.isNotEmpty ? body : null,
          assigneeIds: assigneeIds,
          labelIds: labelIds,
          milestoneId: milestoneId,
          issueTemplate: issueTemplate,
          projectIds: projectIds,
        );
  }

  Future<int?> createPullRequest({
    required final String title,
    required final String baseRefName,
    required final String headRefName,
    final String? body,
    final bool? draft,
    final String? headRepositoryId,
    final bool? maintainerCanModify,
  }) async {
    final String repositoryId = state.requireValue.repository!.id;
    return arg
        .pullCreation(ref.read(apiClientProvider))
        .createPullRequest(
          repositoryId: repositoryId,
          title: title,
          body: body,
          baseRefName: baseRefName,
          headRefName: headRefName,
          draft: draft,
          headRepositoryId: headRepositoryId,
          maintainerCanModify: maintainerCanModify,
        );
  }
}
