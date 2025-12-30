import 'dart:async';

import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/models/authentication/access_token_model.dart';
import 'package:diohub/models/authentication/account_model.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'account_event.dart';
part 'account_state.dart';

/// AccountBloc is the sole authority for account management.
/// Events are processed sequentially by default (bloc's event queue),
/// preventing race conditions in add/switch/remove operations.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AuthRepository authRepository;
  late final StreamSubscription<void> _tokenInvalidationSub;

  AccountBloc(this.authRepository) : super(const AccountUninitialized()) {
    _tokenInvalidationSub = AuthRepository.tokenInvalidationStream.listen((_) {
      add(HandleInvalidToken());
    });

    on<LoadAccounts>(_onLoadAccounts);
    on<SwitchAccount>(_onSwitchAccount);
    on<AddAccount>(_onAddAccount);
    on<RemoveAccount>(_onRemoveAccount);
    on<LogOutAll>(_onLogOutAll);
    on<HandleInvalidToken>(_onHandleInvalidToken);
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountState> emit,
  ) async {
    emit(const AccountLoading());
    try {
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      String? activeAccount = await authRepository.getActiveAccount();

      // Validate active account exists in list
      if (activeAccount != null &&
          !accounts.any((a) => a.username == activeAccount)) {
        await authRepository.setActiveAccount(''); // Clear invalid active
        activeAccount = null;
      }

      emit(AccountReady(accounts, activeAccount));
    } catch (e) {
      emit(AccountError(e.toString()));
    }
  }

  Future<void> _onSwitchAccount(
    SwitchAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      // Validate token exists for target account
      final String? token =
          await authRepository.getAccessTokenForAccount(event.username);
      if (token == null) {
        // Token missing or read failed - remove account and prompt re-auth
        await authRepository.removeAccount(event.username);
        final List<AccountModel> accounts =
            await authRepository.getAllAccounts();
        final String? activeAccount = await authRepository.getActiveAccount();
        // Emit error state only, don't overwrite with AccountReady
        emit(AccountError(
            'Token missing for account ${event.username}. Account removed.'));
        // Then emit ready state so UI can update
        emit(AccountReady(accounts, activeAccount));
        return;
      }

      emit(AccountSwitching(event.username));
      await authRepository.setActiveAccount(event.username);
      await BaseAPIHandler.clearCache();
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      emit(AccountReady(accounts, event.username));
    } catch (e) {
      // Token read failure (PlatformException) - remove account
      await authRepository.removeAccount(event.username);
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      final String? activeAccount = await authRepository.getActiveAccount();
      // Emit error state first, then ready state
      emit(AccountError('Failed to switch account: ${e.toString()}'));
      emit(AccountReady(accounts, activeAccount));
    }
  }

  Future<void> _onAddAccount(
    AddAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      // Validate token
      if (event.token.accessToken == null || event.token.accessToken!.isEmpty) {
        emit(const AccountError('Invalid access token'));
        return;
      }

      emit(const AccountAdding(null));

      // Fetch user info using the token (unified OAuth + PAT flow)
      final AccountModel accountModel =
          await authRepository.fetchViewerInfoWithToken(
        event.token.accessToken!,
        hostUrl: event.hostUrl,
      );

      emit(AccountAdding(accountModel.username));

      // Store token per-account
      await authRepository.storeAccessTokenForAccount(
        accountModel.username,
        event.token,
        accountModel,
      );

      // Set as active account
      await authRepository.setActiveAccount(accountModel.username);

      // Read back to verify
      final List<AccountModel> accounts = await authRepository.getAllAccounts();

      emit(AccountReady(accounts, accountModel.username));
    } catch (e) {
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      final String? activeAccount = await authRepository.getActiveAccount();

      emit(AccountError('Failed to add account: ${e.toString()}'));

      // Return to previous state if accounts exist
      if (accounts.isNotEmpty) {
        emit(AccountReady(accounts, activeAccount));
      }
    }
  }

  Future<void> _onRemoveAccount(
    RemoveAccount event,
    Emitter<AccountState> emit,
  ) async {
    try {
      final String? currentActive = await authRepository.getActiveAccount();
      await authRepository.removeAccount(event.username);
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      final String? activeAccount = await authRepository.getActiveAccount();

      // If we removed the active account and there are other accounts, set first as active
      if (currentActive == event.username &&
          accounts.isNotEmpty &&
          activeAccount == null) {
        await authRepository.setActiveAccount(accounts.first.username);
        emit(AccountReady(accounts, accounts.first.username));
      } else {
        emit(AccountReady(accounts, activeAccount));
      }

      // If no accounts remain, emit empty ready state
      if (accounts.isEmpty) {
        emit(AccountReady(<AccountModel>[], null));
      }
    } catch (e) {
      // Handle removal failure gracefully
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      final String? activeAccount = await authRepository.getActiveAccount();
      // Emit error state first, then ready state
      emit(AccountError('Failed to remove account: ${e.toString()}'));
      emit(AccountReady(accounts, activeAccount));
    }
  }

  Future<void> _onLogOutAll(
    LogOutAll event,
    Emitter<AccountState> emit,
  ) async {
    try {
      // Get all accounts first to delete their tokens
      final List<AccountModel> accounts = await authRepository.getAllAccounts();

      // Delete all account tokens from storage
      for (final account in accounts) {
        try {
          await authRepository.removeAccount(account.username);
        } catch (e) {
          // Continue with other accounts even if one fails
        }
      }

      // Clear all storage using logOut (which handles clearing everything)
      await authRepository.logOut();

      // Emit empty state
      emit(AccountReady(<AccountModel>[], null));
    } catch (e) {
      // Try to get current state anyway
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      final String? activeAccount = await authRepository.getActiveAccount();
      // Emit error state first, then ready state
      emit(AccountError('Failed to log out all accounts: ${e.toString()}'));
      emit(AccountReady(accounts, activeAccount));
    }
  }

  Future<void> _onHandleInvalidToken(
    HandleInvalidToken event,
    Emitter<AccountState> emit,
  ) async {
    final String? active = await authRepository.getActiveAccount();
    if (active == null) {
      return;
    }

    // Remove only the active account
    await authRepository.removeAccount(active);
    final List<AccountModel> accounts = await authRepository.getAllAccounts();

    if (accounts.isNotEmpty) {
      final String next = accounts.first.username;
      await authRepository.setActiveAccount(next);
      await BaseAPIHandler.clearCache();
      emit(AccountReady(accounts, next));
    } else {
      await BaseAPIHandler.clearCache();
      emit(const AccountReady(<AccountModel>[], null));
    }
  }

  @override
  Future<void> close() {
    _tokenInvalidationSub.cancel();
    return super.close();
  }
}
