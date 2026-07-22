import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:diohub_models/models/authentication/access_token_model.dart';
import 'package:diohub_models/models/authentication/access_token_response.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/authentication/device_code_response.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<AuthNotifier, AuthenticationState> authProvider =
    NotifierProvider<AuthNotifier, AuthenticationState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthenticationState> {
  AuthRepository get _authRepository => ref.read(authServiceProvider);
  Timer? _pollTimer;
  int _pollGeneration = 0;
  Duration _pollInterval = const Duration(seconds: 5);
  DateTime? _deviceCodeExpiresAt;

  @override
  AuthenticationState build() {
    ref.onDispose(_cancelPolling);
    return AuthenticationUnauthenticated();
  }

  Future<void> requestDeviceCode({final ServerConfig? serverConfig}) async {
    _cancelPolling();
    final int generation = _pollGeneration;
    state = AuthenticationChecking();

    try {
      final DeviceCodeResponse data = await _authRepository.getDeviceToken(
        serverConfig: serverConfig,
      );
      if (generation != _pollGeneration) {
        return;
      }
      state = AuthenticationInitialized(data);
      _startPolling(data, serverConfig: serverConfig);
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

  void _startPolling(
    final DeviceCodeResponse response, {
    final ServerConfig? serverConfig,
  }) {
    final int generation = _pollGeneration;
    _pollInterval = Duration(seconds: response.interval.clamp(1, 60));
    _deviceCodeExpiresAt = DateTime.now().add(
      Duration(seconds: response.expiresIn),
    );
    _schedulePoll(response.deviceCode, generation, serverConfig: serverConfig);
  }

  void _schedulePoll(
    final String deviceCode,
    final int generation, {
    final ServerConfig? serverConfig,
  }) {
    _pollTimer?.cancel();
    _pollTimer = Timer(
      _pollInterval,
      () => unawaited(
        _pollOnce(deviceCode, generation, serverConfig: serverConfig),
      ),
    );
  }

  Future<void> _pollOnce(
    final String deviceCode,
    final int generation, {
    final ServerConfig? serverConfig,
  }) async {
    if (!_isCurrentPoll(deviceCode, generation)) {
      return;
    }
    if (_deviceCodeExpiresAt case final DateTime expiresAt
        when !DateTime.now().isBefore(expiresAt)) {
      _failDeviceFlow(
        'The GitHub verification code expired. Please try again.',
      );
      return;
    }

    try {
      final AccessTokenResponse response = await _authRepository.getAccessToken(
        deviceCode: deviceCode,
        serverConfig: serverConfig,
      );
      if (!_isCurrentPoll(deviceCode, generation)) {
        return;
      }

      final String? accessToken = response.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        _cancelPolling();
        await _handleAuthSuccess(
          AccessTokenModel(
            accessToken: accessToken,
            scope: response.scope,
            refreshToken: response.refreshToken,
            accessTokenExpiresAt: response.expiresIn != null
                ? DateTime.now().add(Duration(seconds: response.expiresIn!))
                : null,
            refreshTokenExpiresAt: response.refreshTokenExpiresIn != null
                ? DateTime.now().add(
                    Duration(seconds: response.refreshTokenExpiresIn!),
                  )
                : null,
          ),
          authMethod: AuthMethod.deviceCode,
        );
        return;
      }

      final String? error = response.error;
      if (error == 'slow_down') {
        _pollInterval = nextDeviceFlowPollInterval(_pollInterval, response);
      } else if (error == 'access_denied') {
        _failDeviceFlow('GitHub authorization was cancelled.');
        return;
      } else if (error == 'expired_token') {
        _failDeviceFlow(
          'The GitHub verification code expired. Please try again.',
        );
        return;
      } else if (error != 'authorization_pending') {
        _failDeviceFlow(
          response.errorDescription ??
              error ??
              'GitHub returned an invalid device authorization response.',
        );
        return;
      }

      _schedulePoll(deviceCode, generation, serverConfig: serverConfig);
    } on Exception catch (e, stackTrace) {
      AppLogger.error(
        'Failed to request access token',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthNotifier',
      );
      if (_isCurrentPoll(deviceCode, generation)) {
        _failDeviceFlow(e.toString());
      }
    }
  }

  bool _isCurrentPoll(final String deviceCode, final int generation) {
    final AuthenticationState currentState = state;
    return generation == _pollGeneration &&
        currentState is AuthenticationInitialized &&
        currentState.deviceCodeResponse.deviceCode == deviceCode;
  }

  void _failDeviceFlow(final String message) {
    _cancelPolling();
    state = AuthenticationError(message);
  }

  void _cancelPolling() {
    _pollGeneration += 1;
    _pollTimer?.cancel();
    _pollTimer = null;
    _deviceCodeExpiresAt = null;
  }

  Future<void> _handleAuthSuccess(
    final AccessTokenModel token, {
    final AuthMethod authMethod = AuthMethod.oauth,
  }) async {
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

      state = AuthenticationAccountLinking(token);
      // Scopes are now validated and stored by fetchViewerInfoWithToken.
      await ref
          .read(accountProvider.notifier)
          .addAccount(token, authMethod: authMethod);
      final AsyncValue<AccountSession?> accountState = ref.read(
        accountProvider,
      );
      final Object? accountError = accountState.error;
      if (accountError != null) {
        state = AuthenticationError(accountError.toString());
        return;
      }
      state = AuthenticationUnauthenticated();
    } on Exception catch (e, stackTrace) {
      AppLogger.error(
        'Auth successful handler failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'AuthNotifier',
      );
      state = AuthenticationError(e.toString());
    }
  }

  void reset() {
    _cancelPolling();
    state = AuthenticationUnauthenticated();
  }
}

@visibleForTesting
Duration nextDeviceFlowPollInterval(
  final Duration current,
  final AccessTokenResponse response,
) {
  final Duration increased = current + const Duration(seconds: 5);
  final int? serverInterval = response.interval;
  if (serverInterval == null) {
    return increased;
  }
  final Duration hinted = Duration(seconds: serverInterval.clamp(1, 60));
  return hinted > increased ? hinted : increased;
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
