import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/common/misc/settings_slider.dart';
import 'package:diohub/common/misc/settings_toggle.dart';
import 'package:diohub/providers/settings/notifications_provider.dart';
import 'package:diohub/view/settings/sections/watcher_management_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifications section: auto-mark read, group by repo, inbox polling, system notifications, workflow alerts, watchers.
class NotificationsSection extends ConsumerWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return SettingsGroup(
      children: [
        SettingsToggle(
          title: 'Auto-mark as read',
          value: notifications.autoMarkRead,
          onChanged: (bool v) => ref
              .read(notificationsProvider.notifier)
              .update((s) => s.copyWith(autoMarkRead: v)),
          icon: Icons.done_all,
          subtitle: 'Mark notifications as read when they scroll into view',
        ),
        SettingsToggle(
          title: 'Group by repository',
          value: notifications.groupByRepo,
          onChanged: (bool v) => ref
              .read(notificationsProvider.notifier)
              .update((s) => s.copyWith(groupByRepo: v)),
          icon: Icons.folder,
          subtitle: 'Show notifications grouped by repo with section headers',
        ),
        SettingsToggle(
          title: 'Inbox polling',
          value: notifications.inboxPollingEnabled,
          onChanged: (bool v) => ref
              .read(notificationsProvider.notifier)
              .updateInboxPollingEnabled(v),
          icon: Icons.inbox,
          subtitle: 'Check for new notifications in the background',
        ),
        if (notifications.inboxPollingEnabled)
          SettingsSlider(
            title: 'Polling interval',
            value: notifications.inboxPollingIntervalMinutes.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            onChanged: (double v) => ref
                .read(notificationsProvider.notifier)
                .updateInboxPollingInterval(v.toInt()),
            icon: Icons.timer_outlined,
            subtitle: 'Minutes between background inbox checks',
            labelBuilder: (double v) => '${v.toInt()} min',
          ),
        SettingsToggle(
          title: 'System notifications',
          value: notifications.systemNotificationsEnabled,
          onChanged: (bool v) => ref
              .read(notificationsProvider.notifier)
              .update((s) => s.copyWith(systemNotificationsEnabled: v)),
          icon: Icons.notifications,
          subtitle: 'Show OS notifications when app is in background',
        ),
        SettingsToggle(
          title: 'Workflow run alerts',
          value: notifications.runCompletionAlerts,
          onChanged: (bool v) => ref
              .read(notificationsProvider.notifier)
              .update((s) => s.copyWith(runCompletionAlerts: v)),
          icon: Icons.play_circle_outline,
          subtitle: 'Notify when watched workflow runs complete',
        ),
        ListTile(
          leading: Icon(
            Icons.notifications_active_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: const Text('Active watchers'),
          subtitle: const Text(
            'Inbox polling, workflow run alerts, and recent notifications',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Watchers')),
                body: const WatcherManagementContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
