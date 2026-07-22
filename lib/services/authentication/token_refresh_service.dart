import 'dart:async';

import 'package:dio/dio.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/services/authentication/token_set_io.dart';
import 'package:diohub/services/authentication/token_store.dart';
import 'package:diohub_models/models/authentication/access_token_model.dart';
import 'package:diohub_models/models/authentication/access_token_response.dart';
import 'package:diohub_models/models/authentication/authenticated_session.dart';
import 'package:flutter/foundation.dart';

/// Service for refreshing GitHub access tokens using the refresh token flow.
///
/// Handles both proactive refresh (before token expires) and reactive refresh
/// (on 401 error). Uses a Completer-based concurrency guard to prevent
/// simultaneous refresh attempts.
class TokenRefreshService {
  TokenRefreshService(this._tokenStore, {this.onTokenRefreshed, final Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
            ),
          );

  final TokenStore _tokenStore;
  final Dio _dio;
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
    final shouldRefresh =
        tokenSet.accessTokenExpiresAt != null &&
        DateTime.now()
            .add(Duration(minutes: expiryBufferMinutes))
            .isAfter(tokenSet.accessTokenExpiresAt!);

    if (!shouldRefresh) {
      return tokenSet.accessToken;
    }

    return _doRefresh(session, tokenSet);
  }

  /// Force a token refresh regardless of expiry.
  ///
  /// Returns the new access token on success, null on failure.
  /// Used by the 401 error interceptor when the access token is known to be invalid.
  Future<String?> forceRefresh(AuthenticatedSession session) async {
    final tokenSet = await _tokenStore.readTokenSet(session.storageKey);
    if (tokenSet == null || !tokenSet.canRefresh) return null;
    return _doRefresh(session, tokenSet);
  }

  /// Internal refresh implementation with concurrency guard.
  ///
  /// Uses a static Completer to ensure only one refresh happens at a time.
  /// If a refresh is already in progress, subsequent calls wait for it to complete.
  Future<String?> _doRefresh(
    AuthenticatedSession session,
    AccessTokenModel currentTokenSet,
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

      final String refreshToken = currentTokenSet.refreshToken!;
      final Response<Map<String, dynamic>> response = await _dio
          .postUri<Map<String, dynamic>>(
            Uri.parse(oauth.tokenEndpoint),
            data: <String, String>{
              'client_id': oauth.clientId,
              if (oauth.clientSecret.isNotEmpty)
                'client_secret': oauth.clientSecret,
              'grant_type': 'refresh_token',
              'refresh_token': refreshToken,
            },
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              headers: const <String, String>{
                'Accept': 'application/json',
                'User-Agent': 'com.felix.diohub',
              },
            ),
          );
      final Map<String, dynamic>? json = response.data;
      if (json == null) {
        throw const FormatException('GitHub returned an empty token response.');
      }
      final AccessTokenResponse result = AccessTokenResponse.fromJson(json);
      if (result.error case final String error) {
        throw StateError(result.errorDescription ?? error);
      }

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
        scope: result.scope ?? currentTokenSet.scope,
        accessTokenExpiresAt: result.expiresIn != null
            ? DateTime.now().add(Duration(seconds: result.expiresIn!))
            : null,
        refreshTokenExpiresAt: result.refreshTokenExpiresIn != null
            ? DateTime.now().add(
                Duration(seconds: result.refreshTokenExpiresIn!),
              )
            : currentTokenSet.refreshTokenExpiresAt,
      );

      await _tokenStore.writeTokenSet(session.storageKey, newTokenSet);

      AppLogger.info('Token refreshed successfully', tag: 'TokenRefresh');

      _refreshLock?.complete(true);
      onTokenRefreshed?.call();
      return result.accessToken;
    } on Object catch (e, st) {
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
}
