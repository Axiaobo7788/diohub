import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_config.freezed.dart';
part 'server_config.g.dart';

/// How the account was authenticated.
enum AuthMethod {
  /// OAuth browser flow or device code flow — subject to org app restrictions.
  oauth,

  /// Device code flow — same OAuth app, same restrictions as [oauth].
  deviceCode,

  /// Personal Access Token — bypasses OAuth app restrictions in most cases.
  pat,
}

/// GitHub OAuth/PAT scope constants.
///
/// Single source of truth for all scope strings used across the app.
abstract final class GitHubScope {
  static const repo = 'repo';
  static const user = 'user';
  static const gist = 'gist';
  static const notifications = 'notifications';
  static const writeOrg = 'write:org';
  static const deleteRepo = 'delete_repo';
  static const project = 'project';
  static const readPackages = 'read:packages';
  static const adminPublicKey = 'admin:public_key';
  static const adminGpgKey = 'admin:gpg_key';
  static const adminSshSigningKey = 'admin:ssh_signing_key';
  static const securityEvents = 'security_events';
  static const adminOrg = 'admin:org';
}

/// OAuth application credentials and endpoint URLs for a server.
@immutable
@freezed
abstract class OAuthConfig with _$OAuthConfig {
  const OAuthConfig._();

  const factory OAuthConfig({
    required String clientId,
    required String clientSecret,
    required String tokenEndpoint,
    required String authorizationEndpoint,
    required String deviceCodeEndpoint,
    @Default('auth.felix.diohub://login-callback') String redirectUri,
  }) = _OAuthConfig;

  factory OAuthConfig.fromJson(final Map<String, dynamic> json) =>
      _$OAuthConfigFromJson(json);

  /// Core scopes required for basic app functionality.
  static const List<String> requiredScopes = <String>[
    GitHubScope.repo,
    GitHubScope.user,
  ];

  /// Optional scopes for specific features that can degrade gracefully.
  static const List<String> optionalScopes = <String>[
    GitHubScope.writeOrg,
    GitHubScope.gist,
    GitHubScope.notifications,
    GitHubScope.deleteRepo,
    GitHubScope.project,
    GitHubScope.readPackages,
    GitHubScope.adminPublicKey,
    GitHubScope.adminGpgKey,
    GitHubScope.adminSshSigningKey,
    GitHubScope.securityEvents,
  ];

  /// Canonical list of OAuth/PAT scopes requested by the app.
  static const List<String> defaultScopes = <String>[
    ...requiredScopes,
    ...optionalScopes,
  ];
}

/// Server endpoint configuration.
///
/// Encapsulates all URL derivation for a GitHub-compatible server.
/// GitHub.com is [gitHubDotCom] — a const preset, not a special case.
///
/// All URL construction in the app flows through this object.
/// No hardcoded `github.com` or `api.github.com` elsewhere.
@immutable
@Freezed(equal: false) // Identity is id only (see == override)
abstract class ServerConfig with _$ServerConfig {
  const ServerConfig._();

  const factory ServerConfig({
    required String id,
    required String displayName,
    required String webBaseUrl,
    required String restBaseUrl,
    required String graphqlUrl,
    required String rawContentBaseUrl,
    required String uploadBaseUrl,
    required List<AuthMethod> supportedAuthMethods,
    OAuthConfig? oauthConfig,
  }) = _ServerConfig;

  factory ServerConfig.fromJson(final Map<String, dynamic> json) {
    return ServerConfig(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      webBaseUrl: json['webBaseUrl'] as String,
      restBaseUrl: json['restBaseUrl'] as String,
      graphqlUrl: json['graphqlUrl'] as String,
      rawContentBaseUrl: json['rawContentBaseUrl'] as String,
      uploadBaseUrl: json['uploadBaseUrl'] as String,
      supportedAuthMethods: (json['supportedAuthMethods'] as List<dynamic>)
          .map((final dynamic s) =>
              AuthMethod.values.asNameMap()[s as String] ?? AuthMethod.pat)
          .toList(),
      oauthConfig: json['oauthConfig'] != null
          ? OAuthConfig.fromJson(json['oauthConfig'] as Map<String, dynamic>)
          : null,
    );
  }

