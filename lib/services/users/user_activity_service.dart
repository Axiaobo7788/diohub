import 'package:diohub/app/api_handler/dio.dart' show GQLResponse;
import 'package:diohub_graphql/queries/users/user_activity_timeline_full.graphql.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub_models/models/activity_timeline_progress.dart';
import 'package:diohub_models/models/activity/activity_timeline_event.dart';
import 'package:diohub/utils/activity_timeline_converter.dart';
import 'package:diohub_models/models/activity/user_activity_timeline_data.dart';
import 'package:flutter/foundation.dart';
import 'package:lens_annotations/lens_annotations.dart';

@LensService(scope: Scope.global, group: 'user')
class UserActivityService extends BaseService {
  UserActivityService(super.apiClient);

  static const int _repoPageSize = 100;
  static const int _prPageSize = 100;
  static const int _issuePageSize = 100;
  static const int _reviewPageSize = 100;
  static const int _commitPageSize = 100;
  static const int _commitRepoMax = 100;

  /// Fetch a single time-bounded chunk (<=1 year) by paginating all
  /// contribution connections in contributionsCollection.
  ///
  /// [onProgress] is called after each pagination iteration with the number of
  /// items fetched so far and the total expected (from `totalCount`).
  Future<Query$userActivityTimelineFull$user> _fetchTimelineChunk({
    required final String login,
    required final DateTime from,
    required final DateTime to,
    @Skip() final bool refreshCache = false,
    final void Function(int fetched, int total)? onProgress,
  }) async {
    String? repoAfter;
    String? prAfter;
    String? issueAfter;
    String? reviewAfter;

    final List<
            Query$userActivityTimelineFull$user$contributionsCollection$repositoryContributions$nodes>
        repoNodes =
        <Query$userActivityTimelineFull$user$contributionsCollection$repositoryContributions$nodes>[];
    final List<
            Query$userActivityTimelineFull$user$contributionsCollection$pullRequestContributions$nodes>
        prNodes =
        <Query$userActivityTimelineFull$user$contributionsCollection$pullRequestContributions$nodes>[];
    final List<
            Query$userActivityTimelineFull$user$contributionsCollection$issueContributions$nodes>
        issueNodes =
        <Query$userActivityTimelineFull$user$contributionsCollection$issueContributions$nodes>[];
    final List<
            Query$userActivityTimelineFull$user$contributionsCollection$pullRequestReviewContributions$nodes>
        reviewNodes =
        <Query$userActivityTimelineFull$user$contributionsCollection$pullRequestReviewContributions$nodes>[];

    List<Query$userActivityTimelineFull$user$contributionsCollection$commitContributionsByRepository>?
        commitRepos;

    bool repoHasNext = true;
    bool prHasNext = true;
    bool issueHasNext = true;
    bool reviewHasNext = true;

    Query$userActivityTimelineFull$user? lastUser;
    int paginationIteration = 0;
    int? totalExpected;

    // Previous-iteration cursor snapshots for stuck-cursor detection.
    String? prevRepoAfter, prevPrAfter, prevIssueAfter, prevReviewAfter;

    while (true) {
      paginationIteration++;

      // Snapshot cursors and node count before this iteration.
      prevRepoAfter = repoAfter;
      prevPrAfter = prAfter;
      prevIssueAfter = issueAfter;
      prevReviewAfter = reviewAfter;
      final int prevTotal = repoNodes.length +
          prNodes.length +
          issueNodes.length +
          reviewNodes.length;

      final GQLResponse response = await gql.query(
        documentNodeQueryuserActivityTimelineFull,
        Variables$Query$userActivityTimelineFull(
          user: login,
          from: from,
          to: to,
          firstRepoContributions: repoHasNext ? _repoPageSize : 0,
          firstPullRequestContributions: prHasNext ? _prPageSize : 0,
          firstIssueContributions: issueHasNext ? _issuePageSize : 0,
          firstReviewContributions: reviewHasNext ? _reviewPageSize : 0,
          firstCommitContributions: _commitPageSize,
          maxCommitRepositories: _commitRepoMax,
          afterRepoContributions: repoAfter,
          afterPullRequestContributions: prAfter,
          afterIssueContributions: issueAfter,
          afterReviewContributions: reviewAfter,
        ).toJson(),
        refreshCache: refreshCache,
      );

      if (response.data == null) {
        throw Exception('Timeline query returned no data for user "$login"');
      }

      final Query$userActivityTimelineFull parsed =
          Query$userActivityTimelineFull.fromJson(response.data!);
      final Query$userActivityTimelineFull$user? user = parsed.user;
      if (user == null) {
        throw Exception('Timeline query returned invalid data for "$login"');
      }

      lastUser = user;
      final Query$userActivityTimelineFull$user$contributionsCollection cc =
          user.contributionsCollection;

      // Capture totalCount on first iteration for progress reporting.
      if (paginationIteration == 1) {
        totalExpected = cc.repositoryContributions.totalCount +
            cc.pullRequestContributions.totalCount +
            cc.issueContributions.totalCount +
            cc.pullRequestReviewContributions.totalCount;
      }

      final Query$userActivityTimelineFull$user$contributionsCollection$repositoryContributions
          repoConnection = cc.repositoryContributions;
      if (repoConnection.nodes != null) {
        final Iterable<
                Query$userActivityTimelineFull$user$contributionsCollection$repositoryContributions$nodes>
            newRepos = repoConnection.nodes!.whereType<
                Query$userActivityTimelineFull$user$contributionsCollection$repositoryContributions$nodes>();
        repoNodes.addAll(newRepos);
      }
      repoHasNext = repoConnection.pageInfo.hasNextPage;
      repoAfter = repoConnection.pageInfo.endCursor;

      final Query$userActivityTimelineFull$user$contributionsCollection$pullRequestContributions
          prConnection = cc.pullRequestContributions;
      if (prConnection.nodes != null) {
        final Iterable<
                Query$userActivityTimelineFull$user$contributionsCollection$pullRequestContributions$nodes>
            newPRs = prConnection.nodes!.whereType<
                Query$userActivityTimelineFull$user$contributionsCollection$pullRequestContributions$nodes>();
        prNodes.addAll(newPRs);
      }
      prHasNext = prConnection.pageInfo.hasNextPage;
      prAfter = prConnection.pageInfo.endCursor;

      final Query$userActivityTimelineFull$user$contributionsCollection$issueContributions
          issueConnection = cc.issueContributions;
      if (issueConnection.nodes != null) {
        final Iterable<
                Query$userActivityTimelineFull$user$contributionsCollection$issueContributions$nodes>
            newIssues = issueConnection.nodes!.whereType<
                Query$userActivityTimelineFull$user$contributionsCollection$issueContributions$nodes>();
        issueNodes.addAll(newIssues);
      }
      issueHasNext = issueConnection.pageInfo.hasNextPage;
      issueAfter = issueConnection.pageInfo.endCursor;

      final Query$userActivityTimelineFull$user$contributionsCollection$pullRequestReviewContributions
          reviewConnection = cc.pullRequestReviewContributions;
      if (reviewConnection.nodes != null) {
        final Iterable<
                Query$userActivityTimelineFull$user$contributionsCollection$pullRequestReviewContributions$nodes>
            newReviews = reviewConnection.nodes!.whereType<
                Query$userActivityTimelineFull$user$contributionsCollection$pullRequestReviewContributions$nodes>();
        reviewNodes.addAll(newReviews);
      }
      reviewHasNext = reviewConnection.pageInfo.hasNextPage;
      reviewAfter = reviewConnection.pageInfo.endCursor;

      commitRepos ??= cc.commitContributionsByRepository;

      // Log commit truncation in debug mode (only on first iteration).
      if (kDebugMode && paginationIteration == 1) {
        for (final Query$userActivityTimelineFull$user$contributionsCollection$commitContributionsByRepository repo
            in cc.commitContributionsByRepository) {
          if (repo.contributions.pageInfo.hasNextPage) {
            debugPrint(
              '[UserActivityService] WARNING: commit contributions for '
              '"${repo.repository}" truncated '
              '(hasNextPage=true). Consider paginating.',
            );
          }
        }
      }

      // Stuck-cursor detection: if no cursor advanced and no new nodes were
      // added, the API is not making progress — break to avoid infinite loop.
      final int currentTotal = repoNodes.length +
          prNodes.length +
          issueNodes.length +
          reviewNodes.length;
      final bool cursorsStuck = repoAfter == prevRepoAfter &&
          prAfter == prevPrAfter &&
          issueAfter == prevIssueAfter &&
          reviewAfter == prevReviewAfter;

      if (cursorsStuck && currentTotal == prevTotal) {
        if (kDebugMode) {
          debugPrint(
            '[UserActivityService] Pagination stuck: no cursor advanced and '
            'no new nodes after iteration $paginationIteration. Breaking.',
          );
        }
        break;
      }

      // Report progress via callback.
      if (onProgress != null && totalExpected != null) {
        onProgress(currentTotal, totalExpected);
      }

      final bool hasMore =
          repoHasNext || prHasNext || issueHasNext || reviewHasNext;
      if (!hasMore) break;
    }

    // Rebuild the response with all accumulated nodes across pages.
    return Query$userActivityTimelineFull$user(
      id: lastUser!.id,
      $__typename: lastUser.$__typename,
      contributionsCollection: Query$userActivityTimelineFull$user$contributionsCollection(
        $__typename: lastUser.contributionsCollection.$__typename,
        repositoryContributions: Query$userActivityTimelineFull$user$contributionsCollection$repositoryContributions(
          totalCount: lastUser.contributionsCollection.repositoryContributions.totalCount,
          nodes: repoNodes,
          pageInfo: Query$userActivityTimelineFull$user$contributionsCollection$repositoryContributions$pageInfo(
            hasNextPage: false,
            endCursor: repoAfter,
            $__typename: lastUser.contributionsCollection.repositoryContributions.pageInfo.$__typename,
          ),
          $__typename: lastUser.contributionsCollection.repositoryContributions.$__typename,
        ),
        pullRequestContributions: Query$userActivityTimelineFull$user$contributionsCollection$pullRequestContributions(
          totalCount: lastUser.contributionsCollection.pullRequestContributions.totalCount,
          nodes: prNodes,
          pageInfo: Query$userActivityTimelineFull$user$contributionsCollection$pullRequestContributions$pageInfo(
            hasNextPage: false,
            endCursor: prAfter,
            $__typename: lastUser.contributionsCollection.pullRequestContributions.pageInfo.$__typename,
          ),
          $__typename: lastUser.contributionsCollection.pullRequestContributions.$__typename,
        ),
        issueContributions: Query$userActivityTimelineFull$user$contributionsCollection$issueContributions(
          totalCount: lastUser.contributionsCollection.issueContributions.totalCount,
          nodes: issueNodes,
          pageInfo: Query$userActivityTimelineFull$user$contributionsCollection$issueContributions$pageInfo(
            hasNextPage: false,
            endCursor: issueAfter,
            $__typename: lastUser.contributionsCollection.issueContributions.pageInfo.$__typename,
          ),
          $__typename: lastUser.contributionsCollection.issueContributions.$__typename,
        ),
        pullRequestReviewContributions: Query$userActivityTimelineFull$user$contributionsCollection$pullRequestReviewContributions(
          totalCount: lastUser.contributionsCollection.pullRequestReviewContributions.totalCount,
          nodes: reviewNodes,
          pageInfo: Query$userActivityTimelineFull$user$contributionsCollection$pullRequestReviewContributions$pageInfo(
            hasNextPage: false,
            endCursor: reviewAfter,
            $__typename: lastUser.contributionsCollection.pullRequestReviewContributions.pageInfo.$__typename,
          ),
          $__typename: lastUser.contributionsCollection.pullRequestReviewContributions.$__typename,
        ),
        commitContributionsByRepository: commitRepos ?? [],
      ),
    );
  }

