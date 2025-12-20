// ignore_for_file: avoid_classes_with_only_static_members

import 'package:built_collection/built_collection.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_minimal.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_minimal.req.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_activity_timeline_full.req.gql.dart';
import 'package:diohub/models/activity_timeline_progress.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_converter.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';

/// Phase 1 result: cursor before range and total count
class Phase1Result {
  final String? cursorBeforeRange;
  final int totalInRange;
  final String? cursorAfterRange;

  Phase1Result({
    this.cursorBeforeRange,
    required this.totalInRange,
    this.cursorAfterRange,
  });
}

/// Processing result for a single page
class PageProcessResult {
  final int countInRange;
  final String? cursorBeforeRange;
  final String? lastInRangeCursor;
  final bool foundFirstInRange;
  final bool rangeComplete; // true if we've fully traversed the range
  final bool
      needsMorePages; // true if we're still in range and need to continue

  PageProcessResult({
    required this.countInRange,
    this.cursorBeforeRange,
    this.lastInRangeCursor,
    required this.foundFirstInRange,
    required this.rangeComplete,
    required this.needsMorePages,
  });
}

/// Phase 1 state: tracks pagination for all types
class Phase1State {
  int? firstRepos = 100;
  int? firstPRs = 100;
  int? firstIssues = 100;
  String? afterRepos;
  String? afterPRs;
  String? afterIssues;

  // Accumulated state for each type
  int reposTotalInRange = 0;
  String? reposCursorBeforeRange;
  String? reposLastInRangeCursor;
  bool reposFoundFirstInRange = false;
  bool reposRangeComplete = false;

  int prsTotalInRange = 0;
  String? prsCursorBeforeRange;
  String? prsLastInRangeCursor;
  bool prsFoundFirstInRange = false;
  bool prsRangeComplete = false;

  int issuesTotalInRange = 0;
  String? issuesCursorBeforeRange;
  String? issuesLastInRangeCursor;
  bool issuesFoundFirstInRange = false;
  bool issuesRangeComplete = false;

  Phase1Result? reposResult;
  Phase1Result? prsResult;
  Phase1Result? issuesResult;

  bool get allRangesFound =>
      reposRangeComplete && prsRangeComplete && issuesRangeComplete;
}

class UserActivityService {
  static final GraphqlHandler _gqlHandler = GraphqlHandler();

