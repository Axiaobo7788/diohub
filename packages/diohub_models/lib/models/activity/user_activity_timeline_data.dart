import 'package:diohub_models/models/activity/activity_timeline_event.dart';

/// Container for timeline data
///
/// Events are wrapped with flags (isFirst/isLast) for visual styling within each month.
/// Month headers are determined dynamically in the UI by comparing adjacent events.
class UserActivityTimelineData {
  // Factory constructor that sets flags and handles empty months
  factory UserActivityTimelineData({
    required final List<ActivityTimelineEvent> events,
    required final DateTime from,
    required final DateTime to,
  }) {
    final List<TimelineEventWithFlags> wrappedEvents =
        _wrapEventsWithFlags(events);
    final List<TimelineEventWithFlags> withEmptyMonths =
        _addEmptyMonthPlaceholders(
      wrappedEvents,
      from: from,
      to: to,
      hasEvents: events.isNotEmpty,
    );
    return UserActivityTimelineData._(
      events: withEmptyMonths,
      from: from,
      to: to,
    );
  }

  UserActivityTimelineData._({
    required this.events,
    required this.from,
    required this.to,
  });
  final List<TimelineEventWithFlags> events;
  final DateTime from;
  final DateTime to;

  /// Wrap events with flags (isFirst/isLast) for visual styling within each month
  static List<TimelineEventWithFlags> _wrapEventsWithFlags(
    final List<ActivityTimelineEvent> events,
  ) {
    if (events.isEmpty) return <TimelineEventWithFlags>[];

    final List<TimelineEventWithFlags> wrapped = <TimelineEventWithFlags>[];
    int? currentYear;
    int? currentMonth;
    int? firstEventInMonthIndex;

    for (int i = 0; i < events.length; i++) {
      final ActivityTimelineEvent event = events[i];
      final int year = event.date.year;
      final int month = event.date.month;

      // Check if we're starting a new month
      final bool isNewMonth = currentYear != year || currentMonth != month;

      if (isNewMonth) {
        // Mark previous month's last event
        if (firstEventInMonthIndex != null && wrapped.isNotEmpty) {
          final int lastIndex = wrapped.length - 1;
          final TimelineEventWithFlags lastWrapper = wrapped[lastIndex];
          wrapped[lastIndex] = TimelineEventWithFlags(
            event: lastWrapper.event,
            isFirst: lastWrapper.isFirst,
            isLast: true,
            isEmpty: lastWrapper.isEmpty,
          );
        }

        // Start new month
        currentYear = year;
        currentMonth = month;
        firstEventInMonthIndex = wrapped.length;

        wrapped.add(
          TimelineEventWithFlags(
            event: event,
            isFirst: true,
          ),
        );
      } else {
        // Same month - regular event
        wrapped.add(
          TimelineEventWithFlags(
            event: event,
          ),
        );
      }
    }

    // Mark last event of last month as isLast
    if (wrapped.isNotEmpty) {
      final int lastIndex = wrapped.length - 1;
      final TimelineEventWithFlags lastWrapper = wrapped[lastIndex];
      wrapped[lastIndex] = TimelineEventWithFlags(
        event: lastWrapper.event,
        isFirst: lastWrapper.isFirst,
        isLast: true,
        isEmpty: lastWrapper.isEmpty,
      );
    }

    return wrapped;
  }

  /// Add empty month placeholders between events
  static List<TimelineEventWithFlags> _addEmptyMonthPlaceholders(
    final List<TimelineEventWithFlags> events, {
    required final DateTime from,
    required final DateTime to,
    required final bool hasEvents,
  }) {
    if (!hasEvents || events.isEmpty) {
      return events;
    }

    final List<TimelineEventWithFlags> result = <TimelineEventWithFlags>[];
    final List<(int, int)> allMonths = _generateMonthsInRange(from, to);
    int eventIndex = 0;

    for (final (int year, int month) in allMonths) {
      // Check if there are events in this month
      if (eventIndex < events.length) {
        final ActivityTimelineEvent? currentEvent = events[eventIndex].event;
        if (currentEvent != null &&
            currentEvent.date.year == year &&
            currentEvent.date.month == month) {
          // Add all events for this month
          while (eventIndex < events.length) {
            final ActivityTimelineEvent? event = events[eventIndex].event;
            if (event == null ||
                event.date.year != year ||
                event.date.month != month) {
              break;
            }
            result.add(events[eventIndex]);
            eventIndex++;
          }
          continue;
        }
      }

      // No events in this month - add placeholder
      result.add(
        TimelineEventWithFlags(
          isFirst: true,
          isLast: true,
          isEmpty: true,
          emptyYear: year,
          emptyMonth: month,
        ),
      );
    }

    return result;
  }

  /// Generate all (year, month) pairs in the date range (newest first)
  static List<(int year, int month)> _generateMonthsInRange(
    final DateTime from,
    final DateTime to,
  ) {
    final List<(int, int)> months = <(int, int)>[];
    DateTime current = DateTime(to.year, to.month);
    final DateTime start = DateTime(from.year, from.month);

    while (!current.isBefore(start)) {
      months.add((current.year, current.month));
      // Move to previous month
      if (current.month == 1) {
        current = DateTime(current.year - 1, 12);
      } else {
        current = DateTime(current.year, current.month - 1);
      }
    }

    return months;
  }
}
