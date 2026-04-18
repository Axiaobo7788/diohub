import 'dart:async';

import 'package:dio/dio.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/github_oauth.dart';
import 'package:diohub_models/models/authentication/access_token_model.dart';
import 'package:diohub_models/models/authentication/access_token_response.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/device_code_response.dart';
import 'package:diohub_models/models/authentication/viewer_user_payload.dart';
import 'package:diohub_models/models/canonical_node_id.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/services/authentication/account_repository.dart';
import 'package:diohub/services/authentication/scope_gate.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/services/authentication/token_store.dart';
import 'package:diohub/services/authentication/token_set_io.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

/// Auth facade: OAuth flows + token/account access. Delegates to
/// [TokenStore] and [AccountRepository].
class AuthRepository {
  AuthRepository(this._accountRepo, this._tokenStore);

  final AccountRepository _accountRepo;
  final TokenStore _tokenStore;

  static final StreamController<void> _tokenInvalidationController =
      StreamController<void>.broadcast();

  static Stream<void> get tokenInvalidationStream =>
      _tokenInvalidationController.stream;

  static void emitTokenInvalidated() {
    _tokenInvalidationController.add(null);
  }

  RESTHandler _restHandlerFor(ServerConfig serverConfig) {
    final oauth = serverConfig.oauthConfig;
    if (oauth == null) {
      throw UnsupportedError(
        'Server ${serverConfig.id} does not support OAuth device flow',
      );
    }
    return RESTHandler.external(
      accountRepository: _accountRepo,
      notifications: NotificationService(),
      tokenStore: _tokenStore,
      authenticatedSession: null,
      baseUrl: serverConfig.oauthLoginBaseUrl,
      cacheOptions: APICache.noCache(),
      apiLogSettings: APILoggingSettings.none(),
    );
  }

  Future<bool> get isAuthenticated async {
    final activeAccount = await getActiveAccount();
    if (activeAccount == null) return false;
    final token = await getAccessTokenFromDevice();
    return token != null;
  }

  Future<void> storeAccessTokenForAccount(
    String username,
    AccessTokenModel accessTokenModel,
    AccountModel accountModel,
  ) async {
    await _tokenStore.writeTokenSet(accountModel.storageKey, accessTokenModel);
    await _accountRepo.addAccount(accountModel);
  }

  Future<String?> getAccessTokenForAccount(String username,
      {String? serverId}) async {
    final accounts = await _accountRepo.getAllAccounts();
    for (final a in accounts) {
      if (a.username == username &&
          (serverId == null || a.serverConfig.id == serverId)) {
        final tokenSet = await _tokenStore.readTokenSet(a.storageKey);
        return tokenSet?.accessToken;
      }
    }
    return null;
  }

