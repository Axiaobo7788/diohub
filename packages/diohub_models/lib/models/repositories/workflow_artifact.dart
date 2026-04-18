import 'package:diohub_models/models/canonical_node_id.dart';

/// Single workflow run artifact from GitHub REST GET .../actions/runs/{id}/artifacts.
class WorkflowArtifact {
  const WorkflowArtifact({
    required this.id,
    required this.nodeId,
    required this.name,
    required this.sizeInBytes,
    required this.archiveDownloadUrl,
    required this.expired,
    this.createdAt,
    this.expiresAt,
  });

  final int id;
  final String nodeId;
  final String name;
  final int sizeInBytes;
  final String archiveDownloadUrl;
  final bool expired;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  factory WorkflowArtifact.fromJson(Map<String, dynamic> json) {
    return WorkflowArtifact(
      id: json['id'] as int,
      nodeId: (json['node_id'] as String).asGitHubNodeId,
      name: json['name'] as String,
      sizeInBytes: json['size_in_bytes'] as int,
      archiveDownloadUrl: json['archive_download_url'] as String,
      expired: json['expired'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'node_id': nodeId,
        'name': name,
        'size_in_bytes': sizeInBytes,
        'archive_download_url': archiveDownloadUrl,
        'expired': expired,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };
}

/// Response of GitHub REST GET .../actions/runs/{id}/artifacts.
class WorkflowArtifactsResponse {
  const WorkflowArtifactsResponse({
    required this.totalCount,
    required this.artifacts,
  });

  final int totalCount;
  final List<WorkflowArtifact> artifacts;

  factory WorkflowArtifactsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> list = json['artifacts'] as List<dynamic>? ?? [];
    return WorkflowArtifactsResponse(
      totalCount: json['total_count'] as int? ?? 0,
      artifacts: list
          .map((e) => WorkflowArtifact.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'total_count': totalCount,
        'artifacts': artifacts.map((e) => e.toJson()).toList(),
      };
}
