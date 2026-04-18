import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow_job.freezed.dart';
part 'workflow_job.g.dart';

/// Response of GitHub REST GET /repos/{owner}/{repo}/actions/runs/{run_id}/jobs.
@freezed
abstract class WorkflowJobsResponse with _$WorkflowJobsResponse {
  const factory WorkflowJobsResponse({
    @JsonKey(name: 'total_count') @Default(0) int totalCount,
    @Default([]) List<WorkflowJob> jobs,
  }) = _WorkflowJobsResponse;

  factory WorkflowJobsResponse.fromJson(Map<String, dynamic> json) =>
      _$WorkflowJobsResponseFromJson(json);
}

/// Single job in a workflow run.
@freezed
abstract class WorkflowJob with _$WorkflowJob {
  const factory WorkflowJob({
    required int id,
    @JsonKey(name: 'run_id') required int runId,
    required String name,
    required String status,
    String? conclusion,
    @JsonKey(name: 'started_at') required String? startedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
    @JsonKey(name: 'html_url') String? htmlUrl,
    @JsonKey(name: 'runner_name') String? runnerName,
    @JsonKey(name: 'runner_group_name') String? runnerGroupName,
    @Default([]) List<String> labels,
    @Default([]) List<WorkflowStep> steps,
  }) = _WorkflowJob;

  factory WorkflowJob.fromJson(Map<String, dynamic> json) =>
      _$WorkflowJobFromJson(json);
}

/// Single step within a workflow job.
@freezed
abstract class WorkflowStep with _$WorkflowStep {
  const factory WorkflowStep({
    required String name,
    required String status,
    String? conclusion,
    required int number,
    @JsonKey(name: 'started_at') String? startedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
  }) = _WorkflowStep;

  factory WorkflowStep.fromJson(Map<String, dynamic> json) =>
      _$WorkflowStepFromJson(json);
}
