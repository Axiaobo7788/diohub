/// Identifies a GitHub repository without depending on DioHub's legacy models.
final class GitHubRepositoryRef {
  const GitHubRepositoryRef({
    required this.owner,
    required this.name,
    this.host = 'github.com',
  });

  final String host;
  final String owner;
  final String name;

  String get slug => '$owner/$name';

  @override
  // The class is final and all fields are final, so value equality is safe.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is GitHubRepositoryRef &&
          host == other.host &&
          owner == other.owner &&
          name == other.name;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hash(host, owner, name);

  @override
  String toString() => '$host/$slug';
}

/// Repository information required by the first Workbench slice.
final class WorkbenchRepository {
  const WorkbenchRepository({
    required this.ref,
    required this.nodeId,
    required this.htmlUrl,
    required this.isPrivate,
    required this.isArchived,
    this.description,
    this.defaultBranch,
  });

  final GitHubRepositoryRef ref;
  final String nodeId;
  final Uri htmlUrl;
  final String? description;
  final String? defaultBranch;
  final bool isPrivate;
  final bool isArchived;
}

enum WorkbenchWorkflowStatus {
  queued,
  inProgress,
  completed,
  waiting,
  requested,
  pending,
  unknown,
}

enum WorkbenchWorkflowConclusion {
  success,
  failure,
  cancelled,
  skipped,
  neutral,
  timedOut,
  actionRequired,
  stale,
  startupFailure,
  unknown,
}

/// Stable Workbench representation of a GitHub Actions run.
final class WorkbenchWorkflowRun {
  WorkbenchWorkflowRun({
    required this.id,
    required this.status,
    required final List<int> pullRequestNumbers,
    this.name,
    this.displayTitle,
    this.conclusion,
    this.headBranch,
    this.headSha,
    this.headCommitMessage,
    this.event,
    this.runNumber,
    this.runAttempt,
    this.actorLogin,
    this.htmlUrl,
    this.createdAt,
    this.updatedAt,
    this.startedAt,
  }) : pullRequestNumbers = List<int>.unmodifiable(pullRequestNumbers);

  final int id;
  final String? name;
  final String? displayTitle;
  final WorkbenchWorkflowStatus status;
  final WorkbenchWorkflowConclusion? conclusion;
  final String? headBranch;
  final String? headSha;
  final String? headCommitMessage;
  final String? event;
  final int? runNumber;
  final int? runAttempt;
  final String? actorLogin;
  final Uri? htmlUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? startedAt;
  final List<int> pullRequestNumbers;

  bool get isCompleted => status == WorkbenchWorkflowStatus.completed;
}

final class WorkbenchWorkflowRunsPage {
  WorkbenchWorkflowRunsPage({
    required this.totalCount,
    required final List<WorkbenchWorkflowRun> runs,
  }) : runs = List<WorkbenchWorkflowRun>.unmodifiable(runs);

  final int totalCount;
  final List<WorkbenchWorkflowRun> runs;
}

final class WorkbenchWorkflowStep {
  const WorkbenchWorkflowStep({
    required this.number,
    required this.name,
    required this.status,
    this.conclusion,
    this.startedAt,
    this.completedAt,
  });

  final int number;
  final String name;
  final WorkbenchWorkflowStatus status;
  final WorkbenchWorkflowConclusion? conclusion;
  final DateTime? startedAt;
  final DateTime? completedAt;
}

final class WorkbenchWorkflowJob {
  WorkbenchWorkflowJob({
    required this.id,
    required this.runId,
    required this.name,
    required this.status,
    required final List<String> labels,
    required final List<WorkbenchWorkflowStep> steps,
    this.conclusion,
    this.startedAt,
    this.completedAt,
    this.htmlUrl,
    this.runnerName,
    this.runnerGroupName,
  }) : labels = List<String>.unmodifiable(labels),
       steps = List<WorkbenchWorkflowStep>.unmodifiable(steps);

