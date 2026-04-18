import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub_models/models/activity/user_activity_timeline_data.dart';
import 'package:diohub_models/models/activity_timeline_progress.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/services/users/user_activity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/stream_provider.dart';

/// Key for [dayActivityProvider].
typedef DayActivityKey = ({UserRef userRef, DateTime from, DateTime to});

/// Day-level activity timeline (single day range). Used by [DayActivityBottomSheet].
final dayActivityProvider =
    FutureProvider.autoDispose.family<UserActivityTimelineData, DayActivityKey>(
  (final Ref ref, final DayActivityKey key) =>
      ref.read(userActivityServiceProvider).getUserActivityTimeline(
            login: key.userRef.login,
            from: key.from,
            to: key.to,
          ),
);

/// Provider for fetching user activity timeline with progress updates.
/// Uses the same ContributionQueryKey as userContributionsProvider for consistency.
/// Emits ActivityTimelineState updates as data is being fetched.
/// Uses keepAliveFor to prevent refresh when widget comes back into view during scroll.
final userActivityTimelineProvider = StreamProvider.autoDispose
    .family<ActivityTimelineState, ContributionQueryKey>(
  (final Ref ref, final ContributionQueryKey key) {
    // Keep provider alive for 5 minutes to prevent refresh on scroll
    keepAliveFor(ref);

    final (DateTime from, DateTime to) = key.dateRange.dates;

    return ref
        .read(userActivityServiceProvider)
        .getUserActivityTimelineWithProgress(
          login: key.userName,
          from: from,
          to: to,
        );
  },
);
