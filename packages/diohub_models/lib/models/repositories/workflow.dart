import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow.freezed.dart';
part 'workflow.g.dart';

/// Single workflow definition from GitHub REST GET .../actions/workflows.
@freezed
abstract class Workflow with _$Workflow {
  const factory Workflow({
    required final int id,
    @JsonKey(name: 'node_id') required final String nodeId,
    required final String name,
    required final String path,
    required final String state,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') required final DateTime updatedAt,
    @JsonKey(name: 'badge_url') final String? badgeUrl,
  }) = _Workflow;

  factory Workflow.fromJson(final Map<String, dynamic> json) =>
      _$WorkflowFromJson(json);
}

/// Response of GitHub REST GET /repos/{owner}/{repo}/actions/workflows.
@freezed
abstract class WorkflowsResponse with _$WorkflowsResponse {
  const factory WorkflowsResponse({
    @JsonKey(name: 'total_count') @Default(0) final int totalCount,
    @Default([]) final List<Workflow> workflows,
  }) = _WorkflowsResponse;

  factory WorkflowsResponse.fromJson(final Map<String, dynamic> json) =>
      _$WorkflowsResponseFromJson(json);
}
