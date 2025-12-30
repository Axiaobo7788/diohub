// ignore_for_file: avoid_classes_with_only_static_members

import 'package:diohub/app/global.dart';
import 'package:diohub/common/charts/contribution_calendar_widget.dart';
import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_contributions.data.gql.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
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
    if (kDebugMode) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
    }
    try {
      var (from, to) = key.dateRange.dates;

      // Clamp dates to today to prevent future date queries
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);
      if (to.isAfter(todayNormalized)) {
        to = todayNormalized;
      }
      if (from.isAfter(todayNormalized)) {
        from = todayNormalized;
      }

      // Check if this is a multi-year range
      // Use actual day difference instead of year subtraction to correctly handle
      // "last year" queries that span two calendar years but are only 365 days
      final daysDiff = to
          .difference(from)
          .inDays; // If the range is 366 days or less, treat it as single-year
      // (366 accounts for leap years; most years are 365 days)
      if (daysDiff <= 366) {
        // Single year - fetch and convert to view model
        final result = await UserInfoService.getUserContributions(
          key.userName,
          from: from,
          to: to,
        );
        final viewModel = _convertSingleYearToViewModel(result);
        return viewModel;
      }

      // Multi-year range: fetch each year in parallel with error handling
      final yearQueries = <Future<GuserContributionsData_user?>>[];
      final yearCount = to.year - from.year + 1;
      for (int year = from.year; year <= to.year; year++) {
        var yearStart = year == from.year
            ? DateTime(year, from.month, from.day)
            : DateTime(year, 1, 1);
        var yearEnd = year == to.year
            ? DateTime(year, to.month, to.day)
            : DateTime(year, 12, 31);

        // Clamp year dates to today
        if (yearEnd.isAfter(todayNormalized)) {
          yearEnd = todayNormalized;
        }
        if (yearStart.isAfter(todayNormalized)) {
          yearStart = todayNormalized;
        } // Wrap each query in error handling to prevent one failure from failing all
        yearQueries.add(
          UserInfoService.getUserContributions(
            key.userName,
            from: yearStart,
            to: yearEnd,
          ),
        );
      }

      // Fetch all years in parallel (with graceful error handling)
      final results = await Future.wait(yearQueries, eagerError: false);

      // Filter out null results (failed years)
      final successfulResults =
          results.whereType<GuserContributionsData_user>().toList();

      if (successfulResults.isEmpty) {
        throw Exception('All year queries failed for user "${key.userName}"');
      }

      if (successfulResults.length < results.length) {
        final failedCount = results.length - successfulResults.length;
      } // Combine results into unified view model
      final combined = _combineMultiYearResults(successfulResults);
      return combined;
    } catch (e, stackTrace) {
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

    // Merge commit and PR review repositories for Activity Overview
    final commitRepos = viewModel.commitContributionsByRepository;
    final reviewRepos = ContributionDataConverter.convertReviewRepositories(
      collection.pullRequestReviewContributionsByRepository.toList(),
    );
    final issueRepos = ContributionDataConverter.convertIssueRepositories(
      collection.issueContributionsByRepository.toList(),
    );
    final pullRequestRepos =
        ContributionDataConverter.convertPullRequestRepositories(
      collection.pullRequestContributionsByRepository.toList(),
    );

    // Merge repositories by URL, tracking commit, review, issue, and PR counts separately
    // Preserve GraphQL repository objects to avoid data loss
    final repoMap = <String, ContributedRepository>{};
    for (final repo in commitRepos) {
      repoMap[repo.url] = repo;
    }
    for (final repo in reviewRepos) {
      if (repoMap.containsKey(repo.url)) {
        final existing = repoMap[repo.url]!;
        repoMap[repo.url] = ContributedRepository(
          graphQLRepository: existing.graphQLRepository,
          contributionCount:
              existing.contributionCount + repo.contributionCount,
          commitCount: existing.commitCount ?? existing.contributionCount,
          reviewCount: repo.reviewCount ?? repo.contributionCount,
          issueCount: existing.issueCount,
          pullRequestCount: existing.pullRequestCount,
        );
      } else {
        repoMap[repo.url] = repo;
      }
    }
    for (final repo in issueRepos) {
      if (repoMap.containsKey(repo.url)) {
        final existing = repoMap[repo.url]!;
        repoMap[repo.url] = ContributedRepository(
          graphQLRepository: existing.graphQLRepository,
          contributionCount:
              existing.contributionCount + repo.contributionCount,
          commitCount: existing.commitCount,
          reviewCount: existing.reviewCount,
          issueCount: (existing.issueCount ?? 0) + (repo.issueCount ?? 0),
          pullRequestCount: existing.pullRequestCount,
        );
      } else {
        repoMap[repo.url] = repo;
      }
    }
    for (final repo in pullRequestRepos) {
      if (repoMap.containsKey(repo.url)) {
        final existing = repoMap[repo.url]!;
        repoMap[repo.url] = ContributedRepository(
          graphQLRepository: existing.graphQLRepository,
          contributionCount:
              existing.contributionCount + repo.contributionCount,
          commitCount: existing.commitCount,
          reviewCount: existing.reviewCount,
          issueCount: existing.issueCount,
          pullRequestCount:
              (existing.pullRequestCount ?? 0) + (repo.pullRequestCount ?? 0),
        );
      } else {
        repoMap[repo.url] = repo;
      }
    }

    final mergedRepos = repoMap.values.toList()
      ..sort((a, b) => b.contributionCount.compareTo(
          a.contributionCount)); // Update viewModel with merged repositories
    final updatedViewModel = ContributionViewModel(
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
    final calendarMonths = collection.contributionCalendar.months
        .map((month) => ContributionMonth(
              name: month.name,
              year: month.year,
              firstDay: month.firstDay,
              totalWeeks: month.totalWeeks,
            ))
        .toList();

    // Use API dates for accuracy (fallback to week calculation if not available)
    final startedAt = collection.startedAt;
    final endedAt = collection.endedAt;

    // Determine year from startedAt
    final year = startedAt.year;

    // Keep fromDate/toDate for backward compatibility (calculated from weeks)
    final weeks = collection.contributionCalendar.weeks.toList();
    final firstWeek = weeks.isNotEmpty ? weeks.first : null;
    final lastWeek = weeks.isNotEmpty ? weeks.last : null;
    final fromDate = firstWeek?.firstDay ?? startedAt;
    final toDate = lastWeek != null
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
    } catch (e) {}

    // Find most reviewed repository
    ContributionHighlightItem? mostReviewedRepo;
    try {
      final reviewRepos = collection.pullRequestReviewContributionsByRepository
          .whereType<
              GuserContributionsData_user_contributionsCollection_pullRequestReviewContributionsByRepository>();
      if (reviewRepos.isNotEmpty) {
        final topRepo = reviewRepos.reduce((a, b) =>
            a.contributions.totalCount > b.contributions.totalCount ? a : b);
        final repoData = topRepo.repository as GrepositoryFields;
        // Use RepoCardDataModel.fromGraphQL to extract all fields properly
        final cardData = RepoCardDataModel.fromGraphQL(repoData);
        mostReviewedRepo = ContributionHighlightItem(
          title: cardData.name,
          url: cardData.url,
          createdAt:
              startedAt, // repositoryFields fragment doesn't include createdAt
          repositoryName: cardData.name,
          repositoryOwner: repoData.owner.login,
          type: ContributionHighlightType.repository,
          stargazerCount: cardData.stargazersCount,
          isPrivate: cardData.private,
          commentCount: topRepo.contributions.totalCount,
          graphQLRepository: repoData,
        );
      }
    } catch (e) {}

    // Build yearly highlights for single year
    final highlights = YearlyContributionHighlights(
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
          GuserContributionsData_user_contributionsCollection_contributionCalendar_weeks>(); // Extract per-year highlights (no merging)
      final calendarMonths = calendar.months
          .map((month) => ContributionMonth(
                name: month.name,
                year: month.year,
                firstDay: month.firstDay,
                totalWeeks: month.totalWeeks,
              ))
          .toList();

      // Use API dates for accuracy (fallback to week calculation if not available)
      final startedAt = collection.startedAt;
      final endedAt = collection.endedAt;

      // Determine year from startedAt
      final year = startedAt.year;

      // Keep fromDate/toDate for backward compatibility (calculated from weeks)
      final firstWeek = weeks.isNotEmpty ? weeks.first : null;
      final lastWeek = weeks.isNotEmpty ? weeks.lastOrNull : null;
      final fromDate = firstWeek?.firstDay ?? startedAt;
      final toDate = lastWeek != null
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
      } catch (e) {}

      // Find most reviewed repository for this year
      try {
        final reviewRepos =
            collection.pullRequestReviewContributionsByRepository.whereType<
                GuserContributionsData_user_contributionsCollection_pullRequestReviewContributionsByRepository>();
        if (reviewRepos.isNotEmpty) {
          final topRepo = reviewRepos.reduce((a, b) =>
              a.contributions.totalCount > b.contributions.totalCount ? a : b);
          final repoData = topRepo.repository as GrepositoryFields;
          // Use RepoCardDataModel.fromGraphQL to extract all fields properly
          final cardData = RepoCardDataModel.fromGraphQL(repoData);
          mostReviewedRepo = ContributionHighlightItem(
            title: cardData.name,
            url: cardData.url,
            createdAt:
                startedAt, // repositoryFields fragment doesn't include createdAt
            repositoryName: cardData.name,
            repositoryOwner: repoData.owner.login,
            type: ContributionHighlightType.repository,
            stargazerCount: cardData.stargazersCount,
            isPrivate: cardData.private,
            commentCount: topRepo.contributions.totalCount,
            graphQLRepository: repoData,
          );
        }
      } catch (e) {}

      yearlyHighlights.add(YearlyContributionHighlights(
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
      ));

      for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
        final week = weeks.elementAt(weekIndex);

        // Get the first day of the week from the API (more reliable than using contributionDays.first)
        final firstDayDate = DateTime.parse(week.firstDay.toString());
        final firstDayKey = formatDateOnly(
            firstDayDate); // Track unique week first days (use set for O(1) lookup, list for ordered output)
        if (!weekFirstDaysSet.contains(firstDayKey)) {
          weekFirstDaysSet.add(firstDayKey);
          weekFirstDaysList.add(firstDayKey);
        } else // Collect all days from this week
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
    } // Sort week first days chronologically
    weekFirstDaysList.sort((a, b) =>
        a.compareTo(b)); // Reconstruct weeks preserving the original structure
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
          (weekIndex < 3 || weekIndex >= weekFirstDaysList.length - 3)) {}
    } // Combine repositories (merge by repository URL, sum contributions)
    // Use converter methods to preserve GraphQL objects
    final repoMap = <String, ContributedRepository>{};

    // Convert and merge commit repositories
    for (final result in results) {
      final commitRepos = ContributionDataConverter.convertRepositories(
        result.contributionsCollection.commitContributionsByRepository.toList(),
      );
      for (final repo in commitRepos) {
        final url = repo.url;
        if (repoMap.containsKey(url)) {
          final existing = repoMap[url]!;
          repoMap[url] = ContributedRepository(
            graphQLRepository: existing.graphQLRepository,
            contributionCount:
                existing.contributionCount + repo.contributionCount,
            commitCount: (existing.commitCount ?? existing.contributionCount) +
                repo.contributionCount,
            reviewCount: existing.reviewCount,
            issueCount: existing.issueCount,
            pullRequestCount: existing.pullRequestCount,
          );
        } else {
          repoMap[url] = repo;
        }
      }
    }

    // Convert and merge PR review repositories
    for (final result in results) {
      final reviewRepos = ContributionDataConverter.convertReviewRepositories(
        result
            .contributionsCollection.pullRequestReviewContributionsByRepository
            .toList(),
      );
      for (final repo in reviewRepos) {
        final url = repo.url;
        if (repoMap.containsKey(url)) {
          final existing = repoMap[url]!;
          repoMap[url] = ContributedRepository(
            graphQLRepository: existing.graphQLRepository,
            contributionCount:
                existing.contributionCount + repo.contributionCount,
            commitCount: existing.commitCount,
            reviewCount: (existing.reviewCount ?? 0) + (repo.reviewCount ?? 0),
            issueCount: existing.issueCount,
            pullRequestCount: existing.pullRequestCount,
          );
        } else {
          repoMap[url] = repo;
        }
      }
    }

    // Convert and merge issue repositories
    for (final result in results) {
      final issueRepos = ContributionDataConverter.convertIssueRepositories(
        result.contributionsCollection.issueContributionsByRepository.toList(),
      );
      for (final repo in issueRepos) {
        final url = repo.url;
        if (repoMap.containsKey(url)) {
          final existing = repoMap[url]!;
          repoMap[url] = ContributedRepository(
            graphQLRepository: existing.graphQLRepository,
            contributionCount:
                existing.contributionCount + repo.contributionCount,
            commitCount: existing.commitCount,
            reviewCount: existing.reviewCount,
            issueCount: (existing.issueCount ?? 0) + (repo.issueCount ?? 0),
            pullRequestCount: existing.pullRequestCount,
          );
        } else {
          repoMap[url] = repo;
        }
      }
    }

    // Convert and merge pull request repositories
    for (final result in results) {
      final pullRequestRepos =
          ContributionDataConverter.convertPullRequestRepositories(
        result.contributionsCollection.pullRequestContributionsByRepository
            .toList(),
      );
      for (final repo in pullRequestRepos) {
        final url = repo.url;
        if (repoMap.containsKey(url)) {
          final existing = repoMap[url]!;
          repoMap[url] = ContributedRepository(
            graphQLRepository: existing.graphQLRepository,
            contributionCount:
                existing.contributionCount + repo.contributionCount,
            commitCount: existing.commitCount,
            reviewCount: existing.reviewCount,
            issueCount: existing.issueCount,
            pullRequestCount:
                (existing.pullRequestCount ?? 0) + (repo.pullRequestCount ?? 0),
          );
        } else {
          repoMap[url] = repo;
        }
      }
    }

    // Sort repositories by contribution count (descending)
    final repositories = repoMap.values.toList()
      ..sort((a, b) => b.contributionCount
          .compareTo(a.contributionCount)); // Sum all statistics
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
    } // Get colors from the first result (they should be the same)
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
      // Use when() method for type-safe pattern matching on union types
      return contribution.when(
        createdIssueContribution: (created) {
          if (type != 'issue') return null;
          final issue = created.issue;
          if (issue == null) {
            return null;
          }
          // Use occurredAt from contribution wrapper, fallback to issue.createdAt
          final createdAt = created.occurredAt ?? issue.createdAt;
          final item = ContributionHighlightItem(
            title: issue.title ?? '',
            url: created.url.toString(),
            createdAt: createdAt,
            repositoryName: issue.repository?.name ?? '',
            repositoryOwner: issue.repository?.owner?.login ?? '',
            type: ContributionHighlightType.issue,
            number: issue.number,
            commentCount: issue.comments?.totalCount,
            state: issue.state?.name ?? 'OPEN',
            body: issue.body,
            isRestricted: created.isRestricted,
            graphQLIssue: issue,
          );
          return item;
        },
        createdPullRequestContribution: (created) {
          if (type != 'pullRequest') return null;
          final pr = created.pullRequest;
          if (pr == null) {
            return null;
          }
          // Use occurredAt from contribution wrapper, fallback to pr.createdAt
          final createdAt = created.occurredAt ?? pr.createdAt;
          final item = ContributionHighlightItem(
            title: pr.title ?? '',
            url: created.url.toString(),
            createdAt: createdAt,
            repositoryName: pr.repository?.name ?? '',
            repositoryOwner: pr.repository?.owner?.login ?? '',
            type: ContributionHighlightType.pullRequest,
            number: pr.number,
            commentCount: pr.comments?.totalCount,
            state: pr.state?.name ?? 'OPEN',
            body: pr.body,
            mergedAt: pr.mergedAt,
            isRestricted: created.isRestricted,
            graphQLPullRequest: pr,
          );
          return item;
        },
        createdRepositoryContribution: (created) {
          if (type != 'repository') return null;
          final repo = created.repository;
          if (repo == null) return null;
          // Use occurredAt from contribution wrapper, fallback to repo.createdAt
          final createdAt = created.occurredAt ?? repo.createdAt;
          return ContributionHighlightItem(
            title: repo.name,
            url: created.url.toString(),
            createdAt: createdAt,
            repositoryName: repo.name,
            repositoryOwner: repo.owner?.login ?? '',
            type: ContributionHighlightType.repository,
            stargazerCount: repo.stargazerCount,
            isPrivate: repo.isPrivate ?? false,
            isRestricted: created.isRestricted,
            graphQLRepository: repo,
          );
        },
        restrictedContribution: (restricted) {
          return ContributionHighlightItem(
            title: 'Private contribution',
            url: '',
            createdAt: restricted.occurredAt ?? DateTime.now(),
            repositoryName: '',
            repositoryOwner: '',
            type: ContributionHighlightType.restricted,
            isRestricted: true,
          );
        },
        orElse: () {
          return null;
        },
      );
    } catch (e) {}

    return null;
  }
}
