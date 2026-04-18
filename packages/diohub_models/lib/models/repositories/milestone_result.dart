import 'package:freezed_annotation/freezed_annotation.dart';

part 'milestone_result.freezed.dart';
part 'milestone_result.g.dart';

/// REST response for create/update milestone.
@freezed
abstract class MilestoneResult with _$MilestoneResult {
  const factory MilestoneResult({
    required int number,
    required String title,
    String? description,
    required String state,
    @JsonKey(name: 'due_on') DateTime? dueOn,
    @JsonKey(name: 'html_url') required String htmlUrl,
    @JsonKey(name: 'node_id') String? nodeId,
    @JsonKey(name: 'open_issues') @Default(0) int openIssues,
    @JsonKey(name: 'closed_issues') @Default(0) int closedIssues,
  }) = _MilestoneResult;

  factory MilestoneResult.fromJson(final Map<String, dynamic> json) =>
      _$MilestoneResultFromJson(json);
}
