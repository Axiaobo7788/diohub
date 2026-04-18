import 'package:freezed_annotation/freezed_annotation.dart';

part 'gpg_key_item.freezed.dart';
part 'gpg_key_item.g.dart';

/// One GPG key from REST GET /user/gpg_keys.
@freezed
abstract class GpgKeyItem with _$GpgKeyItem {
  const factory GpgKeyItem({
    required int id,
    String? name,
    @JsonKey(name: 'primary_key_id') int? primaryKeyId,
    @JsonKey(name: 'key_id') required String keyId,
    @JsonKey(name: 'public_key') required String publicKey,
    @Default([]) List<GpgKeyEmail> emails,
    @Default([]) List<GpgSubkeySummary> subkeys,
    @JsonKey(name: 'can_sign') @Default(false) bool canSign,
    @JsonKey(name: 'can_encrypt_comms') @Default(false) bool canEncryptComms,
    @JsonKey(name: 'can_encrypt_storage') @Default(false) bool canEncryptStorage,
    @JsonKey(name: 'can_certify') @Default(false) bool canCertify,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @Default(false) bool revoked,
    @JsonKey(name: 'raw_key') String? rawKey,
  }) = _GpgKeyItem;

  factory GpgKeyItem.fromJson(Map<String, dynamic> json) =>
      _$GpgKeyItemFromJson(json);
}

@freezed
abstract class GpgKeyEmail with _$GpgKeyEmail {
  const factory GpgKeyEmail({
    @Default('') String email,
    @Default(false) bool verified,
  }) = _GpgKeyEmail;

  factory GpgKeyEmail.fromJson(Map<String, dynamic> json) =>
      _$GpgKeyEmailFromJson(json);
}

/// Minimal subkey info for display (count / capabilities from primary).
@freezed
abstract class GpgSubkeySummary with _$GpgSubkeySummary {
  const factory GpgSubkeySummary({
    required int id,
    @JsonKey(name: 'primary_key_id') required int primaryKeyId,
    @JsonKey(name: 'key_id') required String keyId,
  }) = _GpgSubkeySummary;

  factory GpgSubkeySummary.fromJson(Map<String, dynamic> json) =>
      _$GpgSubkeySummaryFromJson(json);
}
