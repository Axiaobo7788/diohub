import 'package:diohub/workbench/data/diohub_legacy_github_gateway.dart';
import 'package:diohub/workbench/domain/workbench_models.dart';
import 'package:diohub_models/models/repositories/workflow_job.dart';
import 'package:diohub_models/models/repositories/workflow_run.dart';
import 'package:test/test.dart';

void main() {
  const GitHubRepositoryRef repository = GitHubRepositoryRef(
    owner: 'openai',
    name: 'codex',
  );

  test(
    'maps legacy repository data without leaking generated models',
    () async {
      final DioHubLegacyGitHubGateway gateway = DioHubLegacyGitHubGateway(
        _FakeLegacySource(),
      );

      final WorkbenchRepository result = await gateway.fetchRepository(
        repository,
        refresh: true,
      );

      expect(result.ref, repository);
      expect(result.nodeId, 'R_123');
      expect(result.defaultBranch, 'main');
      expect(result.htmlUrl, Uri.parse('https://github.com/openai/codex'));
    },
  );

  test('maps workflow runs into stable Workbench values', () async {
    final DioHubLegacyGitHubGateway gateway = DioHubLegacyGitHubGateway(
      _FakeLegacySource(),
    );

    final WorkbenchWorkflowRunsPage result = await gateway.listWorkflowRuns(
      repository,
      branch: 'develop',
      page: 2,
      perPage: 10,
      refresh: true,
    );

    expect(result.totalCount, 1);
    expect(result.runs, hasLength(1));
    final WorkbenchWorkflowRun run = result.runs.single;
    expect(run.id, 42);
    expect(run.status, WorkbenchWorkflowStatus.completed);
    expect(run.conclusion, WorkbenchWorkflowConclusion.failure);
    expect(run.headBranch, 'develop');
    expect(run.headSha, 'abc123');
    expect(run.actorLogin, 'octocat');
    expect(run.pullRequestNumbers, <int>[185]);
    expect(run.isCompleted, isTrue);
  });

  test('maps jobs and steps without Flutter or provider state', () async {
    final DioHubLegacyGitHubGateway gateway = DioHubLegacyGitHubGateway(
      _FakeLegacySource(),
    );

    final WorkbenchWorkflowJobsPage result = await gateway.listWorkflowJobs(
      repository,
      runId: 42,
    );

    expect(result.totalCount, 1);
    final WorkbenchWorkflowJob job = result.jobs.single;
    expect(job.status, WorkbenchWorkflowStatus.inProgress);
    expect(job.labels, <String>['ubuntu-latest']);
    expect(job.steps.single.conclusion, WorkbenchWorkflowConclusion.success);
  });

  test(
    'maps and deduplicates HEAD and branch pull requests with checks',
    () async {
      final DioHubLegacyGitHubGateway gateway = DioHubLegacyGitHubGateway(
        _FakeLegacySource(),
      );

      final WorkbenchHeadStatus result = await gateway.fetchHeadStatus(
        repository,
        headSha: 'abc123',
        branch: 'develop',
      );

      expect(result.headSha, 'abc123');
      expect(result.branch, 'develop');
      expect(result.rollupState, WorkbenchCheckRollupState.failure);
      expect(result.pullRequests, hasLength(1));
      expect(result.pullRequests.single.number, 185);
      expect(result.pullRequests.single.state, WorkbenchPullRequestState.open);
      expect(result.checks, hasLength(2));
      expect(result.checks.first.kind, WorkbenchCheckKind.checkRun);
      expect(result.checks.first.status, WorkbenchCheckStatus.completed);
      expect(result.checks.first.conclusion, WorkbenchCheckConclusion.failure);
      expect(result.checks.last.kind, WorkbenchCheckKind.statusContext);
      expect(result.checks.last.status, WorkbenchCheckStatus.success);
    },
  );

  test('maps annotation path and source span for editor handoff', () async {
    final DioHubLegacyGitHubGateway gateway = DioHubLegacyGitHubGateway(
      _FakeLegacySource(),
    );

    final List<WorkbenchCheckAnnotation> result = await gateway
        .listCheckAnnotations(repository, headSha: 'abc123');

    final WorkbenchCheckAnnotation annotation = result.single;
    expect(annotation.checkName, 'analyze');
    expect(annotation.level, WorkbenchAnnotationLevel.failure);
    expect(annotation.checkConclusion, WorkbenchCheckConclusion.failure);
    expect(annotation.path, 'lib/main.dart');
    expect(annotation.location.start.line, 12);
    expect(annotation.location.start.column, 3);
    expect(annotation.location.end.line, 14);
  });

  test('unknown GitHub values remain explicit instead of throwing', () async {
    final DioHubLegacyGitHubGateway gateway = DioHubLegacyGitHubGateway(
      _FakeLegacySource(runStatus: 'future_status', conclusion: 'new_result'),
    );

    final WorkbenchWorkflowRun run = await gateway.fetchWorkflowRun(
      repository,
      runId: 42,
    );

    expect(run.status, WorkbenchWorkflowStatus.unknown);
    expect(run.conclusion, WorkbenchWorkflowConclusion.unknown);
  });
}

