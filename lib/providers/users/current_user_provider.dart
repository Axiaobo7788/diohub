import 'dart:async';

import 'package:dio/dio.dart';
import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

extension ViewerProvider on BuildContext {
  GviewerInfoData_viewer get viewer =>
      Provider.of<CurrentUserProvider>(this).data;
}

class CurrentUserProvider extends BaseDataProvider<GviewerInfoData_viewer> {
  CurrentUserProvider({
    required this.authenticationBloc,
    required this.accountBloc,
  }) : super(loadDataOnInit: false) {
    // Listen to account state changes (sole source of truth)
    _accountSubscription = accountBloc.stream.listen((final AccountState accountState) async {
      // If accounts are empty, just reset - guard will handle routing
      if (accountState is AccountReady && accountState.accounts.isEmpty) {
        debugPrint('[CurrentUserProvider] No accounts, resetting (guard handles routing)');
        reset();
        return;
      }
      
      // Load when AccountReady with active account
      if (accountState is AccountReady && accountState.activeAccount != null) {
        debugPrint('[CurrentUserProvider] AccountReady with active: ${accountState.activeAccount}');
        // Check if active account changed
        if (status == Status.loaded) {
          debugPrint('[CurrentUserProvider] Active account changed, reloading');
          reset();
        }
        await loadData();
      } else if (accountState is AccountSwitching) {
        // Reset during switch but don't load yet
        debugPrint('[CurrentUserProvider] Account switching, resetting');
        reset();
      } else if (accountState is AccountReady && accountState.activeAccount == null) {
        // No active account, reset
        debugPrint('[CurrentUserProvider] No active account, resetting');
        reset();
      }
    });
    
    // Load data if account is already ready with active account
    final accountState = accountBloc.state;
    if (accountState is AccountReady && accountState.activeAccount != null) {
      debugPrint('[CurrentUserProvider] Init: AccountReady with active, loading');
      loadData();
    }
  }

  final AuthenticationBloc authenticationBloc;
  final AccountBloc accountBloc;
  StreamSubscription<AccountState>? _accountSubscription;

  @override
  void dispose() {
    _accountSubscription?.cancel();
    super.dispose();
  }

  @override
  void onError(final Object error) {
    if (error is DioException) {
      if (error.response != null &&
          error.response!.statusCode == 401 &&
          authenticationBloc.state.authenticated) {
        // Only logout if it's specifically "Bad credentials" (revoked/invalid token)
        // Don't logout for resource-specific 401s (permissions, private resources, etc.)
        if (AuthRepository.isTokenInvalidError(error)) {
          // Reset provider first to clear error state and prevent error screen from blocking navigation
          reset();
          // Trigger logout which will handle navigation to auth screen
          authenticationBloc.add(LogOut());
        }
      }
    }
  }

  @override
  Future<GviewerInfoData_viewer> setInitData({
    final bool isInitialisation = false,
  }) =>
      UserInfoService.getViewerInfo();
}
