import 'package:freezed_annotation/freezed_annotation.dart';

part 'environment.freezed.dart';
part 'environment.g.dart';

/// Repository environment from GitHub REST GET .../environments
@freezed
abstract class EnvironmentItem with _$EnvironmentItem {
  const factory EnvironmentItem({
    required int id,
    @JsonKey(name: 'node_id') required String nodeId,
    required String name,
    required String url,
    @JsonKey(name: 'html_url') required String htmlUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'protection_rules') List<ProtectionRule>? protectionRules,
    @JsonKey(name: 'deployment_branch_policy')
    DeploymentBranchPolicy? deploymentBranchPolicy,
  }) = _EnvironmentItem;

  factory EnvironmentItem.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentItemFromJson(json);
}

@freezed
abstract class ProtectionRule with _$ProtectionRule {
  const factory ProtectionRule({
    required int id,
    @JsonKey(name: 'node_id') required String nodeId,
    @Default('wait_timer') String type,
    @JsonKey(name: 'wait_timer') int? waitTimer,
    List<ProtectionRuleReviewer>? reviewers,
  }) = _ProtectionRule;

  factory ProtectionRule.fromJson(Map<String, dynamic> json) =>
      _$ProtectionRuleFromJson(json);
}

@freezed
abstract class ProtectionRuleReviewer with _$ProtectionRuleReviewer {
  const factory ProtectionRuleReviewer({
    @Default('user') String type,
    ProtectionRuleReviewerUser? reviewer,
  }) = _ProtectionRuleReviewer;

  factory ProtectionRuleReviewer.fromJson(Map<String, dynamic> json) =>
      _$ProtectionRuleReviewerFromJson(json);
}

@freezed
abstract class ProtectionRuleReviewerUser with _$ProtectionRuleReviewerUser {
  const factory ProtectionRuleReviewerUser({
    required int id,
    required String login,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _ProtectionRuleReviewerUser;

  factory ProtectionRuleReviewerUser.fromJson(Map<String, dynamic> json) =>
      _$ProtectionRuleReviewerUserFromJson(json);
}

@freezed
abstract class DeploymentBranchPolicy with _$DeploymentBranchPolicy {
  const factory DeploymentBranchPolicy({
    @JsonKey(name: 'protected_branches') @Default(false) bool protectedBranches,
    @JsonKey(name: 'custom_branch_policies')
    @Default(false)
    bool customBranchPolicies,
  }) = _DeploymentBranchPolicy;

  factory DeploymentBranchPolicy.fromJson(Map<String, dynamic> json) =>
      _$DeploymentBranchPolicyFromJson(json);
}

@freezed
abstract class EnvironmentsResponse with _$EnvironmentsResponse {
  const factory EnvironmentsResponse({
    @JsonKey(name: 'total_count') @Default(0) int totalCount,
    @Default([]) List<EnvironmentItem> environments,
  }) = _EnvironmentsResponse;

  factory EnvironmentsResponse.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentsResponseFromJson(json);
}
