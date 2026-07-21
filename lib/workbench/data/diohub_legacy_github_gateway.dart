import 'package:diohub/workbench/domain/github_gateway.dart';
import 'package:diohub/workbench/domain/workbench_models.dart';
import 'package:diohub_models/models/repositories/workflow_job.dart';
import 'package:diohub_models/models/repositories/workflow_run.dart';

/// Minimal repository projection returned by the legacy source.
///
/// Keeping this projection here prevents generated GraphQL types from crossing
/// into the Workbench domain.
final class DioHubLegacyRepositoryData {
  const DioHubLegacyRepositoryData({
    required this.nodeId,
    required this.htmlUrl,
    required this.isPrivate,
    required this.isArchived,
    this.description,
    this.defaultBranch,
  });

  final String nodeId;
  final Uri htmlUrl;
  final String? description;
  final String? defaultBranch;
  final bool isPrivate;
  final bool isArchived;
}

final class DioHubLegacyPullRequestData {
  const DioHubLegacyPullRequestData({
    required this.number,
    required this.title,
    required this.htmlUrl,
    required this.state,
    required this.isDraft,
  });

  final int number;
  final String title;
  final Uri htmlUrl;
  final String state;
  final bool isDraft;
}

final class DioHubLegacyCheckData {
  const DioHubLegacyCheckData({
    required this.name,
    required this.kind,
    required this.status,
    this.conclusion,
    this.detailsUrl,
    this.appName,
    this.appLogoUrl,
    this.startedAt,
    this.completedAt,
  });

  final String name;
  final String kind;
  final String status;
  final String? conclusion;
  final Uri? detailsUrl;
  final String? appName;
  final Uri? appLogoUrl;
  final DateTime? startedAt;
  final DateTime? completedAt;
}

final class DioHubLegacyHeadStatusData {
  DioHubLegacyHeadStatusData({
    required this.headSha,
    required this.rollupState,
    required final List<DioHubLegacyPullRequestData> pullRequests,
    required final List<DioHubLegacyCheckData> checks,
    this.branch,
  }) : pullRequests = List<DioHubLegacyPullRequestData>.unmodifiable(
         pullRequests,
       ),
       checks = List<DioHubLegacyCheckData>.unmodifiable(checks);

  final String headSha;
  final String? branch;
  final String? rollupState;
  final List<DioHubLegacyPullRequestData> pullRequests;
  final List<DioHubLegacyCheckData> checks;
}

final class DioHubLegacyAnnotationData {
  const DioHubLegacyAnnotationData({
    required this.checkName,
    required this.path,
    required this.level,
    required this.message,
    required this.startLine,
    required this.endLine,
    this.checkConclusion,
    this.startColumn,
    this.endColumn,
    this.title,
    this.rawDetails,
  });

  final String checkName;
  final String? checkConclusion;
  final String path;
  final String? level;
  final String message;
  final String? title;
  final String? rawDetails;
  final int startLine;
  final int? startColumn;
  final int endLine;
  final int? endColumn;
}

/// Testable seam around the existing DioHub services.
abstract interface class DioHubLegacyGatewaySource {
  Future<DioHubLegacyRepositoryData> fetchRepository(
    final GitHubRepositoryRef repository, {
    required final bool refresh,
  });

  Future<WorkflowRunsResponse> listWorkflowRuns(
    final GitHubRepositoryRef repository, {
    required final String? branch,
    required final int page,
    required final int perPage,
    required final bool refresh,
  });

  Future<WorkflowRunItem> fetchWorkflowRun(
    final GitHubRepositoryRef repository, {
    required final int runId,
  });

  Future<WorkflowJobsResponse> listWorkflowJobs(
    final GitHubRepositoryRef repository, {
    required final int runId,
    required final String? filter,
    required final int page,
    required final int perPage,
  });