  // ── Convenience getters ──

  /// Whether this is the default GitHub.com server.
  bool get isDefault => this == gitHubDotCom;

  /// Host authority string (e.g. 'github.com').
  String get host => Uri.parse(webBaseUrl).host;

  // ── URL builders ──

  /// Web URL for a given path (e.g. '/flutter/flutter' → 'https://github.com/flutter/flutter').
  Uri webUrl(final String path) => Uri.parse('$webBaseUrl$path');

  /// Raw content URL for a file.
  Uri rawUrl(
    final String owner,
    final String repo,
    final String ref,
    final String path,
  ) =>
      Uri.parse('$rawContentBaseUrl/$owner/$repo/$ref/$path');

  /// Raw content URL for wiki images.
  Uri wikiRawUrl(
    final String owner,
    final String repo,
    final String imagePath,
  ) =>
      Uri.parse('$rawContentBaseUrl/wiki/$owner/$repo/$imagePath');

  /// REST API URL for a given path (e.g. '/repos/flutter/flutter').
  Uri restUrl(final String path) => Uri.parse('$restBaseUrl$path');

  /// URL to create a new PAT with DioHub-appropriate scopes pre-filled.
  Uri get createTokenUrl => Uri.parse(
        '$webBaseUrl/settings/tokens/new'
        '?scopes=${OAuthConfig.defaultScopes.join(',')}'
        '&description=DioHub',
      );

  /// OAuth login base URL (e.g. 'https://github.com/login').
  String get oauthLoginBaseUrl => '$webBaseUrl/login';

  // ── Presets ──

  /// GitHub.com — the default preset. Not a special case.
  static const ServerConfig gitHubDotCom = ServerConfig(
    id: 'github.com',
    displayName: 'GitHub',
    webBaseUrl: 'https://github.com',
    restBaseUrl: 'https://api.github.com',
    graphqlUrl: 'https://api.github.com/graphql',
    rawContentBaseUrl: 'https://raw.githubusercontent.com',
    uploadBaseUrl: 'https://uploads.github.com',
    supportedAuthMethods: <AuthMethod>[
      AuthMethod.oauth,
      AuthMethod.deviceCode,
      AuthMethod.pat,
    ],
  );

  /// Derive a GitHub Enterprise Server config from a host URL.
  ///
  /// [hostUrl] is the bare server URL without any API path suffix.
  /// e.g. 'https://github.company.com' — NOT 'https://github.company.com/api/v3'.
  ///
  /// GHES URL conventions (documented by GitHub):
  /// - REST API: {host}/api/v3
  /// - GraphQL:  {host}/api/graphql
  /// - Raw:     {host}/raw (for raw.githubusercontent.com equivalent)
  /// - Uploads: {host}/api/uploads
  /// - OAuth:   {host}/login/oauth/...
  static ServerConfig gitHubEnterprise(
    final String hostUrl, {
    final String? displayName,
  }) {
    final String base = hostUrl.endsWith('/')
        ? hostUrl.substring(0, hostUrl.length - 1)
        : hostUrl;
    final String host = Uri.parse(base).host;
    return ServerConfig(
      id: host,
      displayName: displayName ?? host,
      webBaseUrl: base,
      restBaseUrl: '$base/api/v3',
      graphqlUrl: '$base/api/graphql',
      rawContentBaseUrl: '$base/raw',
      uploadBaseUrl: '$base/api/uploads',
      supportedAuthMethods: const <AuthMethod>[AuthMethod.pat],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'displayName': displayName,
        'webBaseUrl': webBaseUrl,
        'restBaseUrl': restBaseUrl,
        'graphqlUrl': graphqlUrl,
        'rawContentBaseUrl': rawContentBaseUrl,
        'uploadBaseUrl': uploadBaseUrl,
        'supportedAuthMethods':
            supportedAuthMethods.map((final AuthMethod m) => m.name).toList(),
        if (oauthConfig != null) 'oauthConfig': oauthConfig!.toJson(),
      };

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || (other is ServerConfig && id == other.id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServerConfig($id)';
}
