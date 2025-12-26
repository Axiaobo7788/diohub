part of 'account_bloc.dart';

abstract class AccountEvent {}

class LoadAccounts extends AccountEvent {}

class SwitchAccount extends AccountEvent {
  final String username;

  SwitchAccount(this.username);
}

class AddAccount extends AccountEvent {
  final AccessTokenModel token;
  final String? hostUrl; // For enterprise/PAT flow

  AddAccount(this.token, {this.hostUrl});
}

class RemoveAccount extends AccountEvent {
  final String username;

  RemoveAccount(this.username);
}

class LogOutAll extends AccountEvent {}

/// Handle invalid/revoked token for the active account.
class HandleInvalidToken extends AccountEvent {}

