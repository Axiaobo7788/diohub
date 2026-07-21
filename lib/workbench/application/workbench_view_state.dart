import 'package:diohub/workbench/domain/github_gateway.dart';
import 'package:diohub/workbench/domain/workbench_models.dart';
import 'package:diohub/workbench/domain/workspace_gateway.dart';
import 'package:diohub/workbench/domain/workspace_models.dart';

enum WorkbenchSyncStatus {
  idle,
  syncing,
  fresh,
  stale,
  offline,
  permissionDenied,
  rateLimited,
  failure,
}

/// Framework-independent state that a later desktop or mobile view can render.
final class WorkbenchViewState {
  WorkbenchViewState({
    required this.repositoryRef,
    required this.syncStatus,
    required final List<WorkbenchCheckAnnotation> annotations,
    this.localRepository,
    this.repository,
    this.headStatus,
    this.lastSyncedAt,
    this.failureKind,
    this.workspaceFailureKind,
    this.failureMessage,
    this.retryAt,
  }) : annotations = List<WorkbenchCheckAnnotation>.unmodifiable(annotations);

  factory WorkbenchViewState.initial(final GitHubRepositoryRef repositoryRef) =>
      WorkbenchViewState(
        repositoryRef: repositoryRef,
        syncStatus: WorkbenchSyncStatus.idle,
        annotations: const <WorkbenchCheckAnnotation>[],
      );

  final GitHubRepositoryRef repositoryRef;
  final WorkbenchSyncStatus syncStatus;
  final LocalRepo? localRepository;
  final WorkbenchRepository? repository;
  final WorkbenchHeadStatus? headStatus;
  final List<WorkbenchCheckAnnotation> annotations;
  final DateTime? lastSyncedAt;
  final GitHubGatewayFailureKind? failureKind;
  final WorkspaceFailureKind? workspaceFailureKind;
  final String? failureMessage;
  final DateTime? retryAt;

  bool get hasRemoteSnapshot =>
      repository != null || headStatus != null || annotations.isNotEmpty;

  bool get hasLocalSnapshot => localRepository != null;
}
