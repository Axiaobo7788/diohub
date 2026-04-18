/// Settings UI for active watchers and recent alerts.
library;

import 'package:diohub/providers/watchers/watcher_manager_provider.dart';
import 'package:diohub/services/watchers/watcher_types.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Content for the watcher management screen or sheet.
class WatcherManagementContent extends ConsumerWidget {
  const WatcherManagementContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(watcherManagerProvider);
    final service = ref.read(watcherServiceProvider);

    return ListView(
      padding: EdgeInsets.only(
        top: context.spacing.pagePadding.top,
        bottom: context.spacing.pagePadding.bottom,
        left: 0,
        right: 0,
      ),
      children: <Widget>[
        Padding(
          padding: context.spacing.screenPadding,
          child: Text(
            'Active watchers',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        if (state.watchers.isEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: context.spacing.screenPadding.left,
              right: context.spacing.screenPadding.right,
              top: context.spacing.contentPadding.top,
              bottom: context.spacing.contentPadding.bottom,
            ),
            child: Text(
              'No watchers active. Enable inbox polling in notifications or add a run watcher from a workflow run screen.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ...state.watchers.map(
            (s) => _WatcherTile(
              status: s,
              onPause: () => service.toggleWatcher(
                s.watcher.watcherId,
                enabled: !s.watcher.enabled,
              ),
              onRemove: () => service.removeWatcher(s.watcher.watcherId),
              onCheckNow: () => service.checkNow(s.watcher.watcherId),
              isRunWatcher: s.isRunWatcher,
            ),
          ),
        context.spacing.spaciousGap,
        Padding(
          padding: context.spacing.screenPadding,
          child: Text(
            'Recent alerts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        if (state.recentAlerts.isEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: context.spacing.screenPadding.left,
              right: context.spacing.screenPadding.right,
              top: context.spacing.contentPadding.top,
              bottom: context.spacing.contentPadding.bottom,
            ),
            child: Text(
              'No recent alerts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ...state.recentAlerts.take(10).map(
                (a) => ListTile(
                  leading: Icon(
                    _iconForPriority(a.priority),
                    size: 22,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: a.body != null
                      ? Text(
                          a.body!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                ),
              ),
      ],
    );
  }

  static IconData _iconForPriority(AlertPriority p) => switch (p) {
        AlertPriority.high => Icons.priority_high_rounded,
        AlertPriority.low => Icons.info_outline_rounded,
        AlertPriority.normal => Icons.notifications_outlined,
      };
}

class _WatcherTile extends StatelessWidget {
  const _WatcherTile({
    required this.status,
    required this.onPause,
    required this.onRemove,
    required this.onCheckNow,
    required this.isRunWatcher,
  });

  final WatcherStatus status;
  final VoidCallback onPause;
  final VoidCallback onRemove;
  final VoidCallback onCheckNow;
  final bool isRunWatcher;

  @override
  Widget build(BuildContext context) {
    final w = status.watcher;
    final lastCheck = status.lastCheckTime != null
        ? DateFormat.yMd().add_Hm().format(status.lastCheckTime!)
        : null;

    return ListTile(
      leading: Icon(
        w.enabled
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(w.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Every ${_formatInterval(w.interval)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (lastCheck != null)
            Text(
              'Last checked: $lastCheck',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextButton(
            onPressed: onCheckNow,
            child: const Text('Check now'),
          ),
          if (isRunWatcher)
            TextButton(
              onPressed: onRemove,
              child: const Text('Remove'),
            )
          else
            TextButton(
              onPressed: onPause,
              child: Text(w.enabled ? 'Pause' : 'Resume'),
            ),
        ],
      ),
    );
  }

  static String _formatInterval(Duration d) {
    if (d.inMinutes >= 60) return '${d.inHours}h';
    if (d.inMinutes >= 1) return '${d.inMinutes}min';
    return '${d.inSeconds}s';
  }
}