  Future<String?> getAccessTokenFromDevice() async {
    try {
      final active = await _accountRepo.getActiveAccountModel();
      if (active != null) {
        final tokenSet = await _tokenStore.readTokenSet(active.storageKey);
        return tokenSet?.accessToken;
      }
      return null;
    } on Exception catch (e, st) {
      AppLogger.error('Failed to get access token from device', error: e, stackTrace: st);
      // Only log out on explicit authentication failures (401 with Bad credentials)
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          await logOut();
          return null;
        }
      }
      // Rethrow other errors so callers can handle them
      rethrow;
    }
  }

  Future<ServerConfig> getActiveServerConfig() async {
    final active = await _accountRepo.getActiveAccountModel();
    return active?.serverConfig ?? ServerConfig.gitHubDotCom;
  }

  Future<DeviceCodeResponse> getDeviceToken(
      {ServerConfig? serverConfig}) async {
    final config = serverConfig ?? ServerConfig.gitHubDotCom;
    final oauth = config.oauthConfig;
    if (oauth == null) {
      throw UnsupportedError(
        'Server ${config.id} does not support OAuth device flow',
      );
    }
    final handler = _restHandlerFor(config);
    final formData = FormData.fromMap(<String, dynamic>{
      'client_id': oauth.clientId,
      'scope': OAuthConfig.defaultScopes.join(' '),
    });
    final response = await handler
        .post<Map<String, dynamic>>('/device/code', data: formData);
    return DeviceCodeResponse.fromJson(response.data!);
  }

  static List<String> get oauthScopes => OAuthConfig.defaultScopes;

  /// Returns the canonical scope string (all default scopes).
  String get scopeString => OAuthConfig.defaultScopes.join(' ');
  
  List<String> get scopes => OAuthConfig.defaultScopes;

  Future<AccessTokenResponse> getAccessToken({
    String? deviceCode,
    ServerConfig? serverConfig,
  }) async {
    final config = serverConfig ?? gitHubDotComWithOAuth;
    final oauth = config.oauthConfig;
    if (oauth == null) {
      throw UnsupportedError(
        'Server ${config.id} does not support OAuth device flow',
      );
    }
    final handler = _restHandlerFor(config);
    final formData = FormData.fromMap(<String, dynamic>{
      'client_id': oauth.clientId,
      'device_code': deviceCode,
      'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
    });
    try {
      final response = await handler
          .post<Map<String, dynamic>>('/oauth/access_token', data: formData);
      final data = AccessTokenResponse.fromJson(response.data!);
      if (data.error != null &&
          data.error != 'authorization_pending' &&
          data.error != 'slow_down') {
        throw Exception(data.errorDescription ?? data.error);
      }
      return data;
    } catch (e, st) {
      AppLogger.warning(
        'Device code token exchange failed',
        error: e,
        stackTrace: st,
        tag: 'Auth',
      );
      rethrow;
    }
  }

  Future<DeviceCodeResponse> getDeviceCode() async => getDeviceToken();

  Future<void> logOut() async {
    await BaseAPIHandler.clearCache();
    final activeAccount = await _accountRepo.getActiveAccount();
    if (activeAccount != null) {
      await _accountRepo.removeAccount(activeAccount);
    }
    await _tokenStore.deleteAll();
    await _accountRepo.clearAll();
  }

  Future<AccessTokenModel> oauth2({ServerConfig? serverConfig}) async {
    final config = serverConfig ?? gitHubDotComWithOAuth;
    final oauth = config.oauthConfig;
    if (oauth == null) {
      throw UnsupportedError(
        'Server ${config.id} does not support OAuth browser flow',
      );
    }
    
    // Validate client ID is configured
    if (oauth.clientId.isEmpty) {
      AppLogger.error(
        'GitHub OAuth client ID is not configured',
        error: Exception('GITHUB_CLIENT_ID environment variable is empty or missing'),
        tag: 'Auth',
      );
      throw Exception(
        'GitHub OAuth is not configured. Please set GITHUB_CLIENT_ID in your .env file.',
      );
    }
    
    const appAuth = FlutterAppAuth();
    final result = await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        oauth.clientId,
        oauth.redirectUri,
        clientSecret: oauth.clientSecret,
        serviceConfiguration: AuthorizationServiceConfiguration(
          tokenEndpoint: oauth.tokenEndpoint,
          authorizationEndpoint: oauth.authorizationEndpoint,
        ),
        scopes: OAuthConfig.defaultScopes,
      ),
    );
    
    // Log the OAuth result for debugging
    AppLogger.info(
      'OAuth2 result received: '
      'accessToken=${result.accessToken != null ? "<present>" : "<null>"}, '
      'refreshToken=${result.refreshToken != null ? "<present>" : "<null>"}, '
      'scopes=${result.scopes}',
      tag: 'Auth',
    );
    
    if (result.accessToken == null || result.accessToken!.isEmpty) {
      AppLogger.error(
        'OAuth2 returned null or empty access token',
        error: Exception('TokenResponse: accessToken=${result.accessToken}'),
        tag: 'Auth',
      );
      throw Exception('OAuth flow completed but no access token was returned');
    }
    
    return AccessTokenModel(
      accessToken: result.accessToken,
      scope: result.scopes?.join(' '),
      refreshToken: result.refreshToken,
      accessTokenExpiresAt: result.accessTokenExpirationDateTime,
      refreshTokenExpiresAt:
          _parseRefreshTokenExpiry(result.tokenAdditionalParameters),
    );
  }

  /// Parse the refresh token expiry from tokenAdditionalParameters.
  ///
  /// GitHub returns refresh_token_expires_in (seconds) in the OAuth response.
  static DateTime? _parseRefreshTokenExpiry(Map<String, dynamic>? params) {
    if (params == null) return null;
    final raw = params['refresh_token_expires_in'];
    final seconds = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    if (seconds == null) return null;
    return DateTime.now().add(Duration(seconds: seconds));
  }

  Future<void> setActiveAccount(String username) async =>
      _accountRepo.setActiveAccount(username);

  Future<String?> getActiveAccount() async =>
      _accountRepo.getActiveAccount();

  Future<List<String>> getAllAccountUsernames() async =>
      _accountRepo.getAllAccountUsernames();

  Future<List<AccountModel>> getAllAccounts() async =>
      _accountRepo.getAllAccounts();

  Future<void> addAccount(AccountModel account) async =>
      _accountRepo.addAccount(account);

  Future<void> updateAccountProfile({
    required String nodeId,
    required String serverId,
    required String username,
    String? displayName,
    String? avatarUrl,
  }) async =>
      _accountRepo.updateAccountProfile(
        nodeId: nodeId,
        serverId: serverId,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

  Future<void> removeAccount(String username, {String? serverId}) async =>
      _accountRepo.removeAccount(username, serverId: serverId);

  Future<AccountModel> authenticateWithPAT({
    required ServerConfig serverConfig,
    required String token,
  }) async {
    try {
      return await fetchViewerInfoWithToken(token,
          serverConfig: serverConfig);
    } catch (e) {
      throw Exception('Failed to authenticate with PAT: $e');
    }
  }

  Future<AccountModel?> getActiveAccountModel() async =>
      _accountRepo.getActiveAccountModel();

  Future<(ViewerUserPayload, String?)> _fetchUserData(String token,
      {String? apiBase}) async {
    final dio = Dio(BaseOptions(
      baseUrl: apiBase ?? ServerConfig.gitHubDotCom.restBaseUrl,
    ));
    final response = await dio.get<Map<String, dynamic>>(
      '/user',
      options: Options(
        headers: <String, String>{
          'Authorization': 'token $token',
          'Accept': 'application/json',
        },
      ),
    );
    final scopes = response.headers.value('X-OAuth-Scopes');
    return (ViewerUserPayload.fromJson(response.data!), scopes);
  }

  Future<AccountModel> fetchViewerInfoWithToken(
    String token, {
    required ServerConfig serverConfig,
  }) async {
    try {
      final (userData, grantedScopes) = await _fetchUserData(token,
          apiBase: serverConfig.restBaseUrl);
      
      // Parse granted scopes and validate required scopes
      final grantedScopeSet = ScopeGate.parseScopes(grantedScopes);
      final missingRequired = OAuthConfig.requiredScopes
          .where((scope) => !grantedScopeSet.contains(scope))
          .toList();
      
      if (missingRequired.isNotEmpty) {
        throw Exception(
          'Missing required OAuth scopes: ${missingRequired.join(", ")}',
        );
      }
      
      return AccountModel(
        nodeId: userData.nodeId.asGitHubNodeId,
        username: userData.login,
        displayName: userData.name,
        avatarUrl: userData.avatarUrl,
        addedAt: DateTime.now(),
        serverConfig: serverConfig,
        scope: grantedScopes, // Store actual granted scopes
      );
    } catch (e, st) {
      AppLogger.warning(
        'Fetch viewer info failed',
        error: e,
        stackTrace: st,
        tag: 'Auth',
      );
      throw Exception('Failed to fetch viewer info: $e');
    }
  }

  static bool isTokenInvalidError(DioException error) {
    if (error.response?.statusCode != 401) return false;
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'] as String?;
      if (message == 'Bad credentials') return true;
    }
    return false;
  }
}
