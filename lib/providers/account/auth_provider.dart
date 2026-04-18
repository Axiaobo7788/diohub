import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/authentication/access_token_model.dart';
import 'package:diohub_models/models/authentication/access_token_response.dart';
import 'package:diohub_models/models/authentication/device_code_response.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<AuthNotifier, AuthenticationState> authProvider =
    NotifierProvider<AuthNotifier, AuthenticationState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthenticationState> {
  AuthRepository get _authRepository => ref.read(authServiceProvider);
  Timer? _pollTimer;

  @override
  AuthenticationState build() => AuthenticationUnauthenticated();

  Future<void> requestDeviceCode() async {
    state = AuthenticationChecking();

    try {
      final DeviceCodeResponse data = await _authRepository.getDeviceToken();
      state = AuthenticationInitialized(data);
      _pollForAccessToken(data.deviceCode, data.interval);
    } on Exception catch (e, stackTrace) {
      AppLogger.error(
        'Failed to request device code',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthNotifier',
      );
      state = AuthenticationError(e.toString());
    }
  }

  void _pollForAccessToken(final String? deviceCode, final int interval) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: interval), (final _) async {
      final AuthenticationState currentState = state;
      if (currentState is! AuthenticationInitialized ||
          currentState.deviceCodeResponse.deviceCode != deviceCode) {
        _pollTimer?.cancel();
        return;
      }

      try {
        final AccessTokenResponse data =
            await _authRepository.getAccessToken(deviceCode: deviceCode);
        if (data.accessToken != null && data.accessToken!.isNotEmpty) {
          _pollTimer?.cancel();
          await _handleAuthSuccess(AccessTokenModel(
            accessToken: data.accessToken,
            scope: data.scope,
            refreshToken: data.refreshToken,
            accessTokenExpiresAt: data.expiresIn != null
                ? DateTime.now().add(Duration(seconds: data.expiresIn!))
                : null,
            refreshTokenExpiresAt: data.refreshTokenExpiresIn != null
                ? DateTime.now()
                    .add(Duration(seconds: data.refreshTokenExpiresIn!))
                : null,
          ));
        }
      } on Exception catch (e, stackTrace) {
        AppLogger.error(
          'Failed to request access token',
          error: e,
          stackTrace: stackTrace,
          tag: 'AuthNotifier',
        );
        _pollTimer?.cancel();
        state = AuthenticationError(e.toString());
      }
    });
    ref.onDispose(() => _pollTimer?.cancel());
  }

  Future<void> _handleAuthSuccess(final AccessTokenModel token) async {
    try {
      if (token.accessToken == null || token.accessToken!.isEmpty) {
        AppLogger.error(
          'Invalid access token received: token is null or empty',
          error: Exception('Access token was null or empty'),
          tag: 'AuthNotifier',
        );
        state = AuthenticationError('Invalid access token received');
        return;
      }

      // Scopes are now validated and stored by fetchViewerInfoWithToken
      await ref.read(accountProvider.notifier).addAccount(token);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Auth successful handler failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthNotifier',
      );
      state = AuthenticationError(e.toString());
    }
  }

  /// Browser OAuth flow. Use this instead of calling authRepository.oauth2() from view.
  Future<void> loginWithBrowser() async {
    state = AuthenticationChecking();
    try {
      final AccessTokenModel token = await _authRepository.oauth2();
      await _handleAuthSuccess(token);
    } on Exception catch (e) {
      state = AuthenticationError(e.toString());
      rethrow;
    }
  }

  Future<void> handleAuthSuccess(final AccessTokenModel token) async {
    await _handleAuthSuccess(token);
  }

  void handleAuthError(final String error) {
    state = AuthenticationError(error);
  }

  void reset() {
    state = AuthenticationUnauthenticated();
  }
}

sealed class AuthenticationState {}

class AuthenticationChecking extends AuthenticationState {}

class AuthenticationUnauthenticated extends AuthenticationState {}

class AuthenticationInitialized extends AuthenticationState {
  AuthenticationInitialized(this.deviceCodeResponse);
  final DeviceCodeResponse deviceCodeResponse;
}

class AuthenticationAccountLinking extends AuthenticationState {
  AuthenticationAccountLinking(this.token);
  final AccessTokenModel token;
}

class AuthenticationError extends AuthenticationState {
  AuthenticationError(this.error);
  final String error;
}
