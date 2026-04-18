import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/common/misc/settings_slider.dart';
import 'package:diohub/common/misc/settings_toggle.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/settings/tab_behavior_provider.dart';
import 'package:diohub/providers/settings/terminal_settings_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Integrations section: SSH connections, cloud sync, terminal settings, reset pinned tabs.
class IntegrationsSection extends ConsumerWidget {
  const IntegrationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsGroup(
      children: [
        SettingsToggle(
          title: 'Auto-scroll live logs',
          value: ref.watch(terminalSettingsProvider).logAutoScroll,
          onChanged: (bool v) =>
              ref.read(terminalSettingsProvider.notifier).setLogAutoScroll(v),
          icon: Icons.vertical_align_bottom,
          subtitle: 'Automatically scroll to bottom when new log lines arrive',
        ),
        SettingsSlider(
          title: 'Log polling interval',
          value: ref
              .watch(terminalSettingsProvider)
              .logPollingIntervalSeconds
              .toDouble(),
          min: 2,
          max: 30,
          divisions: 14,
          onChanged: (double v) => ref
              .read(terminalSettingsProvider.notifier)
              .setLogPollingIntervalSeconds(v.toInt()),
          icon: Icons.timer,
          subtitle: 'How often to fetch new log lines during live tailing',
          labelBuilder: (double v) => '${v.toInt()}s',
        ),
        ListTile(
          leading: Icon(
            Icons.terminal_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: const Text('SSH Connections'),
          subtitle: const Text(
            'Manage saved SSH connections and connect to servers',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.router.push(const SSHConnectionsRoute()),
        ),
        // TODO: Cloud Sync screen not implemented yet
        // ListTile(
        //   leading: Icon(
        //     Icons.cloud_sync_rounded,
        //     color: Theme.of(context).colorScheme.onSurfaceVariant,
        //   ),
        //   title: const Text('Cloud Sync'),
        //   subtitle: const Text(
        //     'Back up and sync settings and data across devices',
        //   ),
        //   trailing: const Icon(Icons.chevron_right),
        //   onTap: () => context.router.push(const CloudSyncRoute()),
        // ),
        Padding(
          padding: context.spacing.cardContentPadding,
          child: Row(
            children: [
              Icon(
                Icons.push_pin_outlined,
                size: 22,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: context.spacing.compactSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Reset pinned tabs',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    SizedBox(height: context.spacing.tightSpacing),
                    Text(
                      'Clear all pinned tab labels and collapsed section overrides',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(tabBehaviorProvider.notifier).reset();
                  if (context.mounted) {
                    ref.read(notificationServiceProvider).success(
                          'Pinned tabs and overrides reset',
                        );
                  }
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
