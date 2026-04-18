import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/account/auth_provider.dart';
import 'package:diohub/providers/database_providers.dart' show scopeGateProvider;
import 'package:diohub/providers/startup_flows/startup_flow.dart';
import 'package:diohub/providers/startup_flows/startup_flows_provider.dart';
import 'package:diohub/view/home/widgets/startup_flow_banners.dart';
import 'package:diohub_models/models/server_config.dart';

/// Prompted flow: shows a dismissable banner when the app adds new optional
/// scopes that the user's token doesn't have. Never blocks the app.
class ScopeReauthFlow extends StartupFlow {
  @override
  String get id => 'scope_reauth';

  @override
  int get priority => 0;

  @override
  FlowTier get tier => FlowTier.prompted;

  @override
  Future<bool> shouldShow(final ProviderContainer container) async {
    final accountSession = await container.read(accountProvider.future);
    if (accountSession == null || accountSession.activeAccount == null) {
      return false;
    }

    final scopeGate = container.read(scopeGateProvider);
    final missingScopes = scopeGate.missingOptionalScopes;

    // No missing scopes = nothing to prompt
    if (missingScopes.isEmpty) return false;

    // Check if user dismissed this for the current app version
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;
    final data = container.read(startupFlowsProvider);
    final dismissedVersion = data.dismissedUntil[id];

    // Show banner if not dismissed for this version
    return dismissedVersion != currentVersion;
  }

  @override
  Widget? buildBanner(
    final BuildContext context, {
    required final VoidCallback onDismiss,
    required final VoidCallback onAction,
  }) {
    return StartupFlowBannerCard(
      icon: Icons.lock_outline,
      title: 'New features available',
      subtitle:
          'Update your token permissions to unlock additional app features',
      actionLabel: 'Update Permissions',
      onAction: onAction,
      onDismiss: onDismiss,
    );
  }

  @override
  Widget? buildModal(
    final BuildContext context, {
    required final VoidCallback onComplete,
  }) =>
      null;

  @override
  Future<void> markHandled(final ProviderContainer container) async {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;
    
    // Store the current version in dismissedUntil so we don't show again
    // until the next app version that adds more scopes
    final notifier = container.read(startupFlowsProvider.notifier);
    final current = container.read(startupFlowsProvider);
    await notifier.update((_) => current.copyWith(
      dismissedUntil: {...current.dismissedUntil, id: currentVersion},
    ));
  }

  /// Handle the "Update Permissions" action based on auth method.
  static Future<void> handleUpdateAction(BuildContext context) async {
    final container = ProviderScope.containerOf(context);
    final accountSession = await container.read(accountProvider.future);
    if (accountSession == null) return;

    final authMethod = accountSession.activeAuthMethod;
    final serverConfig =
        accountSession.activeAccountModel?.serverConfig ?? ServerConfig.gitHubDotCom;

    if (authMethod == AuthMethod.pat) {
      // PAT: open the createTokenUrl in browser
      final uri = serverConfig.createTokenUrl;
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // OAuth/Device Code: trigger inline re-auth flow
      try {
        await container.read(authProvider.notifier).loginWithBrowser();
      } on Exception catch (e) {
        if (context.mounted) {
          container
              .read(notificationServiceProvider)
              .error('Re-authentication failed: $e');
        }
      }
    }
  }
}

