import 'package:diohub/app/global.dart';
import 'package:diohub/common/timeline/timeline_shimmer_item.dart';
import 'package:diohub/common/wrappers/infinite_pagination.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/services/users/user_activity_service.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_item.dart';
import 'package:flutter/foundation.dart';
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
  late final InfinitePaginationController<TimelineEventWithFlags>
      _paginationController;

  @override
  void initState() {
    super.initState();
    final (from, to) = widget.providerKey.dateRange.dates;

    _paginationController =
        InfinitePaginationController<TimelineEventWithFlags>(
      future: (final ScrollWrapperFutureArguments<TimelineEventWithFlags>
          args) async {
        try {
          // Calculate which year to fetch based on page number (0-indexed)
          final year = UserActivityService.getYearForPage(
            from,
            to,
            args.pageNumber -
                1, // pageNumber starts at 1, but getYearForPage expects 0-indexed
          );          final events = await UserActivityService.getYearEvents(
            login: widget.providerKey.userName,
            year: year,
            from: from,
            to: to,
            refreshCache: args.refresh,
          );

          return events;
        } catch (e, stackTrace) {          rethrow;
        }
      },
      builder: _buildTimelineItem,
      pageNumber: 1,
      pageSize: 1, // 1 year per page
      paddingBuilder: (final BuildContext context) =>
          const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      firstPageLoadingBuilder: (final BuildContext context) =>
          const TimelineShimmerList(
        itemCount: 5,
        showAvatar: false,
        padding: EdgeInsets.zero,
      ),
      emptyBuilder: (final BuildContext context) =>
          _buildNoActivityMessage(context),
      enableStaggeredAnimation: true,
    );
  }

  @override
  void dispose() {
    _paginationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _paginationController.buildSliverList(context);
  }

  Widget _buildTimelineItem(
    final BuildContext context,
    final ScrollWrapperBuilderData<TimelineEventWithFlags> data,
  ) {
    final eventWithFlags = data.item;
    final event = eventWithFlags.event;

    // Handle empty months
    if (eventWithFlags.isEmpty) {
      final year = eventWithFlags.emptyYear;
      final month = eventWithFlags.emptyMonth;
      if (year == null || month == null) {
        return const SizedBox.shrink();
      }

      // Check if next item exists and needs spacing
      final needsSpacing = data.nextItem != null;

      final item = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthHeader(
            context,
            year,
            month,
            showNoActivity: true,
          ),
          if (needsSpacing) const SizedBox(height: 24),
        ],
      );

      return item;
    }

    // At this point, event is guaranteed to be non-null
    final nonNullEvent = event!;

    // Check if we need to show month header (month changed from previous event)
    final previousEvent = data.previousItem?.event;
    final showMonthHeader = data.index == 0 ||
        previousEvent == null ||
        nonNullEvent.date.year != previousEvent.date.year ||
        nonNullEvent.date.month != previousEvent.date.month;

    // For event count, we'll skip it for now since we don't have access to all items
    // This is a minor trade-off for infinite pagination
    final eventCount = showMonthHeader ? null : null;

    // Check if we need spacing after this event (between months)
    final nextEvent = data.nextItem?.event;
    final needsSpacing =
        nextEvent != null && _needsSpacingAfter(nonNullEvent, nextEvent);

    Widget item;

    if (showMonthHeader) {
      // Show month header + event
      item = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthHeader(
            context,
            nonNullEvent.date.year,
            nonNullEvent.date.month,
            eventCount: eventCount,
          ),
          const SizedBox(height: 4),
          ActivityTimelineItem(
            event: nonNullEvent,
            userLogin: widget.providerKey.userName,
            userAvatarUrl: null, // TODO: Get from userData if available
            isFirst: eventWithFlags.isFirst,
            isLast: eventWithFlags.isLast,
          ),
          if (needsSpacing) const SizedBox(height: 24),
        ],
      );
    } else {
      // Regular event (same month as previous)
      item = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActivityTimelineItem(
            event: nonNullEvent,
            userLogin: widget.providerKey.userName,
            userAvatarUrl: null, // TODO: Get from userData if available
            isFirst: eventWithFlags.isFirst,
            isLast: eventWithFlags.isLast,
          ),
          if (needsSpacing) const SizedBox(height: 24),
        ],
      );
    }

    return item;
  }

  /// Check if we need spacing between this event and the next one
  bool _needsSpacingAfter(
    ActivityTimelineEvent current,
    ActivityTimelineEvent next,
  ) {
    // Need spacing if we're moving to a different month/year
    return current.date.year != next.date.year ||
        current.date.month != next.date.month;
  }

  /// Build message for when there are no events at all
  Widget _buildNoActivityMessage(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Text(
          'No activity',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMonthHeader(
    BuildContext context,
    int year,
    int month, {
    bool showNoActivity = false,
    int? eventCount,
  }) {
    final theme = Theme.of(context);
    final monthNames = [
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
    final padding = showNoActivity
        ? const EdgeInsets.only(top: 24, bottom: 8)
        : EdgeInsets.zero;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '${monthNames[month - 1]} $year',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (showNoActivity) ...[
            const SizedBox(width: 8),
            Text(
              'No activity',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ] else if (eventCount != null && eventCount > 0) ...[
            const SizedBox(width: 8),
            Text(
              eventCount == 1 ? '1 event' : '$eventCount events',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
