import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/pagination/pagination.dart';
import 'package:diohub_models/models/activity/activity_timeline_event.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/users/user_activity_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Section widget that displays user activity timeline grouped by month
/// Uses infinite pagination to load years on-demand
class ActivityTimelineSection extends ConsumerStatefulWidget {
  const ActivityTimelineSection({
    required this.providerKey,
    super.key,
  });

  final ContributionQueryKey providerKey;

  @override
  ConsumerState<ActivityTimelineSection> createState() =>
      _ActivityTimelineSectionState();
}

class _ActivityTimelineSectionState
    extends ConsumerState<ActivityTimelineSection> {
  late final PaginationController<TimelineEventWithFlags,
      TimelineEventWithFlags> _paginationController;

  @override
  void initState() {
    super.initState();
    _paginationController =
        PaginationController<TimelineEventWithFlags, TimelineEventWithFlags>(
      source: ref.read(userActivityTimelineSourceProvider(widget.providerKey)),
      idOf: (final TimelineEventWithFlags e) =>
          '${e.emptyYear ?? ''}_${e.emptyMonth ?? ''}_${identityHashCode(e)}',
      pageSize: 1,
    );
  }

  @override
  void dispose() {
    _paginationController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) =>
      PaginatedSliverList<TimelineEventWithFlags>(
        controller: _paginationController,
        itemBuilder: _buildTimelineItem,
        loadingBuilder: ListLoadingShimmers.timeline,
        emptyBuilder: _buildNoActivityMessage,
      );

  Widget _buildTimelineItem(
    final BuildContext context,
    final TimelineEventWithFlags eventWithFlags,
    final int index,
  ) {
    final List<TimelineEventWithFlags> items =
        _paginationController.state.value.items;
    final TimelineEventWithFlags? previousItem =
        index > 0 ? items[index - 1] : null;
    final TimelineEventWithFlags? nextItem =
        index < items.length - 1 ? items[index + 1] : null;
    final ActivityTimelineEvent? event = eventWithFlags.event;

    // Handle empty months
    if (eventWithFlags.isEmpty) {
      final int? year = eventWithFlags.emptyYear;
      final int? month = eventWithFlags.emptyMonth;
      if (year == null || month == null) {
        return const SizedBox.shrink();
      }

      // Check if next item exists and needs spacing
      final bool needsSpacing = nextItem != null;

      final Column item = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildMonthHeader(
            context,
            year,
            month,
            showNoActivity: true,
          ),
          if (needsSpacing) context.spacing.spaciousGap,
        ],
      );

      return item;
    }

    // At this point, event is guaranteed to be non-null
    final ActivityTimelineEvent nonNullEvent = event!;

    // Check if we need to show month header (month changed from previous event)
    final ActivityTimelineEvent? previousEvent = previousItem?.event;
    final bool showMonthHeader = index == 0 ||
        previousEvent == null ||
        nonNullEvent.date.year != previousEvent.date.year ||
        nonNullEvent.date.month != previousEvent.date.month;

    // Count events in this month from currently loaded items (may be partial with pagination)
    final int? eventCount = showMonthHeader
        ? items.where((e) {
            final ev = e.event;
            return ev != null &&
                ev.date.year == nonNullEvent.date.year &&
                ev.date.month == nonNullEvent.date.month;
          }).length
        : null;

    // Check if we need spacing after this event (between months)
    final ActivityTimelineEvent? nextEvent = nextItem?.event;
    final bool needsSpacing =
        nextEvent != null && _needsSpacingAfter(nonNullEvent, nextEvent);

    Widget item;

    if (showMonthHeader) {
      // Show month header + event
      item = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildMonthHeader(
            context,
            nonNullEvent.date.year,
            nonNullEvent.date.month,
            eventCount: eventCount,
          ),
          context.spacing.tightGap,
          ActivityTimelineItem(
            event: nonNullEvent,
            userLogin: widget.providerKey.userName,
            userAvatarUrl: null, // Avatar from userData when available
            isFirst: eventWithFlags.isFirst,
            isLast: eventWithFlags.isLast,
          ),
          if (needsSpacing) context.spacing.spaciousGap,
        ],
      );
    } else {
      // Regular event (same month as previous)
      item = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ActivityTimelineItem(
            event: nonNullEvent,
            userLogin: widget.providerKey.userName,
            userAvatarUrl: null, // Avatar from userData when available
            isFirst: eventWithFlags.isFirst,
            isLast: eventWithFlags.isLast,
          ),
          if (needsSpacing) context.spacing.spaciousGap,
        ],
      );
    }

    return item;
  }

  /// Check if we need spacing between this event and the next one
  bool _needsSpacingAfter(
    final ActivityTimelineEvent current,
    final ActivityTimelineEvent next,
  ) {
    // Need spacing if we're moving to a different month/year
    return current.date.year != next.date.year ||
        current.date.month != next.date.month;
  }

  /// Build message for when there are no events at all
  Widget _buildNoActivityMessage(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: 24, horizontal: context.spacing.sectionSpacing),
      child: Center(
        child: Text(
          'No activity',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.muted,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMonthHeader(
    final BuildContext context,
    final int year,
    final int month, {
    final bool showNoActivity = false,
    final int? eventCount,
  }) {
    final ThemeData theme = Theme.of(context);
    final List<String> monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    // Adjust padding based on whether there are events below
    final EdgeInsets padding = showNoActivity
        ? const EdgeInsets.only(top: 24, bottom: 8)
        : EdgeInsets.zero;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Text(
            '${monthNames[month - 1]} $year',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (showNoActivity) ...<Widget>[
            context.spacing.itemGap,
            Text(
              'No activity',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant.muted,
              ),
            ),
          ] else if (eventCount != null && eventCount > 0) ...<Widget>[
            context.spacing.itemGap,
            Text(
              eventCount == 1 ? '1 event' : '$eventCount events',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
