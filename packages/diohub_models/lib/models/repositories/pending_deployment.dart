import 'package:diohub_models/models/canonical_node_id.dart';

/// Pending deployment and environment from GitHub REST
/// GET .../actions/runs/{runId}/pending_deployments
class PendingDeployment {
  const PendingDeployment({
    required this.environment,
    required this.waitTimer,
    this.waitTimerStartedAt,
    required this.currentUserCanApprove,
    required this.reviewers,
  });

  final PendingEnvironment environment;
  final int waitTimer;
  final DateTime? waitTimerStartedAt;
  final bool currentUserCanApprove;
  final List<PendingReviewer> reviewers;

  factory PendingDeployment.fromJson(Map<String, dynamic> json) {
    return PendingDeployment(
      environment: PendingEnvironment.fromJson(
        json['environment'] as Map<String, dynamic>,
      ),
      waitTimer: json['wait_timer'] as int? ?? 0,
      waitTimerStartedAt: json['wait_timer_started_at'] != null
          ? DateTime.tryParse(json['wait_timer_started_at'] as String)
          : null,
      currentUserCanApprove: json['current_user_can_approve'] as bool? ?? false,
      reviewers: (json['reviewers'] as List<dynamic>?)
              ?.map((e) => PendingReviewer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'environment': environment.toJson(),
        'wait_timer': waitTimer,
        if (waitTimerStartedAt != null)
          'wait_timer_started_at': waitTimerStartedAt!.toIso8601String(),
        'current_user_can_approve': currentUserCanApprove,
        'reviewers': reviewers.map((e) => e.toJson()).toList(),
      };
}

class PendingEnvironment {
  const PendingEnvironment({
    required this.id,
    required this.nodeId,
    required this.name,
    required this.url,
    required this.htmlUrl,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String nodeId;
  final String name;
  final String url;
  final String htmlUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PendingEnvironment.fromJson(Map<String, dynamic> json) {
    return PendingEnvironment(
      id: json['id'] as int,
      nodeId: (json['node_id'] as String).asGitHubNodeId,
      name: json['name'] as String,
      url: json['url'] as String,
      htmlUrl: json['html_url'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'node_id': nodeId,
        'name': name,
        'url': url,
        'html_url': htmlUrl,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

class PendingReviewer {
  const PendingReviewer({required this.type, this.reviewer});

  final String type;
  final PendingReviewerUser? reviewer;

  factory PendingReviewer.fromJson(Map<String, dynamic> json) {
    return PendingReviewer(
      type: json['type'] as String? ?? 'user',
      reviewer: json['reviewer'] != null
          ? PendingReviewerUser.fromJson(
              json['reviewer'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        if (reviewer != null) 'reviewer': reviewer!.toJson(),
      };
}

class PendingReviewerUser {
  const PendingReviewerUser({
    required this.id,
    required this.login,
    this.avatarUrl,
  });

  final int id;
  final String login;
  final String? avatarUrl;

  factory PendingReviewerUser.fromJson(Map<String, dynamic> json) {
    return PendingReviewerUser(
      id: json['id'] as int,
      login: json['login'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'login': login,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
}
