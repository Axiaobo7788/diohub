/// Branch/ref state and [branchProvider]. Depends on [repository_providers_core].
library;

import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/models/repositories/repository_initial_state.dart';
import 'package:diohub/models/repository_preview.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/repository/repository_preview_provider.dart';
import 'package:diohub/providers/repository/repository_providers_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _BranchInitialOverrideNotifier extends Notifier<BranchState?> {
  _BranchInitialOverrideNotifier(final RepoRef _);

  @override
  BranchState? build() => null;

  void setOverride(final BranchState value) {
    state = value;
  }
}

/// One-shot override for the initial branch selection. Set by [RepositoryScreen]
/// in `initState` when navigated to a specific branch or commit SHA.
final branchInitialOverride =
    NotifierProvider.family<
      _BranchInitialOverrideNotifier,
      BranchState?,
      RepoRef
    >(_BranchInitialOverrideNotifier.new);

/// Kind of ref the user is viewing (branch name, tag name, or detached commit).
enum RefKind { branch, tag, commit }

/// Current branch/ref state. Sealed so consumers must handle [BranchStateLoading].
sealed class BranchState {
  const BranchState();

  factory BranchState.branch(
    final String name, {
    final String? oid,
    final String? treeOid,
  }) = BranchStateResolved.branch;
  factory BranchState.tag(
    final String name, {
    final String? oid,
    final String? treeOid,
  }) = BranchStateResolved.tag;
  factory BranchState.commit(final String sha, {final String? treeOid}) =
      BranchStateResolved.commit;
}

final class BranchStateLoading extends BranchState {
  const BranchStateLoading();
}

final class BranchStateResolved extends BranchState {
  const BranchStateResolved({
    required this.refValue,
    this.refKind = RefKind.branch,
    this.oid,
    required this.treeOid,
  });
  const BranchStateResolved.branch(
    final String name, {
    final String? oid,
    final String? treeOid,
  }) : refValue = name,
       refKind = RefKind.branch,
       oid = oid,
       treeOid = treeOid ?? '';
  const BranchStateResolved.tag(
    final String name, {
    final String? oid,
    final String? treeOid,
  }) : refValue = name,
       refKind = RefKind.tag,
       oid = oid,
       treeOid = treeOid ?? '';
  const BranchStateResolved.commit(final String sha, {final String? treeOid})
    : refValue = sha,
      refKind = RefKind.commit,
      oid = sha,
      treeOid = treeOid ?? '';

  final String refValue;
  final RefKind refKind;
  final String? oid;
  final String treeOid;

  String get currentSHA => refValue;
  String? get resolvedOid =>
      oid ?? (refKind == RefKind.commit ? refValue : null);
  bool get isCommit => refKind == RefKind.commit;
  bool get isTag => refKind == RefKind.tag;

  String? get refPrefix => switch (refKind) {
    RefKind.branch => 'refs/heads/',
    RefKind.tag => 'refs/tags/',
    RefKind.commit => null,
  };

  RepoRevision toRevision() =>
      RepoRevision(refValue: refValue, refKind: refKind, oid: oid);
}

final class RepoRevision {
  const RepoRevision({required this.refValue, required this.refKind, this.oid});

  factory RepoRevision.fromResolved(final BranchStateResolved resolved) =>
      resolved.toRevision();

  static RepoRevision fromRefString(final String s) {
    final RefKind kind = looksLikeFullSha(s)
        ? RefKind.commit
        : (s.startsWith('refs/tags/') ? RefKind.tag : RefKind.branch);
    return RepoRevision(
      refValue: s,
      refKind: kind,
      oid: kind == RefKind.commit ? s : null,
    );
  }

  final String refValue;
  final RefKind refKind;
  final String? oid;

  bool get isCommit => refKind == RefKind.commit;
  bool get canEdit => !isCommit;

  String? get _refPrefix => switch (refKind) {
    RefKind.branch => 'refs/heads/',
    RefKind.tag => 'refs/tags/',
    RefKind.commit => null,
  };

  String? get refForApi => switch (refKind) {
    RefKind.commit => null,
    _ => refValue.startsWith('refs/') ? refValue : '$_refPrefix$refValue',
  };

  String? get oidForApi => refKind == RefKind.commit ? refValue : oid;