  /// Phase 1: Combined minimal fetch with dynamic first params
  /// As we find ranges for each type, set their first to 0
  static Future<Map<String, Phase1Result>> _fetchMinimalData(
    String login,
    DateTime from,
    DateTime to, {
    bool refreshCache = false,
  }) async {
    final state = Phase1State();
    final results = <String, Phase1Result>{};

    // Continue until all types have found their ranges
    while (!state.allRangesFound) {
      GQLResponse batch;
      try {
        batch = await _gqlHandler.query(
          GuserActivityTimelineMinimalReq(
            (final GuserActivityTimelineMinimalReqBuilder b) {
              b..vars.user = login;
              if (state.firstRepos != null && state.firstRepos! > 0) {
                b..vars.firstRepos = state.firstRepos;
                if (state.afterRepos != null) {
                  b..vars.afterRepos = state.afterRepos;
                }
              } else {
                b..vars.firstRepos = 0; // Stop fetching repos
              }

              if (state.firstPRs != null && state.firstPRs! > 0) {
                b..vars.firstPRs = state.firstPRs;
                if (state.afterPRs != null) {
                  b..vars.afterPRs = state.afterPRs;
                }
              } else {
                b..vars.firstPRs = 0; // Stop fetching PRs
              }

              if (state.firstIssues != null && state.firstIssues! > 0) {
                b..vars.firstIssues = state.firstIssues;
                if (state.afterIssues != null) {
                  b..vars.afterIssues = state.afterIssues;
                }
              } else {
                b..vars.firstIssues = 0; // Stop fetching issues
              }
            },
          ),
          refreshCache: refreshCache,
        );
      } catch (e) {
        throw Exception(
          'Phase 1 failed: Error fetching minimal activity data for user "$login": $e',
        );
      }

      if (batch.data == null) {
        throw Exception(
          'Phase 1 failed: No data returned from minimal activity query for user "$login"',
        );
      }

      final parsedData = GuserActivityTimelineMinimalData.fromJson(batch.data!);
      if (parsedData == null || parsedData.user == null) {
        throw Exception(
          'Phase 1 failed: Invalid response structure from minimal activity query for user "$login"',
        );
      }

      final data = parsedData.user!;

      // Process repositories
      if (!state.reposRangeComplete && data.repositories.edges != null) {
        final pageResult = _processRepositories(
          data.repositories.edges!,
          data.repositories.pageInfo,
          from,
          to,
        );

        // Accumulate counts
        if (pageResult.foundFirstInRange) {
          if (!state.reposFoundFirstInRange) {
            // First time finding items in range - save the cursor before range
            state.reposFoundFirstInRange = true;
            state.reposCursorBeforeRange = pageResult.cursorBeforeRange;
          }
          state.reposTotalInRange += pageResult.countInRange;
          if (pageResult.lastInRangeCursor != null) {
            state.reposLastInRangeCursor = pageResult.lastInRangeCursor;
          }
        }

        // Check if we're done with this type
        if (pageResult.rangeComplete) {
          state.reposRangeComplete = true;
          if (state.reposFoundFirstInRange) {
            // Create final result
            state.reposResult = Phase1Result(
              cursorBeforeRange: state.reposCursorBeforeRange,
              totalInRange: state.reposTotalInRange,
              cursorAfterRange: state.reposLastInRangeCursor,
            );
            results['repos'] = state.reposResult!;
          }
          state.firstRepos = 0; // Stop fetching repos
        } else if (pageResult.needsMorePages) {
          // Continue paginating - update cursor for next page
          state.afterRepos = data.repositories.pageInfo.endCursor;
        } else {
          // Shouldn't happen with updated logic, but handle it safely
          state.reposRangeComplete = true;
          state.firstRepos = 0;
        }
      }

      // Process pull requests
      if (!state.prsRangeComplete && data.pullRequests.edges != null) {
        final pageResult = _processPullRequests(
          data.pullRequests.edges!,
          data.pullRequests.pageInfo,
          from,
          to,
        );

        // Accumulate counts
        if (pageResult.foundFirstInRange) {
          if (!state.prsFoundFirstInRange) {
            state.prsFoundFirstInRange = true;
            state.prsCursorBeforeRange = pageResult.cursorBeforeRange;
          }
          state.prsTotalInRange += pageResult.countInRange;
          if (pageResult.lastInRangeCursor != null) {
            state.prsLastInRangeCursor = pageResult.lastInRangeCursor;
          }
        }

        // Check if we're done with this type
        if (pageResult.rangeComplete) {
          state.prsRangeComplete = true;
          if (state.prsFoundFirstInRange) {
            state.prsResult = Phase1Result(
              cursorBeforeRange: state.prsCursorBeforeRange,
              totalInRange: state.prsTotalInRange,
              cursorAfterRange: state.prsLastInRangeCursor,
            );
            results['prs'] = state.prsResult!;
          }
          state.firstPRs = 0; // Stop fetching PRs
        } else if (pageResult.needsMorePages) {
          state.afterPRs = data.pullRequests.pageInfo.endCursor;
        } else {
          state.prsRangeComplete = true;
          state.firstPRs = 0;
        }
      }

      // Process issues
      if (!state.issuesRangeComplete && data.issues.edges != null) {
        final pageResult = _processIssues(
          data.issues.edges!,
          data.issues.pageInfo,
          from,
          to,
        );

        // Accumulate counts
        if (pageResult.foundFirstInRange) {
          if (!state.issuesFoundFirstInRange) {
            state.issuesFoundFirstInRange = true;
            state.issuesCursorBeforeRange = pageResult.cursorBeforeRange;
          }
          state.issuesTotalInRange += pageResult.countInRange;
          if (pageResult.lastInRangeCursor != null) {
            state.issuesLastInRangeCursor = pageResult.lastInRangeCursor;
          }
        }

        // Check if we're done with this type
        if (pageResult.rangeComplete) {
          state.issuesRangeComplete = true;
          if (state.issuesFoundFirstInRange) {
            state.issuesResult = Phase1Result(
              cursorBeforeRange: state.issuesCursorBeforeRange,
              totalInRange: state.issuesTotalInRange,
              cursorAfterRange: state.issuesLastInRangeCursor,
            );
            results['issues'] = state.issuesResult!;
          }
          state.firstIssues = 0; // Stop fetching issues
        } else if (pageResult.needsMorePages) {
          state.afterIssues = data.issues.pageInfo.endCursor;
        } else {
          state.issuesRangeComplete = true;
          state.firstIssues = 0;
        }
      }

      // Check if we should continue
      // Continue if any type is still being fetched and has more pages
      final reposStillFetching =
          state.firstRepos != null && state.firstRepos! > 0;
      final prsStillFetching = state.firstPRs != null && state.firstPRs! > 0;
      final issuesStillFetching =
          state.firstIssues != null && state.firstIssues! > 0;

      final shouldContinue = (!state.allRangesFound) &&
          ((reposStillFetching && data.repositories.pageInfo.hasNextPage) ||
              (prsStillFetching && data.pullRequests.pageInfo.hasNextPage) ||
              (issuesStillFetching && data.issues.pageInfo.hasNextPage));

      if (!shouldContinue) break;
    }

    return results;
  }

