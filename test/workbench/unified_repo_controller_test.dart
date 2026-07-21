import 'dart:async';

import 'package:diohub/workbench/application/unified_repo_controller.dart';
import 'package:diohub/workbench/application/workbench_view_state.dart';
import 'package:diohub/workbench/domain/github_gateway.dart';
import 'package:diohub/workbench/domain/workbench_models.dart';
import 'package:diohub/workbench/domain/workspace_gateway.dart';
import 'package:diohub/workbench/domain/workspace_models.dart';
import 'package:test/test.dart';

import 'fakes/fake_workspace_gateways.dart';

void main() {
  const GitHubRepositoryRef repositoryRef = GitHubRepositoryRef(
    owner: 'openai',
    name: 'codex',
  );

  test('loads one combined local and remote repository snapshot', () async {
    final _FakeGitHubGateway github = _FakeGitHubGateway(repositoryRef);
    final FakeWorkspaceGateway workspace = FakeWorkspaceGateway(
      repository: _localRepository(),
    );
    final UnifiedRepoController controller = UnifiedRepoController(
      github: github,
      workspace: workspace,
      repository: repositoryRef,
      clock: () => DateTime.utc(2026, 7, 21, 8),
    );
    final List<WorkbenchSyncStatus> statuses = <WorkbenchSyncStatus>[];
    final StreamSubscription<WorkbenchViewState> subscription = controller
        .changes
        .listen(
          (final WorkbenchViewState state) => statuses.add(state.syncStatus),
        );

    await controller.load(selectedPath: '/workspace/codex');

    expect(statuses, <WorkbenchSyncStatus>[
      WorkbenchSyncStatus.syncing,
      WorkbenchSyncStatus.syncing,
      WorkbenchSyncStatus.fresh,
    ]);
    expect(workspace.inspectedPaths, <String>['/workspace/codex']);
    expect(
      controller.state.localRepository?.selectedWorktree?.branch,
      'develop',
    );
    expect(controller.state.repository?.ref, repositoryRef);
    expect(controller.state.headStatus?.headSha, 'abc123');
    expect(github.lastHeadOwner, 'contributor');
    expect(controller.state.annotations.single.path, 'lib/main.dart');
    expect(controller.state.lastSyncedAt, DateTime.utc(2026, 7, 21, 8));
    expect(controller.state.hasLocalSnapshot, isTrue);
    expect(controller.state.hasRemoteSnapshot, isTrue);

    await subscription.cancel();
    await controller.dispose();
  });

  test('offline refresh keeps the last successful snapshot', () async {
    final _FakeGitHubGateway github = _FakeGitHubGateway(repositoryRef);
    final FakeWorkspaceGateway workspace = FakeWorkspaceGateway(
      repository: _localRepository(),
    );
    final UnifiedRepoController controller = UnifiedRepoController(
      github: github,
      workspace: workspace,
      repository: repositoryRef,
      clock: () => DateTime.utc(2026, 7, 21, 8),
    );
    await controller.load(selectedPath: '/workspace/codex');
    final LocalRepo? successfulLocal = controller.state.localRepository;
    final WorkbenchRepository? successfulRepository =
        controller.state.repository;
    final WorkbenchHeadStatus? successfulHead = controller.state.headStatus;
    final List<WorkbenchCheckAnnotation> successfulAnnotations =
        controller.state.annotations;

    github.failure = const GitHubGatewayException(
      kind: GitHubGatewayFailureKind.offline,
      message: 'No network',
    );
    await controller.load(selectedPath: '/workspace/codex', refresh: true);

    expect(controller.state.syncStatus, WorkbenchSyncStatus.offline);
    expect(controller.state.failureKind, GitHubGatewayFailureKind.offline);
    expect(controller.state.localRepository, same(successfulLocal));
    expect(controller.state.repository, same(successfulRepository));
    expect(controller.state.headStatus, same(successfulHead));
    expect(controller.state.annotations, successfulAnnotations);
    expect(controller.state.lastSyncedAt, DateTime.utc(2026, 7, 21, 8));

    await controller.dispose();
  });

  test('workspace failure is typed and keeps the previous snapshot', () async {
    final _FakeGitHubGateway github = _FakeGitHubGateway(repositoryRef);
    final FakeWorkspaceGateway workspace = FakeWorkspaceGateway(
      repository: _localRepository(),
    );
    final UnifiedRepoController controller = UnifiedRepoController(
      github: github,
      workspace: workspace,
      repository: repositoryRef,
    );
    await controller.load(selectedPath: '/workspace/codex');
    final WorkbenchViewState successfulState = controller.state;

    workspace.failure = const WorkspaceException(
      kind: WorkspaceFailureKind.notRepository,
      message: 'Not a Git repository',
    );
    await controller.load(selectedPath: '/workspace/missing');

    expect(controller.state.syncStatus, WorkbenchSyncStatus.failure);
    expect(
      controller.state.workspaceFailureKind,
      WorkspaceFailureKind.notRepository,
    );
    expect(
      controller.state.localRepository,
      same(successfulState.localRepository),
    );
    expect(controller.state.headStatus, same(successfulState.headStatus));

    await controller.dispose();
  });
}