final class _FakeLegacySource implements DioHubLegacyGatewaySource {
  _FakeLegacySource({
    this.runStatus = 'completed',
    this.conclusion = 'failure',
  });

  final String runStatus;
  final String conclusion;

  @override
  Future<DioHubLegacyHeadStatusData> fetchHeadStatus(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    required final String? branch,
    required final String? headOwner,
    required final bool refresh,
  }) async => DioHubLegacyHeadStatusData(
    headSha: headSha,
    branch: branch,
    rollupState: 'FAILURE',
    pullRequests: <DioHubLegacyPullRequestData>[
      DioHubLegacyPullRequestData(
        number: 185,
        title: 'Workbench boundary',
        htmlUrl: Uri.parse('https://github.com/openai/codex/pull/185'),
        state: 'OPEN',
        isDraft: false,
      ),
      DioHubLegacyPullRequestData(
        number: 185,
        title: 'Duplicate branch match',
        htmlUrl: Uri.parse('https://github.com/openai/codex/pull/185'),
        state: 'open',
        isDraft: false,
      ),
    ],
    checks: <DioHubLegacyCheckData>[
      DioHubLegacyCheckData(
        name: 'analyze',
        kind: 'check_run',
        status: 'COMPLETED',
        conclusion: 'FAILURE',
        detailsUrl: Uri.parse(
          'https://github.com/openai/codex/actions/runs/42',
        ),
      ),
      const DioHubLegacyCheckData(
        name: 'license/cla',
        kind: 'status_context',
        status: 'SUCCESS',
      ),
    ],
  );

  @override
  Future<DioHubLegacyRepositoryData> fetchRepository(
    final GitHubRepositoryRef repository, {
    required final bool refresh,
  }) async => DioHubLegacyRepositoryData(
    nodeId: 'R_123',
    htmlUrl: Uri.parse('https://github.com/openai/codex'),
    description: 'Developer agent',
    defaultBranch: 'main',
    isPrivate: false,
    isArchived: false,
  );

  @override
  Future<WorkflowRunItem> fetchWorkflowRun(
    final GitHubRepositoryRef repository, {
    required final int runId,
  }) async => _run();

  @override
  Future<WorkflowJobsResponse> listWorkflowJobs(
    final GitHubRepositoryRef repository, {
    required final int runId,
    required final String? filter,
    required final int page,
    required final int perPage,
  }) async => const WorkflowJobsResponse(
    totalCount: 1,
    jobs: <WorkflowJob>[
      WorkflowJob(
        id: 7,
        runId: 42,
        name: 'test',
        status: 'in_progress',
        startedAt: '2026-07-21T00:00:00Z',
        labels: <String>['ubuntu-latest'],
        steps: <WorkflowStep>[
          WorkflowStep(
            name: 'Analyze',
            status: 'completed',
            conclusion: 'success',
            number: 1,
          ),
        ],
      ),
    ],
  );

  @override
  Future<List<DioHubLegacyAnnotationData>> listCheckAnnotations(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    required final bool refresh,
  }) async => const <DioHubLegacyAnnotationData>[
    DioHubLegacyAnnotationData(
      checkName: 'analyze',
      checkConclusion: 'FAILURE',
      path: 'lib/main.dart',
      level: 'FAILURE',
      message: 'Avoid dynamic calls.',
      startLine: 12,
      startColumn: 3,
      endLine: 14,
      endColumn: 8,
    ),
  ];

  @override
  Future<WorkflowRunsResponse> listWorkflowRuns(
    final GitHubRepositoryRef repository, {
    required final String? branch,
    required final int page,
    required final int perPage,
    required final bool refresh,
  }) async => WorkflowRunsResponse(
    totalCount: 1,
    workflowRuns: <WorkflowRunItem>[_run()],
  );

  WorkflowRunItem _run() => WorkflowRunItem(
    id: 42,
    name: 'CI',
    status: runStatus,
    conclusion: conclusion,
    headBranch: 'develop',
    headSha: 'abc123',
    runNumber: 9,
    triggeringActor: const WorkflowActor(login: 'octocat'),
    headCommit: const WorkflowHeadCommit(message: 'Split Workbench boundary'),
    pullRequests: const <WorkflowPullRequest>[WorkflowPullRequest(number: 185)],
  );
}
