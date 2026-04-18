import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/authentication/access_token_model.dart';
import 'package:diohub_models/models/authentication/authenticated_session.dart';
import 'package:diohub/services/authentication/token_store.dart';
import 'package:diohub/services/authentication/token_set_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

/// Service for refreshing GitHub access tokens using the refresh token flow.
///
/// Handles both proactive refresh (before token expires) and reactive refresh
/// (on 401 error). Uses a Completer-based concurrency guard to prevent
/// simultaneous refresh attempts.
class TokenRefreshService {
  TokenRefreshService(this._tokenStore, {this.onTokenRefreshed});

  final TokenStore _tokenStore;
  final VoidCallback? onTokenRefreshed;
  static Completer<bool>? _refreshLock;

  /// Refresh the token if it's expired or about to expire.
  ///
  /// Returns the current or refreshed access token on success, null on failure.
  /// If the token is not expired and not within the expiry buffer, returns
  /// the current token without refreshing.
  ///
  /// [expiryBufferMinutes] controls how early to refresh before actual expiry.
  /// Default is 5 minutes.
  Future<String?> refreshIfNeeded(
    AuthenticatedSession session, {
    int expiryBufferMinutes = 5,
  }) async {
    final tokenSet = await _tokenStore.readTokenSet(session.storageKey);
    if (tokenSet == null || !tokenSet.canRefresh) {
      return tokenSet?.accessToken;
    }

    // Check if token is expired or about to expire
    final shouldRefresh = tokenSet.accessTokenExpiresAt != null &&
        DateTime.now()
            .add(Duration(minutes: expiryBufferMinutes))
            .isAfter(tokenSet.accessTokenExpiresAt!);

    if (!shouldRefresh) {
      return tokenSet.accessToken;
    }

    return _doRefresh(session, tokenSet.refreshToken!);
  }

  /// Force a token refresh regardless of expiry.
  ///
  /// Returns the new access token on success, null on failure.
  /// Used by the 401 error interceptor when the access token is known to be invalid.
  Future<String?> forceRefresh(AuthenticatedSession session) async {
    final tokenSet = await _tokenStore.readTokenSet(session.storageKey);
    if (tokenSet == null || !tokenSet.canRefresh) return null;
    return _doRefresh(session, tokenSet.refreshToken!);
  }

  /// Internal refresh implementation with concurrency guard.
  ///
  /// Uses a static Completer to ensure only one refresh happens at a time.
  /// If a refresh is already in progress, subsequent calls wait for it to complete.
  Future<String?> _doRefresh(
    AuthenticatedSession session,
    String refreshToken,
  ) async {
    // If a refresh is already in progress, wait for it
    if (_refreshLock != null) {
      await _refreshLock!.future;
      // After waiting, re-read the token (the other refresh may have updated it)
      final updated = await _tokenStore.readTokenSet(session.storageKey);
      return updated?.accessToken;
    }

    // Start a new refresh
    _refreshLock = Completer<bool>();

    try {
      final oauth = session.serverConfig.oauthConfig;
      if (oauth == null) {
        throw UnsupportedError(
          'Server ${session.serverConfig.id} does not support OAuth token refresh',
        );
      }

      const appAuth = FlutterAppAuth();
      final result = await appAuth.token(
        TokenRequest(
          oauth.clientId,
          oauth.redirectUri,
          // GitHub App uses PKCE, no client secret
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: oauth.authorizationEndpoint,
            tokenEndpoint: oauth.tokenEndpoint,
          ),
          refreshToken: refreshToken,
        ),
      );

      if (result.accessToken == null) {
        AppLogger.warning(
          'Token refresh returned null access token',
          tag: 'TokenRefresh',
        );
        _refreshLock?.complete(false);
        return null;
      }

      // Store the new token set with actual refresh token expiry
      final newTokenSet = AccessTokenModel(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken ?? refreshToken,
        accessTokenExpiresAt: result.accessTokenExpirationDateTime,
        refreshTokenExpiresAt:
            _parseRefreshTokenExpiry(result.tokenAdditionalParameters),
      );

      await _tokenStore.writeTokenSet(session.storageKey, newTokenSet);

      AppLogger.info(
        'Token refreshed successfully',
        tag: 'TokenRefresh',
      );

      _refreshLock?.complete(true);
      onTokenRefreshed?.call();
      return result.accessToken;
    } catch (e, st) {
      AppLogger.error(
        'Token refresh failed',
        error: e,
        stackTrace: st,
        tag: 'TokenRefresh',
      );
      _refreshLock?.complete(false);
      return null;
    } finally {
      _refreshLock = null;
    }
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
}