LocalRepo _localRepository() => LocalRepo(
  rootPath: '/workspace/codex',
  commonGitDirectoryPath: '/workspace/codex/.git',
  isBare: false,
  selectedWorktreePath: '/workspace/codex',
  worktrees: const <Worktree>[
    Worktree(
      path: '/workspace/codex',
      isMain: true,
      isDetached: false,
      headSha: 'abc123',
      branch: 'develop',
      branchLink: BranchLink(
        localBranch: 'develop',
        remoteName: 'origin',
        remoteBranch: 'develop',
        ahead: 1,
        behind: 0,
      ),
      changes: GitChangeSummary.clean(),
    ),
  ],
  repositoryLinks: const <RepoLink>[
    RepoLink(
      localRootPath: '/workspace/codex',
      repository: GitHubRepositoryRef(owner: 'contributor', name: 'codex'),
      source: RepoLinkSource.remote,
      remoteName: 'origin',
      remoteRole: GitRemoteRole.origin,
    ),
    RepoLink(
      localRootPath: '/workspace/codex',
      repository: GitHubRepositoryRef(owner: 'openai', name: 'codex'),
      source: RepoLinkSource.remote,
      remoteName: 'upstream',
      remoteRole: GitRemoteRole.upstream,
    ),
  ],
  unmatchedRemoteNames: const <String>[],
);

final class _FakeGitHubGateway implements GitHubGateway {
  _FakeGitHubGateway(this.repositoryRef);

  final GitHubRepositoryRef repositoryRef;
  GitHubGatewayException? failure;
  String? lastHeadOwner;

  @override
  Future<WorkbenchRepository> fetchRepository(
    final GitHubRepositoryRef repository, {
    final bool refresh = false,
  }) async => WorkbenchRepository(
    ref: repositoryRef,
    nodeId: 'R_123',
    htmlUrl: Uri.parse('https://github.com/openai/codex'),
    defaultBranch: 'develop',
    isPrivate: false,
    isArchived: false,
  );

  @override
  Future<WorkbenchHeadStatus> fetchHeadStatus(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    final String? branch,
    final String? headOwner,
    final bool refresh = false,
  }) async {
    lastHeadOwner = headOwner;
    final GitHubGatewayException? currentFailure = failure;
    if (currentFailure != null) {
      throw currentFailure;
    }
    return WorkbenchHeadStatus(
      headSha: headSha,
      branch: branch,
      rollupState: WorkbenchCheckRollupState.success,
      pullRequests: const <WorkbenchPullRequestSummary>[],
      checks: const <WorkbenchCheckSummary>[],
    );
  }

  @override
  Future<List<WorkbenchCheckAnnotation>> listCheckAnnotations(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    final bool refresh = false,
  }) async => const <WorkbenchCheckAnnotation>[
    WorkbenchCheckAnnotation(
      checkName: 'analyze',
      path: 'lib/main.dart',
      level: WorkbenchAnnotationLevel.warning,
      message: 'Prefer a typed value.',
      location: WorkbenchSourceSpan(
        start: WorkbenchSourcePosition(line: 8),
        end: WorkbenchSourcePosition(line: 8),
      ),
    ),
  ];

  @override
  Future<WorkbenchWorkflowRun> fetchWorkflowRun(
    final GitHubRepositoryRef repository, {
    required final int runId,
  }) => throw UnimplementedError();

  @override
  Future<WorkbenchWorkflowJobsPage> listWorkflowJobs(
    final GitHubRepositoryRef repository, {
    required final int runId,
    final String? filter,
    final int page = 1,
    final int perPage = 30,
  }) => throw UnimplementedError();

  @override
  Future<WorkbenchWorkflowRunsPage> listWorkflowRuns(
    final GitHubRepositoryRef repository, {
    final String? branch,
    final int page = 1,
    final int perPage = 20,
    final bool refresh = false,
  }) => throw UnimplementedError();
}
