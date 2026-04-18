import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/account/auth_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that shows its child if the required scopes are granted,
/// otherwise shows a placeholder explaining the missing permissions.
class ScopeGatedWidget extends ConsumerWidget {
  const ScopeGatedWidget({
    required this.scopes,
    required this.featureName,
    required this.child,
    super.key,
  });

  final List<String> scopes;
  final String featureName;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(scopeGateProvider);
    if (scopes.every(gate.hasScope)) {
      return child;
    }
    return ScopeMissingPlaceholder(
      scopes: scopes,
      featureName: featureName,
    );
  }
}

/// Placeholder shown when a feature requires scopes that aren't granted.
class ScopeMissingPlaceholder extends ConsumerWidget {
  const ScopeMissingPlaceholder({
    required this.scopes,
    required this.featureName,
    super.key,
  });

  final List<String> scopes;
  final String featureName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final session = ref.watch(accountProvider).value;
    final authMethod = session?.activeAuthMethod;
    final serverConfig = session?.activeAccountModel?.serverConfig ??
        ServerConfig.gitHubDotCom;

    final gate = ref.watch(scopeGateProvider);
    final missingScopes = scopes.where((s) => !gate.hasScope(s)).toList();
    final scopesText = missingScopes.length == 1
        ? '"${missingScopes.first}"'
        : missingScopes.map((s) => '"$s"').join(', ');

    return Center(
      child: Padding(
        padding: spacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.hinted,
            ),
            SizedBox(height: spacing.sectionSpacing),
            Text(
              'Permission Required',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: spacing.itemSpacing),
            Text(
              'This feature requires the $scopesText ${missingScopes.length == 1 ? 'permission' : 'permissions'}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.tightSpacing),
            Text(
              'Update your token to enable $featureName.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.sectionSpacing),
            FilledButton.icon(
              onPressed: () => _handleUpdatePermissions(context, authMethod, serverConfig),
              icon: const Icon(Icons.edit),
              label: Text(
                authMethod == AuthMethod.pat
                    ? 'Update Token'
                    : 'Re-authenticate',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdatePermissions(
    BuildContext context,
    AuthMethod? authMethod,
    ServerConfig serverConfig,
  ) async {
    if (authMethod == AuthMethod.pat) {
      // PAT: open the createTokenUrl in browser
      final uri = serverConfig.createTokenUrl;
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      // OAuth: trigger inline re-auth flow
      final container = ProviderScope.containerOf(context);
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

/// Sliver variant of ScopeGatedWidget for use in CustomScrollView/sliver lists.
class ScopeGatedSliver extends ConsumerWidget {
  const ScopeGatedSliver({
    required this.scopes,
    required this.featureName,
    required this.sliver,
    super.key,
  });

  final List<String> scopes;
  final String featureName;
  final Widget sliver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(scopeGateProvider);
    if (scopes.every(gate.hasScope)) return sliver;
    return SliverFillRemaining(
      child: ScopeMissingPlaceholder(scopes: scopes, featureName: featureName),
    );
  }
}