  /// Process repositories to find range
  /// Returns processing result for this page, indicating if we need to continue
  static PageProcessResult _processRepositories(
    BuiltList<GuserActivityTimelineMinimalData_user_repositories_edges?> edges,
    GuserActivityTimelineMinimalData_user_repositories_pageInfo pageInfo,
    DateTime from,
    DateTime to,
  ) {
    String? cursorBeforeRange;
    int countInRange = 0;
    String? lastInRangeCursor;
    bool foundFirstInRange = false;
    bool passedRange = false;

    for (final edge in edges) {
      if (edge == null) continue;
      final node = edge.node;
      if (node == null) continue;

      final createdAt = node.createdAt;
      final currentCursor = edge.cursor;

      // Stop if date is before range (ordered DESC)
      if (createdAt.isBefore(from)) {
        passedRange = true;
        break;
      }

      if (_isInDateRange(createdAt, from, to)) {
        if (!foundFirstInRange) {
          foundFirstInRange = true;
          // cursorBeforeRange is already set from previous iteration
        }
        countInRange++;
        lastInRangeCursor = currentCursor;
      } else {
        if (!foundFirstInRange) {
          cursorBeforeRange = currentCursor; // Save cursor before range
        } else {
          // Passed range - we've seen items in range, now we're past it
          passedRange = true;
          break;
        }
      }
    }

    // Determine if we need more pages:
    // - If we haven't found the range yet but there are more pages, continue searching
    // - If we found items in range but haven't passed it yet, and there are more pages, continue
    // - If we passed the range or no more pages, we're done
    final needsMorePages = pageInfo.hasNextPage &&
        (!foundFirstInRange || (foundFirstInRange && !passedRange));
    final rangeComplete = passedRange || !pageInfo.hasNextPage;

    return PageProcessResult(
      countInRange: countInRange,
      cursorBeforeRange: cursorBeforeRange,
      lastInRangeCursor: lastInRangeCursor,
      foundFirstInRange: foundFirstInRange,
      rangeComplete: rangeComplete,
      needsMorePages: needsMorePages,
    );
  }

  /// Process pull requests to find range
  /// Returns processing result for this page, indicating if we need to continue
  static PageProcessResult _processPullRequests(
    BuiltList<GuserActivityTimelineMinimalData_user_pullRequests_edges?> edges,
    GuserActivityTimelineMinimalData_user_pullRequests_pageInfo pageInfo,
    DateTime from,
    DateTime to,
  ) {
    String? cursorBeforeRange;
    int countInRange = 0;
    String? lastInRangeCursor;
    bool foundFirstInRange = false;
    bool passedRange = false;

    for (final edge in edges) {
      if (edge == null) continue;
      final node = edge.node;
      if (node == null) continue;

      final createdAt = node.createdAt;
      final currentCursor = edge.cursor;

      if (createdAt.isBefore(from)) {
        passedRange = true;
        break;
      }

      if (_isInDateRange(createdAt, from, to)) {
        if (!foundFirstInRange) {
          foundFirstInRange = true;
        }
        countInRange++;
        lastInRangeCursor = currentCursor;
      } else {
        if (!foundFirstInRange) {
          cursorBeforeRange = currentCursor;
        } else {
          passedRange = true;
          break;
        }
      }
    }

    final needsMorePages =
        foundFirstInRange && !passedRange && pageInfo.hasNextPage;
    final rangeComplete = passedRange || !pageInfo.hasNextPage;

    return PageProcessResult(
      countInRange: countInRange,
      cursorBeforeRange: cursorBeforeRange,
      lastInRangeCursor: lastInRangeCursor,
      foundFirstInRange: foundFirstInRange,
      rangeComplete: rangeComplete,
      needsMorePages: needsMorePages,
    );
  }

