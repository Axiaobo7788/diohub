import 'package:diohub_models/models/server_config.dart';

/// In-memory cache of the active user's authentication credentials.
///
/// This model holds the access token and server config for the currently
/// authenticated account, eliminating the need for per-request database
/// and keychain lookups in API clients.
///
/// Used by Dio interceptors and GraphQL handlers for synchronous auth header
/// and base URL resolution.
class AuthenticatedSession {
  const AuthenticatedSession({
    required this.token,
    required this.serverConfig,
    required this.storageKey,
  });

  final String token;
  final ServerConfig serverConfig;
  final String storageKey;
}
