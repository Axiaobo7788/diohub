import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AccountTransitionKind { adding, switching }

class AccountTransition {
  const AccountTransition(this.kind, this.username);
  final AccountTransitionKind kind;
  final String? username;
}

class _AccountTransitionNotifier extends Notifier<AccountTransition?> {
  @override
  AccountTransition? build() => null;
}

final accountTransitionProvider =
    NotifierProvider<_AccountTransitionNotifier, AccountTransition?>(
  _AccountTransitionNotifier.new,
);
