import 'package:diohub_models/models/activity/activity_timeline_event.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/services/users/user_activity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page source for activity timeline by year (newest first).
/// Used by [ActivityTimelineSection] so the view does not import [UserActivityService].
final userActivityTimelineSourceProvider = Provider.family<
    PageNumberForwardSource<TimelineEventWithFlags>,
    ContributionQueryKey>((ref, key) {
  final (DateTime from, DateTime to) = key.dateRange.dates;
  final service = ref.read(userActivityServiceProvider);
  return PageNumberForwardSource<TimelineEventWithFlags>(
    fetch: ({required int page, required int perPage}) async {
      final int year = service.getYearForPage(from, to, page - 1);
      return service.getYearEvents(
        login: key.userName,
        year: year,
        from: from,
        to: to,
        refreshCache: false,
      );
    },
    startPage: 1,
  );
});
