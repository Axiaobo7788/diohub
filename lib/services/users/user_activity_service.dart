// ignore_for_file: avoid_classes_with_only_static_members

import 'package:built_collection/built_collection.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.req.gql.dart';
import 'package:diohub/models/activity_timeline_progress.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_converter.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';
import 'package:flutter/foundation.dart';

class UserActivityService {
  static const int _repoPageSize = 100;
  static const int _prPageSize = 100;
  static const int _issuePageSize = 100;
  static const int _reviewPageSize = 100;
  static const int _commitPageSize = 100;
  static const int _commitRepoMax = 100;

  static final GraphqlHandler _gqlHandler = GraphqlHandler();

  /// Fetch a single time-bounded chunk (<=1 year) by paginating all
  /// contribution connections in contributionsCollection.
  static Future<GuserActivityTimelineFullData_user> _fetchTimelineChunk({
    required String login,
    required DateTime from,
    required DateTime to,
    bool refreshCache = false,
  }) async {
    if (kDebugMode) {
      log.d(
          '[UserActivityService] _fetchTimelineChunk: Starting for user "$login" from ${from.toIso8601String()} to ${to.toIso8601String()}, refreshCache: $refreshCache');
    }

    String? repoAfter;
    String? prAfter;
    String? issueAfter;
    String? reviewAfter;

    final repoNodes =
        <GuserActivityTimelineFullData_user_contributionsCollection_repositoryContributions_nodes>[];
    final prNodes =
        <GuserActivityTimelineFullData_user_contributionsCollection_pullRequestContributions_nodes>[];
    final issueNodes =
        <GuserActivityTimelineFullData_user_contributionsCollection_issueContributions_nodes>[];
    final reviewNodes =
        <GuserActivityTimelineFullData_user_contributionsCollection_pullRequestReviewContributions_nodes>[];

    BuiltList<
            GuserActivityTimelineFullData_user_contributionsCollection_commitContributionsByRepository>?
        commitRepos;

    var repoHasNext = true;
    var prHasNext = true;
    var issueHasNext = true;
    var reviewHasNext = true;

    GuserActivityTimelineFullData_user? lastUser;
    var paginationIteration = 0;

    while (true) {
      paginationIteration++;
      if (kDebugMode) {
        log.d(
            '[UserActivityService] _fetchTimelineChunk: Pagination iteration $paginationIteration for "$login"');
      }
      final response = await _gqlHandler.query(
        GuserActivityTimelineFullReq(
          (b) => b
            ..vars.user = login
            ..vars.from = from
            ..vars.to = to
            ..vars.firstRepoContributions = _repoPageSize
            ..vars.firstPullRequestContributions = _prPageSize
            ..vars.firstIssueContributions = _issuePageSize
            ..vars.firstReviewContributions = _reviewPageSize
            ..vars.firstCommitContributions = _commitPageSize
            ..vars.maxCommitRepositories = _commitRepoMax
            ..vars.afterRepoContributions = repoAfter
            ..vars.afterPullRequestContributions = prAfter
            ..vars.afterIssueContributions = issueAfter
            ..vars.afterReviewContributions = reviewAfter,
        ),
        refreshCache: refreshCache,
      );

      if (response.data == null) {
        throw Exception('Timeline query returned no data for user "$login"');
      }

      final parsed = GuserActivityTimelineFullData.fromJson(response.data!);
      final user = parsed?.user;
      if (user == null) {
        throw Exception('Timeline query returned invalid data for "$login"');
      }

      lastUser = user;
      final cc = user.contributionsCollection;

      final repoConnection = cc.repositoryContributions;
      if (repoConnection.nodes != null) {
        final newRepos = repoConnection.nodes!.whereType<
            GuserActivityTimelineFullData_user_contributionsCollection_repositoryContributions_nodes>();
        repoNodes.addAll(newRepos);
        if (kDebugMode) {
          log.d(
              '[UserActivityService] _fetchTimelineChunk: Added ${newRepos.length} repository contributions (total: ${repoNodes.length})');
        }
      }
      repoHasNext = repoConnection.pageInfo.hasNextPage;
      repoAfter = repoConnection.pageInfo.endCursor;

      final prConnection = cc.pullRequestContributions;
      if (prConnection.nodes != null) {
        final newPRs = prConnection.nodes!.whereType<
            GuserActivityTimelineFullData_user_contributionsCollection_pullRequestContributions_nodes>();
        prNodes.addAll(newPRs);
        if (kDebugMode) {
          log.d(
              '[UserActivityService] _fetchTimelineChunk: Added ${newPRs.length} PR contributions (total: ${prNodes.length})');
        }
      }
      prHasNext = prConnection.pageInfo.hasNextPage;
      prAfter = prConnection.pageInfo.endCursor;

      final issueConnection = cc.issueContributions;
      if (issueConnection.nodes != null) {
        final newIssues = issueConnection.nodes!.whereType<
            GuserActivityTimelineFullData_user_contributionsCollection_issueContributions_nodes>();
        issueNodes.addAll(newIssues);
        if (kDebugMode) {
          log.d(
              '[UserActivityService] _fetchTimelineChunk: Added ${newIssues.length} issue contributions (total: ${issueNodes.length})');
        }
      }
      issueHasNext = issueConnection.pageInfo.hasNextPage;
      issueAfter = issueConnection.pageInfo.endCursor;

      final reviewConnection = cc.pullRequestReviewContributions;
      if (reviewConnection.nodes != null) {
        final newReviews = reviewConnection.nodes!.whereType<
            GuserActivityTimelineFullData_user_contributionsCollection_pullRequestReviewContributions_nodes>();
        reviewNodes.addAll(newReviews);
        if (kDebugMode) {
          log.d(
              '[UserActivityService] _fetchTimelineChunk: Added ${newReviews.length} review contributions (total: ${reviewNodes.length})');
        }
      }
      reviewHasNext = reviewConnection.pageInfo.hasNextPage;
      reviewAfter = reviewConnection.pageInfo.endCursor;

      commitRepos ??= cc.commitContributionsByRepository;
      if (kDebugMode) {
        log.d(
            '[UserActivityService] _fetchTimelineChunk: Found ${commitRepos.length} commit repositories');
      }

      final hasMore = repoHasNext || prHasNext || issueHasNext || reviewHasNext;
      if (!hasMore) {
        if (kDebugMode) {
          log.d(
              '[UserActivityService] _fetchTimelineChunk: Completed pagination for "$login" after $paginationIteration iterations. Collected: ${repoNodes.length} repos, ${prNodes.length} PRs, ${issueNodes.length} issues, ${reviewNodes.length} reviews');
        }
        return lastUser.rebuild((b) {
          b.contributionsCollection.update((ccBuilder) {
            ccBuilder.repositoryContributions.update((rcBuilder) {
              rcBuilder.nodes.replace(repoNodes);
              rcBuilder.pageInfo.update((pi) {
                pi.hasNextPage = false;
                pi.endCursor = repoAfter;
              });
            });

            ccBuilder.pullRequestContributions.update((pcBuilder) {
              pcBuilder.nodes.replace(prNodes);
              pcBuilder.pageInfo.update((pi) {
                pi.hasNextPage = false;
                pi.endCursor = prAfter;
              });
            });

            ccBuilder.issueContributions.update((icBuilder) {
              icBuilder.nodes.replace(issueNodes);
              icBuilder.pageInfo.update((pi) {
                pi.hasNextPage = false;
                pi.endCursor = issueAfter;
              });
            });

            ccBuilder.pullRequestReviewContributions.update((rcBuilder) {
              rcBuilder.nodes.replace(reviewNodes);
              rcBuilder.pageInfo.update((pi) {
                pi.hasNextPage = false;
                pi.endCursor = reviewAfter;
              });
            });

            if (commitRepos != null) {
              ccBuilder.commitContributionsByRepository.replace(commitRepos);
            }
          });
        });
      }
    }
  }

