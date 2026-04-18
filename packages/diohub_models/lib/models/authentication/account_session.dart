import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:flutter/foundation.dart';

/// Current account list and active account. Returned by [accountProvider] when
/// loaded successfully. Null when no active account or unauthenticated.
@immutable
class AccountSession {
  AccountSession({
    required this.accounts,
    required this.activeAccount,
  }) : _byUsername = {
          for (final AccountModel a in accounts) a.username: a,
        };

  final List<AccountModel> accounts;
  final String? activeAccount;
  final Map<String, AccountModel> _byUsername;

  /// O(1) lookup of active account model.
  AccountModel? get activeAccountModel =>
      activeAccount != null ? _byUsername[activeAccount] : null;

  AuthMethod? get activeAuthMethod => activeAccountModel?.authMethod;

  bool get isOAuthSession {
    final AuthMethod? method = activeAuthMethod;
    return method != null && method != AuthMethod.pat;
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      (other is AccountSession &&
          listEquals(other.accounts, accounts) &&
          other.activeAccount == activeAccount);

  @override
  int get hashCode => Object.hashAll(<Object?>[...accounts, activeAccount]);
}
