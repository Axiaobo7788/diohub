part of 'authentication_bloc.dart';

@immutable
abstract class AuthenticationState {
  final bool authenticated = false;
}

/// Authentication status is being checked (initial state).
class AuthenticationChecking extends AuthenticationState {}

/// User unauthenticated.
class AuthenticationUnauthenticated extends AuthenticationState {}

/// Authentication initialized (device code received, waiting for user).
class AuthenticationInitialized extends AuthenticationState {
  AuthenticationInitialized(this.deviceCodeModel);
  final DeviceCodeModel deviceCodeModel;
}

/// Account linking in progress (token received, fetching user info).
class AuthenticationAccountLinking extends AuthenticationState {
  AuthenticationAccountLinking(this.token);
  final AccessTokenModel token;
}

/// Authenticated (active account is set and ready).
class AuthenticationAuthenticated extends AuthenticationState {
  AuthenticationAuthenticated(this.activeAccount);
  final String activeAccount;

  @override
  bool get authenticated => true;
}

/// Error during authentication.
class AuthenticationError extends AuthenticationState {
  AuthenticationError(this.error);
  final String error;
}
