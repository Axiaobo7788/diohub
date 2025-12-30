import 'dart:async';

import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
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
    _accountSubscription =
        accountBloc.stream.listen((final AccountState accountState) async {
      // If accounts are empty, just reset - guard will handle routing
      if (accountState is AccountReady && accountState.accounts.isEmpty) {
        reset();
        return;
      }

      // Load when AccountReady with active account
      if (accountState is AccountReady && accountState.activeAccount != null) {
        // Check if active account changed
        if (status == Status.loaded) {
          reset();
        }
        await loadData();
      } else if (accountState is AccountSwitching) {
        // Reset during switch but don't load yet
        reset();
      } else if (accountState is AccountReady &&
          accountState.activeAccount == null) {
        // No active account, reset
        reset();
      }
    });

    // Load data if account is already ready with active account
    final accountState = accountBloc.state;
    if (accountState is AccountReady && accountState.activeAccount != null) {
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
    // Logout is now handled centrally in BaseAPIHandler.onError interceptor
    // This ensures all API requests (REST and GraphQL) trigger logout on "Bad credentials"
  }

  @override
  Future<GviewerInfoData_viewer> setInitData({
    final bool isInitialisation = false,
  }) =>
      UserInfoService.getViewerInfo();
}