  /// Process issues to find range
  /// Returns processing result for this page, indicating if we need to continue
  static PageProcessResult _processIssues(
    BuiltList<GuserActivityTimelineMinimalData_user_issues_edges?> edges,
    GuserActivityTimelineMinimalData_user_issues_pageInfo pageInfo,
    DateTime from,
    DateTime to,
  ) {
    String? cursorBeforeRange;
    int countInRange = 0;
    String? lastInRangeCursor;
    bool foundFirstInRange = false;
    bool passedRange = false;

    for (final edge in edges) {
      if (edge == null) continue;
      final node = edge.node;
      if (node == null) continue;

      final createdAt = node.createdAt;
      final currentCursor = edge.cursor;

      if (createdAt.isBefore(from)) {
        passedRange = true;
        break;
      }

      if (_isInDateRange(createdAt, from, to)) {
        if (!foundFirstInRange) {
          foundFirstInRange = true;
        }
        countInRange++;
        lastInRangeCursor = currentCursor;
      } else {
        if (!foundFirstInRange) {
          cursorBeforeRange = currentCursor;
        } else {
          passedRange = true;
          break;
        }
      }
    }

    final needsMorePages =
        foundFirstInRange && !passedRange && pageInfo.hasNextPage;
    final rangeComplete = passedRange || !pageInfo.hasNextPage;

    return PageProcessResult(
      countInRange: countInRange,
      cursorBeforeRange: cursorBeforeRange,
      lastInRangeCursor: lastInRangeCursor,
      foundFirstInRange: foundFirstInRange,
      rangeComplete: rangeComplete,
      needsMorePages: needsMorePages,
    );
  }

  /// Check if date is in range (inclusive boundaries)
  static bool _isInDateRange(DateTime date, DateTime from, DateTime to) {
    return date.isAfter(from.subtract(const Duration(days: 1))) &&
        date.isBefore(to.add(const Duration(days: 1)));
  }

  /// Fetch a single batch of detailed data with specified counts and cursors
  static Future<GuserActivityTimelineFullData_user> _fetchDetailedDataBatch({
    required String login,
    required DateTime from,
    required DateTime to,
    required int reposCount,
    String? reposAfter,
    required int prsCount,
    String? prsAfter,
    required int issuesCount,
    String? issuesAfter,
    bool refreshCache = false,
  }) async {
    GQLResponse response;
    try {
      response = await _gqlHandler.query(
        GuserActivityTimelineFullReq(
          (final GuserActivityTimelineFullReqBuilder b) {
            b.vars
              ..user = login
              ..from = from
              ..to = to;

            // Repositories
            b
              ..vars.firstRepos = reposCount
              ..vars.afterRepos = reposAfter;

            // Pull Requests
            b
              ..vars.firstPRs = prsCount
              ..vars.afterPRs = prsAfter;

            // Issues
            b
              ..vars.firstIssues = issuesCount
              ..vars.afterIssues = issuesAfter;
          },
        ),
        refreshCache: refreshCache,
      );
    } catch (e) {
      throw Exception(
        'Phase 2 batch failed: Error fetching detailed activity data for user "$login": $e',
      );
    }

    if (response.data == null) {
      throw Exception(
        'Phase 2 batch failed: No data returned from detailed activity query for user "$login"',
      );
    }

    final parsedData = GuserActivityTimelineFullData.fromJson(response.data!);
    if (parsedData == null || parsedData.user == null) {
      throw Exception(
        'Phase 2 batch failed: Invalid response structure from detailed activity query for user "$login"',
      );
    }

    return parsedData.user!;
  }

  /// Get the last cursor from a connection's edges
  static String? _getLastCursor<T>(BuiltList<T?>? edges) {
    if (edges == null || edges.isEmpty) return null;

    // Iterate from the end to find the last non-null edge with a cursor
    for (var i = edges.length - 1; i >= 0; i--) {
      final edge = edges[i];
      if (edge == null) continue;

      // Use dynamic to access cursor property (all edge types have cursor)
      try {
        final dynamic dynamicEdge = edge;
        final cursor = dynamicEdge.cursor as String?;
        if (cursor != null) return cursor;
      } catch (e) {
        // If cursor access fails, continue to next edge
        continue;
      }
    }

    return null;
  }

