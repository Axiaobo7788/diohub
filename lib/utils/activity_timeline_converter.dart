// ignore_for_file: avoid_classes_with_only_static_members

import 'package:diohub_graphql/fragments/repo_card_fields.graphql.dart';
import 'package:diohub_graphql/queries/users/user_activity_timeline_full.graphql.dart';
import 'package:diohub_models/models/commits/commit_card_data_model.dart';
import 'package:diohub_models/models/activity/activity_timeline_event.dart';

/// Helper class to store repo data with count
/// Stores all available fields from GraphQL for future UI use
class _RepoData {
  _RepoData({
    required this.owner,
    required this.name,
    required this.url,
    this.id,
    this.repoCardFields,
  });
  final String owner;
  final String name;
  final String url;
  final String? id; // Repository ID from GraphQL
  final Fragment$repoCardFields?
      repoCardFields; // Full repository metadata preserved from GraphQL
  int count = 0;
}

/// Converts GraphQL data to timeline events
///
/// This converter transforms raw GraphQL API responses into a unified
/// `ActivityTimelineEvent` format that the UI can consume.
///
/// **Conversion Flow:**
/// 1. Convert each event type (repos, PRs, issues, commits) independently
/// 2. Combine all events into a single list
/// 3. Sort by date (newest first) for consistent timeline display
class ActivityTimelineConverter {
  /// Convert all GraphQL data to timeline events
  ///
  /// **Process:**
  /// 1. Convert repositories → repository creation events
  /// 2. Convert pull requests → PR events
  /// 3. Convert issues → issue events
  /// 4. Convert commits → commit events (grouped by date)
  /// 5. Sort all events by date (newest first)
  static List<ActivityTimelineEvent> convertToEvents(
    final Query$userActivityTimelineFull$user fullData,
  ) {
    final List<ActivityTimelineEvent> events = <ActivityTimelineEvent>[];

    // Convert each event type independently
    events.addAll(_convertRepositories(fullData));
    events.addAll(_convertPullRequests(fullData));
    events.addAll(_convertIssues(fullData));
    events.addAll(_convertReviews(fullData));
    events.addAll(_convertCommits(fullData));

    // Sort events by date (newest first)
    // Required: While each type is sorted by API, we need to merge across types
    // since repos, PRs, issues, and commits may have overlapping dates
    events.sort(
        (final ActivityTimelineEvent a, final ActivityTimelineEvent b) =>
            b.date.compareTo(a.date));

    return events;
  }

  /// Convert repositories to repository creation events
  static List<ActivityTimelineEvent> _convertRepositories(
    final Query$userActivityTimelineFull$user fullData,
  ) {
    final List<ActivityTimelineEvent> events = <ActivityTimelineEvent>[];
    final List<
            Query$userActivityTimelineFull$user$contributionsCollection$repositoryContributions$nodes?>?
        repoContributions =
        fullData.contributionsCollection.repositoryContributions.nodes;

    if (repoContributions == null) return events;

    for (final Query$userActivityTimelineFull$user$contributionsCollection$repositoryContributions$nodes? contribution
        in repoContributions) {
      final Query$userActivityTimelineFull$user$contributionsCollection$repositoryContributions$nodes$repository?
          repo = contribution?.repository;
      if (repo == null) continue;

      final String owner = repo.owner.when(
        organization: (o) => o.login,
        user: (u) => u.login,
        orElse: () => '',
      );
      final String name = repo.name;
      final String url = repo.url.toString();

      events.add(
        ActivityTimelineEvent(
          type: ActivityEventType.repositoryCreated,
          date: contribution!.occurredAt,
          repositoryOwner: owner,
          repositoryName: name,
          repositoryUrl: url,
          repositoryCardFields: repo,
        ),
      );
    }

    return events;
  }

