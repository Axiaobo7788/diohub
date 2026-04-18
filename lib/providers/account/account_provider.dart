import 'dart:async';

import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/authentication/access_token_model.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/providers/account/account_transition_provider.dart';
import 'package:diohub/providers/database_providers.dart'
    show authServiceProvider;
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountProvider = AsyncNotifierProvider<AccountNotifier, AccountSession?>(
    AccountNotifier.new);

class AccountNotifier extends AsyncNotifier<AccountSession?> {
  StreamSubscription<void>? _tokenInvalidationSub;

  AuthRepository get authRepository => ref.read(authServiceProvider);

  @override
  Future<AccountSession?> build() async {
    _tokenInvalidationSub?.cancel();
    _tokenInvalidationSub =
        AuthRepository.tokenInvalidationStream.listen((final _) {
      handleInvalidToken();
    });
    ref.onDispose(() => _tokenInvalidationSub?.cancel());

    try {
      return await _load();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load accounts',
        error: e,
        stackTrace: stackTrace,
        tag: 'AccountNotifier',
      );
      rethrow;
    }
  }

  Future<AccountSession?> _load() async {
    final List<AccountModel> accounts = await authRepository.getAllAccounts();
    String? activeAccount = await authRepository.getActiveAccount();

    if (activeAccount != null &&
        !accounts.any((final AccountModel a) => a.username == activeAccount)) {
      await authRepository.setActiveAccount('');
      activeAccount = null;
    }

    if (activeAccount == null && accounts.isEmpty) {
      return null;
    }
    return AccountSession(accounts: accounts, activeAccount: activeAccount);
  }

  Future<void> switchAccount(final String username) async {
    try {
      final String? token =
          await authRepository.getAccessTokenForAccount(username);
      if (token == null) {
        AppLogger.warning(
          'Token missing for account $username. Account removed.',
          tag: 'AccountNotifier',
        );
        await authRepository.removeAccount(username);
        state = AsyncData(await _load());
        return;
      }

      ref.read(accountTransitionProvider.notifier).state =
          AccountTransition(AccountTransitionKind.switching, username);
      await authRepository.setActiveAccount(username);
      await BaseAPIHandler.clearCache();
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      ref.read(accountTransitionProvider.notifier).state = null;
      state = AsyncData(
          AccountSession(accounts: accounts, activeAccount: username));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to switch account',
        error: e,
        stackTrace: stackTrace,
        tag: 'AccountNotifier',
      );
      ref.read(accountTransitionProvider.notifier).state = null;
      await authRepository.removeAccount(username);
      state = AsyncData(await _load());
    }
  }

  /// Updates stored profile (username, displayName, avatarUrl) for the account.
  Future<void> updateAccountProfile({
    required final String nodeId,
    required final String serverId,
    required final String username,
    final String? displayName,
    final String? avatarUrl,
  }) async {
    await authRepository.updateAccountProfile(
      nodeId: nodeId,
      serverId: serverId,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
    state = AsyncData(await _load());
  }

  Future<void> addAccount(
    final AccessTokenModel token, {
    final String? hostUrl,
    final AuthMethod authMethod = AuthMethod.oauth,
    bool setActive = true,
  }) async {
    try {
      if (token.accessToken == null || token.accessToken!.isEmpty) {
        state = AsyncError('Invalid access token', StackTrace.current);
        return;
      }

      ref.read(accountTransitionProvider.notifier).state =
          const AccountTransition(AccountTransitionKind.adding, null);

      final ServerConfig serverConfig = hostUrl != null
          ? ServerConfig.gitHubEnterprise(hostUrl)
          : ServerConfig.gitHubDotCom;
      final AccountModel accountModel =
          (await authRepository.fetchViewerInfoWithToken(
        token.accessToken!,
        serverConfig: serverConfig,
      ))
              .copyWith(authMethod: authMethod);

      ref.read(accountTransitionProvider.notifier).state = AccountTransition(
          AccountTransitionKind.adding, accountModel.username);

      await authRepository.storeAccessTokenForAccount(
        accountModel.username,
        token,
        accountModel,
      );
      if (setActive) {
        await authRepository.setActiveAccount(accountModel.username);
      }

      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      final String? activeAccount = await authRepository.getActiveAccount();
      ref.read(accountTransitionProvider.notifier).state = null;
      state = AsyncData(
          AccountSession(accounts: accounts, activeAccount: activeAccount));
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to add account',
        error: e,
        stackTrace: stackTrace,
        tag: 'AccountNotifier',
      );
      ref.read(accountTransitionProvider.notifier).state = null;
      final List<AccountModel> accounts = await authRepository.getAllAccounts();
      final String? activeAccount = await authRepository.getActiveAccount();
      if (accounts.isNotEmpty) {
        state = AsyncData(
            AccountSession(accounts: accounts, activeAccount: activeAccount));
      } else {
        state = AsyncError(
          'Failed to add account: $e',
          StackTrace.current,
        );
      }
    }
  }

  Future<void> removeAccount(final String username) async {
    try {
      await authRepository.removeAccount(username);
      state = AsyncData(await _load());
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to remove account',
        error: e,
        stackTrace: stackTrace,
        tag: 'AccountNotifier',
      );
      state = AsyncData(await _load());
    }
  }

  Future<void> logOutAll() async {
    try {
      await authRepository.logOut();
      state = const AsyncData(null);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to log out all accounts',
        error: e,
        stackTrace: stackTrace,
        tag: 'AccountNotifier',
      );
      state = AsyncData(await _load());
    }
  }

  Future<void> handleInvalidToken() async {
    final String? active = await authRepository.getActiveAccount();
    if (active == null) return;

    await authRepository.removeAccount(active);
    final List<AccountModel> accounts = await authRepository.getAllAccounts();
    final String? nextActive = await authRepository.getActiveAccount();
    await BaseAPIHandler.clearCache();
    state = AsyncData(
      nextActive != null || accounts.isNotEmpty
          ? AccountSession(accounts: accounts, activeAccount: nextActive)
          : null,
    );
  }

  /// Reload accounts and update state. Use after external changes (e.g. profile update).
  Future<void> loadAccounts() async {
    try {
      state = AsyncData(await _load());
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load accounts',
        error: e,
        stackTrace: stackTrace,
        tag: 'AccountNotifier',
      );
      state = AsyncError(e, stackTrace);
    }
  }
}