  Stream<ActivityTimelineState> getUserActivityTimelineWithProgress({
    required final String login,
    required final DateTime from,
    required final DateTime to,
    @Skip() final bool refreshCache = false,
  }) async* {
    try {
      final int daysDiff = to.difference(from).inDays;
      final bool exceedsOneYear = daysDiff > 365;
      if (!exceedsOneYear) {
        yield ActivityTimelineLoading(
          phase: 'loading',
          current: 0,
          total: 100,
          message: "Loading $login's activity...",
        );

        int lastFetched = 0;
        int lastTotal = 1;
        final Query$userActivityTimelineFull$user fullData =
            await _fetchTimelineChunk(
          login: login,
          from: from,
          to: to,
          refreshCache: refreshCache,
          onProgress: (final int fetched, final int total) {
            lastFetched = fetched;
            lastTotal = total;
          },
        );

        final List<ActivityTimelineEvent> events =
            ActivityTimelineConverter.convertToEvents(fullData);
        final int pct = lastTotal > 0
            ? (lastFetched / lastTotal * 90).round().clamp(0, 90)
            : 90;
        yield ActivityTimelineLoading(
          phase: 'loading',
          current: pct,
          total: 100,
          message: 'Almost ready...',
          eventCount: events.length,
        );

        final UserActivityTimelineData timelineData =
            _buildTimelineData(fullData, from, to);
        yield ActivityTimelineSuccess(timelineData);
        return;
      }

      // Multi-year path: Split into chunks
      final List<(DateTime, DateTime)> chunks =
          _splitDateRangeIntoYearChunks(from, to);
      final int totalSteps = chunks.length;
      final double progressPerStep = 90 / totalSteps;
      double currentProgress = 0;
      int totalEventCount = 0;
      yield ActivityTimelineLoading(
        phase: 'loading',
        current: 0,
        total: 100,
        message:
            "Loading ${chunks.length} year${chunks.length > 1 ? 's' : ''} of $login's activity...",
      );

      final List<List<ActivityTimelineEvent>> chunkEventLists =
          <List<ActivityTimelineEvent>>[];

      for (int i = 0; i < chunks.length; i++) {
        final (DateTime chunkFrom, DateTime chunkTo) = chunks[i];
        final String yearLabel = chunkFrom.year == chunkTo.year
            ? '${chunkFrom.year}'
            : '${chunkFrom.year}-${chunkTo.year}';

        yield ActivityTimelineLoading(
          phase: 'loading',
          current: currentProgress.round(),
          total: 100,
          message: 'Loading $yearLabel activity...',
          eventCount: totalEventCount,
        );

        try {
          final Query$userActivityTimelineFull$user fullData =
              await _fetchTimelineChunk(
            login: login,
            from: chunkFrom,
            to: chunkTo,
            refreshCache: refreshCache,
          );

          final List<ActivityTimelineEvent> events =
              ActivityTimelineConverter.convertToEvents(fullData);
          chunkEventLists.add(events);
          totalEventCount += events.length;
          currentProgress += progressPerStep;
        } catch (e) {
          yield ActivityTimelineError(
            message: 'Failed to load activity for $yearLabel',
            error: e,
          );
          return;
        }
      }

      yield ActivityTimelineLoading(
        phase: 'loading',
        current: 95,
        total: 100,
        message: 'Organizing your timeline...',
        eventCount: totalEventCount,
      );

      final List<ActivityTimelineEvent> allEvents = chunkEventLists.length == 1
          ? chunkEventLists.first
          : _mergeSortedChunks(chunkEventLists);
      final UserActivityTimelineData timelineData = UserActivityTimelineData(
        events: allEvents,
        from: from,
        to: to,
      );
      yield ActivityTimelineSuccess(timelineData);
    } catch (e, stackTrace) {
      yield ActivityTimelineError(
        message: 'Failed to fetch activity timeline for user "$login": $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @Lens(
    'get_user_activity_timeline',
    'Get comprehensive activity timeline for a user in date range. Handles multi-year ranges automatically.',
    category: ToolCategory.user,
  )
  Future<UserActivityTimelineData> getUserActivityTimeline({
    @Desc('GitHub username') required final String login,
    @Desc('Start date') required final DateTime from,
    @Desc('End date') required final DateTime to,
    @Desc('Force refresh cache') @Skip() final bool refreshCache = false,
  }) async {
    final int daysDiff = to.difference(from).inDays;
    final bool exceedsOneYear = daysDiff > 365;

    if (!exceedsOneYear) {
      final Query$userActivityTimelineFull$user fullData =
          await _fetchTimelineChunk(
        login: login,
        from: from,
        to: to,
        refreshCache: refreshCache,
      );
      final UserActivityTimelineData result =
          _buildTimelineData(fullData, from, to);
      return result;
    }

    final List<(DateTime, DateTime)> chunks =
        _splitDateRangeIntoYearChunks(from, to);
    final List<List<ActivityTimelineEvent>> chunkEventLists =
        <List<ActivityTimelineEvent>>[];
    for (final (DateTime chunkFrom, DateTime chunkTo) in chunks) {
      final Query$userActivityTimelineFull$user fullData =
          await _fetchTimelineChunk(
        login: login,
        from: chunkFrom,
        to: chunkTo,
        refreshCache: refreshCache,
      );
      final List<ActivityTimelineEvent> events =
          ActivityTimelineConverter.convertToEvents(fullData);
      chunkEventLists.add(events);
    }

    final List<ActivityTimelineEvent> allEvents = chunkEventLists.length == 1
        ? chunkEventLists.first
        : _mergeSortedChunks(chunkEventLists);
    return UserActivityTimelineData(
      events: allEvents,
      from: from,
      to: to,
    );
  }

  List<(DateTime, DateTime)> _splitDateRangeIntoYearChunks(
    final DateTime from,
    final DateTime to,
  ) {
    final List<(DateTime, DateTime)> chunks = <(DateTime, DateTime)>[];
    DateTime currentFrom = from;

    while (currentFrom.isBefore(to) ||
        (currentFrom.year == to.year &&
            currentFrom.month == to.month &&
            currentFrom.day == to.day)) {
      final DateTime oneYearLater = DateTime(
        currentFrom.year + 1,
        currentFrom.month,
        currentFrom.day,
      );

      DateTime chunkTo;
      if (oneYearLater.isAfter(to)) {
        chunkTo = to;
      } else {
        chunkTo = DateTime(
          currentFrom.year,
          12,
          31,
        );
      }

      chunks.add((currentFrom, chunkTo));
      if (chunkTo.year == to.year &&
          chunkTo.month == to.month &&
          chunkTo.day == to.day) {
        break;
      }

      currentFrom = chunkTo.add(const Duration(days: 1));

      if (chunks.length > 100) {
        throw Exception(
          'Date range splitting exceeded maximum chunks (100). Range: $from to $to',
        );
      }
    }
    return chunks;
  }

  List<ActivityTimelineEvent> _mergeSortedChunks(
    final List<List<ActivityTimelineEvent>> sortedChunks,
  ) {
    if (sortedChunks.isEmpty) {
      return <ActivityTimelineEvent>[];
    }
    if (sortedChunks.length == 1) {
      return sortedChunks.first;
    }

    if (kDebugMode) {
      final int totalEvents = sortedChunks.fold<int>(
          0,
          (final int sum, final List<ActivityTimelineEvent> chunk) =>
              sum + chunk.length);
    }

    final List<ActivityTimelineEvent> merged = <ActivityTimelineEvent>[];
    final List<Iterator<ActivityTimelineEvent>> iterators = sortedChunks
        .map((final List<ActivityTimelineEvent> chunk) => chunk.iterator)
        .toList();
    final List<ActivityTimelineEvent?> currentValues =
        <ActivityTimelineEvent?>[];

    for (final Iterator<ActivityTimelineEvent> iterator in iterators) {
      if (iterator.moveNext()) {
        currentValues.add(iterator.current);
      } else {
        currentValues.add(null);
      }
    }

    while (currentValues.any((final ActivityTimelineEvent? v) => v != null)) {
      ActivityTimelineEvent? newest;
      int newestIndex = -1;

      for (int i = 0; i < currentValues.length; i++) {
        final ActivityTimelineEvent? value = currentValues[i];
        if (value != null) {
          if (newest == null || value.date.isAfter(newest.date)) {
            newest = value;
            newestIndex = i;
          }
        }
      }

      if (newest != null && newestIndex >= 0) {
        merged.add(newest);
        if (iterators[newestIndex].moveNext()) {
          currentValues[newestIndex] = iterators[newestIndex].current;
        } else {
          currentValues[newestIndex] = null;
        }
      }
    }
    return merged;
  }

  UserActivityTimelineData _buildTimelineData(
    final Query$userActivityTimelineFull$user fullData,
    final DateTime from,
    final DateTime to,
  ) {
    final List<ActivityTimelineEvent> events =
        ActivityTimelineConverter.convertToEvents(fullData);
    return UserActivityTimelineData(
      events: events,
      from: from,
      to: to,
    );
  }

  /// Get the year for a given page number (0-indexed, newest first)
  /// Pages are ordered from newest year to oldest year
  int getYearForPage(
      final DateTime from, final DateTime to, final int pageNumber) {
    final List<int> years = <int>[];

    // Start from the end year and work backwards
    int currentYear = to.year;
    final int startYear = from.year;

    // Collect all years in the range (newest first)
    while (currentYear >= startYear) {
      years.add(currentYear);
      currentYear--;
    }

    if (pageNumber < 0 || pageNumber >= years.length) {
      throw Exception(
        'Page $pageNumber out of range. Available years: ${years.length} (${years.firstOrNull ?? 'none'} to ${years.lastOrNull ?? 'none'})',
      );
    }

    return years[pageNumber];
  }

  @Lens(
    'get_year_activity_events',
    'Get activity events for a specific year within a date range. Used for infinite pagination.',
    category: ToolCategory.user,
  )
  Future<List<TimelineEventWithFlags>> getYearEvents({
    @Desc('GitHub username') required final String login,
    @Desc('Year for activity') required final int year,
    @Desc('Start date') required final DateTime from,
    @Desc('End date') required final DateTime to,
    @Desc('Force refresh cache') @Skip() final bool refreshCache = false,
  }) async {
    // Calculate year boundaries
    final DateTime yearStart = DateTime(year);
    final DateTime yearEnd = DateTime(year, 12, 31);

    // Clamp to actual date range
    final DateTime chunkFrom = yearStart.isBefore(from) ? from : yearStart;
    final DateTime chunkTo = yearEnd.isAfter(to) ? to : yearEnd;
    final Query$userActivityTimelineFull$user fullData =
        await _fetchTimelineChunk(
      login: login,
      from: chunkFrom,
      to: chunkTo,
      refreshCache: refreshCache,
    );

    final List<ActivityTimelineEvent> events =
        ActivityTimelineConverter.convertToEvents(fullData);
    final UserActivityTimelineData timelineData = UserActivityTimelineData(
      events: events,
      from: chunkFrom,
      to: chunkTo,
    );
    return timelineData.events;
  }
}