  /// Phase 2: Fetch detailed data with pagination support for >100 items per type
  /// Uses combined queries to minimize API calls while handling large result sets
  static Future<GuserActivityTimelineFullData_user> _fetchDetailedData(
    Map<String, Phase1Result> phase1Results,
    String login,
    DateTime from,
    DateTime to, {
    bool refreshCache = false,
  }) async {
    final reposResult = phase1Results['repos'];
    final prsResult = phase1Results['prs'];
    final issuesResult = phase1Results['issues'];

    // Step 1: Fetch first batch (up to 100 of each type)
    final reposFirstCount = reposResult != null && reposResult.totalInRange > 0
        ? (reposResult.totalInRange > 100 ? 100 : reposResult.totalInRange)
        : 0;
    final prsFirstCount = prsResult != null && prsResult.totalInRange > 0
        ? (prsResult.totalInRange > 100 ? 100 : prsResult.totalInRange)
        : 0;
    final issuesFirstCount = issuesResult != null &&
            issuesResult.totalInRange > 0
        ? (issuesResult.totalInRange > 100 ? 100 : issuesResult.totalInRange)
        : 0;

    final firstBatch = await _fetchDetailedDataBatch(
      login: login,
      from: from,
      to: to,
      reposCount: reposFirstCount,
      reposAfter: reposResult?.cursorBeforeRange,
      prsCount: prsFirstCount,
      prsAfter: prsResult?.cursorBeforeRange,
      issuesCount: issuesFirstCount,
      issuesAfter: issuesResult?.cursorBeforeRange,
      refreshCache: refreshCache,
    );

    // Step 2: Initialize edge accumulators from first batch
    final allReposEdges =
        <GuserActivityTimelineFullData_user_repositories_edges?>[
      ...?firstBatch.repositories.edges,
    ];
    final allPRsEdges =
        <GuserActivityTimelineFullData_user_pullRequests_edges?>[
      ...?firstBatch.pullRequests.edges,
    ];
    final allIssuesEdges = <GuserActivityTimelineFullData_user_issues_edges?>[
      ...?firstBatch.issues.edges,
    ];

    // Step 3: Calculate remaining counts and initialize cursors
    var reposRemaining = (reposResult?.totalInRange ?? 0) - reposFirstCount;
    var prsRemaining = (prsResult?.totalInRange ?? 0) - prsFirstCount;
    var issuesRemaining = (issuesResult?.totalInRange ?? 0) - issuesFirstCount;

    var reposAfter = _getLastCursor(firstBatch.repositories.edges) ??
        reposResult?.cursorBeforeRange;
    var prsAfter = _getLastCursor(firstBatch.pullRequests.edges) ??
        prsResult?.cursorBeforeRange;
    var issuesAfter = _getLastCursor(firstBatch.issues.edges) ??
        issuesResult?.cursorBeforeRange;

    // Step 4: Loop for remaining items (combined queries)
    while (reposRemaining > 0 || prsRemaining > 0 || issuesRemaining > 0) {
      // Calculate batch size for each type (min of remaining and 100)
      final reposBatchSize = reposRemaining > 0
          ? (reposRemaining > 100 ? 100 : reposRemaining)
          : 0;
      final prsBatchSize =
          prsRemaining > 0 ? (prsRemaining > 100 ? 100 : prsRemaining) : 0;
      final issuesBatchSize = issuesRemaining > 0
          ? (issuesRemaining > 100 ? 100 : issuesRemaining)
          : 0;

      // Fetch combined batch
      final batch = await _fetchDetailedDataBatch(
        login: login,
        from: from,
        to: to,
        reposCount: reposBatchSize,
        reposAfter: reposAfter,
        prsCount: prsBatchSize,
        prsAfter: prsAfter,
        issuesCount: issuesBatchSize,
        issuesAfter: issuesAfter,
        refreshCache: refreshCache,
      );

      // Append edges to accumulators
      if (batch.repositories.edges != null && reposBatchSize > 0) {
        allReposEdges.addAll(batch.repositories.edges!);
        reposRemaining -= reposBatchSize;
        reposAfter = _getLastCursor(batch.repositories.edges) ?? reposAfter;
      }

      if (batch.pullRequests.edges != null && prsBatchSize > 0) {
        allPRsEdges.addAll(batch.pullRequests.edges!);
        prsRemaining -= prsBatchSize;
        prsAfter = _getLastCursor(batch.pullRequests.edges) ?? prsAfter;
      }

      if (batch.issues.edges != null && issuesBatchSize > 0) {
        allIssuesEdges.addAll(batch.issues.edges!);
        issuesRemaining -= issuesBatchSize;
        issuesAfter = _getLastCursor(batch.issues.edges) ?? issuesAfter;
      }
    }

    // Step 5: Rebuild merged result with accumulated edges
    return firstBatch.rebuild((b) => b
      ..repositories.edges.replace(allReposEdges)
      ..pullRequests.edges.replace(allPRsEdges)
      ..issues.edges.replace(allIssuesEdges));
  }

