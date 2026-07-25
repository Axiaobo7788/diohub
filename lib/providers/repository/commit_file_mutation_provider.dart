/// Mutation to create/update/delete files via Git database commit. Used by
/// create file screen and other commit-file flows.
library;

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub/providers/code_browser/directory_resource.dart';
import 'package:diohub/providers/repository/repository_document_resource.dart';
import 'package:diohub/providers/repository/repository_readme_resource.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/git/file_change.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parameters for a single commit (additions and/or deletions).
class CommitFileParams {
  const CommitFileParams({
    required this.branchRef,
    required this.expectedHeadOid,
    required this.message,
    this.additions = const [],
    this.deletions = const [],
  });

  final String branchRef;
  final String expectedHeadOid;
  final String message;
  final List<FileChange> additions;
  final List<String> deletions;
}

class CommitFileMutationNotifier extends Notifier<MutationState<void>>
    with MutationNotifierMixin<void> {
  CommitFileMutationNotifier(this._repoRef);

  final RepoRef _repoRef;

  @override
  MutationState<void> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  Future<void> commit(final CommitFileParams params) async {
    if (state is MutationLoading<void>) return;
    state = MutationState.loading();
    try {
      await _repoRef
          .gitDb(ref.read(apiClientProvider))
          .commitFileChanges(
            branchRef: params.branchRef,
            expectedHeadOid: params.expectedHeadOid,
            message: params.message,
            additions: params.additions,
            deletions: params.deletions,
          );
      final scope = ref.read(activeResourceScopeProvider);
      if (scope != null) {
        final List<String> changedPaths = <String>[
          ...params.additions.map((final FileChange change) => change.path),
          ...params.deletions,
        ];
        final runtime = ref.read(resourceRuntimeProvider);
        invalidateRepositoryDirectoriesForFiles(
          runtime: runtime,
          scope: scope,
          repo: _repoRef,
          branch: params.branchRef,
          filePaths: changedPaths,
        );
        invalidateRepositoryReadmeForFiles(
          runtime: runtime,
          scope: scope,
          repo: _repoRef,
          branch: params.branchRef,
          filePaths: changedPaths,
        );
        invalidateRepositoryDocumentsForFiles(
          runtime: runtime,
          scope: scope,
          repo: _repoRef,
          branch: params.branchRef,
          filePaths: changedPaths,
        );
      }
      state = const MutationState.success(null);
      scheduleReset();
    } catch (e, st) {
      AppLogger.warning(
        'Commit file changes failed',
        error: e,
        stackTrace: st,
        tag: 'CommitFile',
      );
      state = MutationState.error(e, st);
      scheduleReset();
      rethrow;
    }
  }
}

final commitFileMutationProvider = NotifierProvider.autoDispose
    .family<CommitFileMutationNotifier, MutationState<void>, RepoRef>(
      CommitFileMutationNotifier.new,
    );
