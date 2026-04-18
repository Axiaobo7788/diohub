import 'package:freezed_annotation/freezed_annotation.dart';

part 'ssh_key_item.freezed.dart';

/// One SSH key from REST GET /user/keys (viewer) or GQL publicKeys (other users).
@freezed
abstract class SSHKeyItem with _$SSHKeyItem {
  const factory SSHKeyItem({
    required int id,
    required String title,
    required String key,
    required String fingerprint,
    required DateTime createdAt,
    DateTime? lastUsedAt,
    @Default(false) bool readOnly,
  }) = _SSHKeyItem;

  factory SSHKeyItem.fromJson(Map<String, dynamic> json) {
    final keyStr = json['key'] as String;
    return SSHKeyItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      key: keyStr,
      fingerprint:
          json['fingerprint'] as String? ?? _extractFingerprint(keyStr),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      readOnly: json['read_only'] as bool? ?? false,
    );
  }
}

/// Derives a short display fingerprint from the key when API does not provide one.
/// SSH key format: "type base64data [comment]". We use a prefix of the base64 part.
String _extractFingerprint(String key) {
  final parts = key.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[1].length >= 16) {
    return 'SHA256:${parts[1].substring(0, 16)}...';
  }
  if (key.length > 24) {
    return '${key.substring(0, 24)}...';
  }
  return key;
}