  /// Convert pull requests to PR events
  static List<ActivityTimelineEvent> _convertPullRequests(
    final Query$userActivityTimelineFull$user fullData,
  ) {
    final List<ActivityTimelineEvent> events = <ActivityTimelineEvent>[];
    final List<
            Query$userActivityTimelineFull$user$contributionsCollection$pullRequestContributions$nodes?>?
        contributions =
        fullData.contributionsCollection.pullRequestContributions.nodes;

    if (contributions == null) return events;

    for (final Query$userActivityTimelineFull$user$contributionsCollection$pullRequestContributions$nodes? contribution
        in contributions) {
      final Query$userActivityTimelineFull$user$contributionsCollection$pullRequestContributions$nodes$pullRequest?
          pr = contribution?.pullRequest;
      if (pr == null) continue;

      final String owner = pr.repository.owner.login;
      final String name = pr.repository.name;
      final String url = pr.repository.url.toString();

      events.add(
        ActivityTimelineEvent(
          type: ActivityEventType.pullRequest,
          date: contribution!.occurredAt,
          title: pr.title,
          repositoryOwner: owner,
          repositoryName: name,
          repositoryUrl: url,
          pullRequestData: pr,
        ),
      );
    }

    return events;
  }

  /// Convert issues to issue events
  static List<ActivityTimelineEvent> _convertIssues(
    final Query$userActivityTimelineFull$user fullData,
  ) {
    final List<ActivityTimelineEvent> events = <ActivityTimelineEvent>[];
    final List<
            Query$userActivityTimelineFull$user$contributionsCollection$issueContributions$nodes?>?
        contributions =
        fullData.contributionsCollection.issueContributions.nodes;

    if (contributions == null) return events;

    for (final Query$userActivityTimelineFull$user$contributionsCollection$issueContributions$nodes? contribution
        in contributions) {
      final Query$userActivityTimelineFull$user$contributionsCollection$issueContributions$nodes$issue?
          issue = contribution?.issue;
      if (issue == null) continue;

      final String owner = issue.repository.owner.login;
      final String name = issue.repository.name;
      final String url = issue.repository.url.toString();

      events.add(
        ActivityTimelineEvent(
          type: ActivityEventType.issue,
          date: contribution!.occurredAt,
          title: issue.title,
          repositoryOwner: owner,
          repositoryName: name,
          repositoryUrl: url,
          issueData: issue,
        ),
      );
    }

    return events;
  }

  /// Convert reviews to review events
  static List<ActivityTimelineEvent> _convertReviews(
    final Query$userActivityTimelineFull$user fullData,
  ) {
    final List<ActivityTimelineEvent> events = <ActivityTimelineEvent>[];
    final List<
            Query$userActivityTimelineFull$user$contributionsCollection$pullRequestReviewContributions$nodes?>?
        contributions =
        fullData.contributionsCollection.pullRequestReviewContributions.nodes;

    if (contributions == null) return events;

    for (final Query$userActivityTimelineFull$user$contributionsCollection$pullRequestReviewContributions$nodes? contribution
        in contributions) {
      final Query$userActivityTimelineFull$user$contributionsCollection$pullRequestReviewContributions$nodes$pullRequest?
          pullRequest = contribution?.pullRequest;
      if (pullRequest == null) continue;

      final String owner = pullRequest.repository.owner.login;
      final String name = pullRequest.repository.name;
      final String url = pullRequest.repository.url.toString();

      events.add(
        ActivityTimelineEvent(
          type: ActivityEventType.review,
          date: contribution!.occurredAt,
          title: pullRequest.title,
          repositoryOwner: owner,
          repositoryName: name,
          repositoryUrl: url,
          pullRequestData: pullRequest,
        ),
      );
    }

    return events;
  }

