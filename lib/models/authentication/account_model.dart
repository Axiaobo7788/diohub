import 'package:diohub/utils/type_cast.dart';

class AccountModel {
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime addedAt;
  final String? scope;
  final String serverUrl;

  AccountModel({
    required this.username,
    required this.addedAt, this.displayName,
    this.avatarUrl,
    this.scope,
    this.serverUrl = _defaultServerUrl,
  });

   static const String _defaultServerUrl = 'https://api.github.com';

  bool get isEnterprise => serverUrl != _defaultServerUrl;

  String get hostHash => serverUrl.hashCode.toRadixString(36);

  String get storageKey => '${hostHash}_$username';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'username': username,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'addedAt': addedAt.toIso8601String(),
        'scope': scope,
        'serverUrl': serverUrl,
      };

  factory AccountModel.fromJson(TypeMap json) => AccountModel(
        username: json['username'] as String,
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        addedAt: DateTime.parse(json['addedAt'] as String),
        scope: json['scope'] as String?,
        serverUrl: json['serverUrl'] as String? ?? 'https://github.com',
      );

  AccountModel copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    DateTime? addedAt,
    String? scope,
    String? serverUrl,
  }) {
    return AccountModel(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      addedAt: addedAt ?? this.addedAt,
      scope: scope ?? this.scope,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountModel &&
          runtimeType == other.runtimeType &&
          username == other.username &&
          serverUrl == other.serverUrl;

  @override
  int get hashCode => username.hashCode ^ serverUrl.hashCode;

  @override
  String toString() {
    return 'AccountModel(username: $username, displayName: $displayName, avatarUrl: $avatarUrl, addedAt: $addedAt, scope: $scope, serverUrl: $serverUrl, isEnterprise: $isEnterprise)';
  }
}
