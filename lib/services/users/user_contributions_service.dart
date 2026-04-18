import 'dart:ui';

import 'package:diohub/app/api_handler/dio.dart' show GQLResponse;
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub/common/utils/contribution_data_converter.dart';
import 'package:diohub_graphql/fragments/actor.graphql.dart';
import 'package:diohub_graphql/fragments/repo_card_fields.graphql.dart';
import 'package:diohub_graphql/queries/users/user_contributions.graphql.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart'
    show
        FirstIssueContribution,
        FirstPRContribution,
        FirstRepoContribution,
        PopularIssueContribution,
        PopularPRContribution;
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/contributions/contribution_day.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:flutter/foundation.dart';
import 'package:lens_annotations/lens_annotations.dart';

String _getOwnerLogin(Fragment$repoCardFields$owner owner) => switch (owner) {
  Fragment$actor actor => actor.login,
  _ => throw ArgumentError('Invalid owner type: ${owner.runtimeType}'),
};

/// Service for fetching and aggregating user contribution data.
/// Bound to a user via [UserRef], like [IssueService] with [IssueRef] / [RepositoryServices] with [RepoRef].
/// Uses [gql] only; no Riverpod refs or providers.
@LensService(scope: Scope.user, group: 'user')
class UserContributionsService extends EntityService<UserRef> {
  UserContributionsService(super.apiClient, super.ref);

  /// Fetches raw contribution data for this user in [from]–[to]. Used internally.
  Future<Query$userContributions$user> _fetchContributionsGql({
    required DateTime from,
    required DateTime to,
    bool refreshCache = false,
  }) async {
    final GQLResponse response = await gql.query(
      documentNodeQueryuserContributions,
      Variables$Query$userContributions(
        user: ref.login,
        from: from,
        to: to,
      ).toJson(),
      refreshCache: refreshCache,
    );
    final Query$userContributions parsed = Query$userContributions.fromJson(
      response.data!,
    );
    final Query$userContributions$user? user = parsed.user;
    if (user == null) {
      throw Exception('Contribution data for "${ref.login}" not found');
    }
    return user;
  }

  /// Merges [repos] into [repoMap] by URL. When a URL already exists, [merge] is called to produce the combined repo.
  static void _mergeContributionReposIntoMap(
    final Map<String, ContributedRepository> repoMap,
    final List<ContributedRepository> repos,
    final ContributedRepository Function(
      ContributedRepository existing,
      ContributedRepository repo,
    )
    merge,
  ) {
    for (final ContributedRepository repo in repos) {
      final String url = repo.url;
      if (repoMap.containsKey(url)) {
        repoMap[url] = merge(repoMap[url]!, repo);
      } else {
        repoMap[url] = repo;
      }
    }
  }

  static ContributedRepository _mergeReviewInto(
    final ContributedRepository existing,
    final ContributedRepository repo,
  ) => ContributedRepository(
    graphQLRepository: existing.graphQLRepository,
    contributionCount: existing.contributionCount + repo.contributionCount,
    commitCount: existing.commitCount ?? existing.contributionCount,
    reviewCount: repo.reviewCount ?? repo.contributionCount,
    issueCount: existing.issueCount,
    pullRequestCount: existing.pullRequestCount,
  );

  static ContributedRepository _mergeIssueInto(
    final ContributedRepository existing,
    final ContributedRepository repo,
  ) => ContributedRepository(
    graphQLRepository: existing.graphQLRepository,
    contributionCount: existing.contributionCount + repo.contributionCount,
    commitCount: existing.commitCount,
    reviewCount: existing.reviewCount,
    issueCount: (existing.issueCount ?? 0) + (repo.issueCount ?? 0),
    pullRequestCount: existing.pullRequestCount,
  );

  static ContributedRepository _mergePullRequestInto(
    final ContributedRepository existing,
    final ContributedRepository repo,
  ) => ContributedRepository(
    graphQLRepository: existing.graphQLRepository,
    contributionCount: existing.contributionCount + repo.contributionCount,
    commitCount: existing.commitCount,
    reviewCount: existing.reviewCount,
    issueCount: existing.issueCount,
    pullRequestCount:
        (existing.pullRequestCount ?? 0) + (repo.pullRequestCount ?? 0),
  );

