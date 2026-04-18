import 'package:freezed_annotation/freezed_annotation.dart';

part 'collaborator_item.freezed.dart';
part 'collaborator_item.g.dart';

@freezed
abstract class CollaboratorItem with _$CollaboratorItem {
  const factory CollaboratorItem({
    required int id,
    required String login,
    @JsonKey(name: 'avatar_url') required String avatarUrl,
    String? type,
    @Default(CollaboratorPermissions()) CollaboratorPermissions permissions,
  }) = _CollaboratorItem;

  factory CollaboratorItem.fromJson(Map<String, dynamic> json) =>
      _$CollaboratorItemFromJson(json);
}

@freezed
abstract class CollaboratorPermissions with _$CollaboratorPermissions {
  const factory CollaboratorPermissions({
    @Default(false) bool admin,
    @Default(false) bool maintain,
    @Default(false) bool push,
    @Default(false) bool triage,
    @Default(false) bool pull,
  }) = _CollaboratorPermissions;

  factory CollaboratorPermissions.fromJson(Map<String, dynamic> json) =>
      _$CollaboratorPermissionsFromJson(json);
}
