import 'package:freezed_annotation/freezed_annotation.dart';

part 'pat_request.freezed.dart';

/// Personal Access Token (PAT) request awaiting approval in an organization.
@freezed
abstract class PatRequest with _$PatRequest {
  const factory PatRequest({
    required int id,
    required String owner,
    String? ownerAvatarUrl,
    required String tokenName,
    DateTime? tokenLastUsedAt,
    required DateTime createdAt,
    required Map<String, String> permissions,  // removed @Default({}) since we initialize in fromJson
    List<String>? repositories,
    String? reason,
  }) = _PatRequest;

  factory PatRequest.fromJson(Map<String, dynamic> json) {
    return PatRequest(
      id: json['id'] as int,
      owner: json['owner'] is String
          ? json['owner'] as String
          : (json['owner'] as Map?)?['login'] as String? ?? '',
      ownerAvatarUrl: json['owner_avatar_url'] as String? ??
          (json['owner'] as Map?)?['avatar_url'] as String?,
      tokenName: json['token_name'] as String? ??
          (json['token'] as Map?)?['name'] as String? ??
          '',
      tokenLastUsedAt: json['token_last_used_at'] != null
          ? DateTime.parse(json['token_last_used_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      permissions:
          Map<String, String>.from(json['permissions'] as Map? ?? {}),
      repositories: (json['repositories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      reason: json['reason'] as String?,
    );
  }
}