  static ContributedRepository _mergeCommitInto(
    final ContributedRepository existing,
    final ContributedRepository repo,
  ) => ContributedRepository(
    graphQLRepository: existing.graphQLRepository,
    contributionCount: existing.contributionCount + repo.contributionCount,
    commitCount:
        (existing.commitCount ?? existing.contributionCount) +
        repo.contributionCount,
    reviewCount: existing.reviewCount,
    issueCount: existing.issueCount,
    pullRequestCount: existing.pullRequestCount,
  );

  /// Fetch contributions for the given query key.
  /// Returns a unified collection result with both flattened data and per-year highlights.
  Future<ContributionCollectionResult> fetchContributions(
    final ContributionQueryKey key,
  ) async {
    if (kDebugMode) {
      DateTime.now().millisecondsSinceEpoch;
    }
    var (DateTime from, DateTime to) = key.dateRange.dates;

    // Clamp dates to today to prevent future date queries
    final DateTime today = DateTime.now();
    final DateTime todayNormalized = DateTime(
      today.year,
      today.month,
      today.day,
    );
    if (to.isAfter(todayNormalized)) {
      to = todayNormalized;
    }
    if (from.isAfter(todayNormalized)) {
      from = todayNormalized;
    }

    // Check if this is a multi-year range
    // Use actual day difference instead of year subtraction to correctly handle
    // "last year" queries that span two calendar years but are only 365 days
    final int daysDiff = to
        .difference(from)
        .inDays; // If the range is 366 days or less, treat it as single-year
    // (366 accounts for leap years; most years are 365 days)
    if (daysDiff <= 366) {
      // Single year - fetch and convert to view model
      final Query$userContributions$user result = await _fetchContributionsGql(
        from: from,
        to: to,
      );
      final ContributionCollectionResult viewModel =
          _convertSingleYearToViewModel(result);
      return viewModel;
    }

    // Multi-year range: fetch each year in parallel with error handling
    final List<Future<Query$userContributions$user?>> yearQueries =
        <Future<Query$userContributions$user?>>[];
    for (int year = from.year; year <= to.year; year++) {
      DateTime yearStart = year == from.year
          ? DateTime(year, from.month, from.day)
          : DateTime(year);
      DateTime yearEnd = year == to.year
          ? DateTime(year, to.month, to.day)
          : DateTime(year, 12, 31);

      // Clamp year dates to today
      if (yearEnd.isAfter(todayNormalized)) {
        yearEnd = todayNormalized;
      }
      if (yearStart.isAfter(todayNormalized)) {
        yearStart = todayNormalized;
      } // Wrap each query in error handling to prevent one failure from failing all
      yearQueries.add(_fetchContributionsGql(from: yearStart, to: yearEnd));
    }

    // Fetch all years in parallel (with graceful error handling)
    final List<Query$userContributions$user?> results = await Future.wait(
      yearQueries,
    );

    // Filter out null results (failed years)
    final List<Query$userContributions$user> successfulResults = results
        .whereType<Query$userContributions$user>()
        .toList();

    if (successfulResults.isEmpty) {
      throw Exception('All year queries failed for user "${ref.login}"');
    }

    if (successfulResults.length <
        results.length) {} // Combine results into unified view model
    final ContributionCollectionResult combined = _combineMultiYearResults(
      successfulResults,
    );
    return combined;
  }

