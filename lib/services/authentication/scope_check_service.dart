import 'package:diohub/app/global.dart';
import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Service for checking and handling OAuth scope changes
///
/// Global Scope Tracking Rationale:
/// - Uses a single `grantedScope` for all accounts (stored globally)
/// - Assumes all accounts use the same requested scopes
/// - When scopes grow, prompts re-auth for all accounts
///
/// Trade-offs:
/// - Simpler implementation and storage
/// - Aligns with "same scopes for all accounts" assumption
/// - If individual accounts need different scopes, would require per-account tracking
class ScopeCheckService {
  static Future<void> checkAndPromptScopeReauth(BuildContext context) async {
    final AuthRepository authRepo = AuthRepository();
    final String requestedScope = authRepo.scopeString;
    final String? grantedScope = await authRepo.getGrantedScope();

    if (grantedScope == null) {
      // No scope stored yet, likely first run with multi-account
      // Set the current requested scope as granted
      await authRepo.setGrantedScope(requestedScope);
      return;
    }

    if (!_isScopeSubset(requestedScope, grantedScope)) {
      // Requested scopes have grown, need re-auth
      _showScopeReauthDialog(context);
    }
  }

  static bool _isScopeSubset(String requested, String granted) {
    final Set<String> requestedSet = requested.split(' ').toSet();
    final Set<String> grantedSet = granted.split(' ').toSet();
    return requestedSet.difference(grantedSet).isEmpty;
  }

  static void _showScopeReauthDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Additional Permissions Required'),
          content: const Text(
            'This app now requires additional permissions to function properly. '
            'Please re-authenticate all accounts to grant these permissions.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Dispatch LogOutAll to clear accounts - observer will redirect to AuthRoute
                BlocProvider.of<AccountBloc>(currentContext).add(LogOutAll());
              },
              child: const Text('Re-authenticate'),
            ),
          ],
        );
      },
    );
  }
}
