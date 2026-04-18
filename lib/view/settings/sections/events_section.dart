import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/common/misc/settings_toggle.dart';
import 'package:diohub/providers/settings/events_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Events section: combine related actions, timeline view.
class EventsSection extends ConsumerWidget {
  const EventsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);

    return SettingsGroup(
      children: [
        SettingsToggle(
          title: 'Combine related actions',
          value: events.compoundActions,
          onChanged: (bool v) => ref
              .read(eventsProvider.notifier)
              .update((s) => s.copyWith(compoundActions: v)),
          icon: Icons.merge_type,
          subtitle: 'Group related events on the same item',
        ),
        SettingsToggle(
          title: 'Timeline view for events',
          value: events.useTimelineView,
          onChanged: (bool v) => ref
              .read(eventsProvider.notifier)
              .update((s) => s.copyWith(useTimelineView: v)),
          icon: Icons.timeline,
          subtitle: 'Display events in a timeline format',
        ),
      ],
    );
  }
}
