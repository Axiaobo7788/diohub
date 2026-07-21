import 'dart:async';

import 'package:diohub/workbench/application/workbench_view_state.dart';
import 'package:diohub/workbench/domain/github_gateway.dart';
import 'package:diohub/workbench/domain/workbench_models.dart';
import 'package:diohub/workbench/domain/workspace_gateway.dart';
import 'package:diohub/workbench/domain/workspace_models.dart';

/// Coordinates one selected repository without depending on a UI framework.
///
/// A later Riverpod provider may own this controller, but loading, stale
/// request suppression, and failure-to-state mapping stay here.
final class UnifiedRepoController {
  UnifiedRepoController({
    required this.github,
    required this.workspace,
    required final GitHubRepositoryRef repository,
    final DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _state = WorkbenchViewState.initial(repository);

  final GitHubGateway github;
  final WorkspaceGateway workspace;
  final DateTime Function() _clock;
  final StreamController<WorkbenchViewState> _changes =
      StreamController<WorkbenchViewState>.broadcast(sync: true);

  WorkbenchViewState _state;
  int _requestSerial = 0;
  bool _isDisposed = false;

  WorkbenchViewState get state => _state;

  Stream<WorkbenchViewState> get changes => _changes.stream;

  Future<void> load({
    required final String selectedPath,
    final bool refresh = false,
  }) async {
    if (_isDisposed) {
      throw StateError('UnifiedRepoController has been disposed.');
    }
    final int requestSerial = ++_requestSerial;
    LocalRepo? localRepository = _state.localRepository;
    WorkbenchRepository? repository = _state.repository;
    _emit(
      WorkbenchViewState(
        repositoryRef: _state.repositoryRef,
        syncStatus: WorkbenchSyncStatus.syncing,
        localRepository: localRepository,
        repository: repository,
        headStatus: _state.headStatus,
        annotations: _state.annotations,
        lastSyncedAt: _state.lastSyncedAt,
      ),
    );

    try {
      localRepository = await workspace.inspectRepository(selectedPath);
      final Worktree? worktree = localRepository.selectedWorktree;
      if (worktree == null) {
        throw const WorkspaceException(
          kind: WorkspaceFailureKind.invalidData,
          message: 'The selected path does not resolve to a worktree.',
        );
      }
      final String? headSha = worktree.headSha;
      if (headSha == null || headSha.isEmpty) {
        throw const WorkspaceException(
          kind: WorkspaceFailureKind.invalidData,
          message: 'The selected worktree does not have a HEAD commit.',
        );
      }
      if (!_isCurrent(requestSerial)) {
        return;
      }
      _emit(
        WorkbenchViewState(
          repositoryRef: _state.repositoryRef,
          syncStatus: WorkbenchSyncStatus.syncing,
          localRepository: localRepository,
          repository: _state.repository,
          headStatus: _state.headStatus,
          annotations: _state.annotations,
          lastSyncedAt: _state.lastSyncedAt,
        ),
      );
      repository = await github.fetchRepository(
        _state.repositoryRef,
        refresh: refresh,
      );
      final WorkbenchHeadStatus headStatus = await github.fetchHeadStatus(
        _state.repositoryRef,
        headSha: headSha,
        branch: worktree.branch,
        headOwner: _headOwner(localRepository, worktree),
        refresh: refresh,
      );
      final List<WorkbenchCheckAnnotation> annotations = await github
          .listCheckAnnotations(
            _state.repositoryRef,
            headSha: headSha,
            refresh: refresh,
          );
      if (!_isCurrent(requestSerial)) {
        return;
      }
      _emit(
        WorkbenchViewState(
          repositoryRef: _state.repositoryRef,
          syncStatus: WorkbenchSyncStatus.fresh,
          localRepository: localRepository,
          repository: repository,
          headStatus: headStatus,
          annotations: annotations,
          lastSyncedAt: _clock(),
        ),
      );
    } on WorkspaceException catch (failure) {
      if (!_isCurrent(requestSerial)) {
        return;
      }
      _emitWorkspaceFailure(failure);
    } on GitHubGatewayException catch (failure) {
      if (!_isCurrent(requestSerial)) {
        return;
      }
      _emitFailure(failure);
    } on Object catch (error) {
      if (!_isCurrent(requestSerial)) {
        return;
      }
      _emitFailure(
        GitHubGatewayException(
          kind: GitHubGatewayFailureKind.unknown,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _requestSerial++;
    await _changes.close();
  }

  void _emit(final WorkbenchViewState next) {
    if (_isDisposed) {
      return;
    }
    _state = next;
    _changes.add(next);
  }

  void _emitFailure(final GitHubGatewayException failure) {
    _emit(
      WorkbenchViewState(
        repositoryRef: _state.repositoryRef,
        syncStatus: _syncStatusFor(failure.kind),
        localRepository: _state.localRepository,
        repository: _state.repository,
        headStatus: _state.headStatus,
        annotations: _state.annotations,
        lastSyncedAt: _state.lastSyncedAt,
        failureKind: failure.kind,
        failureMessage: failure.message,
        retryAt: failure.retryAt,
      ),
    );
  }

  void _emitWorkspaceFailure(final WorkspaceException failure) {
    _emit(
      WorkbenchViewState(
        repositoryRef: _state.repositoryRef,
        syncStatus: WorkbenchSyncStatus.failure,
        localRepository: _state.localRepository,
        repository: _state.repository,
        headStatus: _state.headStatus,
        annotations: _state.annotations,
        lastSyncedAt: _state.lastSyncedAt,
        workspaceFailureKind: failure.kind,
        failureMessage: failure.message,
      ),
    );
  }

  String? _headOwner(final LocalRepo localRepository, final Worktree worktree) {
    final String? trackingRemote = worktree.branchLink?.remoteName;
    if (trackingRemote != null) {
      return localRepository.linkForRemote(trackingRemote)?.repository.owner;
    }
    for (final RepoLink link in localRepository.repositoryLinks) {
      if (link.remoteRole == GitRemoteRole.origin) {
        return link.repository.owner;
      }
    }
    return null;
  }

  bool _isCurrent(final int requestSerial) =>
      !_isDisposed && requestSerial == _requestSerial;

  static WorkbenchSyncStatus _syncStatusFor(
    final GitHubGatewayFailureKind kind,
  ) => switch (kind) {
    GitHubGatewayFailureKind.offline => WorkbenchSyncStatus.offline,
    GitHubGatewayFailureKind.permissionDenied =>
      WorkbenchSyncStatus.permissionDenied,
    GitHubGatewayFailureKind.rateLimited => WorkbenchSyncStatus.rateLimited,
    GitHubGatewayFailureKind.notFound ||
    GitHubGatewayFailureKind.invalidData ||
    GitHubGatewayFailureKind.unknown => WorkbenchSyncStatus.failure,
  };
}
