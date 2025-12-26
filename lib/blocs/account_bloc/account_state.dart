part of 'account_bloc.dart';

sealed class AccountState {
  const AccountState();
}

class AccountUninitialized extends AccountState {
  const AccountUninitialized();
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountAdding extends AccountState {
  const AccountAdding(this.username);
  final String? username; // Nullable since we may not know username yet

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountAdding &&
          runtimeType == other.runtimeType &&
          username == other.username;

  @override
  int get hashCode => username.hashCode;
}

class AccountSwitching extends AccountState {
  const AccountSwitching(this.username);
  final String username;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountSwitching &&
          runtimeType == other.runtimeType &&
          username == other.username;

  @override
  int get hashCode => username.hashCode;
}

class AccountReady extends AccountState {
  const AccountReady(this.accounts, this.activeAccount);
  final List<AccountModel> accounts;
  final String? activeAccount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountReady &&
          runtimeType == other.runtimeType &&
          accounts == other.accounts &&
          activeAccount == other.activeAccount;

  @override
  int get hashCode => accounts.hashCode ^ activeAccount.hashCode;
}

class AccountError extends AccountState {
  const AccountError(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

