import 'package:diohub/workbench/domain/workspace_gateway.dart';
import 'package:diohub/workbench/domain/workspace_models.dart';

final class FakeWorkspaceGateway implements WorkspaceGateway {
  FakeWorkspaceGateway({required this.repository});

  LocalRepo repository;
  WorkspaceException? failure;
  final List<String> inspectedPaths = <String>[];

  @override
  Future<bool> isGitAvailable() async =>
      failure?.kind != WorkspaceFailureKind.gitUnavailable;

  @override
  Future<LocalRepo> inspectRepository(final String selectedPath) async {
    inspectedPaths.add(selectedPath);
    final WorkspaceException? currentFailure = failure;
    if (currentFailure != null) {
      throw currentFailure;
    }
    return repository;
  }
}

final class FakeEditorGateway implements EditorGateway {
  EditorException? failure;
  final List<EditorTarget> openedTargets = <EditorTarget>[];

  @override
  Future<bool> isAvailable() async =>
      failure?.kind != EditorFailureKind.executableUnavailable;

  @override
  Future<void> open(final EditorTarget target) async {
    final EditorException? currentFailure = failure;
    if (currentFailure != null) {
      throw currentFailure;
    }
    openedTargets.add(target);
  }
}