  static Stream<ActivityTimelineState> getUserActivityTimelineWithProgress({
    required String login,
    required DateTime from,
    required DateTime to,
    bool refreshCache = false,
  }) async* {
    if (kDebugMode) {
      log.d(
          '[UserActivityService] getUserActivityTimelineWithProgress: Starting for user "$login" from ${from.toIso8601String()} to ${to.toIso8601String()}, refreshCache: $refreshCache');
    }
    try {
      final daysDiff = to.difference(from).inDays;
      final exceedsOneYear = daysDiff > 365;
      if (kDebugMode) {
        log.d(
            '[UserActivityService] getUserActivityTimelineWithProgress: Date range is $daysDiff days, exceedsOneYear: $exceedsOneYear');
      }

      if (!exceedsOneYear) {
        yield ActivityTimelineLoading(
          phase: 'loading',
          current: 0,
          total: 100,
          message: 'Loading $login\'s activity...',
          eventCount: 0,
        );

        final fullData = await _fetchTimelineChunk(
          login: login,
          from: from,
          to: to,
          refreshCache: refreshCache,
        );

        final events = ActivityTimelineConverter.convertToEvents(fullData);
        if (kDebugMode) {
          log.d(
              '[UserActivityService] getUserActivityTimelineWithProgress: Converted to ${events.length} events');
        }

        yield ActivityTimelineLoading(
          phase: 'loading',
          current: 90,
          total: 100,
          message: 'Almost ready...',
          eventCount: events.length,
        );

        final timelineData = _buildTimelineData(fullData, from, to);
        if (kDebugMode) {
          log.d(
              '[UserActivityService] getUserActivityTimelineWithProgress: Successfully built timeline with ${timelineData.events.length} events');
        }
        yield ActivityTimelineSuccess(timelineData);
        return;
      }

      // Multi-year path: Split into chunks
      final chunks = _splitDateRangeIntoYearChunks(from, to);
      final totalSteps = chunks.length;
      final progressPerStep = 90 / totalSteps;
      var currentProgress = 0.0;
      var totalEventCount = 0;
      if (kDebugMode) {
        log.d(
            '[UserActivityService] getUserActivityTimelineWithProgress: Split into $totalSteps chunks');
      }

      yield ActivityTimelineLoading(
        phase: 'loading',
        current: 0,
        total: 100,
        message:
            'Loading ${chunks.length} year${chunks.length > 1 ? 's' : ''} of $login\'s activity...',
        eventCount: 0,
      );

      final chunkEventLists = <List<ActivityTimelineEvent>>[];

      for (var i = 0; i < chunks.length; i++) {
        final (chunkFrom, chunkTo) = chunks[i];
        final yearLabel = chunkFrom.year == chunkTo.year
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
          final fullData = await _fetchTimelineChunk(
            login: login,
            from: chunkFrom,
            to: chunkTo,
            refreshCache: refreshCache,
          );

          final events = ActivityTimelineConverter.convertToEvents(fullData);
          chunkEventLists.add(events);
          totalEventCount += events.length;
          if (kDebugMode) {
            log.d(
                '[UserActivityService] getUserActivityTimelineWithProgress: Chunk $yearLabel: ${events.length} events (total so far: $totalEventCount)');
          }

          currentProgress += progressPerStep;
        } catch (e, stackTrace) {
          log.e(
              '[UserActivityService] getUserActivityTimelineWithProgress: Failed to load chunk $yearLabel',
              error: e,
              stackTrace: stackTrace);
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

      final allEvents = chunkEventLists.length == 1
          ? chunkEventLists.first
          : _mergeSortedChunks(chunkEventLists);
      if (kDebugMode) {
        log.d(
            '[UserActivityService] getUserActivityTimelineWithProgress: Merged ${chunkEventLists.length} chunks into ${allEvents.length} total events');
      }

      final timelineData = UserActivityTimelineData(
        events: allEvents,
        from: from,
        to: to,
      );
      if (kDebugMode) {
        log.d(
            '[UserActivityService] getUserActivityTimelineWithProgress: Successfully built multi-year timeline');
      }
      yield ActivityTimelineSuccess(timelineData);
    } catch (e, stackTrace) {
      log.e(
          '[UserActivityService] getUserActivityTimelineWithProgress: Error fetching timeline for "$login"',
          error: e,
          stackTrace: stackTrace);
      yield ActivityTimelineError(
        message: 'Failed to fetch activity timeline for user "$login": $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<UserActivityTimelineData> getUserActivityTimeline({
    required String login,
    required DateTime from,
    required DateTime to,
    bool refreshCache = false,
  }) async {
    if (kDebugMode) {
      log.d(
          '[UserActivityService] getUserActivityTimeline: Starting for user "$login" from ${from.toIso8601String()} to ${to.toIso8601String()}, refreshCache: $refreshCache');
    }
    try {
      final daysDiff = to.difference(from).inDays;
      final exceedsOneYear = daysDiff > 365;

      if (!exceedsOneYear) {
        final fullData = await _fetchTimelineChunk(
          login: login,
          from: from,
          to: to,
          refreshCache: refreshCache,
        );
        final result = _buildTimelineData(fullData, from, to);
        if (kDebugMode) {
          log.d(
              '[UserActivityService] getUserActivityTimeline: Single-year timeline completed with ${result.events.length} events');
        }
        return result;
      }

      final chunks = _splitDateRangeIntoYearChunks(from, to);
      final chunkEventLists = <List<ActivityTimelineEvent>>[];
      if (kDebugMode) {
        log.d(
            '[UserActivityService] getUserActivityTimeline: Processing ${chunks.length} chunks');
      }

      for (final (chunkFrom, chunkTo) in chunks) {
        final fullData = await _fetchTimelineChunk(
          login: login,
          from: chunkFrom,
          to: chunkTo,
          refreshCache: refreshCache,
        );
        final events = ActivityTimelineConverter.convertToEvents(fullData);
        chunkEventLists.add(events);
        if (kDebugMode) {
          log.d(
              '[UserActivityService] getUserActivityTimeline: Chunk ${chunkFrom.year}-${chunkTo.year}: ${events.length} events');
        }
      }

      final allEvents = chunkEventLists.length == 1
          ? chunkEventLists.first
          : _mergeSortedChunks(chunkEventLists);
      if (kDebugMode) {
        log.d(
            '[UserActivityService] getUserActivityTimeline: Merged into ${allEvents.length} total events');
      }

      return UserActivityTimelineData(
        events: allEvents,
        from: from,
        to: to,
      );
    } catch (e, stackTrace) {
      log.e(
          '[UserActivityService] getUserActivityTimeline: Error for user "$login"',
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }

  static List<(DateTime, DateTime)> _splitDateRangeIntoYearChunks(
    DateTime from,
    DateTime to,
  ) {
    if (kDebugMode) {
      log.d(
          '[UserActivityService] _splitDateRangeIntoYearChunks: Splitting from ${from.toIso8601String()} to ${to.toIso8601String()}');
    }
    final chunks = <(DateTime, DateTime)>[];
    var currentFrom = from;

    while (currentFrom.isBefore(to) ||
        (currentFrom.year == to.year &&
            currentFrom.month == to.month &&
            currentFrom.day == to.day)) {
      final oneYearLater = DateTime(
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
      if (kDebugMode) {
        log.d(
            '[UserActivityService] _splitDateRangeIntoYearChunks: Added chunk ${currentFrom.year}-${chunkTo.year}: ${currentFrom.toIso8601String()} to ${chunkTo.toIso8601String()}');
      }

      if (chunkTo.year == to.year &&
          chunkTo.month == to.month &&
          chunkTo.day == to.day) {
        break;
      }

      currentFrom = chunkTo.add(const Duration(days: 1));

      if (chunks.length > 100) {
        log.e(
            '[UserActivityService] _splitDateRangeIntoYearChunks: Exceeded maximum chunks (100)');
        throw Exception(
          'Date range splitting exceeded maximum chunks (100). Range: $from to $to',
        );
      }
    }

    if (kDebugMode) {
      log.d(
          '[UserActivityService] _splitDateRangeIntoYearChunks: Created ${chunks.length} chunks');
    }
    return chunks;
  }

  static List<ActivityTimelineEvent> _mergeSortedChunks(
    List<List<ActivityTimelineEvent>> sortedChunks,
  ) {
    if (sortedChunks.isEmpty) {
      if (kDebugMode) {
        log.d('[UserActivityService] _mergeSortedChunks: No chunks to merge');
      }
      return [];
    }
    if (sortedChunks.length == 1) {
      if (kDebugMode) {
        log.d(
            '[UserActivityService] _mergeSortedChunks: Single chunk with ${sortedChunks.first.length} events');
      }
      return sortedChunks.first;
    }

    if (kDebugMode) {
      final totalEvents =
          sortedChunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
      log.d(
          '[UserActivityService] _mergeSortedChunks: Merging ${sortedChunks.length} chunks with $totalEvents total events');
    }

    final merged = <ActivityTimelineEvent>[];
    final iterators = sortedChunks.map((chunk) => chunk.iterator).toList();
    final currentValues = <ActivityTimelineEvent?>[];

    for (final iterator in iterators) {
      if (iterator.moveNext()) {
        currentValues.add(iterator.current);
      } else {
        currentValues.add(null);
      }
    }

    while (currentValues.any((v) => v != null)) {
      ActivityTimelineEvent? newest;
      int newestIndex = -1;

      for (var i = 0; i < currentValues.length; i++) {
        final value = currentValues[i];
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

    if (kDebugMode) {
      log.d(
          '[UserActivityService] _mergeSortedChunks: Merged into ${merged.length} events');
    }
    return merged;
  }

  static UserActivityTimelineData _buildTimelineData(
    GuserActivityTimelineFullData_user fullData,
    DateTime from,
    DateTime to,
  ) {
    final events = ActivityTimelineConverter.convertToEvents(fullData);
    if (kDebugMode) {
      log.d(
          '[UserActivityService] _buildTimelineData: Built timeline with ${events.length} events');
    }

    return UserActivityTimelineData(
      events: events,
      from: from,
      to: to,
    );
  }

  /// Get the year for a given page number (0-indexed, newest first)
  /// Pages are ordered from newest year to oldest year
  static int getYearForPage(DateTime from, DateTime to, int pageNumber) {
    final years = <int>[];

    // Start from the end year and work backwards
    var currentYear = to.year;
    final startYear = from.year;

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

  /// Fetch events for a single year (for infinite pagination)
  /// Returns events wrapped with flags, ready for display
  static Future<List<TimelineEventWithFlags>> getYearEvents({
    required String login,
    required int year,
    required DateTime from,
    required DateTime to,
    bool refreshCache = false,
  }) async {
    if (kDebugMode) {
      log.d(
          '[UserActivityService] getYearEvents: Fetching year $year for user "$login"');
    }

    // Calculate year boundaries
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year, 12, 31);

    // Clamp to actual date range
    final chunkFrom = yearStart.isBefore(from) ? from : yearStart;
    final chunkTo = yearEnd.isAfter(to) ? to : yearEnd;

    if (kDebugMode) {
      log.d(
          '[UserActivityService] getYearEvents: Year $year range: ${chunkFrom.toIso8601String()} to ${chunkTo.toIso8601String()}');
    }

    final fullData = await _fetchTimelineChunk(
      login: login,
      from: chunkFrom,
      to: chunkTo,
      refreshCache: refreshCache,
    );

    final events = ActivityTimelineConverter.convertToEvents(fullData);
    final timelineData = UserActivityTimelineData(
      events: events,
      from: chunkFrom,
      to: chunkTo,
    );

    if (kDebugMode) {
      log.d(
          '[UserActivityService] getYearEvents: Year $year returned ${timelineData.events.length} events');
    }

    return timelineData.events;
  }
}