  String get fullRefName => refKind == RefKind.commit
      ? refValue
      : (refValue.startsWith('refs/') ? refValue : '$_refPrefix$refValue');
}

class BranchNotifier extends Notifier<BranchState> {
  BranchNotifier(this.arg);
  final RepoRef arg;

  @override
  BranchState build() {
    final BranchState? override = ref.watch(branchInitialOverride(arg));
    final accountState = ref.watch(accountProvider);
    final bool accountResolved =
        accountState.hasValue && !accountState.hasError;
    final bool signedIn =
        accountResolved && accountState.value?.activeAccountModel != null;
    final RepositoryPreview? preview = ref.watch(
      repositoryPreviewProvider(arg),
    );
    final RepoInfo? repo = signedIn
        ? ref.watch(
            repositoryProvider(
              arg,
            ).select((final AsyncValue<RepoInfoData> a) => a.value?.repository),
          )
        : null;
    final RepoCardData? card = signedIn && preview?.defaultBranch == null
        ? ref.watch(repoCardProvider(arg)).value
        : null;

    if (override != null) {
      final BranchStateResolved resolved = override as BranchStateResolved;
      final initialRef = repo?.initialRef;
      if (initialRef != null && initialRef.name == resolved.refValue) {
        final String? oid = initialRef.target?.maybeWhen(
          commit: (final c) => c.oid,
          orElse: () => null,
        );
        final String? treeOid = initialRef.target?.maybeWhen(
          commit: (final c) => c.tree.oid,
          orElse: () => null,
        );
        if (oid != null && treeOid != null) {
          return BranchStateResolved(
            refValue: resolved.refValue,
            refKind: resolved.refKind,
            oid: oid,
            treeOid: treeOid,
          );
        }
      }
      return resolved;
    }

    final String? defaultBranch =
        repo?.defaultBranchRef?.name ??
        card?.defaultBranchRef?.name ??
        preview?.defaultBranch;
    if (defaultBranch == null || defaultBranch.isEmpty) {
      return const BranchStateLoading();
    }
    final String? defaultOid = repo?.defaultBranchRef?.target?.maybeWhen(
      commit: (final c) => c.oid,
      orElse: () => null,
    );
    final String? defaultTreeOid = repo?.defaultBranchRef?.target?.maybeWhen(
      commit: (final c) => c.tree.oid,
      orElse: () => null,
    );
    return BranchState.branch(
      defaultBranch,
      oid: defaultOid,
      treeOid: defaultTreeOid ?? '',
    );
  }

  void setBranchState(final BranchState newState) {
    state = newState;
  }

  void setRef(
    final String refValue,
    final RefKind kind, {
    required final String oid,
    required final String treeOid,
  }) {
    state = BranchStateResolved(
      refValue: refValue,
      refKind: kind,
      oid: oid,
      treeOid: treeOid,
    );
  }
}

final branchProvider =
    NotifierProvider.family<BranchNotifier, BranchState, RepoRef>(
      BranchNotifier.new,
    );

final class RepositoryInitialRef {
  const RepositoryInitialRef._({this.branchState});

  final BranchState? branchState;

  factory RepositoryInitialRef.fromRepo(final RepoRef repo) {
    final String? ref = resolveRepoLocation(repo.location).branch;
    if (ref == null || ref.isEmpty) {
      return const RepositoryInitialRef._(branchState: null);
    }
    final RepoRevision rev = RepoRevision.fromRefString(ref);
    if (rev.isCommit) {
      return RepositoryInitialRef._(branchState: BranchState.commit(ref));
    }
    return RepositoryInitialRef._(branchState: BranchState.branch(ref));
  }

  bool get shouldInvalidateRepo => branchState != null;
}

/// Applies [initialRef] to providers for [repo]. Call from [RepositoryScreen] initState.
void applyInitialRef(
  final WidgetRef ref,
  final RepoRef repo,
  final RepositoryInitialRef initialRef,
) {
  if (initialRef.branchState != null) {
    ref
        .read(branchInitialOverride(repo).notifier)
        .setOverride(initialRef.branchState!);
  }
  if (initialRef.shouldInvalidateRepo) {
    ref.invalidate(repositoryProvider(repo));
  }
}
