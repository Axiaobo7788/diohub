import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/settings/error_tracking.dart';
import 'package:diohub/app/settings/notifications.dart';
import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/providers/settings/error_tracking_provider.dart';
import 'package:diohub/providers/settings/notifications_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/settings/md3/settings_md3_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsNotificationsPage extends ConsumerWidget {
  const SettingsNotificationsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final NotificationsSettings settings = ref.watch(notificationsProvider);
    final NotificationsNotifier notifier = ref.read(
      notificationsProvider.notifier,
    );

    void update(
      final NotificationsSettings Function(NotificationsSettings) mutate,
    ) {
      unawaited(runSettingsUpdate(context, notifier.update(mutate)));
    }

    return Column(
      key: const ValueKey<String>('settings-notifications-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.settingsNotifications,
          description: context.l10n.settingsNotificationsDescription,
        ),
        Md3SettingsSection(
          title: context.l10n.settingsInbox,
          children: <Widget>[
            SettingsSwitchRow(
              title: context.l10n.settingsAutoMarkRead,
              subtitle: context.l10n.settingsAutoMarkReadDescription,
              value: settings.autoMarkRead,
              onChanged: (final bool value) => update(
                (final NotificationsSettings current) =>
                    current.copyWith(autoMarkRead: value),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsGroupByRepository,
              subtitle: context.l10n.settingsGroupByRepositoryDescription,
              value: settings.groupByRepo,
              onChanged: (final bool value) => update(
                (final NotificationsSettings current) =>
                    current.copyWith(groupByRepo: value),
              ),
            ),
          ],
        ),
        Md3SettingsSection(
          title: context.l10n.settingsBackgroundChecks,
          description: context.l10n.settingsBackgroundChecksDescription,
          children: <Widget>[
            SettingsSwitchRow(
              title: context.l10n.settingsInboxPolling,
              subtitle: context.l10n.settingsInboxPollingDescription,
              value: settings.inboxPollingEnabled,
              onChanged: (final bool value) => unawaited(
                runSettingsUpdate(
                  context,
                  notifier.updateInboxPollingEnabled(value),
                ),
              ),
            ),
            if (settings.inboxPollingEnabled)
              SettingsSliderRow(
                title: context.l10n.settingsPollingInterval,
                subtitle: context.l10n.settingsPollingIntervalDescription,
                value: settings.inboxPollingIntervalMinutes.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                valueLabelBuilder: (final double value) =>
                    context.l10n.settingsMinutes(value.round()),
                onChanged: (final double value) => unawaited(
                  runSettingsUpdate(
                    context,
                    notifier.updateInboxPollingInterval(value.round()),
                  ),
                ),
              ),
            SettingsSwitchRow(
              title: context.l10n.settingsSystemNotifications,
              subtitle: context.l10n.settingsSystemNotificationsDescription,
              value: settings.systemNotificationsEnabled,
              onChanged: (final bool value) => update(
                (final NotificationsSettings current) =>
                    current.copyWith(systemNotificationsEnabled: value),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsWorkflowAlerts,
              subtitle: context.l10n.settingsWorkflowAlertsDescription,
              value: settings.runCompletionAlerts,
              onChanged: (final bool value) => update(
                (final NotificationsSettings current) =>
                    current.copyWith(runCompletionAlerts: value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SettingsPrivacyPage extends ConsumerWidget {
  const SettingsPrivacyPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ErrorTrackingSettings settings = ref.watch(errorTrackingProvider);

    void update(
      final ErrorTrackingSettings Function(ErrorTrackingSettings) mutate,
    ) {
      unawaited(
        runSettingsUpdate(
          context,
          ref.read(errorTrackingProvider.notifier).update(mutate),
        ),
      );
    }

    return Column(
      key: const ValueKey<String>('settings-privacy-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.settingsPrivacy,
          description: context.l10n.settingsPrivacyDescription,
        ),
        Md3SettingsSection(
          title: context.l10n.settingsDiagnostics,
          description: context.l10n.settingsDiagnosticsDescription,
          children: <Widget>[
            SettingsSwitchRow(
              title: context.l10n.settingsCrashReports,
              subtitle: context.l10n.settingsCrashReportsDescription,
              value: settings.crashReports,
              onChanged: (final bool value) => update(
                (final ErrorTrackingSettings current) =>
                    current.copyWith(crashReports: value),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsHttpDiagnostics,
              subtitle: context.l10n.settingsHttpDiagnosticsDescription,
              value: settings.httpMetadata,
              enabled: settings.crashReports,
              onChanged: (final bool value) => update(
                (final ErrorTrackingSettings current) =>
                    current.copyWith(httpMetadata: value),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsNavigationDiagnostics,
              subtitle: context.l10n.settingsNavigationDiagnosticsDescription,
              value: settings.navigationTracking,
              enabled: settings.crashReports,
              onChanged: (final bool value) => update(
                (final ErrorTrackingSettings current) =>
                    current.copyWith(navigationTracking: value),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsPerformanceDiagnostics,
              subtitle: context.l10n.settingsPerformanceDiagnosticsDescription,
              value: settings.performanceTracing,
              enabled: settings.crashReports,
              onChanged: (final bool value) => update(
                (final ErrorTrackingSettings current) =>
                    current.copyWith(performanceTracing: value),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsSessionReplay,
              subtitle: context.l10n.settingsSessionReplayDescription,
              value: settings.sessionReplay,
              enabled: settings.crashReports,
              onChanged: (final bool value) => update(
                (final ErrorTrackingSettings current) =>
                    current.copyWith(sessionReplay: value),
              ),
            ),
          ],
        ),
        Text(
          context.l10n.settingsRestartRequired,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class SettingsAboutPage extends StatelessWidget {
  const SettingsAboutPage({super.key});

  @override
  Widget build(final BuildContext context) => Column(
    key: const ValueKey<String>('settings-about-page'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SettingsPageHeading(
        title: context.l10n.settingsAbout,
        description: context.l10n.settingsAboutDescription,
      ),
      Md3SettingsSection(
        title: context.l10n.settingsApplication,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: <Widget>[
                const AppLogoWidget(size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const AppNameWidget(size: 24),
                      const SizedBox(height: 4),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder:
                            (
                              final BuildContext context,
                              final AsyncSnapshot<PackageInfo> snapshot,
                            ) => Text(
                              snapshot.hasData
                                  ? context.l10n.settingsVersion(
                                      snapshot.data!.version,
                                      snapshot.data!.buildNumber,
                                    )
                                  : context.l10n.commonLoading,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SettingsActionRow(
            title: context.l10n.settingsWhatsNew,
            subtitle: context.l10n.settingsWhatsNewDescription,
            icon: Icons.new_releases_outlined,
            onPressed: () =>
                unawaited(context.router.push<void>(const ChangelogRoute())),
          ),
          SettingsActionRow(
            title: context.l10n.settingsOpenSourceLicenses,
            subtitle: context.l10n.settingsOpenSourceLicensesDescription,
            icon: Icons.description_outlined,
            onPressed: () => showLicensePage(
              context: context,
              applicationName: context.l10n.settingsApplicationName,
            ),
          ),
        ],
      ),
    ],
  );
}
