import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow_run.freezed.dart';
part 'workflow_run.g.dart';

/// Response of GitHub REST GET /repos/{owner}/{repo}/actions/runs.
@freezed
abstract class WorkflowRunsResponse with _$WorkflowRunsResponse {
  const factory WorkflowRunsResponse({
    @JsonKey(name: 'total_count') @Default(0) final int totalCount,
    @JsonKey(name: 'workflow_runs') @Default([]) final List<WorkflowRunItem> workflowRuns,
  }) = _WorkflowRunsResponse;

  factory WorkflowRunsResponse.fromJson(final Map<String, dynamic> json) =>
      _$WorkflowRunsResponseFromJson(json);
}

/// Actor who triggered the workflow.
@freezed
abstract class WorkflowActor with _$WorkflowActor {
  const factory WorkflowActor({
    final String? login,
    @JsonKey(name: 'avatar_url') final String? avatarUrl,
  }) = _WorkflowActor;

  factory WorkflowActor.fromJson(final Map<String, dynamic> json) =>
      _$WorkflowActorFromJson(json);
}

/// Head commit info in a workflow run.
@freezed
abstract class WorkflowHeadCommit with _$WorkflowHeadCommit {
  const factory WorkflowHeadCommit({
    final String? id,
    final String? message,
  }) = _WorkflowHeadCommit;

  factory WorkflowHeadCommit.fromJson(final Map<String, dynamic> json) =>
      _$WorkflowHeadCommitFromJson(json);
}

/// Pull request info associated with a workflow run.
@freezed
abstract class WorkflowPullRequest with _$WorkflowPullRequest {
  const factory WorkflowPullRequest({
    required final int number,
    @JsonKey(name: 'head') final WorkflowPRRef? head,
    @JsonKey(name: 'base') final WorkflowPRRef? base,
  }) = _WorkflowPullRequest;

  factory WorkflowPullRequest.fromJson(final Map<String, dynamic> json) =>
      _$WorkflowPullRequestFromJson(json);
}

/// PR ref (head or base branch).
@freezed
abstract class WorkflowPRRef with _$WorkflowPRRef {
  const factory WorkflowPRRef({
    final String? ref,
    final String? sha,
  }) = _WorkflowPRRef;

  factory WorkflowPRRef.fromJson(final Map<String, dynamic> json) =>
      _$WorkflowPRRefFromJson(json);
}

/// Referenced workflow (reusable workflow call).
@freezed
abstract class ReferencedWorkflow with _$ReferencedWorkflow {
  const factory ReferencedWorkflow({
    final String? path,
    final String? sha,
    final String? ref,
  }) = _ReferencedWorkflow;

  factory ReferencedWorkflow.fromJson(final Map<String, dynamic> json) =>
      _$ReferencedWorkflowFromJson(json);
}

/// Single workflow run from the actions/runs list.
@freezed
abstract class WorkflowRunItem with _$WorkflowRunItem {
  const factory WorkflowRunItem({
    required final int id,
    final String? name,
    final String? status,
    final String? conclusion,
    @JsonKey(name: 'head_branch') final String? headBranch,
    @JsonKey(name: 'created_at') final String? createdAt,
    @JsonKey(name: 'updated_at') final String? updatedAt,
    @JsonKey(name: 'html_url') final String? htmlUrl,
    @JsonKey(name: 'run_number') final int? runNumber,
    final String? event,
    @JsonKey(name: 'head_sha') final String? headSha,
    @JsonKey(name: 'display_title') final String? displayTitle,
    @JsonKey(name: 'run_attempt') final int? runAttempt,
    @JsonKey(name: 'triggering_actor') final WorkflowActor? triggeringActor,
    @JsonKey(name: 'head_commit') final WorkflowHeadCommit? headCommit,
    @JsonKey(name: 'workflow_id') final int? workflowId,
    @JsonKey(name: 'run_started_at') final String? runStartedAt,
    @JsonKey(name: 'jobs_url') final String? jobsUrl,
    @JsonKey(name: 'pull_requests') @Default([]) final List<WorkflowPullRequest> pullRequests,
    @JsonKey(name: 'referenced_workflows') @Default([]) final List<ReferencedWorkflow> referencedWorkflows,
  }) = _WorkflowRunItem;

  factory WorkflowRunItem.fromJson(final Map<String, dynamic> json) =>
      _$WorkflowRunItemFromJson(json);
}