  /// Stream-based version that reports progress
  /// Emits ActivityTimelineState updates as data is fetched
  static Stream<ActivityTimelineState> getUserActivityTimelineWithProgress({
    required String login,
    required DateTime from,
    required DateTime to,
    bool refreshCache = false,
  }) async* {
    try {
      // Check if range exceeds GitHub's 1-year API limit
      final daysDiff = to.difference(from).inDays;
      final exceedsOneYear = daysDiff > 365;

      if (!exceedsOneYear) {
        // Fast path: Single chunk
        yield ActivityTimelineLoading(
          phase: 'loading',
          current: 0,
          total: 100,
          message: 'Loading $login\'s activity...',
          eventCount: 0,
        );

        final phase1Results = await _fetchMinimalData(
          login,
          from,
          to,
          refreshCache: refreshCache,
        );

        yield ActivityTimelineLoading(
          phase: 'loading',
          current: 50,
          total: 100,
          message: 'Getting activity details...',
          eventCount: 0,
        );

        final fullData = await _fetchDetailedData(
          phase1Results,
          login,
          from,
          to,
          refreshCache: refreshCache,
        );

        final events = ActivityTimelineConverter.convertToEvents(fullData);
        final eventCount = events.length;

        yield ActivityTimelineLoading(
          phase: 'loading',
          current: 90,
          total: 100,
          message: 'Almost ready...',
          eventCount: eventCount,
        );

        final timelineData = _buildTimelineData(fullData, from, to);
        yield ActivityTimelineSuccess(timelineData);
        return;
      }

      // Multi-year path: Split into chunks
      final chunks = _splitDateRangeIntoYearChunks(from, to);
      final totalSteps = chunks.length * 2; // Each chunk has 2 phases
      final progressPerStep =
          90 / totalSteps; // Reserve 10% for final processing
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

        // Phase 1 for this chunk
        yield ActivityTimelineLoading(
          phase: 'loading',
          current: currentProgress.round(),
          total: 100,
          message: 'Loading $yearLabel activity...',
          eventCount: totalEventCount,
        );

        try {
          final phase1Results = await _fetchMinimalData(
            login,
            chunkFrom,
            chunkTo,
            refreshCache: refreshCache,
          );

          currentProgress += progressPerStep;

          // Phase 2 for this chunk
          yield ActivityTimelineLoading(
            phase: 'loading',
            current: currentProgress.round(),
            total: 100,
            message: 'Getting details for $yearLabel...',
            eventCount: totalEventCount,
          );

          final fullData = await _fetchDetailedData(
            phase1Results,
            login,
            chunkFrom,
            chunkTo,
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

      // Final step: Merging chunks
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
        message: e.toString().contains('Phase')
            ? e.toString()
            : 'Failed to fetch activity timeline for user "$login": $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Main entry point: Two-phase fetch with combined queries
  ///
  /// **GitHub API Constraint:**
  /// - `contributionsCollection` query has a 1-year maximum date range
  /// - Requests exceeding 1 year return: "The total time spanned by 'from' and 'to' must not exceed 1 year"
  ///
  /// **Solution:**
  /// - Automatically split date ranges >1 year into non-overlapping 1-year chunks
  /// - Process each chunk independently (Phase 1 + Phase 2)
  /// - Combine results and sort chronologically
  ///
  /// **Flow:**
  /// 1. Check if date range exceeds 1 year
  /// 2. If yes: Split into chunks → Process each → Combine results
  /// 3. If no: Process single chunk directly
  /// 4. Set timeline position flags (isFirst/isLast) for UI rendering
  static Future<UserActivityTimelineData> getUserActivityTimeline({
    required String login,
    required DateTime from,
    required DateTime to,
    bool refreshCache = false,
  }) async {
    try {
      // Check if range exceeds GitHub's 1-year API limit
      final daysDiff = to.difference(from).inDays;
      final exceedsOneYear = daysDiff > 365;

      if (!exceedsOneYear) {
        // Fast path: Single chunk, no splitting needed
        return await _getUserActivityTimelineSingleChunk(
          login,
          from,
          to,
          refreshCache: refreshCache,
        );
      }

      // Split date range into non-overlapping 1-year chunks
      // Example: 2022-01-01 to 2024-06-15 becomes:
      //   Chunk 1: 2022-01-01 to 2022-12-31
      //   Chunk 2: 2023-01-01 to 2023-12-31
      //   Chunk 3: 2024-01-01 to 2024-06-15
      final chunks = _splitDateRangeIntoYearChunks(from, to);
      final chunkEventLists = <List<ActivityTimelineEvent>>[];

      // Process each chunk independently (each chunk does Phase 1 + Phase 2)
      // This ensures we stay within GitHub's API limits
      for (final (chunkFrom, chunkTo) in chunks) {
        try {
          // Fetch and convert chunk data (already sorted by converter)
          final phase1Results = await _fetchMinimalData(
            login,
            chunkFrom,
            chunkTo,
            refreshCache: refreshCache,
          );
          final fullData = await _fetchDetailedData(
            phase1Results,
            login,
            chunkFrom,
            chunkTo,
            refreshCache: refreshCache,
          );
          // Convert to events (converter already sorts them)
          final events = ActivityTimelineConverter.convertToEvents(fullData);
          chunkEventLists.add(events);
        } catch (e) {
          throw Exception(
            'Failed to fetch activity timeline for chunk $chunkFrom to $chunkTo: $e',
          );
        }
      }

      // Merge sorted chunks instead of sorting again
      // Each chunk is already sorted (newest first) by converter
      // We want overall newest first, so merge them (O(n)) instead of sort (O(n log n))
      final allEvents = chunkEventLists.length == 1
          ? chunkEventLists.first
          : _mergeSortedChunks(chunkEventLists);

      // Create data structure - flags will be set per month in _groupByMonth
      return UserActivityTimelineData(
        events: allEvents,
        from: from,
        to: to,
      );
    } catch (e) {
      // Re-throw with context if it's already our formatted exception
      if (e is Exception && e.toString().contains('Phase')) {
        rethrow;
      }
      // Otherwise wrap in a generic error
      throw Exception(
        'Failed to fetch activity timeline for user "$login": $e',
      );
    }
  }

  /// Process a single chunk (original logic extracted)
  ///
  /// **Two-Phase Fetch Strategy:**
  /// This method implements an optimized two-phase approach to minimize API calls:
  ///
  /// **Phase 1:** Minimal data fetch
  /// - Fetch only cursors and counts (pagination metadata)
  /// - Determine how many items of each type are in the date range
  /// - Purpose: Know exactly how much data to fetch in Phase 2
  ///
  /// **Phase 2:** Detailed data fetch
  /// - Use Phase 1 results to fetch exactly the needed data
  /// - Single combined query for all types (repos, PRs, issues, commits)
  /// - Includes all fields needed for UI display
  ///
  /// **Why Two Phases?**
  /// - Avoids over-fetching: Don't fetch 100 PRs if only 5 are in range
  /// - Reduces API calls: Single query per phase instead of multiple
  /// - Fetches only what's needed
  static Future<UserActivityTimelineData> _getUserActivityTimelineSingleChunk(
    String login,
    DateTime from,
    DateTime to, {
    bool refreshCache = false,
  }) async {
    // Phase 1: Fetch minimal data (cursors, counts) to determine pagination needs
    // This tells us: "How many repos/PRs/issues are in this date range?"
    final phase1Results = await _fetchMinimalData(
      login,
      from,
      to,
      refreshCache: refreshCache,
    );

    // Phase 2: Fetch full data using Phase 1 results
    // Uses the counts/cursors from Phase 1 to fetch exactly what we need
    // Single combined query fetches: repos + PRs + issues + commits
    final fullData = await _fetchDetailedData(
      phase1Results,
      login,
      from,
      to,
      refreshCache: refreshCache,
    );

    // Convert GraphQL data to timeline events
    // This transforms the API response into our unified event format
    try {
      return _buildTimelineData(fullData, from, to);
    } catch (e) {
      throw Exception(
        'Failed to convert activity timeline data for user "$login": $e',
      );
    }
  }

  /// Split date range into 1-year chunks with non-overlapping boundaries
  /// Example: 2022-01-01 to 2024-06-15 becomes:
  ///   Chunk 1: 2022-01-01 to 2022-12-31
  ///   Chunk 2: 2023-01-01 to 2023-12-31
  ///   Chunk 3: 2024-01-01 to 2024-06-15
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
      // Calculate 1 year from current start
      final oneYearLater = DateTime(
        currentFrom.year + 1,
        currentFrom.month,
        currentFrom.day,
      );

      DateTime chunkTo;
      if (oneYearLater.isAfter(to)) {
        // Last chunk - use the actual end date
        chunkTo = to;
      } else {
        // Make end exclusive by using last day of the year (non-overlapping)
        chunkTo = DateTime(
          currentFrom.year,
          12,
          31,
        );
      }

      chunks.add((currentFrom, chunkTo));

      // If we've reached the end date, stop
      if (chunkTo.year == to.year &&
          chunkTo.month == to.month &&
          chunkTo.day == to.day) {
        break;
      }

      // Move to next chunk (day after current chunk ends)
      currentFrom = chunkTo.add(const Duration(days: 1));

      // Safety check to prevent infinite loop
      if (chunks.length > 100) {
        throw Exception(
          'Date range splitting exceeded maximum chunks (100). Range: $from to $to',
        );
      }
    }

    return chunks;
  }

  /// Merge multiple sorted lists (newest first) into one sorted list
  ///
  /// Each list is already sorted in descending order (newest first).
  /// Chunks are in chronological order (oldest to newest).
  /// Returns merged list in descending order (newest first).
  ///
  /// **Algorithm:** Multi-way merge using iterators
  /// **Complexity:** O(n) where n is total number of events
  /// **Performance:** ~90% faster than sorting for large datasets
  static List<ActivityTimelineEvent> _mergeSortedChunks(
    List<List<ActivityTimelineEvent>> sortedChunks,
  ) {
    if (sortedChunks.isEmpty) return [];
    if (sortedChunks.length == 1) return sortedChunks.first;

    final merged = <ActivityTimelineEvent>[];
    final iterators = sortedChunks.map((chunk) => chunk.iterator).toList();
    final currentValues = <ActivityTimelineEvent?>[];

    // Initialize: move all iterators to first element
    for (final iterator in iterators) {
      if (iterator.moveNext()) {
        currentValues.add(iterator.current);
      } else {
        currentValues.add(null);
      }
    }

    // Merge: always pick the event with the newest (latest) date
    while (currentValues.any((v) => v != null)) {
      // Find the event with the newest (latest) date
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
        // Move iterator for the chunk we just consumed
        if (iterators[newestIndex].moveNext()) {
          currentValues[newestIndex] = iterators[newestIndex].current;
        } else {
          currentValues[newestIndex] = null;
        }
      }
    }

    return merged;
  }

  /// Build timeline data from GraphQL responses
  ///
  /// **Process:**
  /// 1. Convert GraphQL data to unified ActivityTimelineEvent format
  ///    - Handles repos, PRs, issues, commits
  ///    - Events are sorted by date (newest first) here
  ///
  /// 2. Create UserActivityTimelineData with grouped structure
  ///    - Flat list of events
  ///    - Nested map grouped by year/month (for efficient UI rendering)
  ///    - Timeline position flags (isFirst/isLast) are set per month in _groupByMonth
  static UserActivityTimelineData _buildTimelineData(
    GuserActivityTimelineFullData_user fullData,
    DateTime from,
    DateTime to,
  ) {
    // Convert GraphQL response to unified event format
    // Converter already sorts events (newest first) to merge across event types
    final events = ActivityTimelineConverter.convertToEvents(fullData);

    // Create data structure - flags will be set per month in _groupByMonth
    return UserActivityTimelineData(
      events: events,
      from: from,
      to: to,
    );
  }
}
