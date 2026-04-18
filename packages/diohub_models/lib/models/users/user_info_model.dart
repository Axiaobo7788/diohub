import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_info_model.freezed.dart';
part 'user_info_model.g.dart';

/// REST events API returns user id as int; GQL and other REST return String.
class _NullableIdConverter implements JsonConverter<String?, dynamic> {
  const _NullableIdConverter();

  @override
  String? fromJson(final dynamic json) {
    if (json == null) return null;
    if (json is int) return json.toString();
    if (json is String) return json;
    return json.toString();
  }

  @override
  dynamic toJson(final String? object) => object;
}

@freezed
abstract class SimpleUser with _$SimpleUser {
  const factory SimpleUser({
    required final String login,
    final String? avatarUrl,
    final String? name,
    final String? bio,
    final String? email,
    final String? company,
    final String? location,
    final String? blog,
    final String? twitterUsername,
    final DateTime? createdAt,
    @_NullableIdConverter() final String? id,
    final String? url,
    final bool? viewerIsFollowing,
    final bool? viewerCanFollow,
    final int? repositoryCount,
    final int? membersOrFollowersCount,
    final bool? isOrganization,
  }) = _SimpleUser;

  factory SimpleUser.fromJson(final Map<String, dynamic> json) =>
      _$SimpleUserFromJson(json);
}

typedef UserInfoModel = SimpleUser;
