import 'package:freezed_annotation/freezed_annotation.dart';

part 'ssh_connection.freezed.dart';
part 'ssh_connection.g.dart';

/// How to authenticate to the SSH server.
enum SSHAuthMethod {
  key,
  password,
}

/// Saved SSH connection (host, port, username, auth method).
/// Password is not persisted; key ID references stored key in secure storage or raw key.
@freezed
abstract class SSHConnection with _$SSHConnection {
  const factory SSHConnection({
    required String id,
    required String label,
    required String host,
    @Default(22) int port,
    required String username,
    @Default(SSHAuthMethod.key) SSHAuthMethod authMethod,
    String? privateKeyId,
    String? password,
  }) = _SSHConnection;

  factory SSHConnection.fromJson(Map<String, dynamic> json) =>
      _$SSHConnectionFromJson(json);
}
