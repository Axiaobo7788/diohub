import 'package:diohub/graphql/__generated__/schema.schema.gql.dart' as _i2;
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/commits/commit_card_data_model.dart';
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:diohub/models/pull_requests/pull_request_card_data_model.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';

/// Timeline event types matching GitHub's contribution activity
enum ActivityEventType {
  commit,
  pullRequest,
  issue,
  repositoryCreated,
  review,
}


/// Wrapper class that holds event with timeline flags (avoids copying events)
class TimelineEventWithFlags {
  final ActivityTimelineEvent? event;
  final bool isFirst;
  final bool isLast;
  final bool isEmpty;
  // Only used for empty month placeholders
  final int? emptyYear;
  final int? emptyMonth;

  TimelineEventWithFlags({
    this.event,
    this.isFirst = false,
    this.isLast = false,
    this.isEmpty = false,
    this.emptyYear,
    this.emptyMonth,
  });
}

/// Represents a single activity event in the timeline
class ActivityTimelineEvent {
  final ActivityEventType type;
  final DateTime date;
  final String? title;
  final String? repositoryOwner;
  final String? repositoryName;
  final String? repositoryUrl;

  // Full GraphQL node data (preserves all fields from API)
  final GpullInfoTimeline? pullRequestNode;
  final GissueInfoTimeline? issueNode;
  final GrepositoryFields? repositoryNode;
  // For reviews, we store the pull request node from the review contribution
  final GpullInfoTimeline? reviewPullRequestNode;
  // For commits, we use commitData since it's aggregated from multiple repos

  // Unified data models for card widgets
  final IssueCardDataModel? issueData;
  final PullRequestCardDataModel? pullRequestData;
  final CommitCardDataModel? commitData;
  final RepoCardDataModel? repositoryData;

  ActivityTimelineEvent({
    required this.type,
    required this.date,
    this.title,
    this.repositoryOwner,
    this.repositoryName,
    this.repositoryUrl,
    this.pullRequestNode,
    this.issueNode,
    this.repositoryNode,
    this.reviewPullRequestNode,
    this.issueData,
    this.pullRequestData,
    this.commitData,
    this.repositoryData,
  });

  /// Get display title based on type and GraphQL data
  String get displayTitle {
    if (title != null) return title!;

    // Generate title based on type using GraphQL node data
    switch (type) {
      case ActivityEventType.commit:
        final count = commitData?.count ?? 1;
        final repoCount = commitData?.repositories.length ?? 1;
        if (repoCount > 1) {
          return 'Created $count commit${count > 1 ? 's' : ''} in $repoCount repositories';
        }
        return 'Created $count commit${count > 1 ? 's' : ''}';
      case ActivityEventType.pullRequest:
        if (pullRequestNode != null) {
          final action = pullRequestData?.action ?? 'opened';
          final number = pullRequestNode!.number;
          return '${_capitalize(action)} pull request #$number';
        }
        return 'Opened pull request';
      case ActivityEventType.issue:
        if (issueNode != null) {
          final action =
              issueNode!.state == _i2.GIssueState.CLOSED ? 'closed' : 'opened';
          final number = issueNode!.number;
          return '${_capitalize(action)} issue #$number';
        }
        return 'Opened issue';
      case ActivityEventType.repositoryCreated:
        return 'Created 1 repository';
      case ActivityEventType.review:
        if (pullRequestNode != null || reviewPullRequestNode != null) {
          final prNode = pullRequestNode ?? reviewPullRequestNode;
          final number = prNode?.number;
          if (number != null) {
            return 'Reviewed pull request #$number';
          }
        }
        return 'Reviewed pull request';
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Container for timeline data
///
/// Events are wrapped with flags (isFirst/isLast) for visual styling within each month.
/// Month headers are determined dynamically in the UI by comparing adjacent events.
class UserActivityTimelineData {
  final List<TimelineEventWithFlags> events;
  final DateTime from;
  final DateTime to;

  // Factory constructor that sets flags and handles empty months
  factory UserActivityTimelineData({
    required List<ActivityTimelineEvent> events,
    required DateTime from,
    required DateTime to,
  }) {
    final wrappedEvents = _wrapEventsWithFlags(events);
    final withEmptyMonths = _addEmptyMonthPlaceholders(
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

  /// Wrap events with flags (isFirst/isLast) for visual styling within each month
  static List<TimelineEventWithFlags> _wrapEventsWithFlags(
    List<ActivityTimelineEvent> events,
  ) {
    if (events.isEmpty) return [];

    final wrapped = <TimelineEventWithFlags>[];
    int? currentYear;
    int? currentMonth;
    int? firstEventInMonthIndex;

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final year = event.date.year;
      final month = event.date.month;

      // Check if we're starting a new month
      final isNewMonth = currentYear != year || currentMonth != month;

      if (isNewMonth) {
        // Mark previous month's last event
        if (firstEventInMonthIndex != null && wrapped.isNotEmpty) {
          final lastIndex = wrapped.length - 1;
          final lastWrapper = wrapped[lastIndex];
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
            isLast: false,
            isEmpty: false,
          ),
        );
      } else {
        // Same month - regular event
        wrapped.add(
          TimelineEventWithFlags(
            event: event,
            isFirst: false,
            isLast: false,
            isEmpty: false,
          ),
        );
      }
    }

    // Mark last event of last month as isLast
    if (wrapped.isNotEmpty) {
      final lastIndex = wrapped.length - 1;
      final lastWrapper = wrapped[lastIndex];
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
    List<TimelineEventWithFlags> events, {
    required DateTime from,
    required DateTime to,
    required bool hasEvents,
  }) {
    if (!hasEvents || events.isEmpty) {
      return events;
    }

    final result = <TimelineEventWithFlags>[];
    final allMonths = _generateMonthsInRange(from, to);
    var eventIndex = 0;

    for (final (year, month) in allMonths) {
      // Check if there are events in this month
      if (eventIndex < events.length) {
        final currentEvent = events[eventIndex].event;
        if (currentEvent != null &&
            currentEvent.date.year == year &&
            currentEvent.date.month == month) {
          // Add all events for this month
          while (eventIndex < events.length) {
            final event = events[eventIndex].event;
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
          event: null,
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
    DateTime from,
    DateTime to,
  ) {
    final months = <(int, int)>[];
    var current = DateTime(to.year, to.month, 1);
    final start = DateTime(from.year, from.month, 1);

    while (!current.isBefore(start)) {
      months.add((current.year, current.month));
      // Move to previous month
      if (current.month == 1) {
        current = DateTime(current.year - 1, 12, 1);
      } else {
        current = DateTime(current.year, current.month - 1, 1);
      }
    }

    return months;
  }
}
