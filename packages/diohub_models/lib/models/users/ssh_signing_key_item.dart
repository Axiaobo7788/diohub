import 'package:freezed_annotation/freezed_annotation.dart';

part 'ssh_signing_key_item.freezed.dart';
part 'ssh_signing_key_item.g.dart';

/// One SSH signing key from REST GET /user/ssh_signing_keys.
@freezed
abstract class SSHSigningKeyItem with _$SSHSigningKeyItem {
  const factory SSHSigningKeyItem({
    required int id,
    @Default('') String title,
    @Default('') String key,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _SSHSigningKeyItem;

  factory SSHSigningKeyItem.fromJson(Map<String, dynamic> json) =>
      _$SSHSigningKeyItemFromJson(json);
}
