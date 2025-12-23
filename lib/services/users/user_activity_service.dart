// ignore_for_file: avoid_classes_with_only_static_members

import 'package:built_collection/built_collection.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.req.gql.dart';
import 'package:diohub/models/activity_timeline_progress.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_converter.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';

class UserActivityService {
  static const int _repoPageSize = 50;
  static const int _prPageSize = 50;
  static const int _issuePageSize = 50;
  static const int _reviewPageSize = 50;
  static const int _commitPageSize = 100;
  static const int _commitRepoMax = 50;

  static final GraphqlHandler _gqlHandler = GraphqlHandler();

  /// Fetch a single time-bounded chunk (<=1 year) by paginating all
  /// contribution connections in contributionsCollection.
  static Future<GuserActivityTimelineFullData_user> _fetchTimelineChunk({
    required String login,
    required DateTime from,
    required DateTime to,
    bool refreshCache = false,
  }) async {
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

    while (true) {
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
        repoNodes.addAll(
          repoConnection.nodes!.whereType<
              GuserActivityTimelineFullData_user_contributionsCollection_repositoryContributions_nodes>(),
        );
      }
      repoHasNext = repoConnection.pageInfo.hasNextPage;
      repoAfter = repoConnection.pageInfo.endCursor;

      final prConnection = cc.pullRequestContributions;
      if (prConnection.nodes != null) {
        prNodes.addAll(
          prConnection.nodes!.whereType<
              GuserActivityTimelineFullData_user_contributionsCollection_pullRequestContributions_nodes>(),
        );
      }
      prHasNext = prConnection.pageInfo.hasNextPage;
      prAfter = prConnection.pageInfo.endCursor;

      final issueConnection = cc.issueContributions;
      if (issueConnection.nodes != null) {
        issueNodes.addAll(
          issueConnection.nodes!.whereType<
              GuserActivityTimelineFullData_user_contributionsCollection_issueContributions_nodes>(),
        );
      }
      issueHasNext = issueConnection.pageInfo.hasNextPage;
      issueAfter = issueConnection.pageInfo.endCursor;

      final reviewConnection = cc.pullRequestReviewContributions;
      if (reviewConnection.nodes != null) {
        reviewNodes.addAll(
          reviewConnection.nodes!.whereType<
              GuserActivityTimelineFullData_user_contributionsCollection_pullRequestReviewContributions_nodes>(),
        );
      }
      reviewHasNext = reviewConnection.pageInfo.hasNextPage;
      reviewAfter = reviewConnection.pageInfo.endCursor;

      commitRepos ??= cc.commitContributionsByRepository;

      final hasMore = repoHasNext || prHasNext || issueHasNext || reviewHasNext;
      if (!hasMore) {
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
    try {
      final daysDiff = to.difference(from).inDays;
      final exceedsOneYear = daysDiff > 365;

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

        yield ActivityTimelineLoading(
          phase: 'loading',
          current: 90,
          total: 100,
          message: 'Almost ready...',
          eventCount: events.length,
        );

        final timelineData = _buildTimelineData(fullData, from, to);
        yield ActivityTimelineSuccess(timelineData);
        return;
      }

      // Multi-year path: Split into chunks
      final chunks = _splitDateRangeIntoYearChunks(from, to);
      final totalSteps = chunks.length;
      final progressPerStep = 90 / totalSteps;
      var currentProgress = 0.0;
      var totalEventCount = 0;

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

      final allEvents = chunkEventLists.length == 1
          ? chunkEventLists.first
          : _mergeSortedChunks(chunkEventLists);

      final timelineData = UserActivityTimelineData(
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

  static Future<UserActivityTimelineData> getUserActivityTimeline({
    required String login,
    required DateTime from,
    required DateTime to,
    bool refreshCache = false,
  }) async {
    final daysDiff = to.difference(from).inDays;
    final exceedsOneYear = daysDiff > 365;

    if (!exceedsOneYear) {
      final fullData = await _fetchTimelineChunk(
        login: login,
        from: from,
        to: to,
        refreshCache: refreshCache,
      );
      return _buildTimelineData(fullData, from, to);
    }

    final chunks = _splitDateRangeIntoYearChunks(from, to);
    final chunkEventLists = <List<ActivityTimelineEvent>>[];

    for (final (chunkFrom, chunkTo) in chunks) {
      final fullData = await _fetchTimelineChunk(
        login: login,
        from: chunkFrom,
        to: chunkTo,
        refreshCache: refreshCache,
      );
      chunkEventLists.add(ActivityTimelineConverter.convertToEvents(fullData));
    }

    final allEvents = chunkEventLists.length == 1
        ? chunkEventLists.first
        : _mergeSortedChunks(chunkEventLists);

    return UserActivityTimelineData(
      events: allEvents,
      from: from,
      to: to,
    );
  }

  static List<(DateTime, DateTime)> _splitDateRangeIntoYearChunks(
    DateTime from,
    DateTime to,
  ) {
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

  static List<ActivityTimelineEvent> _mergeSortedChunks(
    List<List<ActivityTimelineEvent>> sortedChunks,
  ) {
    if (sortedChunks.isEmpty) return [];
    if (sortedChunks.length == 1) return sortedChunks.first;

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

    return merged;
  }

  static UserActivityTimelineData _buildTimelineData(
    GuserActivityTimelineFullData_user fullData,
    DateTime from,
    DateTime to,
  ) {
    final events = ActivityTimelineConverter.convertToEvents(fullData);

    return UserActivityTimelineData(
      events: events,
      from: from,
      to: to,
    );
  }
}
