import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/models/authentication/access_token_model.dart';
import 'package:diohub/models/authentication/account_model.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'account_event.dart';
part 'account_state.dart';

/// AccountBloc is the sole authority for account management.
/// Events are processed sequentially by default (bloc's event queue),
/// preventing race conditions in add/switch/remove operations.
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AuthRepository authRepository;

  AccountBloc(this.authRepository) : super(const AccountUninitialized()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<SwitchAccount>(_onSwitchAccount);
    on<AddAccount>(_onAddAccount);
    on<RemoveAccount>(_onRemoveAccount);
    on<LogOutAll>(_onLogOutAll);
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountState> emit,
  ) async {
    debugPrint('[AccountBloc] _onLoadAccounts: Loading accounts...');
    emit(const AccountLoading());
    try {
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      String? activeAccount = await authRepository.getActiveAccount();

      debugPrint(
          '[AccountBloc] _onLoadAccounts: Found ${accounts.length} accounts, active: $activeAccount');

      // Validate active account exists in list
      if (activeAccount != null &&
          !accounts.any((a) => a.username == activeAccount)) {
        debugPrint(
            '[AccountBloc] _onLoadAccounts: Active account "$activeAccount" not in list, clearing');
        await authRepository.setActiveAccount(''); // Clear invalid active
        activeAccount = null;
      }

      for (final account in accounts) {
        debugPrint(
            '[AccountBloc] _onLoadAccounts: Account - ${account.username} (${account.displayName})');
      }

      emit(AccountReady(accounts, activeAccount));
      debugPrint('[AccountBloc] _onLoadAccounts: Emitted AccountReady state');
    } catch (e) {
      debugPrint('[AccountBloc] _onLoadAccounts: Error loading accounts: $e');
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
      debugPrint('[AccountBloc] _onSwitchAccount: Error switching account: $e');
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
    debugPrint('[AccountBloc] _onAddAccount: Starting unified add flow');

    try {
      // Validate token
      if (event.token.accessToken == null || event.token.accessToken!.isEmpty) {
        emit(const AccountError('Invalid access token'));
        return;
      }

      emit(const AccountAdding(null));

      // Fetch user info using the token (unified OAuth + PAT flow)
      debugPrint(
          '[AccountBloc] _onAddAccount: Fetching user info with token...');
      final AccountModel accountModel =
          await authRepository.fetchViewerInfoWithToken(
        event.token.accessToken!,
        hostUrl: event.hostUrl,
      );
      debugPrint(
          '[AccountBloc] _onAddAccount: Fetched user - ${accountModel.username} (${accountModel.displayName})');

      emit(AccountAdding(accountModel.username));

      // Store token per-account
      await authRepository.storeAccessTokenForAccount(
        accountModel.username,
        event.token,
        accountModel,
      );
      debugPrint(
          '[AccountBloc] _onAddAccount: Stored token for ${accountModel.username}');

      // Set as active account
      await authRepository.setActiveAccount(accountModel.username);
      debugPrint(
          '[AccountBloc] _onAddAccount: Set ${accountModel.username} as active');

      // Read back to verify
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      debugPrint(
          '[AccountBloc] _onAddAccount: Verified ${accounts.length} accounts in storage');
      for (final account in accounts) {
        debugPrint(
            '[AccountBloc] _onAddAccount: - ${account.username} (${account.displayName})');
      }

      emit(AccountReady(accounts, accountModel.username));
      debugPrint(
          '[AccountBloc] _onAddAccount: Emitted AccountReady with active: ${accountModel.username}');
    } catch (e) {
      debugPrint('[AccountBloc] _onAddAccount: Error: $e');
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
    debugPrint(
        '[AccountBloc] _onRemoveAccount: Removing account ${event.username}');
    try {
      final String? currentActive = await authRepository.getActiveAccount();
      await authRepository.removeAccount(event.username);
      debugPrint(
          '[AccountBloc] _onRemoveAccount: Removed account ${event.username}');
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      final String? activeAccount = await authRepository.getActiveAccount();
      debugPrint(
          '[AccountBloc] _onRemoveAccount: Remaining accounts: ${accounts.length}, active: $activeAccount');

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
        debugPrint('[AccountBloc] _onRemoveAccount: No accounts remaining');
        emit(AccountReady(<AccountModel>[], null));
      }
    } catch (e) {
      debugPrint('[AccountBloc] _onRemoveAccount: Error removing account: $e');
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
    debugPrint('[AccountBloc] _onLogOutAll: Starting to log out all accounts');
    try {
      // Get all accounts first to delete their tokens
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      debugPrint(
          '[AccountBloc] _onLogOutAll: Found ${accounts.length} accounts to remove');

      // Delete all account tokens from storage
      for (final account in accounts) {
        debugPrint(
            '[AccountBloc] _onLogOutAll: Deleting token for account ${account.username}');
        try {
          await authRepository.removeAccount(account.username);
        } catch (e) {
          debugPrint(
              '[AccountBloc] _onLogOutAll: Error removing account ${account.username}: $e');
        }
      }

      // Clear all storage using logOut (which handles clearing everything)
      await authRepository.logOut();
      debugPrint(
          '[AccountBloc] _onLogOutAll: Cleared all accounts and storage');

      // Emit empty state
      emit(AccountReady(<AccountModel>[], null));
      debugPrint(
          '[AccountBloc] _onLogOutAll: Emitted empty AccountReady state');
    } catch (e) {
      debugPrint(
          '[AccountBloc] _onLogOutAll: Error logging out all accounts: $e');
      debugPrint(
          '[AccountBloc] _onLogOutAll: Stack trace: ${StackTrace.current}');
      // Try to get current state anyway
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      final String? activeAccount = await authRepository.getActiveAccount();
      // Emit error state first, then ready state
      emit(AccountError('Failed to log out all accounts: ${e.toString()}'));
      emit(AccountReady(accounts, activeAccount));
    }
  }
}
