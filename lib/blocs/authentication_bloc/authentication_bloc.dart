import 'dart:async';

import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/models/authentication/access_token_model.dart';
import 'package:diohub/models/authentication/device_code_model.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:diohub/utils/type_cast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required this.accountBloc,
  }) : super(AuthenticationUnauthenticated()) {
    on<RequestDeviceCode>(_requestDeviceCode);
    on<RequestAccessToken>(_requestAccessToken);
    on<AuthError>(_authError);
    on<ResetStates>(_resetStates);
    on<AuthSuccessful>(_authSuccessful);
    on<LogOut>(_logOut);
  }

  final AuthRepository authRepository = AuthRepository();
  final AccountBloc accountBloc;

  Future<void> _requestDeviceCode(
    final RequestDeviceCode event,
    final Emitter<AuthenticationState> emit,
  ) async {
    // Emit checking state immediately to show loading indicator
    emit(AuthenticationChecking());

    // Get device code to initiate authentication.
    try {
      final TypeMap map = await authRepository.getDeviceToken();
      // ['device_code'] should not be null.
      if (map['device_code'] != null) {
        final DeviceCodeModel data = DeviceCodeModel.fromJson(map);
        add(RequestAccessToken(data.deviceCode, data.interval));
        emit(AuthenticationInitialized(data));
      } else {
        emit(AuthenticationError('Something went wrong, please try again.'));
      }
    } on Exception catch (e) {
      add(AuthError(e.toString()));
    }
  }

  Future<void> _requestAccessToken(
    final RequestAccessToken event,
    final Emitter<AuthenticationState> emit,
  ) async {
    // Recurring function to request access token from Github on the supplied
    // interval.
    Future<void> requestAccessToken(
      final String? deviceCode,
      final int interval,
    ) async {
      // Wait the interval provided by Github before hitting the API to check
      // the status of Authentication.
      await Future<void>.delayed(Duration(seconds: interval));
      // Get the current Authentication state.
      final AuthenticationState currentState = state;
      // Check if state is still on the code display mode before executing
      // the (recursive) function. Also checks if the request is for the same
      // deviceCode to prevent a false positive on back to back state changes.
      // If not, the recursion will break here.
      if (currentState is AuthenticationInitialized &&
          currentState.deviceCodeModel.deviceCode == deviceCode) {
        try {
          final TypeMap data =
              await authRepository.getAccessToken(deviceCode: deviceCode);
          if (data['access_token'] != null) {
            // Access token received. State is set to authenticated. Function
            // can stop executing now.
            add(AuthSuccessful(AccessTokenModel.fromJson(data)));
          } else if (data['interval'] != null) {
            // Execute the function again with the new interval given by
            // GitHub.
            await requestAccessToken(deviceCode, data['interval']);
          } else {
            // Execute the function again.
            await requestAccessToken(deviceCode, interval);
          }
        } on Exception catch (error) {
          add(AuthError(error.toString()));
        }
      }
    }

    // Initiate recursive function to request for access token at set
    // intervals.
    await requestAccessToken(event.deviceCode, event.interval!);
  }

  Future<void> _authSuccessful(
    final AuthSuccessful event,
    final Emitter<AuthenticationState> emit,
  ) async {
    debugPrint(
        '[AuthenticationBloc] _authSuccessful: Token acquired, acting as gate only');
    try {
      final AccessTokenModel token = event.accessToken;

      // Validate token
      if (token.accessToken == null || token.accessToken!.isEmpty) {
        emit(AuthenticationError('Invalid access token received'));
        debugPrint(
            '[AuthenticationBloc] _authSuccessful: Invalid token, aborting');
        return;
      }

      // Handle scope tracking (global)
      final String requestedScope = authRepository.scopeString;
      final String grantedScope = token.scope ?? requestedScope;
      final String? storedGrantedScope = await authRepository.getGrantedScope();

      if (storedGrantedScope == null ||
          !_isScopeSubset(requestedScope, storedGrantedScope)) {
        await authRepository.setGrantedScope(grantedScope);
        debugPrint(
            '[AuthenticationBloc] _authSuccessful: Updated granted scope');
      }

      // Dispatch to AccountBloc to handle unified account addition
      // AccountBloc will handle fetching user, persisting, and setting active
      // No AuthenticationAuthenticated emission - AccountBloc drives the flow
      debugPrint(
          '[AuthenticationBloc] _authSuccessful: Dispatching AddAccount to AccountBloc');
      accountBloc.add(AddAccount(token));
    } catch (e) {
      debugPrint('[AuthenticationBloc] _authSuccessful: Error: $e');
      emit(AuthenticationError(e.toString()));
    }
  }

  bool _isScopeSubset(String requested, String granted) {
    final Set<String> requestedSet = requested.split(' ').toSet();
    final Set<String> grantedSet = granted.split(' ').toSet();
    return requestedSet.difference(grantedSet).isEmpty;
  }

  void _resetStates(
    final ResetStates event,
    final Emitter<AuthenticationState> emit,
  ) {
    emit(AuthenticationUnauthenticated());
  }

  Future<void> _logOut(
    final LogOut event,
    final Emitter<AuthenticationState> emit,
  ) async {
    await authRepository.logOut();
    emit(AuthenticationUnauthenticated());
  }

  void _authError(
    final AuthError event,
    final Emitter<AuthenticationState> emit,
  ) {
    emit(AuthenticationError(event.error));
  }
}
