import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/view/settings/md3/settings_md3_layout.dart';
import 'package:flutter/material.dart';

final class SettingsNavigationGroup {
  const SettingsNavigationGroup({required this.destinations, this.label});

  final String? label;
  final List<SettingsDestination> destinations;
}

List<SettingsNavigationGroup> settingsNavigationGroups(
  final BuildContext context,
) => <SettingsNavigationGroup>[
  const SettingsNavigationGroup(
    destinations: <SettingsDestination>[
      SettingsDestination.publicProfile,
      SettingsDestination.account,
      SettingsDestination.githubAppearance,
      SettingsDestination.githubAccessibility,
      SettingsDestination.githubNotifications,
    ],
  ),
  SettingsNavigationGroup(
    label: context.l10n.settingsAccessGroup,
    destinations: const <SettingsDestination>[
      SettingsDestination.billingAndLicensing,
      SettingsDestination.emails,
      SettingsDestination.passwordAndAuthentication,
      SettingsDestination.sessions,
      SettingsDestination.sshAndGpgKeys,
      SettingsDestination.organizations,
      SettingsDestination.enterprises,
      SettingsDestination.moderation,
    ],
  ),
  SettingsNavigationGroup(
    label: context.l10n.settingsCodePlanningAutomation,
    destinations: const <SettingsDestination>[
      SettingsDestination.githubRepositories,
      SettingsDestination.codespaces,
    ],
  ),
  SettingsNavigationGroup(
    label: context.l10n.settingsDioHubGroup,
    destinations: const <SettingsDestination>[
      SettingsDestination.dioHubGeneral,
      SettingsDestination.dioHubAppearance,
      SettingsDestination.dioHubAccessibility,
      SettingsDestination.dioHubCodeAndRepositories,
      SettingsDestination.dioHubNotifications,
      SettingsDestination.dioHubPrivacy,
      SettingsDestination.dioHubAbout,
    ],
  ),
];

String settingsDestinationLabel(
  final BuildContext context,
  final SettingsDestination destination,
) => switch (destination) {
  SettingsDestination.publicProfile => context.l10n.settingsPublicProfile,
  SettingsDestination.account => context.l10n.settingsGitHubAccount,
  SettingsDestination.githubAppearance => context.l10n.settingsAppearance,
  SettingsDestination.githubAccessibility => context.l10n.settingsAccessibility,
  SettingsDestination.githubNotifications => context.l10n.settingsNotifications,
  SettingsDestination.billingAndLicensing =>
    context.l10n.settingsBillingAndLicensing,
  SettingsDestination.emails => context.l10n.settingsEmails,
  SettingsDestination.passwordAndAuthentication =>
    context.l10n.settingsPasswordAndAuthentication,
  SettingsDestination.sessions => context.l10n.settingsSessions,
  SettingsDestination.sshAndGpgKeys => context.l10n.settingsSshAndGpgKeys,
  SettingsDestination.organizations => context.l10n.settingsOrganizations,
  SettingsDestination.enterprises => context.l10n.settingsEnterprises,
  SettingsDestination.moderation => context.l10n.settingsModeration,
  SettingsDestination.githubRepositories => context.l10n.accountRepositories,
  SettingsDestination.codespaces => context.l10n.settingsCodespaces,
  SettingsDestination.dioHubGeneral => context.l10n.settingsGeneral,
  SettingsDestination.dioHubAppearance => context.l10n.settingsAppearance,
  SettingsDestination.dioHubAccessibility => context.l10n.settingsAccessibility,
  SettingsDestination.dioHubCodeAndRepositories =>
    context.l10n.settingsCodeAndRepositories,
  SettingsDestination.dioHubNotifications => context.l10n.settingsNotifications,
  SettingsDestination.dioHubPrivacy => context.l10n.settingsPrivacy,
  SettingsDestination.dioHubAbout => context.l10n.settingsAbout,
};

