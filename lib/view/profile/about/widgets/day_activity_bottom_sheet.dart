import 'package:diohub_models/models/activity/activity_timeline_event.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub_models/models/activity/user_activity_timeline_data.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_activity_timeline_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet displaying activity for a specific day.
/// Callers must pass [scrollController] from [AppSheet.scrollable] and provide
/// a header (e.g. [AppSheetHeader.text] with trailing close button).
class DayActivityBottomSheet extends ConsumerWidget {
  const DayActivityBottomSheet({
    required this.userRef,
    required this.from,
    required this.to,
    required this.scrollController,
    super.key,
  });

  final UserRef userRef;
  final DateTime from;
  final DateTime to;
  final ScrollController scrollController;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final key = (userRef: userRef, from: from, to: to);
    final asyncData = ref.watch(dayActivityProvider(key));

    return asyncData.when(
      loading: () => const CenteredSpinner(),
      error: (final Object err, _) => Center(
        child: Padding(
          padding: context.spacing.spaciousPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              context.spacing.sectionGap,
              Text(
                'Failed to load activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              context.spacing.itemGap,
              Text(
                err.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (final UserActivityTimelineData data) {
        final List<ActivityTimelineEvent> events = data.events
            .where((final TimelineEventWithFlags e) => e.event != null)
            .map((final TimelineEventWithFlags e) => e.event!)
            .toList();

        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: context.spacing.spaciousPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  context.spacing.sectionGap,
                  Text(
                    'No activity for this day',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          controller: scrollController,
          padding: context.spacing.pagePadding,
          itemCount: events.length,
          separatorBuilder: (final _, final __) => context.spacing.contentGap,
          itemBuilder: (final BuildContext context, final int index) {
            final ActivityTimelineEvent event = events[index];
            return ActivityTimelineItem(
              event: event,
              userLogin: userRef.login,
              userAvatarUrl: null,
              isFirst: index == 0,
              isLast: index == events.length - 1,
            );
          },
        );
      },
    );
  }
}
