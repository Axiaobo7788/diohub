import 'dart:async';

import 'package:diohub/app/settings/locale_settings.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/l10n/language_picker.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:flutter/material.dart';

/// Account menu shared by every page hosted in the application chrome.
///
/// Profile tabs that already have native routes are connected by the caller;
/// staged destinations stay visible and report their state consistently.
class GlobalAccountMenu extends StatelessWidget {
  const GlobalAccountMenu({
    required this.loading,
    required this.onSignIn,
    required this.onSignOut,
    required this.onOpenProfileTab,
    required this.onSwitchAccount,
    required this.language,
    required this.onLanguageSelected,
    required this.onStagedAction,
    this.account,
    this.statusEmoji,
    this.statusMessage,
    this.compact = false,
    super.key,
  });

  final AccountModel? account;
  final bool loading;
  final bool compact;
  final String? statusEmoji;
  final String? statusMessage;
  final AppLanguage language;
  final Future<void> Function() onSignIn;
  final Future<void> Function() onSignOut;
  final ValueChanged<String?> onOpenProfileTab;
  final VoidCallback onSwitchAccount;
  final ValueChanged<AppLanguage> onLanguageSelected;
  final ValueChanged<String> onStagedAction;

  @override
  Widget build(final BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final AccountModel? activeAccount = account;
    if (activeAccount == null) {
      if (compact) {
        return IconButton(
          onPressed: () => unawaited(onSignIn()),
          tooltip: context.l10n.commonSignIn,
          icon: const Icon(Icons.login),
        );
      }
      return FilledButton.tonalIcon(
        onPressed: () => unawaited(onSignIn()),
        icon: const Icon(Icons.login),
        label: Text(context.l10n.commonSignIn),
      );
    }

    return MenuAnchor(
      key: const ValueKey<String>('global-account-menu'),
      style: const MenuStyle(
        minimumSize: WidgetStatePropertyAll<Size>(Size(300, 0)),
        maximumSize: WidgetStatePropertyAll<Size>(Size(320, double.infinity)),
        padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(vertical: 8),
        ),
      ),
      menuChildren: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: <Widget>[
              UserAvatar(
                avatarUrl: activeAccount.avatarUrl,
                fallbackText: activeAccount.username,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      activeAccount.displayName ?? activeAccount.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      activeAccount.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (final BuildContext menuContext) => IconButton(
                  onPressed: () {
                    MenuController.maybeOf(menuContext)?.close();
                    onSwitchAccount();
                  },
                  tooltip: context.l10n.accountSwitch,
                  icon: const Icon(Icons.swap_horiz, size: 20),
                ),
              ),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () => onStagedAction(context.l10n.accountSetStatus),
          leadingIcon: Text(
            (statusEmoji ?? '').isEmpty ? '💬' : statusEmoji!,
            style: const TextStyle(fontSize: 18),
          ),
          child: Text(
            (statusMessage ?? '').isEmpty
                ? context.l10n.accountSetStatus
                : statusMessage!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(),
        _profileItem(
          icon: Icons.person_outline,
          label: context.l10n.accountProfile,
          tab: null,
        ),
        _profileItem(
          icon: Icons.book_outlined,
          label: context.l10n.accountRepositories,
          tab: 'repositories',
        ),
        _profileItem(
          icon: Icons.star_outline,
          label: context.l10n.accountStars,
          tab: 'stars',
        ),
        _profileItem(
          icon: Icons.code,
          label: context.l10n.accountGists,
          tab: 'gists',
        ),
        _profileItem(
          icon: Icons.apartment_outlined,
          label: context.l10n.accountOrganizations,
          tab: 'organizations',
        ),
        MenuItemButton(
          onPressed: () => onStagedAction(context.l10n.accountEnterprises),
          leadingIcon: const Icon(Icons.language_outlined),
          child: Text(context.l10n.accountEnterprises),
        ),
        _profileItem(
          icon: Icons.favorite_border,
          label: context.l10n.accountSponsors,
          tab: 'sponsors',
        ),
        const Divider(),
        _profileItem(
          icon: Icons.settings_outlined,
          label: context.l10n.accountSettings,
          tab: 'settings',
        ),
        for (final (IconData, String) destination in <(IconData, String)>[
          (Icons.smart_toy_outlined, context.l10n.accountCopilotSettings),
          (Icons.science_outlined, context.l10n.accountFeaturePreview),
          (Icons.palette_outlined, context.l10n.accountAppearance),
          (Icons.accessibility_new_outlined, context.l10n.accountAccessibility),
        ])
          MenuItemButton(
            onPressed: () => onStagedAction(destination.$2),
            leadingIcon: Icon(destination.$1),
            child: Text(destination.$2),
          ),
        MenuItemButton(
          key: const ValueKey<String>('global-language-menu-item'),
          onPressed: () => unawaited(_showLanguageDialog(context)),
          leadingIcon: const Icon(Icons.translate_outlined),
          trailingIcon: Text(appLanguageLabel(context, language)),
          child: Text(context.l10n.languageAndRegion),
        ),
        MenuItemButton(
          onPressed: () => onStagedAction(context.l10n.accountTryEnterprise),
          leadingIcon: const Icon(Icons.upload_outlined),
          trailingIcon: Chip(
            label: Text(context.l10n.commonFree),
            visualDensity: VisualDensity.compact,
          ),
          child: Text(context.l10n.accountTryEnterprise),
        ),
        MenuItemButton(
          onPressed: onSwitchAccount,
          leadingIcon: const Icon(Icons.swap_horiz),
          child: Text(context.l10n.accountSwitch),
        ),
        const Divider(),
        MenuItemButton(
          onPressed: () => unawaited(onSignOut()),
          leadingIcon: const Icon(Icons.logout),
          child: Text(context.l10n.accountSignOut),
        ),
      ],
      builder:
          (
            final BuildContext context,
            final MenuController controller,
            final Widget? child,
          ) {
            void toggleMenu() {
              controller.isOpen ? controller.close() : controller.open();
            }

            final Widget avatar = UserAvatar(
              avatarUrl: activeAccount.avatarUrl,
              fallbackText: activeAccount.username,
              size: compact ? 30 : 22,
            );
            if (compact) {
              return IconButton(
                key: const ValueKey<String>('global-account-menu-button'),
                onPressed: toggleMenu,
                tooltip: '@${activeAccount.username}',
                icon: avatar,
              );
            }
            return OutlinedButton.icon(
              onPressed: toggleMenu,
              icon: avatar,
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 112),
                child: Text(
                  '@${activeAccount.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
    );
  }

  Future<void> _showLanguageDialog(final BuildContext context) async {
    final AppLanguage? selected = await showAppLanguageDialog(
      context,
      language,
    );
    if (selected != null && selected != language) {
      onLanguageSelected(selected);
    }
  }

  MenuItemButton _profileItem({
    required final IconData icon,
    required final String label,
    required final String? tab,
  }) => MenuItemButton(
    onPressed: () => onOpenProfileTab(tab),
    leadingIcon: Icon(icon),
    child: Text(label),
  );
}
