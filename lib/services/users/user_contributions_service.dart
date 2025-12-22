// ignore_for_file: avoid_classes_with_only_static_members

import 'package:diohub/app/global.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_contributions.data.gql.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/view/profile/about/widgets/activity_overview_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_data_converter.dart';
import 'package:flutter/foundation.dart';

/// Service for fetching and aggregating user contribution data.
/// Handles both single-year and multi-year queries, always returning a unified ContributionCollectionResult.
class UserContributionsService {
  /// Fetch contributions for the given query key.
  /// Returns a unified collection result with both flattened data and per-year highlights.
  static Future<ContributionCollectionResult> fetchContributions(
    ContributionQueryKey key,
  ) async {
    try {
      final (from, to) = key.dateRange.dates;

      // Check if this is a multi-year range
      final yearsDiff = (to.year - from.year) + 1;

      if (yearsDiff <= 1) {
        // Single year - fetch and convert to view model
        final result = await UserInfoService.getUserContributions(
          key.userName,
          from: from,
          to: to,
        );
        return _convertSingleYearToViewModel(result);
      }

      // Multi-year range: fetch each year in parallel
      final yearQueries = <Future<GuserContributionsData_user>>[];

      for (int year = from.year; year <= to.year; year++) {
        final yearStart = year == from.year
            ? DateTime(year, from.month, from.day)
            : DateTime(year, 1, 1);
        final yearEnd = year == to.year
            ? DateTime(year, to.month, to.day)
            : DateTime(year, 12, 31);

        yearQueries.add(
          UserInfoService.getUserContributions(
            key.userName,
            from: yearStart,
            to: yearEnd,
          ),
        );
      }

      // Fetch all years in parallel
      final results = await Future.wait(yearQueries, eagerError: true);

      // Combine results into unified view model
      return _combineMultiYearResults(results);
    } catch (e, stackTrace) {
      log.e('Error fetching user contributions',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Convert single-year GraphQL data to unified collection result
  static ContributionCollectionResult _convertSingleYearToViewModel(
    GuserContributionsData_user data,
  ) {
    final collection = data.contributionsCollection;

    // Build flattened view model
    final viewModel = ContributionViewModel(
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

    // Extract calendar months
    final calendarMonths = collection.contributionCalendar.months
        .map((month) => ContributionMonth(
              name: month.name,
              year: month.year,
              firstDay: month.firstDay,
              totalWeeks: month.totalWeeks,
            ))
        .toList();

    // Determine year from the weeks
    final weeks = collection.contributionCalendar.weeks.toList();
    final firstWeek = weeks.isNotEmpty ? weeks.first : null;
    final lastWeek = weeks.isNotEmpty ? weeks.last : null;
    final fromDate = firstWeek?.firstDay ?? DateTime.now();
    final toDate = lastWeek != null
        ? lastWeek.firstDay.add(const Duration(days: 6))
        : DateTime.now();
    final year = fromDate.year;

    // Extract highlights (requires generated types from build_runner)
    ContributionHighlightItem? firstIssue;
    ContributionHighlightItem? firstPR;
    ContributionHighlightItem? firstRepo;
    ContributionHighlightItem? popularIssue;
    ContributionHighlightItem? popularPR;
    DateTime? joinedGitHub;

    try {
      firstIssue = _extractHighlightItem(
        contribution: collection.firstIssueContribution,
        type: 'issue',
      );
      firstPR = _extractHighlightItem(
        contribution: collection.firstPullRequestContribution,
        type: 'pullRequest',
      );
      firstRepo = _extractHighlightItem(
        contribution: collection.firstRepositoryContribution,
        type: 'repository',
      );
      popularIssue = _extractHighlightItem(
        contribution: collection.popularIssueContribution,
        type: 'issue',
      );
      popularPR = _extractHighlightItem(
        contribution: collection.popularPullRequestContribution,
        type: 'pullRequest',
      );
      joinedGitHub = collection.joinedGitHubContribution?.occurredAt;
    } catch (e) {
      if (kDebugMode) {
        log.w('Error extracting highlights (run build_runner if types missing)',
            error: e);
      }
    }

    // Build yearly highlights for single year
    final highlights = YearlyContributionHighlights(
      year: year,
      fromDate: fromDate,
      toDate: toDate,
      restrictedContributionsCount: collection.restrictedContributionsCount,
      totalRepositoriesWithContributedCommits:
          collection.totalRepositoriesWithContributedCommits,
      totalRepositoriesWithContributedIssues:
          collection.totalRepositoriesWithContributedIssues,
      totalRepositoriesWithContributedPullRequests:
          collection.totalRepositoriesWithContributedPullRequests,
      calendarMonths: calendarMonths,
      firstIssue: firstIssue,
      firstPullRequest: firstPR,
      firstRepository: firstRepo,
      popularIssue: popularIssue,
      popularPullRequest: popularPR,
      joinedGitHub: joinedGitHub,
    );

    return ContributionCollectionResult(
      viewModel: viewModel,
      yearlyHighlights: [highlights],
    );
  }

  /// Combine multiple year results into a single unified collection result
  static ContributionCollectionResult _combineMultiYearResults(
    List<GuserContributionsData_user> results,
  ) {
    if (results.isEmpty) {
      throw Exception('No results to combine');
    }

    if (kDebugMode) {
      log.d(
          '[_combineMultiYearResults] Starting to combine ${results.length} year results');
    }

    // Combine all weeks from all years, preserving the original week structure from API
    // Use a map to track days by date (YYYY-MM-DD) to handle duplicates at year boundaries
    final allDaysMap = <String, ContributionDay>{};
    // Track week first days (as date strings) to preserve week structure and avoid duplicates
    final weekFirstDaysSet = <String>{};
    final weekFirstDaysList = <String>[];

    // Collect per-year highlights (no merging - keep them separate)
    final yearlyHighlights = <YearlyContributionHighlights>[];

    // Collect all weeks and days from all year results
    for (int resultIndex = 0; resultIndex < results.length; resultIndex++) {
      final result = results[resultIndex];
      final collection = result.contributionsCollection;
      final calendar = collection.contributionCalendar;
      final weeks = calendar.weeks.whereType<
          GuserContributionsData_user_contributionsCollection_contributionCalendar_weeks>();

      if (kDebugMode) {
        log.d(
            '[_combineMultiYearResults] Result $resultIndex: Found ${weeks.length} weeks');
      }

      // Extract per-year highlights (no merging)
      final calendarMonths = calendar.months
          .map((month) => ContributionMonth(
                name: month.name,
                year: month.year,
                firstDay: month.firstDay,
                totalWeeks: month.totalWeeks,
              ))
          .toList();

      final firstWeek = weeks.isNotEmpty ? weeks.first : null;
      final lastWeek = weeks.isNotEmpty ? weeks.lastOrNull : null;
      final fromDate = firstWeek?.firstDay ?? DateTime.now();
      final toDate = lastWeek != null
          ? lastWeek.firstDay.add(const Duration(days: 6))
          : DateTime.now();
      final year = fromDate.year;

      // Extract highlights (requires generated types from build_runner)
      ContributionHighlightItem? firstIssue;
      ContributionHighlightItem? firstPR;
      ContributionHighlightItem? firstRepo;
      ContributionHighlightItem? popularIssue;
      ContributionHighlightItem? popularPR;
      DateTime? joinedGitHub;

      try {
        firstIssue = _extractHighlightItem(
          contribution: collection.firstIssueContribution,
          type: 'issue',
        );
        firstPR = _extractHighlightItem(
          contribution: collection.firstPullRequestContribution,
          type: 'pullRequest',
        );
        firstRepo = _extractHighlightItem(
          contribution: collection.firstRepositoryContribution,
          type: 'repository',
        );
        popularIssue = _extractHighlightItem(
          contribution: collection.popularIssueContribution,
          type: 'issue',
        );
        popularPR = _extractHighlightItem(
          contribution: collection.popularPullRequestContribution,
          type: 'pullRequest',
        );
        joinedGitHub = collection.joinedGitHubContribution?.occurredAt;
      } catch (e) {
        if (kDebugMode) {
          log.w(
              'Error extracting highlights (run build_runner if types missing)',
              error: e);
        }
      }

      yearlyHighlights.add(YearlyContributionHighlights(
        year: year,
        fromDate: fromDate,
        toDate: toDate,
        restrictedContributionsCount: collection.restrictedContributionsCount,
        totalRepositoriesWithContributedCommits:
            collection.totalRepositoriesWithContributedCommits,
        totalRepositoriesWithContributedIssues:
            collection.totalRepositoriesWithContributedIssues,
        totalRepositoriesWithContributedPullRequests:
            collection.totalRepositoriesWithContributedPullRequests,
        calendarMonths: calendarMonths,
        firstIssue: firstIssue,
        firstPullRequest: firstPR,
        firstRepository: firstRepo,
        popularIssue: popularIssue,
        popularPullRequest: popularPR,
        joinedGitHub: joinedGitHub,
      ));

      for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
        final week = weeks.elementAt(weekIndex);

        // Get the first day of the week from the API (more reliable than using contributionDays.first)
        final firstDayDate = DateTime.parse(week.firstDay.toString());
        final firstDayKey = formatDateOnly(firstDayDate);

        if (kDebugMode) {
          log.d(
              '[_combineMultiYearResults] Result $resultIndex, Week $weekIndex: firstDay=$firstDayKey, days=${week.contributionDays.length}');
        }

        // Track unique week first days (use set for O(1) lookup, list for ordered output)
        if (!weekFirstDaysSet.contains(firstDayKey)) {
          weekFirstDaysSet.add(firstDayKey);
          weekFirstDaysList.add(firstDayKey);
          if (kDebugMode) {
            log.d(
                '[_combineMultiYearResults] Added new week: $firstDayKey (total unique weeks: ${weekFirstDaysList.length})');
          }
        } else if (kDebugMode) {
          log.d(
              '[_combineMultiYearResults] Skipped duplicate week: $firstDayKey');
        }

        // Collect all days from this week
        for (final day in week.contributionDays) {
          final dayDate = DateTime.parse(day.date.toString());
          final dateKey = formatDateOnly(dayDate);

          // Use the latest data if there's a duplicate (at year boundaries)
          if (!allDaysMap.containsKey(dateKey)) {
            final contributionDay = ContributionDay(
              date: dayDate,
              count: day.contributionCount,
              color: parseContributionColor(day.color),
              level: convertContributionLevel(day.contributionLevel),
            );
            allDaysMap[dateKey] = contributionDay;
          }
        }
      }
    }

    if (kDebugMode) {
      log.d(
          '[_combineMultiYearResults] Collected ${allDaysMap.length} unique days');
      log.d(
          '[_combineMultiYearResults] Collected ${weekFirstDaysList.length} unique week first days');
    }

    // Sort week first days chronologically
    weekFirstDaysList.sort((a, b) => a.compareTo(b));
    if (kDebugMode) {
      log.d(
          '[_combineMultiYearResults] Sorted weeks. First week: ${weekFirstDaysList.firstOrNull}, Last week: ${weekFirstDaysList.lastOrNull}');
    }

    // Reconstruct weeks preserving the original structure
    // Each week from API starts on the first day and has 7 days
    final allWeeks = <List<ContributionDay>>[];
    for (int weekIndex = 0; weekIndex < weekFirstDaysList.length; weekIndex++) {
      final firstDayKey = weekFirstDaysList[weekIndex];
      final firstDayDate = DateTime.parse(firstDayKey);
      final week = <ContributionDay>[];

      // Add 7 days for this week (preserving API structure)
      for (int i = 0; i < 7; i++) {
        final weekDay = firstDayDate.add(Duration(days: i));
        final dateKey = formatDateOnly(weekDay);

        // Get day from map or create empty day
        final day = allDaysMap[dateKey] ??
            ContributionDay(
              date: weekDay,
              count: 0,
              color: null,
              level: ContributionLevel.none,
            );

        week.add(day);
      }

      allWeeks.add(week);

      if (kDebugMode &&
          (weekIndex < 3 || weekIndex >= weekFirstDaysList.length - 3)) {
        log.d(
            '[_combineMultiYearResults] Reconstructed week $weekIndex: firstDay=$firstDayKey, days=${week.length}');
      }
    }

    if (kDebugMode) {
      log.d(
          '[_combineMultiYearResults] Final result: ${allWeeks.length} weeks, ${allDaysMap.length} unique days');
    }

    // Combine repositories (merge by repository URL, sum contributions)
    final repoMap = <String, ContributedRepository>{};

    for (final result in results) {
      final repos = result
          .contributionsCollection.commitContributionsByRepository
          .whereType<
              GuserContributionsData_user_contributionsCollection_commitContributionsByRepository>();

      for (final repo in repos) {
        final repoData = repo.repository;
        final url = repoData.url.toString();
        final owner = repoData.owner.login;
        final primaryLang = repoData.primaryLanguage;

        if (repoMap.containsKey(url)) {
          // Sum contributions for existing repo
          final existing = repoMap[url]!;
          repoMap[url] = ContributedRepository(
            name: existing.name,
            owner: existing.owner,
            url: existing.url,
            contributionCount:
                existing.contributionCount + repo.contributions.totalCount,
            description: existing.description,
            language: existing.language,
            languageColor: existing.languageColor,
            stargazersCount: existing.stargazersCount,
            isPrivate: existing.isPrivate,
            isFork: existing.isFork,
          );
        } else {
          // Add new repo
          repoMap[url] = ContributedRepository(
            name: repoData.name,
            owner: owner,
            url: url,
            contributionCount: repo.contributions.totalCount,
            description: repoData.description,
            language: primaryLang?.name,
            languageColor: primaryLang?.color,
            stargazersCount: repoData.stargazerCount,
            isPrivate: repoData.isPrivate,
            isFork: repoData.isFork,
          );
        }
      }
    }

    // Sort repositories by contribution count (descending)
    final repositories = repoMap.values.toList()
      ..sort((a, b) => b.contributionCount.compareTo(a.contributionCount));

    // Sum all statistics
    int totalContributions = 0;
    int totalCommits = 0;
    int totalPRs = 0;
    int totalIssues = 0;
    int totalReviews = 0;
    final allYears = <int>{};

    for (final result in results) {
      final collection = result.contributionsCollection;
      totalContributions += collection.contributionCalendar.totalContributions;
      totalCommits += collection.totalCommitContributions;
      totalPRs += collection.totalPullRequestContributions;
      totalIssues += collection.totalIssueContributions;
      totalReviews += collection.totalPullRequestReviewContributions;
      allYears.addAll(collection.contributionYears);
    }

    // Get colors from the first result (they should be the same)
    final colors = parseContributionColors(
      results.first.contributionsCollection.contributionCalendar.colors
          .toList(),
    );

    // Build flattened view model
    final viewModel = ContributionViewModel(
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
  static ContributionHighlightItem? _extractHighlightItem({
    required dynamic contribution,
    required String type,
  }) {
    if (contribution == null) return null;

    try {
      // Check for restricted contribution
      final typename = contribution.G__typename;
      if (typename == 'RestrictedContribution') {
        return ContributionHighlightItem(
          title: 'Private contribution',
          url: '',
          createdAt: contribution.occurredAt ?? DateTime.now(),
          repositoryName: '',
          repositoryOwner: '',
          type: ContributionHighlightType.restricted,
          isRestricted: true,
        );
      }

      // Extract based on type
      if (type == 'issue') {
        final issue = contribution.issue;
        if (issue == null) return null;
        return ContributionHighlightItem(
          title: issue.title ?? '',
          url: issue.url?.toString() ?? '',
          createdAt: issue.createdAt,
          repositoryName: issue.repository?.name ?? '',
          repositoryOwner: issue.repository?.owner?.login ?? '',
          type: ContributionHighlightType.issue,
          number: issue.number,
          commentCount: issue.comments?.totalCount,
          state: issue.state?.name ?? 'OPEN',
          body: issue.body,
        );
      } else if (type == 'pullRequest') {
        final pr = contribution.pullRequest;
        if (pr == null) return null;
        return ContributionHighlightItem(
          title: pr.title ?? '',
          url: pr.url?.toString() ?? '',
          createdAt: pr.createdAt,
          repositoryName: pr.repository?.name ?? '',
          repositoryOwner: pr.repository?.owner?.login ?? '',
          type: ContributionHighlightType.pullRequest,
          number: pr.number,
          commentCount: pr.comments?.totalCount,
          state: pr.state?.name ?? 'OPEN',
          body: pr.body,
          mergedAt: pr.mergedAt,
        );
      } else if (type == 'repository') {
        final repo = contribution.repository;
        if (repo == null) return null;
        return ContributionHighlightItem(
          title: repo.name,
          url: repo.url?.toString() ?? '',
          createdAt: repo.createdAt,
          repositoryName: repo.name,
          repositoryOwner: repo.owner?.login ?? '',
          type: ContributionHighlightType.repository,
          stargazerCount: repo.stargazerCount,
          isPrivate: repo.isPrivate ?? false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        log.e('Error extracting highlight item', error: e);
      }
    }

    return null;
  }
}