IconData settingsDestinationIcon(
  final SettingsDestination destination,
) => switch (destination) {
  SettingsDestination.publicProfile => Icons.person_outline,
  SettingsDestination.account => Icons.settings_outlined,
  SettingsDestination.githubAppearance => Icons.brush_outlined,
  SettingsDestination.githubAccessibility => Icons.accessibility_new_outlined,
  SettingsDestination.githubNotifications => Icons.notifications_outlined,
  SettingsDestination.billingAndLicensing => Icons.credit_card_outlined,
  SettingsDestination.emails => Icons.email_outlined,
  SettingsDestination.passwordAndAuthentication => Icons.shield_outlined,
  SettingsDestination.sessions => Icons.wifi_tethering_outlined,
  SettingsDestination.sshAndGpgKeys => Icons.key_outlined,
  SettingsDestination.organizations => Icons.apartment_outlined,
  SettingsDestination.enterprises => Icons.language_outlined,
  SettingsDestination.moderation => Icons.chat_bubble_outline,
  SettingsDestination.githubRepositories => Icons.book_outlined,
  SettingsDestination.codespaces => Icons.dns_outlined,
  SettingsDestination.dioHubGeneral => Icons.tune_outlined,
  SettingsDestination.dioHubAppearance => Icons.palette_outlined,
  SettingsDestination.dioHubAccessibility => Icons.accessibility_new_outlined,
  SettingsDestination.dioHubCodeAndRepositories => Icons.code_outlined,
  SettingsDestination.dioHubNotifications => Icons.notifications_outlined,
  SettingsDestination.dioHubPrivacy => Icons.privacy_tip_outlined,
  SettingsDestination.dioHubAbout => Icons.info_outline,
};

class SettingsSidebar extends StatelessWidget {
  const SettingsSidebar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final SettingsDestination selected;
  final ValueChanged<SettingsDestination> onSelected;

  @override
  Widget build(final BuildContext context) => SizedBox(
    key: const ValueKey<String>('settings-sidebar'),
    width: SettingsMd3Layout.navigationWidth,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        for (final SettingsNavigationGroup group in settingsNavigationGroups(
          context,
        )) ...<Widget>[
          if (group.label case final String label) ...<Widget>[
            const Divider(height: 25),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Text(
                label,
                key: ValueKey<String>(
                  'settings-group-${group.destinations.first.path.replaceAll('/', '-')}',
                ),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          for (final SettingsDestination destination in group.destinations)
            _SettingsSidebarDestination(
              destination: destination,
              selected: destination == selected,
              onTap: () => onSelected(destination),
            ),
        ],
      ],
    ),
  );
}

class _SettingsSidebarDestination extends StatelessWidget {
  const _SettingsSidebarDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final SettingsDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final String label = settingsDestinationLabel(context, destination);
    final String destinationKey = destination.path.replaceAll('/', '-');
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      key: ValueKey<String>('settings-nav-$destinationKey'),
      label: label,
      button: true,
      selected: selected,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Material(
            color: selected
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: <Widget>[
                    AnimatedContainer(
                      key: ValueKey<String>(
                        'settings-nav-indicator-$destinationKey',
                      ),
                      duration: reducedMotion
                          ? Duration.zero
                          : kContentTransitionDuration,
                      width: 4,
                      height: selected ? 28 : 0,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              settingsDestinationIcon(destination),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsCompactNavigation extends StatelessWidget {
  const SettingsCompactNavigation({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final SettingsDestination selected;
  final ValueChanged<SettingsDestination> onSelected;

  @override
  Widget build(final BuildContext context) => MenuAnchor(
    key: ValueKey<String>('settings-compact-navigation-${selected.path}'),
    menuChildren: <Widget>[
      for (final SettingsNavigationGroup group in settingsNavigationGroups(
        context,
      )) ...<Widget>[
        if (group.label case final String label) ...<Widget>[
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              label,
              key: ValueKey<String>(
                'settings-compact-group-${group.destinations.first.path.replaceAll('/', '-')}',
              ),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
        for (final SettingsDestination destination in group.destinations)
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
            ),
            child: MenuItemButton(
              key: ValueKey<String>(
                'settings-compact-nav-${destination.path.replaceAll('/', '-')}',
              ),
              onPressed: () => onSelected(destination),
              leadingIcon: Icon(settingsDestinationIcon(destination)),
              trailingIcon: destination == selected
                  ? const Icon(Icons.check)
                  : null,
              child: Text(settingsDestinationLabel(context, destination)),
            ),
          ),
      ],
    ],
    builder:
        (
          final BuildContext context,
          final MenuController controller,
          final Widget? child,
        ) => ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              icon: Icon(settingsDestinationIcon(selected)),
              label: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(settingsDestinationLabel(context, selected)),
              ),
            ),
          ),
        ),
  );
}
