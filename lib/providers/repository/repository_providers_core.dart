/// Core repository providers: [repositoryProvider].
/// [branchProvider] and related types live in [branch_notifier.dart] to avoid circular imports.
library;

import 'dart:async';
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

/// Lightweight provider that fetches repository data for card contexts.
/// Currently delegates to the full repository fetch; card-specific optimization
/// can be added to the service layer if needed.
final repoCardProvider = FutureProvider.autoDispose.family<RepoCardData, RepoRef>((
  final Ref ref,
  final RepoRef repoRef,
) async {
  // Check if repositoryProvider already has data for this repo to avoid redundant fetch
  final fullRepoData = ref.read(repositoryProvider(repoRef));
  if (fullRepoData.hasValue && fullRepoData.value?.repository != null) {
    final repo = fullRepoData.value?.repository;
    if (repo != null) return repo;
  }

  // Fetch through service layer
  final repository = await repoRef
      .services(ref.read(apiClientProvider))
      .fetchRepositoryGraphQL(refresh: false);

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

  Future<void> toggleStar() async {
    final RepoInfo current = state.requireValue.repository!;
    final bool willStar = !current.viewerHasStarred;
    final StarMutationResult? res = await optimistic(
      transform: (final RepoInfoData full) {
        final repo = full.repository;
        if (repo == null) return full;
        return full.copyWith.repository(
          viewerHasStarred: willStar,
          stargazerCount: repo.stargazerCount + (willStar ? 1 : -1),
        );
      },
      mutation: () async {
        final StarMutationResult? raw = await _services.changeStar(
          isStarred: willStar,
          repoNodeId: current.id,
        );
        if (raw == null) throw StateError('changeStar returned null');
        return raw;
      },
      errorMessage: (_, __) => "Couldn't update star",
      applyResponse: (final RepoInfoData full, final StarMutationResult? res) {
        if (res == null) return full;
        return full.copyWith.repository(
          viewerHasStarred: res.viewerHasStarred,
          stargazerCount: res.stargazerCount,
        );
      },
    );
    if (res != null) {
      ref
          .read(notificationServiceProvider)
          .success(willStar ? 'Starred' : 'Unstarred');
    }
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
    state = await AsyncValue.guard(
      () => _services.fetchRepositoryGraphQLFull(refresh: true),
    );
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
