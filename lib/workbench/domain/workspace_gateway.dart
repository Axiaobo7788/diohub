import 'package:diohub/workbench/domain/workspace_models.dart';

enum WorkspaceFailureKind {
  notRepository,
  gitUnavailable,
  permissionDenied,
  invalidData,
  unknown,
}

final class WorkspaceException implements Exception {
  const WorkspaceException({required this.kind, required this.message});

  final WorkspaceFailureKind kind;
  final String message;

  @override
  String toString() => 'WorkspaceException($kind): $message';
}

/// Read-only system Git boundary.
///
/// Implementations may inspect Git state but must not fetch, checkout, switch,
/// create/delete worktrees, reset, merge, rebase, or modify user files.
abstract interface class WorkspaceGateway {
  Future<bool> isGitAvailable();

  Future<LocalRepo> inspectRepository(final String selectedPath);
}

enum EditorFailureKind {
  executableUnavailable,
  unsafeTarget,
  launchFailed,
  unknown,
}

final class EditorException implements Exception {
  const EditorException({required this.kind, required this.message});

  final EditorFailureKind kind;
  final String message;

  @override
  String toString() => 'EditorException($kind): $message';
}

/// Semantic editor launcher boundary; callers never construct shell strings.
abstract interface class EditorGateway {
  Future<bool> isAvailable();

  Future<void> open(final EditorTarget target);
}