  Future<DioHubLegacyHeadStatusData> fetchHeadStatus(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    required final String? branch,
    required final String? headOwner,
    required final bool refresh,
  });

  Future<List<DioHubLegacyAnnotationData>> listCheckAnnotations(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    required final bool refresh,
  });
}

/// Adapts legacy DioHub API models to stable, Flutter-free Workbench models.
final class DioHubLegacyGitHubGateway implements GitHubGateway {
  const DioHubLegacyGitHubGateway(this._source);

  final DioHubLegacyGatewaySource _source;

  @override
  Future<WorkbenchRepository> fetchRepository(
    final GitHubRepositoryRef repository, {
    final bool refresh = false,
  }) async {
    final DioHubLegacyRepositoryData legacy = await _source.fetchRepository(
      repository,
      refresh: refresh,
    );
    return WorkbenchRepository(
      ref: repository,
      nodeId: legacy.nodeId,
      htmlUrl: legacy.htmlUrl,
      description: legacy.description,
      defaultBranch: legacy.defaultBranch,
      isPrivate: legacy.isPrivate,
      isArchived: legacy.isArchived,
    );
  }

  @override
  Future<WorkbenchHeadStatus> fetchHeadStatus(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    final String? branch,
    final String? headOwner,
    final bool refresh = false,
  }) async {
    final DioHubLegacyHeadStatusData legacy = await _source.fetchHeadStatus(
      repository,
      headSha: headSha,
      branch: branch,
      headOwner: headOwner,
      refresh: refresh,
    );
    final Map<int, WorkbenchPullRequestSummary> pullRequests =
        <int, WorkbenchPullRequestSummary>{};
    for (final DioHubLegacyPullRequestData pull in legacy.pullRequests) {
      pullRequests.putIfAbsent(pull.number, () => _mapPullRequest(pull));
    }
    return WorkbenchHeadStatus(
      headSha: legacy.headSha,
      branch: legacy.branch,
      rollupState: _mapRollupState(legacy.rollupState),
      pullRequests: pullRequests.values.toList(growable: false),
      checks: legacy.checks.map(_mapCheck).toList(growable: false),
    );
  }

  @override
  Future<WorkbenchWorkflowRun> fetchWorkflowRun(
    final GitHubRepositoryRef repository, {
    required final int runId,
  }) async => _mapRun(await _source.fetchWorkflowRun(repository, runId: runId));

  @override
  Future<WorkbenchWorkflowJobsPage> listWorkflowJobs(
    final GitHubRepositoryRef repository, {
    required final int runId,
    final String? filter,
    final int page = 1,
    final int perPage = 30,
  }) async {
    final WorkflowJobsResponse legacy = await _source.listWorkflowJobs(
      repository,
      runId: runId,
      filter: filter,
      page: page,
      perPage: perPage,
    );
    return WorkbenchWorkflowJobsPage(
      totalCount: legacy.totalCount,
      jobs: legacy.jobs.map(_mapJob).toList(growable: false),
    );
  }

  @override
  Future<List<WorkbenchCheckAnnotation>> listCheckAnnotations(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    final bool refresh = false,
  }) async => (await _source.listCheckAnnotations(
    repository,
    headSha: headSha,
    refresh: refresh,
  )).map(_mapAnnotation).toList(growable: false);

  @override
  Future<WorkbenchWorkflowRunsPage> listWorkflowRuns(
    final GitHubRepositoryRef repository, {
    final String? branch,
    final int page = 1,
    final int perPage = 20,
    final bool refresh = false,
  }) async {
    final WorkflowRunsResponse legacy = await _source.listWorkflowRuns(
      repository,
      branch: branch,
      page: page,
      perPage: perPage,
      refresh: refresh,
    );
    return WorkbenchWorkflowRunsPage(
      totalCount: legacy.totalCount,
      runs: legacy.workflowRuns.map(_mapRun).toList(growable: false),
    );
  }

  static WorkbenchWorkflowJob _mapJob(final WorkflowJob job) =>
      WorkbenchWorkflowJob(
        id: job.id,
        runId: job.runId,
        name: job.name,
        status: _mapStatus(job.status),
        conclusion: _mapConclusion(job.conclusion),
        startedAt: _parseDate(job.startedAt),
        completedAt: _parseDate(job.completedAt),
        htmlUrl: _parseUri(job.htmlUrl),
        runnerName: job.runnerName,
        runnerGroupName: job.runnerGroupName,
        labels: job.labels,
        steps: job.steps
            .map(
              (final WorkflowStep step) => WorkbenchWorkflowStep(
                number: step.number,
                name: step.name,
                status: _mapStatus(step.status),
                conclusion: _mapConclusion(step.conclusion),
                startedAt: _parseDate(step.startedAt),
                completedAt: _parseDate(step.completedAt),
              ),
            )
            .toList(growable: false),
      );

  static WorkbenchWorkflowRun _mapRun(final WorkflowRunItem run) =>
      WorkbenchWorkflowRun(
        id: run.id,
        name: run.name,
        displayTitle: run.displayTitle,
        status: _mapStatus(run.status),
        conclusion: _mapConclusion(run.conclusion),
        headBranch: run.headBranch,
        headSha: run.headSha,
        headCommitMessage: run.headCommit?.message,
        event: run.event,
        runNumber: run.runNumber,
        runAttempt: run.runAttempt,
        actorLogin: run.triggeringActor?.login,
        htmlUrl: _parseUri(run.htmlUrl),
        createdAt: _parseDate(run.createdAt),
        updatedAt: _parseDate(run.updatedAt),
        startedAt: _parseDate(run.runStartedAt),
        pullRequestNumbers: run.pullRequests
            .map((final WorkflowPullRequest pull) => pull.number)
            .toList(growable: false),
      );

  static WorkbenchCheckAnnotation _mapAnnotation(
    final DioHubLegacyAnnotationData annotation,
  ) => WorkbenchCheckAnnotation(
    checkName: annotation.checkName,
    checkConclusion: _mapCheckConclusion(annotation.checkConclusion),
    path: annotation.path,
    level: _mapAnnotationLevel(annotation.level),
    message: annotation.message,
    title: annotation.title,
    rawDetails: annotation.rawDetails,
    location: WorkbenchSourceSpan(
      start: WorkbenchSourcePosition(
        line: annotation.startLine,
        column: annotation.startColumn,
      ),
      end: WorkbenchSourcePosition(
        line: annotation.endLine,
        column: annotation.endColumn,
      ),
    ),
  );

  static WorkbenchCheckSummary _mapCheck(final DioHubLegacyCheckData check) =>
      WorkbenchCheckSummary(
        name: check.name,
        kind: _normalized(check.kind) == 'status_context'
            ? WorkbenchCheckKind.statusContext
            : WorkbenchCheckKind.checkRun,
        status: _mapCheckStatus(check.status),
        conclusion: _mapCheckConclusion(check.conclusion),
        detailsUrl: check.detailsUrl,
        appName: check.appName,
        appLogoUrl: check.appLogoUrl,
        startedAt: check.startedAt,
        completedAt: check.completedAt,
      );

  static WorkbenchPullRequestSummary _mapPullRequest(
    final DioHubLegacyPullRequestData pull,
  ) => WorkbenchPullRequestSummary(
    number: pull.number,
    title: pull.title,
    htmlUrl: pull.htmlUrl,
    state: switch (_normalized(pull.state)) {
      'open' => WorkbenchPullRequestState.open,
      'closed' => WorkbenchPullRequestState.closed,
      'merged' => WorkbenchPullRequestState.merged,
      _ => WorkbenchPullRequestState.unknown,
    },
    isDraft: pull.isDraft,
  );

  static WorkbenchAnnotationLevel _mapAnnotationLevel(final String? value) =>
      switch (_normalized(value)) {
        'notice' => WorkbenchAnnotationLevel.notice,
        'warning' => WorkbenchAnnotationLevel.warning,
        'failure' => WorkbenchAnnotationLevel.failure,
        _ => WorkbenchAnnotationLevel.unknown,
      };

  static WorkbenchCheckConclusion? _mapCheckConclusion(final String? value) =>
      switch (_normalized(value)) {
        null => null,
        'success' => WorkbenchCheckConclusion.success,
        'failure' => WorkbenchCheckConclusion.failure,
        'cancelled' => WorkbenchCheckConclusion.cancelled,
        'skipped' => WorkbenchCheckConclusion.skipped,
        'neutral' => WorkbenchCheckConclusion.neutral,
        'timed_out' => WorkbenchCheckConclusion.timedOut,
        'action_required' => WorkbenchCheckConclusion.actionRequired,
        'stale' => WorkbenchCheckConclusion.stale,
        'startup_failure' => WorkbenchCheckConclusion.startupFailure,
        _ => WorkbenchCheckConclusion.unknown,
      };

  static WorkbenchCheckRollupState _mapRollupState(final String? value) =>
      switch (_normalized(value)) {
        'error' => WorkbenchCheckRollupState.error,
        'expected' => WorkbenchCheckRollupState.expected,
        'failure' => WorkbenchCheckRollupState.failure,
        'pending' => WorkbenchCheckRollupState.pending,
        'success' => WorkbenchCheckRollupState.success,
        _ => WorkbenchCheckRollupState.unknown,
      };

  static WorkbenchCheckStatus _mapCheckStatus(final String? value) =>
      switch (_normalized(value)) {
        'queued' => WorkbenchCheckStatus.queued,
        'in_progress' => WorkbenchCheckStatus.inProgress,
        'completed' => WorkbenchCheckStatus.completed,
        'waiting' => WorkbenchCheckStatus.waiting,
        'requested' => WorkbenchCheckStatus.requested,
        'pending' => WorkbenchCheckStatus.pending,
        'expected' => WorkbenchCheckStatus.expected,
        'success' => WorkbenchCheckStatus.success,
        'failure' => WorkbenchCheckStatus.failure,
        'error' => WorkbenchCheckStatus.error,
        _ => WorkbenchCheckStatus.unknown,
      };

  static WorkbenchWorkflowConclusion? _mapConclusion(final String? value) =>
      switch (value) {
        null => null,
        'success' => WorkbenchWorkflowConclusion.success,
        'failure' => WorkbenchWorkflowConclusion.failure,
        'cancelled' => WorkbenchWorkflowConclusion.cancelled,
        'skipped' => WorkbenchWorkflowConclusion.skipped,
        'neutral' => WorkbenchWorkflowConclusion.neutral,
        'timed_out' => WorkbenchWorkflowConclusion.timedOut,
        'action_required' => WorkbenchWorkflowConclusion.actionRequired,
        'stale' => WorkbenchWorkflowConclusion.stale,
        'startup_failure' => WorkbenchWorkflowConclusion.startupFailure,
        _ => WorkbenchWorkflowConclusion.unknown,
      };

  static WorkbenchWorkflowStatus _mapStatus(final String? value) =>
      switch (value) {
        'queued' => WorkbenchWorkflowStatus.queued,
        'in_progress' => WorkbenchWorkflowStatus.inProgress,
        'completed' => WorkbenchWorkflowStatus.completed,
        'waiting' => WorkbenchWorkflowStatus.waiting,
        'requested' => WorkbenchWorkflowStatus.requested,
        'pending' => WorkbenchWorkflowStatus.pending,
        _ => WorkbenchWorkflowStatus.unknown,
      };

  static DateTime? _parseDate(final String? value) =>
      value == null ? null : DateTime.tryParse(value);

  static Uri? _parseUri(final String? value) =>
      value == null ? null : Uri.tryParse(value);

  static String? _normalized(final String? value) =>
      value?.trim().toLowerCase();
}