  /// Convert commits to commit events (grouped by date and repository)
  ///
  /// **GitHub API Structure:**
  /// - API returns commits grouped by repository
  /// - Each repository has contributions (date + commit count)
  ///
  /// **Our Transformation:**
  /// - Regroup by date (one event per day)
  /// - Aggregate commits across all repositories for that day
  /// - Store all repository info for UI display
  ///
  /// **Flow:**
  /// 1. **First Pass:** Iterate through repos and contributions
  ///    - Extract repo data (owner, name, url, id) - CAPTURE ALL FIELDS HERE
  ///    - Group contributions by date (YYYY-MM-DD key)
  ///    - Accumulate commit counts per repo per date
  ///    - Store complete repo data to avoid later lookups
  ///
  /// 2. **Second Pass:** Create events for each date
  ///    - Count total commits across all repos for that date
  ///    - Build repository info list (already has all data, no lookups needed)
  ///    - Create one ActivityTimelineEvent per date
  ///
  /// **Example:**
  /// Input: Repo A (Jan 1: 3 commits), Repo B (Jan 1: 2 commits)
  /// Output: One event for Jan 1 with 5 total commits, 2 repositories
  static List<ActivityTimelineEvent> _convertCommits(
    final Query$userActivityTimelineFull$user fullData,
  ) {
    final List<ActivityTimelineEvent> events = <ActivityTimelineEvent>[];
    final List<
            Query$userActivityTimelineFull$user$contributionsCollection$commitContributionsByRepository>
        repos =
        fullData.contributionsCollection.commitContributionsByRepository;

    // Group contributions by date
    // Structure: dateKey -> {repoKey -> _RepoData with count}
    // We store complete repo data here to avoid expensive lookups later
    final Map<String, Map<String, _RepoData>> contributionsByDate =
        <String, Map<String, _RepoData>>{};

    // Iterate through repositories (API groups by repo)
    for (final Query$userActivityTimelineFull$user$contributionsCollection$commitContributionsByRepository repoContributions
        in repos) {
      final Fragment$repoCardFields
          repo = repoContributions.repository;

      // Extract all repo fields ONCE - store for later use (query uses ...repoCardFields)
      final String owner = repo.owner.when(
        organization: (o) => o.login,
        user: (u) => u.login,
        orElse: () => '',
      );
      final String name = repo.name;
      final String repoKey = '$owner/$name'; // Key for grouping
      final String repoUrl = repo.url.toString();
      final String repoId = repo.id; // Store repository ID for future UI use

      final Query$userActivityTimelineFull$user$contributionsCollection$commitContributionsByRepository$contributions
          contributions = repoContributions.contributions;
      if (contributions.nodes == null) continue;

      // Iterate through contributions for this repository
      for (final Query$userActivityTimelineFull$user$contributionsCollection$commitContributionsByRepository$contributions$nodes? contribution
          in contributions.nodes!) {
        if (contribution == null) continue;

        final DateTime occurredAt = contribution.occurredAt;
        final int commitCount = contribution.commitCount;

        // Create date key for grouping (YYYY-MM-DD format)
        final String dateKey = _getDateKey(occurredAt);

        // Ensure date entry exists
        contributionsByDate.putIfAbsent(dateKey, () => <String, _RepoData>{});

        // Ensure repo entry exists for this date, initialize with repo card fields
        contributionsByDate[dateKey]!.putIfAbsent(
          repoKey,
          () => _RepoData(
            owner: owner,
            name: name,
            url: repoUrl,
            id: repoId,
            repoCardFields: repo,
          ),
        );

        // Accumulate commit count for this repo on this date
        contributionsByDate[dateKey]![repoKey]!.count += commitCount;
      }
    }

    // Create events for each date
    // Now we have contributions grouped by date, create one event per date
    for (final MapEntry<String, Map<String, _RepoData>> dateEntry
        in contributionsByDate.entries) {
      final DateTime date = _parseDateKey(dateEntry.key);
      final Map<String, _RepoData> reposForDate = dateEntry.value;

      // Count total commits across all repositories for this date
      int totalCommits = 0;
      for (final _RepoData repoData in reposForDate.values) {
        totalCommits += repoData.count;
      }

      // Get first repository for display header (already has all data, no lookup needed)
      final _RepoData firstRepo = reposForDate.values.first;

      // Build repository info list for commit card display
      // All repo data (owner, name, url, id, full metadata) already stored - no lookups needed
      final List<CommitRepositoryInfo> repoInfos = <CommitRepositoryInfo>[];
      for (final _RepoData r in reposForDate.values) {
        repoInfos.add(
          CommitRepositoryInfo(
            owner: r.owner,
            name: r.name,
            url: r.url,
            id: r.id,
            count: r.count,
            repoCardFields: r.repoCardFields,
          ),
        );
      }

      // Create unified commit data model for the card widget
      final CommitCardDataModel commitData = CommitCardDataModel(
        count: totalCommits,
        date: date,
        repositories: repoInfos,
      );

      // Create timeline event for this date
      events.add(
        ActivityTimelineEvent(
          type: ActivityEventType.commit,
          date: date,
          repositoryOwner: firstRepo.owner,
          repositoryName: firstRepo.name,
          repositoryUrl:
              firstRepo.url, // Already stored in first loop, no lookup needed
          commitData: commitData,
          // Commits are aggregated, so no single GraphQL node to store
        ),
      );
    }

    return events;
  }

  /// Get date key in YYYY-MM-DD format
  static String _getDateKey(final DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Parse date key back to DateTime (start of day)
  static DateTime _parseDateKey(final String dateKey) {
    final List<String> parts = dateKey.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