  /// Tool-friendly entry point: year, or from/to date range, for this user. Replaces hand-written get_user_contributions.
  @Lens(
    'get_user_contributions',
    'Get contribution calendar and stats for a user. Can fetch by year or custom date range. Defaults to last year if no params provided.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<ContributionCollectionResult> getContributionsForTool({
    @Desc('Year for contributions') final int? year,
    @Desc('Start date (ISO 8601)') final String? from,
    @Desc('End date (ISO 8601)') final String? to,
  }) async {
    final ContributionQueryKey key;
    if (year != null) {
      key = ContributionQueryKey.year(ref.login, year);
    } else if (from != null && to != null) {
      final fromDate = DateTime.tryParse(from);
      final toDate = DateTime.tryParse(to);
      key = (fromDate != null && toDate != null)
          ? ContributionQueryKey.customRange(
              userName: ref.login,
              from: fromDate,
              to: toDate,
            )
          : ContributionQueryKey.lastYear(ref.login);
    } else {
      key = ContributionQueryKey.lastYear(ref.login);
    }
    return fetchContributions(key);
  }

  /// Convert single-year GraphQL data to unified collection result
  static ContributionCollectionResult _convertSingleYearToViewModel(
    final Query$userContributions$user data,
  ) {
    final Query$userContributions$user$contributionsCollection collection =
        data.contributionsCollection;

    // Build flattened view model
    final ContributionViewModel viewModel = ContributionViewModel(
      weeks: ContributionDataConverter.convertWeeks(
        collection.contributionCalendar.weeks.toList(),
      ),
      colors: ContributionDataConverter.convertColors(
        collection.contributionCalendar.colors.toList(),
      ),
      totalContributions: collection.contributionCalendar.totalContributions,
      totalCommitContributions: collection.totalCommitContributions,
      totalPullRequestContributions: collection.totalPullRequestContributions,
      totalIssueContributions: collection.totalIssueContributions,
      totalPullRequestReviewContributions:
          collection.totalPullRequestReviewContributions,
      commitContributionsByRepository:
          ContributionDataConverter.convertRepositories(
            collection.commitContributionsByRepository.toList(),
          ),
      contributionYears: collection.contributionYears.toList(),
    );

    // Merge commit and PR review repositories for Activity Overview
    final List<ContributedRepository> commitRepos =
        viewModel.commitContributionsByRepository;
    final List<ContributedRepository> reviewRepos =
        ContributionDataConverter.convertReviewRepositories(
          collection.pullRequestReviewContributionsByRepository.toList(),
        );
    final List<ContributedRepository> issueRepos =
        ContributionDataConverter.convertIssueRepositories(
          collection.issueContributionsByRepository.toList(),
        );
    final List<ContributedRepository> pullRequestRepos =
        ContributionDataConverter.convertPullRequestRepositories(
          collection.pullRequestContributionsByRepository.toList(),
        );

    // Merge repositories by URL, tracking commit, review, issue, and PR counts separately
    final Map<String, ContributedRepository> repoMap =
        <String, ContributedRepository>{};
    for (final ContributedRepository repo in commitRepos) {
      repoMap[repo.url] = repo;
    }
    _mergeContributionReposIntoMap(repoMap, reviewRepos, _mergeReviewInto);
    _mergeContributionReposIntoMap(repoMap, issueRepos, _mergeIssueInto);
    _mergeContributionReposIntoMap(
      repoMap,
      pullRequestRepos,
      _mergePullRequestInto,
    );

    final List<ContributedRepository> mergedRepos = repoMap.values.toList()
      ..sort(
        (final ContributedRepository a, final ContributedRepository b) =>
            b.contributionCount.compareTo(a.contributionCount),
      ); // Update viewModel with merged repositories
    final ContributionViewModel updatedViewModel = ContributionViewModel(
      weeks: viewModel.weeks,
      colors: viewModel.colors,
      totalContributions: viewModel.totalContributions,
      totalCommitContributions: viewModel.totalCommitContributions,
      totalPullRequestContributions: viewModel.totalPullRequestContributions,
      totalIssueContributions: viewModel.totalIssueContributions,
      totalPullRequestReviewContributions:
          viewModel.totalPullRequestReviewContributions,
      commitContributionsByRepository: mergedRepos,
      contributionYears: viewModel.contributionYears,
    );

    // Extract calendar months
    final List<ContributionMonth> calendarMonths = collection
        .contributionCalendar
        .months
        .map(
          (
            final Query$userContributions$user$contributionsCollection$contributionCalendar$months
            month,
          ) => ContributionMonth(
            name: month.name,
            year: month.year,
            firstDay: month.firstDay,
            totalWeeks: month.totalWeeks,
          ),
        )
        .toList();

    // Use API dates for accuracy (fallback to week calculation if not available)
    final DateTime startedAt = collection.startedAt;
    final DateTime endedAt = collection.endedAt;

    // Determine year from startedAt
    final int year = startedAt.year;

    final List<
      Query$userContributions$user$contributionsCollection$contributionCalendar$weeks
    >
    weeks = collection.contributionCalendar.weeks.toList();
    final Query$userContributions$user$contributionsCollection$contributionCalendar$weeks?
    firstWeek = weeks.isNotEmpty ? weeks.first : null;
    final Query$userContributions$user$contributionsCollection$contributionCalendar$weeks?
    lastWeek = weeks.isNotEmpty ? weeks.last : null;
    final DateTime fromDate = firstWeek?.firstDay ?? startedAt;
    final DateTime toDate = lastWeek != null
        ? lastWeek.firstDay.add(const Duration(days: 6))
        : endedAt;

    // Extract highlights (requires generated types from build_runner)
    ContributionHighlightItem? firstIssue;
    ContributionHighlightItem? firstPR;
    ContributionHighlightItem? firstRepo;
    ContributionHighlightItem? popularIssue;
    ContributionHighlightItem? popularPR;
    DateTime? joinedGitHub;

    try {
      firstIssue = _extractFromFirstIssue(collection.firstIssueContribution);
      firstPR = _extractFromFirstPR(collection.firstPullRequestContribution);
      firstRepo = _extractFromFirstRepo(collection.firstRepositoryContribution);
      popularIssue = _extractFromPopularIssue(
        collection.popularIssueContribution,
      );
      popularPR = _extractFromPopularPR(
        collection.popularPullRequestContribution,
      );
      joinedGitHub = collection.joinedGitHubContribution?.occurredAt;
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Contribution highlight extraction failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'Contributions',
      );
    }

    // Find most reviewed repository
    ContributionHighlightItem? mostReviewedRepo;
    try {
      final Iterable<
        Query$userContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository
      >
      reviewRepos = collection.pullRequestReviewContributionsByRepository
          .whereType<
            Query$userContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository
          >();
      if (reviewRepos.isNotEmpty) {
        final Query$userContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository
        topRepo = reviewRepos.reduce(
          (
            final Query$userContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository
            a,
            final Query$userContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository
            b,
          ) => a.contributions.totalCount > b.contributions.totalCount ? a : b,
        );
        final repoData = topRepo.repository;
        mostReviewedRepo = ContributionHighlightItem(
          title: repoData.name,
          url: repoData.url.toString(),
          createdAt: startedAt,
          repositoryName: repoData.name,
          repositoryOwner: _getOwnerLogin(repoData.owner),
          type: ContributionHighlightType.repository,
          stargazerCount: repoData.stargazerCount,
          isPrivate: repoData.isPrivate,
          commentCount: topRepo.contributions.totalCount,
          graphQLRepository: repoData,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Most-reviewed repo extraction failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'Contributions',
      );
    }

    // Build yearly highlights for single year
    final YearlyContributionHighlights
    highlights = YearlyContributionHighlights(
      year: year,
      fromDate: fromDate,
      toDate: toDate,
      startedAt: startedAt,
      endedAt: endedAt,
      restrictedContributionsCount: collection.restrictedContributionsCount,
      totalCommitContributions: collection.totalCommitContributions,
      totalIssueContributions: collection.totalIssueContributions,
      totalPullRequestContributions: collection.totalPullRequestContributions,
      totalPullRequestReviewContributions:
          collection.totalPullRequestReviewContributions,
      totalRepositoryContributions: collection.totalRepositoryContributions,
      totalContributions: collection.contributionCalendar.totalContributions,
      totalRepositoriesWithContributedCommits:
          collection.totalRepositoriesWithContributedCommits,
      totalRepositoriesWithContributedIssues:
          collection.totalRepositoriesWithContributedIssues,
      totalRepositoriesWithContributedPullRequests:
          collection.totalRepositoriesWithContributedPullRequests,
      totalRepositoriesWithContributedPullRequestReviews:
          collection.totalRepositoriesWithContributedPullRequestReviews,
      calendarMonths: calendarMonths,
      earliestRestrictedContributionDate:
          collection.earliestRestrictedContributionDate,
      latestRestrictedContributionDate:
          collection.latestRestrictedContributionDate,
      firstIssue: firstIssue,
      firstPullRequest: firstPR,
      firstRepository: firstRepo,
      popularIssue: popularIssue,
      popularPullRequest: popularPR,
      mostReviewedRepository: mostReviewedRepo,
      joinedGitHub: joinedGitHub,
    );
    return ContributionCollectionResult(
      viewModel: updatedViewModel,
      yearlyHighlights: <YearlyContributionHighlights>[highlights],
    );
  }

  /// Combine multiple year results into a single unified collection result
  static ContributionCollectionResult _combineMultiYearResults(
    final List<Query$userContributions$user> results,
  ) {
    if (results.isEmpty) {
      throw Exception('No results to combine');
    }
    // Combine all weeks from all years, preserving the original week structure from API
    // Use a map to track days by date (YYYY-MM-DD) to handle duplicates at year boundaries
    final Map<String, ContributionDay> allDaysMap = <String, ContributionDay>{};
    // Track week first days (as date strings) to preserve week structure and avoid duplicates
    final Set<String> weekFirstDaysSet = <String>{};
    final List<String> weekFirstDaysList = <String>[];

    // Collect per-year highlights (no merging - keep them separate)
    final List<YearlyContributionHighlights> yearlyHighlights =
        <YearlyContributionHighlights>[];

    // Collect all weeks and days from all year results
    for (int resultIndex = 0; resultIndex < results.length; resultIndex++) {
      final Query$userContributions$user result = results[resultIndex];
      final Query$userContributions$user$contributionsCollection collection =
          result.contributionsCollection;
      final Query$userContributions$user$contributionsCollection$contributionCalendar
      calendar = collection.contributionCalendar;
      final Iterable<
        Query$userContributions$user$contributionsCollection$contributionCalendar$weeks
      >
      weeks = calendar.weeks
          .whereType<
            Query$userContributions$user$contributionsCollection$contributionCalendar$weeks
          >(); // Extract per-year highlights (no merging)
      final List<ContributionMonth> calendarMonths = calendar.months
          .map(
            (
              final Query$userContributions$user$contributionsCollection$contributionCalendar$months
              month,
            ) => ContributionMonth(
              name: month.name,
              year: month.year,
              firstDay: month.firstDay,
              totalWeeks: month.totalWeeks,
            ),
          )
          .toList();

      // Use API dates for accuracy (fallback to week calculation if not available)
      final DateTime startedAt = collection.startedAt;
      final DateTime endedAt = collection.endedAt;

      // Determine year from startedAt
      final int year = startedAt.year;

      final Query$userContributions$user$contributionsCollection$contributionCalendar$weeks?
      firstWeek = weeks.isNotEmpty ? weeks.first : null;
      final Query$userContributions$user$contributionsCollection$contributionCalendar$weeks?
      lastWeek = weeks.isNotEmpty ? weeks.lastOrNull : null;
      final DateTime fromDate = firstWeek?.firstDay ?? startedAt;
      final DateTime toDate = lastWeek != null
          ? lastWeek.firstDay.add(const Duration(days: 6))
          : endedAt;

      // Extract highlights (requires generated types from build_runner)
      ContributionHighlightItem? firstIssue;
      ContributionHighlightItem? firstPR;
      ContributionHighlightItem? firstRepo;
      ContributionHighlightItem? popularIssue;
      ContributionHighlightItem? popularPR;
      ContributionHighlightItem? mostReviewedRepo;
      DateTime? joinedGitHub;

      try {
        firstIssue = _extractFromFirstIssue(collection.firstIssueContribution);
        firstPR = _extractFromFirstPR(collection.firstPullRequestContribution);
        firstRepo = _extractFromFirstRepo(
          collection.firstRepositoryContribution,
        );
        popularIssue = _extractFromPopularIssue(
          collection.popularIssueContribution,
        );
        popularPR = _extractFromPopularPR(
          collection.popularPullRequestContribution,
        );
        joinedGitHub = collection.joinedGitHubContribution?.occurredAt;
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Multi-year highlight extraction failed',
          error: e,
          stackTrace: stackTrace,
          tag: 'Contributions',
        );
      }

      // Find most reviewed repository for this year
      try {
        final Iterable<
          Query$userContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository
        >
        reviewRepos = collection.pullRequestReviewContributionsByRepository
            .whereType<
              Query$userContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository
            >();
        if (reviewRepos.isNotEmpty) {
          final Query$userContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository
          topRepo = reviewRepos.reduce(
            (
              final Query$userContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository
              a,
              final Query$userContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository
              b,
            ) =>
                a.contributions.totalCount > b.contributions.totalCount ? a : b,
          );
          final repoData = topRepo.repository;
          mostReviewedRepo = ContributionHighlightItem(
            title: repoData.name,
            url: repoData.url.toString(),
            createdAt: startedAt,
            repositoryName: repoData.name,
            repositoryOwner: _getOwnerLogin(repoData.owner),
            type: ContributionHighlightType.repository,
            stargazerCount: repoData.stargazerCount,
            isPrivate: repoData.isPrivate,
            commentCount: topRepo.contributions.totalCount,
            graphQLRepository: repoData,
          );
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Multi-year most-reviewed repo extraction failed',
          error: e,
          stackTrace: stackTrace,
          tag: 'Contributions',
        );
      }

      yearlyHighlights.add(
        YearlyContributionHighlights(
          year: year,
          fromDate: fromDate,
          toDate: toDate,
          startedAt: startedAt,
          endedAt: endedAt,
          restrictedContributionsCount: collection.restrictedContributionsCount,
          totalCommitContributions: collection.totalCommitContributions,
          totalIssueContributions: collection.totalIssueContributions,
          totalPullRequestContributions:
              collection.totalPullRequestContributions,
          totalPullRequestReviewContributions:
              collection.totalPullRequestReviewContributions,
          totalRepositoryContributions: collection.totalRepositoryContributions,
          totalContributions:
              collection.contributionCalendar.totalContributions,
          totalRepositoriesWithContributedCommits:
              collection.totalRepositoriesWithContributedCommits,
          totalRepositoriesWithContributedIssues:
              collection.totalRepositoriesWithContributedIssues,
          totalRepositoriesWithContributedPullRequests:
              collection.totalRepositoriesWithContributedPullRequests,
          totalRepositoriesWithContributedPullRequestReviews:
              collection.totalRepositoriesWithContributedPullRequestReviews,
          calendarMonths: calendarMonths,
          earliestRestrictedContributionDate:
              collection.earliestRestrictedContributionDate,
          latestRestrictedContributionDate:
              collection.latestRestrictedContributionDate,
          firstIssue: firstIssue,
          firstPullRequest: firstPR,
          firstRepository: firstRepo,
          popularIssue: popularIssue,
          popularPullRequest: popularPR,
          mostReviewedRepository: mostReviewedRepo,
          joinedGitHub: joinedGitHub,
        ),
      );

      for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
        final Query$userContributions$user$contributionsCollection$contributionCalendar$weeks
        week = weeks.elementAt(weekIndex);

        // Get the first day of the week from the API (more reliable than using contributionDays.first)
        final DateTime firstDayDate = DateTime.parse(week.firstDay.toString());
        final String firstDayKey = formatDateOnly(
          firstDayDate,
        ); // Track unique week first days (use set for O(1) lookup, list for ordered output)
        if (!weekFirstDaysSet.contains(firstDayKey)) {
          weekFirstDaysSet.add(firstDayKey);
          weekFirstDaysList.add(firstDayKey);
        } else // Collect all days from this week
          for (final Query$userContributions$user$contributionsCollection$contributionCalendar$weeks$contributionDays
              day
              in week.contributionDays) {
            final DateTime dayDate = DateTime.parse(day.date.toString());
            final String dateKey = formatDateOnly(dayDate);

            // Use the latest data if there's a duplicate (at year boundaries)
            if (!allDaysMap.containsKey(dateKey)) {
              final ContributionDay contributionDay = ContributionDay(
                date: dayDate,
                count: day.contributionCount,
                color: parseContributionColor(day.color),
                level: convertContributionLevel(day.contributionLevel),
              );
              allDaysMap[dateKey] = contributionDay;
            }
          }
      }
    } // Sort week first days chronologically
    weekFirstDaysList.sort(
      (final String a, final String b) => a.compareTo(b),
    ); // Reconstruct weeks preserving the original structure
    // Each week from API starts on the first day and has 7 days
    final List<List<ContributionDay>> allWeeks = <List<ContributionDay>>[];
    for (int weekIndex = 0; weekIndex < weekFirstDaysList.length; weekIndex++) {
      final String firstDayKey = weekFirstDaysList[weekIndex];
      final DateTime firstDayDate = DateTime.parse(firstDayKey);
      final List<ContributionDay> week = <ContributionDay>[];

      // Add 7 days for this week (preserving API structure)
      for (int i = 0; i < 7; i++) {
        final DateTime weekDay = firstDayDate.add(Duration(days: i));
        final String dateKey = formatDateOnly(weekDay);

        // Get day from map or create empty day
        final ContributionDay day =
            allDaysMap[dateKey] ??
            ContributionDay(
              date: weekDay,
              count: 0,
              level: ContributionLevel.none,
            );

        week.add(day);
      }

      allWeeks.add(week);

      if (kDebugMode &&
          (weekIndex < 3 || weekIndex >= weekFirstDaysList.length - 3)) {}
    } // Combine repositories (merge by repository URL, sum contributions)
    final List<ContributedRepository> commitReposAll =
        <ContributedRepository>[];
    final List<ContributedRepository> reviewReposAll =
        <ContributedRepository>[];
    final List<ContributedRepository> issueReposAll = <ContributedRepository>[];
    final List<ContributedRepository> pullRequestReposAll =
        <ContributedRepository>[];
    for (final Query$userContributions$user result in results) {
      final collection = result.contributionsCollection;
      commitReposAll.addAll(
        ContributionDataConverter.convertRepositories(
          collection.commitContributionsByRepository.toList(),
        ),
      );
      reviewReposAll.addAll(
        ContributionDataConverter.convertReviewRepositories(
          collection.pullRequestReviewContributionsByRepository.toList(),
        ),
      );
      issueReposAll.addAll(
        ContributionDataConverter.convertIssueRepositories(
          collection.issueContributionsByRepository.toList(),
        ),
      );
      pullRequestReposAll.addAll(
        ContributionDataConverter.convertPullRequestRepositories(
          collection.pullRequestContributionsByRepository.toList(),
        ),
      );
    }
    final Map<String, ContributedRepository> repoMap =
        <String, ContributedRepository>{};
    for (final ContributedRepository repo in commitReposAll) {
      if (repoMap.containsKey(repo.url)) {
        repoMap[repo.url] = _mergeCommitInto(repoMap[repo.url]!, repo);
      } else {
        repoMap[repo.url] = repo;
      }
    }
    _mergeContributionReposIntoMap(repoMap, reviewReposAll, _mergeReviewInto);
    _mergeContributionReposIntoMap(repoMap, issueReposAll, _mergeIssueInto);
    _mergeContributionReposIntoMap(
      repoMap,
      pullRequestReposAll,
      _mergePullRequestInto,
    );

    // Sort repositories by contribution count (descending)
    final List<ContributedRepository> repositories = repoMap.values.toList()
      ..sort(
        (final ContributedRepository a, final ContributedRepository b) =>
            b.contributionCount.compareTo(a.contributionCount),
      ); // Sum all statistics
    int totalContributions = 0;
    int totalCommits = 0;
    int totalPRs = 0;
    int totalIssues = 0;
    int totalReviews = 0;
    final Set<int> allYears = <int>{};

    for (final Query$userContributions$user result in results) {
      final Query$userContributions$user$contributionsCollection collection =
          result.contributionsCollection;
      totalContributions += collection.contributionCalendar.totalContributions;
      totalCommits += collection.totalCommitContributions;
      totalPRs += collection.totalPullRequestContributions;
      totalIssues += collection.totalIssueContributions;
      totalReviews += collection.totalPullRequestReviewContributions;
      allYears.addAll(collection.contributionYears);
    } // Get colors from the first result (they should be the same)
    final List<Color> colors = parseContributionColors(
      results.first.contributionsCollection.contributionCalendar.colors
          .toList(),
    );

    // Build flattened view model
    final ContributionViewModel viewModel = ContributionViewModel(
      weeks: allWeeks,
      colors: colors,
      totalContributions: totalContributions,
      totalCommitContributions: totalCommits,
      totalPullRequestContributions: totalPRs,
      totalIssueContributions: totalIssues,
      totalPullRequestReviewContributions: totalReviews,
      commitContributionsByRepository: repositories,
      contributionYears: allYears.toList()..sort(),
    );

    // Return combined result with both flattened data and per-year highlights
    return ContributionCollectionResult(
      viewModel: viewModel,
      yearlyHighlights: yearlyHighlights,
    );
  }

  /// Extract highlight contribution from GraphQL union type
  /// NOTE: Requires running `flutter pub run build_runner build` after adding highlight fields to query
  static ContributionHighlightItem? _extractFromFirstIssue(
    final FirstIssueContribution? contribution,
  ) {
    if (contribution == null) return null;
    return contribution.maybeWhen<ContributionHighlightItem?>(
      createdIssueContribution: (final created) {
        final issue = created.issue;
        final createdAt = created.occurredAt;
        return ContributionHighlightItem(
          title: issue.title,
          url: created.url.toString(),
          createdAt: createdAt,
          repositoryName: issue.repository.name,
          repositoryOwner: issue.repository.owner.login,
          type: ContributionHighlightType.issue,
          number: issue.number,
          commentCount: issue.comments.totalCount,
          state: IssueVisualState.fromNames(issue.issueState.name),
          body: issue.body,
          isRestricted: created.isRestricted,
          graphQLIssue: issue,
        );
      },
      restrictedContribution: (final restricted) => ContributionHighlightItem(
        title: 'Private contribution',
        url: '',
        createdAt: restricted.occurredAt,
        repositoryName: '',
        repositoryOwner: '',
        type: ContributionHighlightType.restricted,
        isRestricted: true,
      ),
      orElse: () => null,
    );
  }

  static ContributionHighlightItem? _extractFromFirstPR(
    final FirstPRContribution? contribution,
  ) {
    if (contribution == null) return null;
    return contribution.maybeWhen<ContributionHighlightItem?>(
      createdPullRequestContribution: (final created) {
        final pr = created.pullRequest;
        final createdAt = created.occurredAt;
        return ContributionHighlightItem(
          title: pr.title,
          url: created.url.toString(),
          createdAt: createdAt,
          repositoryName: pr.repository.name,
          repositoryOwner: pr.repository.owner.login,
          type: ContributionHighlightType.pullRequest,
          number: pr.number,
          commentCount: pr.comments.totalCount,
          state: PrVisualState.fromNames(
            pr.pullRequestState.name,
            merged: pr.mergedAt != null,
          ),
          body: pr.body,
          mergedAt: pr.mergedAt,
          isRestricted: created.isRestricted,
          graphQLPullRequest: pr,
        );
      },
      restrictedContribution: (final restricted) => ContributionHighlightItem(
        title: 'Private contribution',
        url: '',
        createdAt: restricted.occurredAt,
        repositoryName: '',
        repositoryOwner: '',
        type: ContributionHighlightType.restricted,
        isRestricted: true,
      ),
      orElse: () => null,
    );
  }

  static ContributionHighlightItem? _extractFromFirstRepo(
    final FirstRepoContribution? contribution,
  ) {
    if (contribution == null) return null;
    return contribution.maybeWhen<ContributionHighlightItem?>(
      createdRepositoryContribution: (final created) {
        final repo = created.repository;
        final createdAt = created.occurredAt;
        return ContributionHighlightItem(
          title: repo.name,
          url: created.url.toString(),
          createdAt: createdAt,
          repositoryName: repo.name,
          repositoryOwner: _getOwnerLogin(repo.owner),
          type: ContributionHighlightType.repository,
          stargazerCount: repo.stargazerCount,
          isPrivate: repo.isPrivate,
          isRestricted: created.isRestricted,
          graphQLRepository: repo,
        );
      },
      restrictedContribution: (final restricted) => ContributionHighlightItem(
        title: 'Private contribution',
        url: '',
        createdAt: restricted.occurredAt,
        repositoryName: '',
        repositoryOwner: '',
        type: ContributionHighlightType.restricted,
        isRestricted: true,
      ),
      orElse: () => null,
    );
  }

  static ContributionHighlightItem? _extractFromPopularIssue(
    final PopularIssueContribution? contribution,
  ) {
    if (contribution == null) return null;
    final issue = contribution.issue;
    return ContributionHighlightItem(
      title: issue.title,
      url: issue.url.toString(),
      createdAt: contribution.occurredAt,
      repositoryName: issue.repository.name,
      repositoryOwner: issue.repository.owner.login,
      type: ContributionHighlightType.issue,
      number: issue.number,
      commentCount: issue.comments.totalCount,
      state: IssueVisualState.fromNames(issue.issueState.name),
      body: issue.body,
      isRestricted: contribution.isRestricted,
      graphQLIssue: issue,
    );
  }

  static ContributionHighlightItem? _extractFromPopularPR(
    final PopularPRContribution? contribution,
  ) {
    if (contribution == null) return null;
    final pr = contribution.pullRequest;
    return ContributionHighlightItem(
      title: pr.title,
      url: pr.url.toString(),
      createdAt: contribution.occurredAt,
      repositoryName: pr.repository.name,
      repositoryOwner: pr.repository.owner.login,
      type: ContributionHighlightType.pullRequest,
      number: pr.number,
      commentCount: pr.comments.totalCount,
      state: PrVisualState.fromNames(
        pr.pullRequestState.name,
        merged: pr.mergedAt != null,
      ),
      body: pr.body,
      mergedAt: pr.mergedAt,
      isRestricted: contribution.isRestricted,
      graphQLPullRequest: pr,
    );
  }
}
