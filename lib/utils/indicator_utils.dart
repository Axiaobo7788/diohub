// Pure utility functions for computing indicator data.
// No Flutter dependency — import only dart:core for testability.

import 'package:diohub_models/models/reviews/review_state.dart';

/// Urgency tier for time-to-resolution display.
enum TimeCategory {
  fast,
  normal,
  slow,
  stale,
}

/// Conversation activity level (comments per day).
enum ConversationHeat {
  cold,
  warm,
  hot,
}

/// Aggregated review states for the coverage bar.
class ReviewCoverageSummary {
  const ReviewCoverageSummary({
    required this.approved,
    required this.changesRequested,
    required this.pending,
  });

  final int approved;
  final int changesRequested;
  final int pending;

  int get total => approved + changesRequested + pending;
  bool get isEmpty => total == 0;
}

/// Categorizes a duration into urgency tiers.
///
/// - [TimeCategory.fast]: < 1 day (issues closed quickly)
/// - [TimeCategory.normal]: 1 day – 1 week
/// - [TimeCategory.slow]: 1 week – 1 month
/// - [TimeCategory.stale]: > 1 month
TimeCategory categorizeTime(final Duration duration) {
  if (duration.inDays < 1) {
    return TimeCategory.fast;
  }
  if (duration.inDays < 7) {
    return TimeCategory.normal;
  }
  if (duration.inDays < 30) {
    return TimeCategory.slow;
  }
  return TimeCategory.stale;
}

/// Computes conversation "heat" — how active the discussion is relative
/// to its age. A high comment-to-age ratio means a hot conversation.
///
/// - [ConversationHeat.cold]: < 0.5 comments/day on average
/// - [ConversationHeat.warm]: 0.5–3 comments/day
/// - [ConversationHeat.hot]: > 3 comments/day
///
/// Edge: 0 comments → cold; just-created (age < 0.01 days) → hot.
ConversationHeat computeHeat({
  required final int commentCount,
  required final DateTime createdAt,
  required final DateTime now,
}) {
  if (commentCount <= 0) {
    return ConversationHeat.cold;
  }
  final double ageDays = now.difference(createdAt).inHours / 24.0;
  if (ageDays < 0.01) {
    return ConversationHeat.hot;
  }
  final double rate = commentCount / ageDays;
  if (rate > 3) {
    return ConversationHeat.hot;
  }
  if (rate > 0.5) {
    return ConversationHeat.warm;
  }
  return ConversationHeat.cold;
}

/// Aggregates review states into a summary for the coverage bar.
ReviewCoverageSummary summarizeReviews(final List<String> reviewStates) {
  int approved = 0;
  int changesRequested = 0;
  int pending = 0;

  for (final String stateStr in reviewStates) {
    final state = ReviewState.fromString(stateStr);
    switch (state) {
      case ReviewState.approved:
        approved++;
        break;
      case ReviewState.changesRequested:
        changesRequested++;
        break;
      default:
        pending++;
    }
  }

  return ReviewCoverageSummary(
    approved: approved,
    changesRequested: changesRequested,
    pending: pending,
  );
}
