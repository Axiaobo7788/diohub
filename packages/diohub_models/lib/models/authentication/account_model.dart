import 'package:diohub_models/models/server_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// AuthMethod is defined in server_config.dart and exported for backward compatibility.
export 'package:diohub_models/models/server_config.dart' show AuthMethod;

part 'account_model.freezed.dart';
part 'account_model.g.dart';

@immutable
@Freezed(equal: false) // Identity is nodeId + serverConfig only (see == override)
abstract class AccountModel with _$AccountModel {
  const AccountModel._();

  const factory AccountModel({
    required String nodeId,
    required String username,
    required DateTime addedAt,
    String? displayName,
    String? avatarUrl,
    String? scope,
    @Default(ServerConfig.gitHubDotCom) ServerConfig serverConfig,
    @Default(AuthMethod.oauth) AuthMethod authMethod,
  }) = _AccountModel;

  factory AccountModel.fromJson(final Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  // ── Derived ──

  /// Whether this account is on the default GitHub.com server.
  bool get isDefault => serverConfig.isDefault;

  /// Host authority for display (e.g. 'github.com', 'github.company.com').
  String get host => serverConfig.host;

  /// Stable account key for data scoping. Immutable — uses nodeId, not username.
  /// Format: 'github.com/MDQ6VXNlcjEyMzQ1'
  /// Used as the `accountKey` column value in all entity tables.
  String get accountKey => '${serverConfig.id}/$nodeId';

  /// Stable storage key for FlutterSecureStorage token lookup.
  /// Uses nodeId, not username, so token survives renames.
  String get storageKey =>
      '${serverConfig.id.hashCode.toRadixString(36)}_$nodeId';

  // ── Equality — based on immutable identity, not mutable username ──

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      (other is AccountModel &&
          nodeId == other.nodeId &&
          serverConfig == other.serverConfig);

  @override
  int get hashCode => Object.hash(nodeId, serverConfig);
}