  final int id;
  final int runId;
  final String name;
  final WorkbenchWorkflowStatus status;
  final WorkbenchWorkflowConclusion? conclusion;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Uri? htmlUrl;
  final String? runnerName;
  final String? runnerGroupName;
  final List<String> labels;
  final List<WorkbenchWorkflowStep> steps;
}

final class WorkbenchWorkflowJobsPage {
  WorkbenchWorkflowJobsPage({
    required this.totalCount,
    required final List<WorkbenchWorkflowJob> jobs,
  }) : jobs = List<WorkbenchWorkflowJob>.unmodifiable(jobs);

  final int totalCount;
  final List<WorkbenchWorkflowJob> jobs;
}

enum WorkbenchPullRequestState { open, closed, merged, unknown }

/// Pull request associated with either the selected branch or its HEAD commit.
final class WorkbenchPullRequestSummary {
  const WorkbenchPullRequestSummary({
    required this.number,
    required this.title,
    required this.htmlUrl,
    required this.state,
    required this.isDraft,
  });

  final int number;
  final String title;
  final Uri htmlUrl;
  final WorkbenchPullRequestState state;
  final bool isDraft;
}

enum WorkbenchCheckKind { checkRun, statusContext }

enum WorkbenchCheckStatus {
  queued,
  inProgress,
  completed,
  waiting,
  requested,
  pending,
  expected,
  success,
  failure,
  error,
  unknown,
}

enum WorkbenchCheckConclusion {
  success,
  failure,
  cancelled,
  skipped,
  neutral,
  timedOut,
  actionRequired,
  stale,
  startupFailure,
  unknown,
}

enum WorkbenchCheckRollupState {
  error,
  expected,
  failure,
  pending,
  success,
  unknown,
}

/// One check run or legacy commit status context in the HEAD rollup.
final class WorkbenchCheckSummary {
  const WorkbenchCheckSummary({
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
  final WorkbenchCheckKind kind;
  final WorkbenchCheckStatus status;
  final WorkbenchCheckConclusion? conclusion;
  final Uri? detailsUrl;
  final String? appName;
  final Uri? appLogoUrl;
  final DateTime? startedAt;
  final DateTime? completedAt;
}

/// Remote status resolved for the selected local HEAD and optional branch.
final class WorkbenchHeadStatus {
  WorkbenchHeadStatus({
    required this.headSha,
    required this.rollupState,
    required final List<WorkbenchPullRequestSummary> pullRequests,
    required final List<WorkbenchCheckSummary> checks,
    this.branch,
  }) : pullRequests = List<WorkbenchPullRequestSummary>.unmodifiable(
         pullRequests,
       ),
       checks = List<WorkbenchCheckSummary>.unmodifiable(checks);

  final String headSha;
  final String? branch;
  final WorkbenchCheckRollupState rollupState;
  final List<WorkbenchPullRequestSummary> pullRequests;
  final List<WorkbenchCheckSummary> checks;
}

enum WorkbenchAnnotationLevel { notice, warning, failure, unknown }

final class WorkbenchSourcePosition {
  const WorkbenchSourcePosition({required this.line, this.column});

  final int line;
  final int? column;
}

final class WorkbenchSourceSpan {
  const WorkbenchSourceSpan({required this.start, required this.end});

  final WorkbenchSourcePosition start;
  final WorkbenchSourcePosition end;
}

/// Check annotation that can later be resolved against a local worktree.
final class WorkbenchCheckAnnotation {
  const WorkbenchCheckAnnotation({
    required this.checkName,
    required this.path,
    required this.level,
    required this.message,
    required this.location,
    this.checkConclusion,
    this.title,
    this.rawDetails,
  });

  final String checkName;
  final WorkbenchCheckConclusion? checkConclusion;
  final String path;
  final WorkbenchAnnotationLevel level;
  final String message;
  final String? title;
  final String? rawDetails;
  final WorkbenchSourceSpan location;
}
