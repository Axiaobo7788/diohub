import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/app/keys.dart';
import 'package:diohub/models/authentication/access_token_model.dart';
import 'package:diohub/models/authentication/account_model.dart';
import 'package:diohub/models/authentication/device_code_model.dart';
import 'package:diohub/utils/type_cast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final StreamController<void> _tokenInvalidationController =
      StreamController<void>.broadcast();

  static Stream<void> get tokenInvalidationStream =>
      _tokenInvalidationController.stream;

  /// Emit a token invalidation signal to be handled by app layer (blocs/UI).
  static void emitTokenInvalidated() {
    _tokenInvalidationController.add(null);
  }

  final RESTHandler _restHandler = RESTHandler.external(
    baseUrl: 'https://github.com/login',
    cacheOptions: APICache.noCache(),
    apiLogSettings: APILoggingSettings.comprehensive(),
  );

  Future<bool> get isAuthenticated async {
    final String? activeAccount = await getActiveAccount();
    if (activeAccount == null) return false;
    final String? token = await getAccessTokenFromDevice();
    if (token != null) {
      return true;
    }
    return false;
  }

  // Legacy method removed - use storeAccessTokenForAccount instead

  Future<void> storeAccessTokenForAccount(
    String username,
    AccessTokenModel accessTokenModel,
    AccountModel accountModel,
  ) async {
    final String storageKey = 'accessToken_${accountModel.storageKey}';
    await _storage.write(
      key: storageKey,
      value: accessTokenModel.accessToken,
    );
    await addAccount(accountModel);
  }

  Future<String?> getAccessTokenForAccount(String username,
      {String? serverUrl}) async {
    try {
      // If serverUrl provided, construct the key directly
      if (serverUrl != null) {
        final String hostHash = serverUrl.hashCode.toRadixString(36);
        return await _storage.read(key: 'accessToken_${hostHash}_$username');
      }
      // Otherwise, find the account and use its storage key
      final List<AccountModel> accounts = await getAllAccounts();
      final AccountModel? account = accounts.cast<AccountModel?>().firstWhere(
            (AccountModel? a) => a?.username == username,
            orElse: () => null,
          );
      if (account == null) return null;
      return await _storage.read(key: 'accessToken_${account.storageKey}');
    } on PlatformException {
      return null;
    }
  }

  Future<String?> getAccessTokenFromDevice() async {
    try {
      final AccountModel? activeAccount = await getActiveAccountModel();
      if (activeAccount != null) {
        return await _storage.read(
            key: 'accessToken_${activeAccount.storageKey}');
      }
      // No active account means no token
      return null;
    } on PlatformException {
      // Workaround for https://github.com/mogol/flutter_secure_storage/issues/43
      await logOut();
    }
    return null;
  }

  static const String apiBaseURL = 'https://api.github.com';

  Future<String> getActiveAccountServerUrl() async {
    final AccountModel? activeAccount = await getActiveAccountModel();
    return activeAccount?.serverUrl ?? apiBaseURL;
  }

  Future<TypeMap> getDeviceToken() async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'client_id': PrivateKeys.clientID,
      'scope': scopeString,
    });
    final Response<TypeMap> response =
        await _restHandler.post<TypeMap>('/device/code', data: formData);
    return response.data!;
  }

  String get scopeString => scopes.join(' ');
  List<String> get scopes => const <String>[
        'repo',
        'public_repo',
        'repo:invite',
        'write:org',
        'gist',
        'notifications',
        'user',
        'delete_repo',
        'write:discussion',
        'read:packages',
        'delete:packages',
      ];

  Future<TypeMap> getAccessToken({final String? deviceCode}) async {
    final FormData formData = FormData.fromMap(<String, dynamic>{
      'client_id': PrivateKeys.clientID,
      'device_code': deviceCode,
      'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
    });
    try {
      final Response<TypeMap> response = await _restHandler
          .post<TypeMap>('/oauth/access_token', data: formData);
      if (response.data!['access_token'] != null) {
        return response.data!;
      } else if (response.data!['error'] != null &&
          response.data!['error'] != 'authorization_pending' &&
          response.data!['error'] != 'slow_down') {
        throw Exception(response.data!['error_description']);
      }
      return response.data!;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<DeviceCodeModel> getDeviceCode() async {
    final TypeMap data = await getDeviceToken();
    if (data['device_code'] != null) {
      return DeviceCodeModel.fromJson(data);
    }
    //Exception is thrown if the response does not contain device_code.
    throw Exception('Some error occurred.');
  }

  Future<void> logOut() async {
    await BaseAPIHandler.clearCache();
    // Remove active account token if present
    final String? activeAccount = await getActiveAccount();
    if (activeAccount != null) {
      await removeAccount(activeAccount);
    }
    // Clear all storage including any legacy keys
    await _storage.deleteAll();
    await sharedPrefs.remove('accountList');
  }

  Future<AccessTokenModel> oauth2() async {
    const FlutterAppAuth appAuth = FlutterAppAuth();
    final AuthorizationTokenResponse? result =
        await appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        PrivateKeys.clientID,
        'auth.felix.diohub://login-callback',
        clientSecret: PrivateKeys.clientSecret,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          tokenEndpoint: 'https://github.com/login/oauth/access_token',
          authorizationEndpoint: 'https://github.com/login/oauth/authorize',
        ),
        scopes: scopes,
      ),
    );
    return AccessTokenModel(
      accessToken: result!.accessToken,
      scope: scopeString,
    );
  }

  // Multi-account management methods
  Future<void> setActiveAccount(String username) async {
    await _storage.write(key: 'activeAccount', value: username);
  }

  Future<String?> getActiveAccount() async {
    try {
      return await _storage.read(key: 'activeAccount');
    } on PlatformException {
      return null;
    }
  }

  Future<List<String>> getAllAccountUsernames() async {
    final List<AccountModel> accounts = await getAllAccounts();
    return accounts.map((AccountModel a) => a.username).toList();
  }

  Future<List<AccountModel>> getAllAccounts() async {
    final String? accountListJson = sharedPrefs.getString('accountList');
    if (accountListJson == null) return <AccountModel>[];
    try {
      final List<dynamic> accountsList = jsonDecode(accountListJson);
      return accountsList
          .map((dynamic json) => AccountModel.fromJson(json as TypeMap))
          .toList();
    } catch (e) {
      return <AccountModel>[];
    }
  }

  Future<void> addAccount(AccountModel account) async {
    final List<AccountModel> accounts = await getAllAccounts();
    final int existingIndex =
        accounts.indexWhere((AccountModel a) => a.username == account.username);
    if (existingIndex != -1) {
      // Update existing account
      accounts[existingIndex] = account;
    } else {
      // Add new account
      accounts.add(account);
    }
    await _saveAccountList(accounts);
  }

  Future<void> removeAccount(String username, {String? serverUrl}) async {
    final List<AccountModel> accounts = await getAllAccounts();
    final AccountModel? accountToRemove =
        accounts.cast<AccountModel?>().firstWhere(
              (AccountModel? a) =>
                  a?.username == username &&
                  (serverUrl == null || a?.serverUrl == serverUrl),
              orElse: () => null,
            );

    if (accountToRemove != null) {
      await _storage.delete(key: 'accessToken_${accountToRemove.storageKey}');
      accounts.removeWhere((AccountModel a) =>
          a.username == username && a.serverUrl == accountToRemove.serverUrl);
      await _saveAccountList(accounts);

      final String? activeAccountUsername = await getActiveAccount();
      if (activeAccountUsername == username) {
        if (accounts.isNotEmpty) {
          await setActiveAccount(accounts.first.username);
        } else {
          await _storage.delete(key: 'activeAccount');
        }
      }
    }
  }

  Future<void> _saveAccountList(List<AccountModel> accounts) async {
    await sharedPrefs.setString(
      'accountList',
      jsonEncode(accounts.map((AccountModel a) => a.toJson()).toList()),
    );
  }

  // Global scope tracking
  Future<String?> getGrantedScope() async {
    try {
      return await _storage.read(key: 'grantedScope');
    } on PlatformException {
      return null;
    }
  }

  Future<void> setGrantedScope(String scope) async {
    await _storage.write(key: 'grantedScope', value: scope);
  }

  // Enterprise PAT flow helper - fetch only, no storage
  // Storage should be handled by AccountBloc
  Future<AccountModel> authenticateWithPAT({
    required String hostUrl,
    required String token,
  }) async {
    try {
      // Use shared fetch helper (handles host normalization)
      return await fetchViewerInfoWithToken(token, hostUrl: hostUrl);
    } catch (e) {
      throw Exception('Failed to authenticate with PAT: $e');
    }
  }

  Future<AccountModel?> getActiveAccountModel() async {
    final String? activeUsername = await getActiveAccount();
    if (activeUsername == null) return null;

    final List<AccountModel> accounts = await getAllAccounts();
    return accounts.cast<AccountModel?>().firstWhere(
          (AccountModel? a) => a?.username == activeUsername,
          orElse: () => null,
        );
  }

  /// Fetches user data from REST /user endpoint with explicit token.
  /// Private helper used by both OAuth and PAT flows.
  Future<TypeMap> _fetchUserData(String token, {String? apiBase}) async {
    final Dio dio = Dio(BaseOptions(baseUrl: apiBase ?? apiBaseURL));

    final Response<TypeMap> response = await dio.get<TypeMap>(
      '/user',
      options: Options(
        headers: <String, String>{
          'Authorization': 'token $token',
          'Accept': 'application/json',
        },
      ),
    );

    return response.data!;
  }

  /// Fetches viewer info using an explicit token (without storing it).
  /// Used during auth flow to get user details before persisting account.
  /// Supports both github.com and enterprise hosts.
  Future<AccountModel> fetchViewerInfoWithToken(
    String token, {
    String? hostUrl,
  }) async {
    try {
      // Normalize API base for enterprise if provided
      String? apiBase;
      if (hostUrl != null) {
        apiBase =
            hostUrl.endsWith('/') ? '${hostUrl}api/v3' : '$hostUrl/api/v3';
      }

      final TypeMap userData = await _fetchUserData(token, apiBase: apiBase);

      return AccountModel(
        username: userData['login'] as String,
        displayName: userData['name'] as String?,
        avatarUrl: userData['avatar_url'] as String?,
        addedAt: DateTime.now(),
        serverUrl: hostUrl ?? apiBaseURL, // Use default if hostUrl is null
      );
    } catch (e) {
      throw Exception('Failed to fetch viewer info: $e');
    }
  }

  /// Validates if a 401 error indicates an invalid/revoked token
  /// Returns true if token should be considered invalid (e.g., "Bad credentials")
  /// Returns false for resource-specific 401s (permissions, private resources, etc.)
  static bool isTokenInvalidError(DioException error) {
    if (error.response?.statusCode != 401) {
      return false;
    }

    // Check for "Bad credentials" message which indicates revoked/invalid token
    final dynamic responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final String? message = responseData['message'] as String?;
      // GitHub returns "Bad credentials" for invalid/revoked tokens
      if (message == 'Bad credentials') {
        return true;
      }
    }

    // All other 401s are likely permission/scope issues, not invalid tokens
    return false;
  }
}
