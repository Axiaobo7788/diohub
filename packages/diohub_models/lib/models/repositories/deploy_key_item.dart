import 'package:freezed_annotation/freezed_annotation.dart';

part 'deploy_key_item.freezed.dart';
part 'deploy_key_item.g.dart';

/// One deploy key from REST GET /repos/{owner}/{repo}/keys.
@freezed
abstract class DeployKeyItem with _$DeployKeyItem {
  const factory DeployKeyItem({
    required int id,
    required String key,
    required String title,
    @Default(false) bool verified,
    @JsonKey(name: 'read_only') @Default(false) bool readOnly,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    String? url,
    @JsonKey(name: 'last_used') DateTime? lastUsedAt,
  }) = _DeployKeyItem;

  factory DeployKeyItem.fromJson(Map<String, dynamic> json) =>
      _$DeployKeyItemFromJson(json);
}
