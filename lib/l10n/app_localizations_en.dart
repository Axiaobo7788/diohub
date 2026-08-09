// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DioHub';

  @override
  String get languageAndRegion => 'Language & region';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSimplifiedChinese => 'Simplified Chinese';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSignIn => 'Sign in';

  @override
  String get commonShowMore => 'Show more';

  @override
  String get commonNew => 'New';

  @override
  String get commonCode => 'Code';

  @override
  String get commonFilter => 'Filter';

  @override
  String get commonAuto => 'Auto';

  @override
  String get commonFree => 'Free';

  @override
  String get homeDashboard => 'Dashboard';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeSearchGitHub => 'Search GitHub';

  @override
  String get homeSearchRepositories => 'Search GitHub repositories';

  @override
  String get homeSearchRepositoriesHint => 'Owner, repository, topic...';

  @override
  String get homeBackToSearch => 'Back to search';

  @override
  String get homeNotifications => 'Notifications';

  @override
  String get notificationsInbox => 'Inbox';

  @override
  String get notificationsSaved => 'Saved';

  @override
  String get notificationsDone => 'Done';

  @override
  String get notificationsAll => 'All';

  @override
  String get notificationsUnread => 'Unread';

  @override
  String get notificationsSearchHint => 'Search notifications';

  @override
  String get notificationsClearSearch => 'Clear notification search';

  @override
  String notificationsSortLabel(String value) {
    return 'Sort by: $value';
  }

  @override
  String notificationsGroupLabel(String value) {
    return 'Group by: $value';
  }

  @override
  String get notificationsNewestToOldest => 'Newest to oldest';

  @override
  String get notificationsOldestToNewest => 'Oldest to newest';

  @override
  String get notificationsRepository => 'Repository';

  @override
  String get notificationsRepositories => 'Repositories';

  @override
  String get notificationsAllRepositories => 'All repositories';

  @override
  String get notificationsDate => 'Date';

  @override
  String get notificationsDateUnknown => 'Unknown date';

  @override
  String get notificationsRefresh => 'Refresh notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsMarkRead => 'Mark as read';

  @override
  String get notificationsMarkDone => 'Mark as done';

  @override
  String get notificationsSelectAll => 'Select all loaded notifications';

  @override
  String get notificationsClearSelection => 'Clear selection';

  @override
  String notificationsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String notificationsBulkDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications marked as done.',
      one: '1 notification marked as done.',
    );
    return '$_temp0';
  }

  @override
  String notificationsBulkFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications could not be updated.',
      one: '1 notification could not be updated.',
    );
    return '$_temp0';
  }

  @override
  String get notificationsFilters => 'Filters';

  @override
  String get notificationsFilterReasons => 'Reasons';

  @override
  String get notificationsClearFilters => 'Clear filters';

  @override
  String get notificationsAssigned => 'Assigned';

  @override
  String get notificationsParticipating => 'Participating';

  @override
  String get notificationsAuthor => 'Author';

  @override
  String get notificationsComment => 'Comment';

  @override
  String get notificationsInvitation => 'Invitation';

  @override
  String get notificationsFollowing => 'Following';

  @override
  String get notificationsMentioned => 'Mentioned';

  @override
  String get notificationsReviewRequested => 'Review requested';

  @override
  String get notificationsSecurityAlert => 'Security alert';

  @override
  String get notificationsStateChange => 'State change';

  @override
  String get notificationsSubscribed => 'Subscribed';

  @override
  String get notificationsTeamMention => 'Team mention';

  @override
  String get notificationsCiActivity => 'CI activity';

  @override
  String notificationsReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get notificationsCaughtUp => 'You’re all caught up';

  @override
  String get notificationsNoUnread => 'You have no unread notifications.';

  @override
  String get notificationsNoResults =>
      'No notifications match the selected filters.';

  @override
  String get notificationsLoadError => 'Notifications could not be loaded.';

  @override
  String get notificationsUpdateError =>
      'The notification could not be updated.';

  @override
  String get notificationsSignInTitle => 'Sign in to view notifications';

  @override
  String get notificationsSignInBody =>
      'GitHub notifications are private to your account.';

  @override
  String get notificationsOpen => 'Open notification';

  @override
  String get notificationsAddFilter => 'Add new filter';

  @override
  String get notificationsFilterName => 'Filter name';

  @override
  String get notificationsFilterQuery => 'Filter query';

  @override
  String get notificationsSaveFilter => 'Save filter';

  @override
  String get notificationsCleanupTitle => 'Clear out the clutter.';

  @override
  String get notificationsCleanupBody =>
      'Select the read notifications currently loaded so you can mark them as done.';

  @override
  String get notificationsDismiss => 'Dismiss';

  @override
  String get notificationsGetStarted => 'Get started';

  @override
  String notificationsSectionUnavailable(String section) {
    return '$section cannot be listed through the current GitHub API.';
  }

  @override
  String get homeCouldNotOpenLink => 'Could not open the link.';

  @override
  String homeFeatureNotAvailable(String feature) {
    return '$feature is not connected in this phase yet.';
  }

  @override
  String get homeNoSystemBrowser => 'No system browser is available.';

  @override
  String get homeOpenRepositoryOnGitHub => 'Open repository on GitHub';

  @override
  String get homeDirectoryEmpty => 'This directory is empty.';

  @override
  String get homeParentDirectory => 'Parent directory';

  @override
  String get homeBackToDirectory => 'Back to directory';

  @override
  String get homeOpenFileOnGitHub => 'Open file on GitHub';

  @override
  String get homeOpenOnGitHub => 'Open on GitHub';

  @override
  String get homeBrowsingGitHubPublicly => 'Browsing GitHub publicly';

  @override
  String get homePublicBrowsing => 'Public browsing';

  @override
  String get homeAskAnything => 'Ask anything or type @ to add context';

  @override
  String get homeAddContext => 'Add context';

  @override
  String get homeSelectModel => 'Select model';

  @override
  String get homeSendPrompt => 'Send prompt';

  @override
  String get homeAgent => 'Agent';

  @override
  String get homeCreateIssue => 'Create issue';

  @override
  String get homeWriteCode => 'Write code';

  @override
  String get homePullRequests => 'Pull requests';

  @override
  String get homeTopRepositories => 'Top repositories';

  @override
  String get homeTopRepositoriesSignInBody =>
      'Sign in to see repositories you have recently contributed to or created.';

  @override
  String get homeFindRepository => 'Find a repository...';

  @override
  String get homeFindRepositoryTooltip => 'Find a repository';

  @override
  String get homeRepositoriesLoadError => 'Could not load repositories.';

  @override
  String get homeNoRepositoriesFound => 'No repositories found.';

  @override
  String get homeRepositorySearch => 'Repository search';

  @override
  String get homeCloseSearch => 'Close search';

  @override
  String get homeSignInToPersonalizeFeed => 'Sign in to personalize your feed';

  @override
  String get homePublicSearchAvailable =>
      'Public repository search remains available without an account.';

  @override
  String get homeFeed => 'Feed';

  @override
  String get homeRefreshActivity => 'Refresh activity';

  @override
  String get homeActivityNotConnected => 'Activity feed is not connected.';

  @override
  String get homeFollowingAndWatched => 'Following & watched';

  @override
  String get homeSignInToPersonalize => 'Sign in to personalize';

  @override
  String get homeTopRepositoriesUnavailable =>
      'Top repositories are unavailable.';

  @override
  String get navClose => 'Close navigation';

  @override
  String get navAllIssues => 'All issues';

  @override
  String get navAllPullRequests => 'All pull requests';

  @override
  String get navAllRepositories => 'All repositories';

  @override
  String get globalListsSignInTitle => 'Sign in to view your work';

  @override
  String get globalListsSignInDescription =>
      'Issues, pull requests, and repositories associated with your account are available after sign-in.';

  @override
  String get globalListsSignInAction => 'Sign in';

  @override
  String get globalListsAll => 'All';

  @override
  String get globalListsSearchIssues => 'Search your issues';

  @override
  String get globalListsSearchPullRequests => 'Search your pull requests';

  @override
  String get globalListsSearchRepositories => 'Find a repository';

  @override
  String globalListsResultsCount(int count) {
    return '$count results';
  }

  @override
  String get globalListsNoIssues => 'No issues match these filters';

  @override
  String get globalListsNoPullRequests =>
      'No pull requests match these filters';

  @override
  String get globalListsNoRepositories => 'No repositories match these filters';

  @override
  String get globalListsNoResultsDescription =>
      'Try changing the search text or filters.';

  @override
  String globalListsRepositoriesFor(String login) {
    return 'Repositories available to @$login';
  }

  @override
  String globalListsUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String globalListsIssueMetadata(
    String repository,
    int number,
    String action,
    String author,
    String time,
  ) {
    return '$repository #$number $action by $author $time';
  }

  @override
  String get globalListsBestMatch => 'Best match';

  @override
  String get globalListsNewest => 'Newest';

  @override
  String get globalListsOldest => 'Oldest';

  @override
  String get globalListsMostComments => 'Most comments';

  @override
  String get globalListsRecentlyPushed => 'Recently pushed';

  @override
  String get globalListsRecentlyUpdated => 'Recently updated';

  @override
  String get globalListsName => 'Name';

  @override
  String get globalListsMostStars => 'Most stars';

  @override
  String get globalListsMostForks => 'Most forks';

  @override
  String get globalListsMirrors => 'Mirrors';

  @override
  String get globalListsForks => 'Forks';

  @override
  String get globalListsClearFilters => 'Clear filters';

  @override
  String get globalListsRefresh => 'Refresh results';

  @override
  String get globalListsLoadError => 'Could not load results.';

  @override
  String get globalListsNewIssue => 'New issue';

  @override
  String get globalListsNewPullRequest => 'New pull request';

  @override
  String get globalListsSelectRepository => 'Select a repository';

  @override
  String get globalListsChooseIssueTemplate => 'Choose an issue template';

  @override
  String get globalListsBlankIssue => 'Blank issue';

  @override
  String get globalListsCreateFlowError => 'Could not start the create flow.';

  @override
  String get navProjects => 'Projects';

  @override
  String get navDiscussions => 'Discussions';

  @override
  String get navCodespaces => 'Codespaces';

  @override
  String get navCopilot => 'Copilot';

  @override
  String get navExplore => 'Explore';

  @override
  String get navMarketplace => 'Marketplace';

  @override
  String get navMcpRegistry => 'MCP registry';

  @override
  String get accountSwitch => 'Switch account';

  @override
  String get accountSetStatus => 'Set status';

  @override
  String get accountProfile => 'Profile';

  @override
  String get accountRepositories => 'Repositories';

  @override
  String get accountStars => 'Stars';

  @override
  String get accountGists => 'Gists';

  @override
  String get accountOrganizations => 'Organizations';

  @override
  String get accountEnterprises => 'Enterprises';

  @override
  String get accountSponsors => 'Sponsors';

  @override
  String get accountSettings => 'Settings';

  @override
  String get accountCopilotSettings => 'Copilot settings';

  @override
  String get accountFeaturePreview => 'Feature preview';

  @override
  String get accountAppearance => 'Appearance';

  @override
  String get accountAccessibility => 'Accessibility';

  @override
  String get accountTryEnterprise => 'Try Enterprise';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignOutAllTitle => 'Sign out of all accounts?';

  @override
  String get accountSignOutAllBody =>
      'This removes every saved DioHub account and its local access token from this device.';

  @override
  String get profileOverview => 'Overview';

  @override
  String get profileRepositories => 'Repositories';

  @override
  String get profileProjects => 'Projects';

  @override
  String get profilePackages => 'Packages';

  @override
  String get profileStars => 'Stars';

  @override
  String get profileRefresh => 'Refresh profile';

  @override
  String get profileOptions => 'Profile options';

  @override
  String get profileOpenLegacyLayout => 'Open legacy profile';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileFollow => 'Follow';

  @override
  String get profileUnfollow => 'Unfollow';

  @override
  String profileFollowersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count followers',
      one: '1 follower',
    );
    return '$_temp0';
  }

  @override
  String profileFollowingCount(int count) {
    return '$count following';
  }

  @override
  String get profilePinned => 'Pinned';

  @override
  String get profileContributions => 'Contributions';

  @override
  String get profileContributionActivity => 'Contribution activity';

  @override
  String get profileContributionsLoadError => 'Could not load contributions.';

  @override
  String profileLoadError(String login) {
    return 'Could not load $login\'s profile.';
  }

  @override
  String get changelogLatest => 'Latest from our changelog';

  @override
  String get changelogEmpty => 'No changelog entries are available.';

  @override
  String get changelogViewAll => 'View changelog →';

  @override
  String get changelogLoadError => 'Could not load the GitHub changelog.';

  @override
  String get relativeJustNow => 'just now';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get relativeYesterday => 'yesterday';

  @override
  String relativeDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String relativeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String relativeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String relativeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get repoDashboard => 'Dashboard';

  @override
  String get repoRepository => 'Repository';

  @override
  String get repoLegacyView => 'Legacy view';

  @override
  String get repoOpenNavigation => 'Open navigation';

  @override
  String get repoSearchGitHub => 'Search GitHub';

  @override
  String get repoRefreshRepository => 'Refresh repository';

  @override
  String get repoOptions => 'Repository options';

  @override
  String get repoOpenLegacyLayout => 'Open legacy layout';

  @override
  String get repoOpenNewLayout => 'Open new layout';

  @override
  String get repoLoading => 'Loading repository…';

  @override
  String get repoUnavailable => 'Repository unavailable';

  @override
  String repoLoadError(String error) {
    return 'Error loading repository: $error';
  }

  @override
  String get repoCode => 'Code';

  @override
  String get repoIssues => 'Issues';

  @override
  String get repoPullRequests => 'Pull requests';

  @override
  String get repoActions => 'Actions';

  @override
  String get repoProjects => 'Projects';

  @override
  String get repoWiki => 'Wiki';

  @override
  String get repoSecurity => 'Security';

  @override
  String get repoInsights => 'Insights';

  @override
  String get repoPublic => 'Public';

  @override
  String get repoPrivate => 'Private';

  @override
  String get repoArchived => 'Archived';

  @override
  String repoForkedFrom(String repository) {
    return 'Forked from $repository';
  }

  @override
  String get repoAbout => 'About';

  @override
  String get repoNoDescription => 'No description provided.';

  @override
  String get repoContributing => 'Contributing';

  @override
  String get repoSecurityPolicy => 'Security policy';

  @override
  String get wikiPages => 'Wiki pages';

  @override
  String wikiCurrentPage(String page) {
    return 'Current page: $page';
  }

  @override
  String get wikiNoPages => 'No wiki pages';

  @override
  String get wikiNoPagesDescription =>
      'This repository does not have a wiki yet.';

  @override
  String get wikiCreateOnGitHub => 'Create wiki on GitHub';

  @override
  String get wikiOpenOnGitHub => 'Open wiki on GitHub';

  @override
  String get wikiLoadError => 'Could not load this repository wiki.';

  @override
  String get wikiPageLoadError => 'Could not open the wiki page.';

  @override
  String get issueDetailLoadError => 'Could not load this issue.';

  @override
  String get pullRequestDetailLoadError => 'Could not load this pull request.';

  @override
  String repoStarsCount(String count) {
    return '$count stars';
  }

  @override
  String repoForksCount(String count) {
    return '$count forks';
  }

  @override
  String repoWatchingCount(String count) {
    return '$count watching';
  }

  @override
  String repoBranchesCount(String count) {
    return '$count branches';
  }

  @override
  String repoTagsCount(String count) {
    return '$count tags';
  }

  @override
  String get repoReleases => 'Releases';

  @override
  String get repoLatest => 'Latest';

  @override
  String get repoSponsorProject => 'Sponsor this project';

  @override
  String get repoLanguages => 'Languages';

  @override
  String get repoContributors => 'Contributors';

  @override
  String get repoLicense => 'License';

  @override
  String get repoDocumentNotFound =>
      'This document is not available on the selected branch.';

  @override
  String repoDocumentLoadError(String error) {
    return 'Could not load this document: $error';
  }

  @override
  String get repoFunding => 'Funding';

  @override
  String repoWatchCount(String count) {
    return 'Watch $count';
  }

  @override
  String repoForkCount(String count) {
    return 'Fork $count';
  }

  @override
  String repoStarCount(String count) {
    return 'Star $count';
  }

  @override
  String get repoAllActivity => 'All activity';

  @override
  String get repoNotWatching => 'Not watching';

  @override
  String get repoIgnore => 'Ignore';

  @override
  String repoNotMigrated(String tab) {
    return '$tab is not migrated yet';
  }

  @override
  String get repoPhaseCodeOnly =>
      'This phase only rewrites the Repository Code page. Use the legacy layout for the existing implementation.';

  @override
  String get repoReadme => 'README';

  @override
  String get repoEditReadme => 'Edit README on GitHub';

  @override
  String get repoEditReadmeRequiresWrite =>
      'Write permission is required to edit README';

  @override
  String get repoReadmeOutlineUnavailable =>
      'README outline is not available in this phase.';

  @override
  String get repoOpenSubmoduleUnavailable =>
      'Opening submodules is not available in this phase.';

  @override
  String get repoFileSearchUnavailable =>
      'Repository-wide file search is not available in this phase.';

  @override
  String get repoGoToFile => 'Go to file';

  @override
  String get repoClearFileFilter => 'Clear file filter';

  @override
  String get repoFilterCurrentDirectory => 'Filter current directory';

  @override
  String get repoGoToFileUnavailable => 'Go to file (not available)';

  @override
  String get repoCreateNewFile => 'Create new file';

  @override
  String get repoCodeOptions => 'Code options';

  @override
  String repoBrowsingCommit(String commit) {
    return 'Browsing commit $commit. Editing is disabled.';
  }

  @override
  String get repoDefaultBranch => 'Default branch';

  @override
  String get repoSwitchBranch => 'Switch branch…';

  @override
  String get repoSwitchTag => 'Switch tag…';

  @override
  String get repoUploadFilesUnavailable => 'Upload files (not available)';

  @override
  String get repoAddFile => 'Add file';

  @override
  String get repoViewUpstream => 'View upstream';

  @override
  String get repoLoadingLatestCommit => 'Loading latest commit…';

  @override
  String get repoLatestCommitUnavailable => 'Latest commit unavailable';

  @override
  String get repoRetryLatestCommit => 'Retry latest commit';

  @override
  String get repoNoCommitInformation =>
      'No commit information for this directory';

  @override
  String get repoUnknownAuthor => 'Unknown author';

  @override
  String get repoNameColumn => 'Name';

  @override
  String get repoLastCommitColumn => 'Last commit';

  @override
  String get repoUpdatedColumn => 'Updated';

  @override
  String get repoCouldNotLoadFiles => 'Could not load repository files';

  @override
  String get repoNoMatchingFiles => 'No matching files';

  @override
  String get repoDirectoryEmpty => 'This directory is empty';

  @override
  String get repoClearFilterHint =>
      'Clear the file filter to show every entry.';

  @override
  String get repoCloneRepository => 'Clone repository';

  @override
  String get repoDirectory => 'Directory';

  @override
  String get repoSubmodule => 'Submodule';

  @override
  String repoReadmeLoadError(String error) {
    return 'Could not load README: $error';
  }

  @override
  String get repoNoReadme => 'No README';

  @override
  String get repoNoReadmeBody => 'This repository doesn\'t have a README file.';

  @override
  String get repoSearchBranches => 'Search branches…';

  @override
  String get repoSearchTags => 'Search tags…';

  @override
  String get repoDefault => 'Default';

  @override
  String get repoCurrent => 'Current';

  @override
  String get repoCopyCloneUrl => 'Copy clone URL';

  @override
  String get repoOtherLanguages => 'Other';

  @override
  String get repoAllIssues => 'All issues';

  @override
  String get repoNewIssue => 'New issue';

  @override
  String get repoNewPullRequest => 'New pull request';

  @override
  String get repoFilters => 'Filters';

  @override
  String get repoSearchIssues => 'Search issues';

  @override
  String get repoSearchPullRequests => 'Search pull requests';

  @override
  String get repoOpen => 'Open';

  @override
  String get repoClosed => 'Closed';

  @override
  String get repoSort => 'Sort';

  @override
  String get repoAssignedToMe => 'Assigned to me';

  @override
  String get repoCreatedByMe => 'Created by me';

  @override
  String get repoMentioned => 'Mentioned';

  @override
  String get repoRecentActivity => 'Recent activity';

  @override
  String get repoViews => 'Views';

  @override
  String get repoMilestones => 'Milestones';

  @override
  String get repoLabels => 'Labels';

  @override
  String get repoAuthor => 'Author';

  @override
  String get repoReviews => 'Reviews';

  @override
  String get repoAssignee => 'Assignee';

  @override
  String get filterClearAll => 'Clear all';

  @override
  String get filterDone => 'Done';

  @override
  String get filterMoreFilters => 'More filters';

  @override
  String get filterAdvanced => 'Advanced';

  @override
  String get filterAdvancedQueryHint => 'e.g. is:open label:bug';

  @override
  String filterSelect(String section) {
    return 'Select $section';
  }

  @override
  String filterSearch(String section) {
    return 'Search $section…';
  }

  @override
  String filterEnter(String section) {
    return 'Enter $section…';
  }

  @override
  String get filterSearchLabels => 'Search labels…';

  @override
  String get filterSearchAssignees => 'Search assignees…';

  @override
  String get filterApply => 'Apply';

  @override
  String get filterAfter => 'After…';

  @override
  String get filterBefore => 'Before…';

  @override
  String get filterRange => 'Range…';

  @override
  String get filterMinimum => 'Min';

  @override
  String get filterMaximum => 'Max';

  @override
  String get filterNoOptions => 'No options';

  @override
  String get filterOptionsLoadError => 'Could not load options';

  @override
  String get filterNoMilestone => 'No milestone';

  @override
  String get filterUnsupportedPicker => 'This filter is not supported yet.';

  @override
  String get filterNoItemsFound => 'No items found';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterLabel => 'Label';

  @override
  String get filterMilestone => 'Milestone';

  @override
  String get filterBaseBranch => 'Base branch';

  @override
  String get filterHeadBranch => 'Head branch';

  @override
  String get filterCreated => 'Created';

  @override
  String get filterUpdated => 'Updated';

  @override
  String get filterComments => 'Comments';

  @override
  String get filterReactions => 'Reactions';

  @override
  String get filterInteractions => 'Interactions';

  @override
  String get filterDraft => 'Draft';

  @override
  String get filterReviewStatus => 'Review status';

  @override
  String get filterReviewedBy => 'Reviewed by';

  @override
  String get filterReviewRequested => 'Review requested';

  @override
  String get filterTeamRequested => 'Team requested';

  @override
  String get filterLinkedIssue => 'Linked issue';

  @override
  String get filterExclude => 'Exclude';

  @override
  String get filterClosed => 'Closed';

  @override
  String get filterMerged => 'Merged';

  @override
  String get filterOptionMerged => 'Merged';

  @override
  String get filterOptionBestMatch => 'Best match';

  @override
  String get filterOptionNewest => 'Newest';

  @override
  String get filterOptionOldest => 'Oldest';

  @override
  String get filterOptionMostComments => 'Most comments';

  @override
  String get filterOptionRecentlyUpdated => 'Recently updated';

  @override
  String get filterOptionNoReview => 'No review';

  @override
  String get filterOptionReviewRequired => 'Review required';

  @override
  String get filterOptionApproved => 'Approved';

  @override
  String get filterOptionChangesRequested => 'Changes requested';

  @override
  String get filterOptionDraftOnly => 'Draft only';

  @override
  String get filterOptionNonDraftOnly => 'Non-draft only';

  @override
  String get filterOptionHasLinkedPullRequest => 'Has linked pull request';

  @override
  String get filterOptionHasLinkedIssue => 'Has linked issue';

  @override
  String get filterOptionNoLabels => 'No labels';

  @override
  String get filterOptionNoMilestone => 'No milestone';

  @override
  String get filterOptionNoAssignee => 'No assignee';

  @override
  String get repoIssuesUnavailable => 'Issues unavailable';

  @override
  String get repoIssuesDisabled => 'Issues are disabled for this repository.';

  @override
  String get repoNoOpenIssues => 'There aren’t any open issues.';

  @override
  String get repoNoClosedIssues => 'There aren’t any closed issues.';

  @override
  String get repoNoOpenPullRequests => 'There aren’t any open pull requests.';

  @override
  String get repoNoClosedPullRequests =>
      'There aren’t any closed pull requests.';

  @override
  String get repoAdjustSearchFilters => 'Try adjusting your search filters.';

  @override
  String get repoIssuePullLoadError => 'Could not load this list.';

  @override
  String get publicGitHubRateLimitReached =>
      'GitHub\'s unsigned API limit has been reached. Sign in for a higher limit or try again later.';

  @override
  String get repoSignInRequired => 'Sign in to continue';

  @override
  String get repoAccountStateLoadError =>
      'Could not read the local account state.';

  @override
  String get repoSignInToBrowseIssues =>
      'Sign in to browse and filter this repository\'s issues.';

  @override
  String get repoSignInToBrowsePullRequests =>
      'Sign in to browse and filter this repository\'s pull requests.';

  @override
  String get repoListOpened => 'opened';

  @override
  String get repoListClosed => 'closed';

  @override
  String get repoListDraft => 'draft';

  @override
  String get repoListMerged => 'merged';

  @override
  String repoIssuePullListMetadata(
    int number,
    String author,
    String action,
    String time,
  ) {
    return '#$number · $author $action $time';
  }

  @override
  String repoCommentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
    );
    return '$_temp0';
  }

  @override
  String get repoSecondaryTabSignInBody =>
      'Repository Actions, Projects, Security, and Insights use authenticated GitHub endpoints.';

  @override
  String get repoAllWorkflows => 'All workflows';

  @override
  String get repoWorkflow => 'Workflow';

  @override
  String get repoWorkflowRun => 'Workflow run';

  @override
  String repoWorkflowRunsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workflow runs',
      one: '1 workflow run',
    );
    return '$_temp0';
  }

  @override
  String get repoFilterBranch => 'Filter by branch';

  @override
  String get repoNoWorkflowRuns => 'No workflow runs found';

  @override
  String get repoNoWorkflowRunsBody =>
      'This workflow has no runs matching the current branch filter.';

  @override
  String get repoActionsLoadError => 'Could not load workflow runs';

  @override
  String get repoWorkflowsLoadError => 'Could not load workflows';

  @override
  String get repoProjectsDescription =>
      'Repository projects track work across issues and pull requests.';

  @override
  String get repoProjectsLoadError => 'Could not load projects';

  @override
  String get repoNoProjects => 'No projects found';

  @override
  String get repoNoProjectsBody =>
      'This repository has no projects matching the selected order.';

  @override
  String get repoSortTitle => 'Title';

  @override
  String repoProjectItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String repoUpdatedTime(String time) {
    return 'Updated $time';
  }

  @override
  String get repoSecurityOverview => 'Security overview';

  @override
  String get repoSecurityPolicyChecking =>
      'Checking the default branch for a security policy.';

  @override
  String get repoSecurityPolicyMissing =>
      'No SECURITY.md policy was found on the default branch.';

  @override
  String get repoSecurityPolicyUnavailable =>
      'The security policy could not be checked.';

  @override
  String repoSecurityPolicyFound(String path) {
    return 'Security policy detected at $path';
  }

  @override
  String get repoDependabot => 'Dependabot';

  @override
  String get repoCodeScanning => 'Code scanning';

  @override
  String get repoSecretScanning => 'Secret scanning';

  @override
  String get repoNoDependabotAlerts => 'No Dependabot alerts';

  @override
  String get repoNoCodeScanningAlerts => 'No code scanning alerts';

  @override
  String get repoNoSecretScanningAlerts => 'No secret scanning alerts';

  @override
  String get repoSecurityNoAlertsBody =>
      'No alerts are currently visible for this repository and account.';

  @override
  String get repoSecurityDataUnavailable => 'Security data unavailable';

  @override
  String repoSecurityPermissionBody(String error) {
    return 'GitHub may require repository administration permission or the feature may be disabled. $error';
  }

  @override
  String repoSecurityAlertsLoaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visible alerts',
      one: '1 visible alert',
    );
    return '$_temp0';
  }

  @override
  String get repoUnknownLocation => 'Unknown location';

  @override
  String get repoSecret => 'Secret';

  @override
  String get repoPulse => 'Pulse';

  @override
  String get repoTraffic => 'Traffic';

  @override
  String get repoCommunityStandards => 'Community standards';

  @override
  String get repoCommitActivity => 'Commit activity';

  @override
  String repoCommitsLastYear(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits in the last year',
      one: '1 commit in the last year',
    );
    return '$_temp0';
  }

  @override
  String get repoNoContributors => 'No contributor statistics are available.';

  @override
  String get repoUnknownContributor => 'Unknown contributor';

  @override
  String repoContributionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contributions',
      one: '1 contribution',
    );
    return '$_temp0';
  }

  @override
  String get repoClones => 'Clones';

  @override
  String get repoTopReferrers => 'Top referrers';

  @override
  String get repoPopularContent => 'Popular content';

  @override
  String get repoTotal => 'Total';

  @override
  String get repoUnique => 'Unique';

  @override
  String repoUniqueVisitors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unique visitors',
      one: '1 unique visitor',
    );
    return '$_temp0';
  }

  @override
  String get repoNoInsightData => 'No data is available for this section.';

  @override
  String get repoInsightsDataUnavailable => 'Insights data unavailable';

  @override
  String repoInsightsPermissionBody(String error) {
    return 'Some repository statistics are delayed or require push access. $error';
  }

  @override
  String repoCommunityHealth(int percent) {
    return 'Community profile health: $percent%';
  }

  @override
  String get repoCodeOfConduct => 'Code of conduct';

  @override
  String get repoIssueTemplate => 'Issue template';

  @override
  String get repoPullRequestTemplate => 'Pull request template';

  @override
  String get activityNoRecent => 'No recent activity';

  @override
  String get activityNoRecentBody =>
      'Activity from people and repositories you follow will appear here.';

  @override
  String get activityRefresh => 'Refresh';

  @override
  String activityLoadMoreError(String error) {
    return 'Could not load more activity: $error';
  }

  @override
  String activityIssueState(String action, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'opened $count issues',
      one: 'opened an issue',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'closed $count issues',
      one: 'closed an issue',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'reopened $count issues',
      one: 'reopened an issue',
    );
    String _temp3 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'marked $count issues as ready',
      one: 'marked an issue as ready',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'converted $count issues to draft',
      one: 'converted an issue to draft',
    );
    String _temp5 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'updated $count issues',
      one: 'updated an issue',
    );
    String _temp6 = intl.Intl.selectLogic(action, {
      'opened': '$_temp0',
      'closed': '$_temp1',
      'reopened': '$_temp2',
      'readyForReview': '$_temp3',
      'convertedToDraft': '$_temp4',
      'other': '$_temp5',
    });
    return '$_temp6';
  }

  @override
  String activityPullRequestState(String action, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'opened $count pull requests',
      one: 'opened a pull request',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'closed $count pull requests',
      one: 'closed a pull request',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'reopened $count pull requests',
      one: 'reopened a pull request',
    );
    String _temp3 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'merged $count pull requests',
      one: 'merged a pull request',
    );
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'marked $count pull requests as ready',
      one: 'marked a pull request as ready',
    );
    String _temp5 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'converted $count pull requests to draft',
      one: 'converted a pull request to draft',
    );
    String _temp6 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'updated $count pull requests',
      one: 'updated a pull request',
    );
    String _temp7 = intl.Intl.selectLogic(action, {
      'opened': '$_temp0',
      'closed': '$_temp1',
      'reopened': '$_temp2',
      'merged': '$_temp3',
      'readyForReview': '$_temp4',
      'convertedToDraft': '$_temp5',
      'other': '$_temp6',
    });
    return '$_temp7';
  }

  @override
  String activityPush(int commits, int branches) {
    String _temp0 = intl.Intl.pluralLogic(
      commits,
      locale: localeName,
      other: 'pushed $commits commits',
      one: 'pushed a commit',
    );
    String _temp1 = intl.Intl.pluralLogic(
      branches,
      locale: localeName,
      other: 'pushed $commits commits to $branches branches',
      one: '$_temp0',
    );
    return '$_temp1';
  }

  @override
  String get activityLabelsUpdated => 'updated labels';

  @override
  String activityLabelsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'added $count labels',
      one: 'added a label',
    );
    return '$_temp0';
  }

  @override
  String activityLabelsRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'removed $count labels',
      one: 'removed a label',
    );
    return '$_temp0';
  }

  @override
  String activityComments(String action, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'added $count comments',
      one: 'added a comment',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'edited $count comments',
      one: 'edited a comment',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'deleted $count comments',
      one: 'deleted a comment',
    );
    String _temp3 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'updated $count comments',
      one: 'updated a comment',
    );
    String _temp4 = intl.Intl.selectLogic(action, {
      'created': '$_temp0',
      'edited': '$_temp1',
      'deleted': '$_temp2',
      'other': '$_temp3',
    });
    return '$_temp4';
  }

  @override
  String activityReferences(String action, String kind, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'created $count branches',
      one: 'created a branch',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'created $count tags',
      one: 'created a tag',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'created $count references',
      one: 'created a reference',
    );
    String _temp3 = intl.Intl.selectLogic(kind, {
      'branch': '$_temp0',
      'tag': '$_temp1',
      'other': '$_temp2',
    });
    String _temp4 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'deleted $count branches',
      one: 'deleted a branch',
    );
    String _temp5 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'deleted $count tags',
      one: 'deleted a tag',
    );
    String _temp6 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'deleted $count references',
      one: 'deleted a reference',
    );
    String _temp7 = intl.Intl.selectLogic(kind, {
      'branch': '$_temp4',
      'tag': '$_temp5',
      'other': '$_temp6',
    });
    String _temp8 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'updated $count references',
      one: 'updated a reference',
    );
    String _temp9 = intl.Intl.selectLogic(action, {
      'created': '$_temp3',
      'deleted': '$_temp7',
      'other': '$_temp8',
    });
    return '$_temp9';
  }

  @override
  String activityStarredRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'starred $count repositories',
      one: 'starred a repository',
    );
    return '$_temp0';
  }

  @override
  String activityForkedRepositories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'forked $count repositories',
      one: 'forked a repository',
    );
    return '$_temp0';
  }

  @override
  String activityMadeRepositoriesPublic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'made $count repositories public',
      one: 'made a repository public',
    );
    return '$_temp0';
  }

  @override
  String activityMembers(String action, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'removed $count members',
      one: 'removed a member',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'added $count members',
      one: 'added a member',
    );
    String _temp2 = intl.Intl.selectLogic(action, {
      'removed': '$_temp0',
      'other': '$_temp1',
    });
    return '$_temp2';
  }

  @override
  String activityAssignedIssues(String action, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'unassigned $count issues',
      one: 'unassigned an issue',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'assigned $count issues',
      one: 'assigned an issue',
    );
    String _temp2 = intl.Intl.selectLogic(action, {
      'unassigned': '$_temp0',
      'other': '$_temp1',
    });
    return '$_temp2';
  }

  @override
  String activityReviews(String state, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'approved $count pull requests',
      one: 'approved a pull request',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'requested changes on $count pull requests',
      one: 'requested changes on a pull request',
    );
    String _temp2 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dismissed reviews on $count pull requests',
      one: 'dismissed a review on a pull request',
    );
    String _temp3 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'reviewed $count pull requests',
      one: 'reviewed a pull request',
    );
    String _temp4 = intl.Intl.selectLogic(state, {
      'approved': '$_temp0',
      'changesRequested': '$_temp1',
      'dismissed': '$_temp2',
      'other': '$_temp3',
    });
    return '$_temp4';
  }

  @override
  String activityPublishedReleases(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'published $count releases',
      one: 'published a release',
    );
    return '$_temp0';
  }

  @override
  String activityStartedDiscussions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'started $count discussions',
      one: 'started a discussion',
    );
    return '$_temp0';
  }

  @override
  String activityUpdatedWikiPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'updated $count wiki pages',
      one: 'updated a wiki page',
      zero: 'updated wiki pages',
    );
    return '$_temp0';
  }

  @override
  String activityPerformedActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'performed $count actions',
      one: 'performed an action',
    );
    return '$_temp0';
  }

  @override
  String activityJoinTwo(String first, String second) {
    return '$first and $second';
  }

  @override
  String activityJoinMany(String head, String last) {
    return '$head, and $last';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPageDescription =>
      'Manage your GitHub account and DioHub preferences in one place.';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsCategory => 'Settings category';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAccessibility => 'Accessibility';

  @override
  String get settingsCodeAndRepositories => 'Code & repositories';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPrivacy => 'Privacy & diagnostics';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsSaveError => 'The setting could not be saved.';

  @override
  String get settingsGeneralDescription =>
      'Choose the app language, information density, and default browsing behavior.';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsAppLanguageDescription =>
      'Follow the operating system or choose a language for DioHub.';

  @override
  String get settingsLayout => 'Layout';

  @override
  String get settingsLayoutDescription =>
      'Use one density across shared Android and desktop layouts.';

  @override
  String get settingsDensity => 'Information density';

  @override
  String get settingsDensityDescription =>
      'Adjust spacing without shrinking text or touch targets.';

  @override
  String get settingsDensityCompact => 'Compact';

  @override
  String get settingsDensityDefault => 'Default';

  @override
  String get settingsDensitySpacious => 'Spacious';

  @override
  String get settingsStickyHeaders => 'Sticky section headers';

  @override
  String get settingsStickyHeadersDescription =>
      'Keep section context visible while scrolling supported legacy views.';

  @override
  String get settingsFeedAndSearch => 'Feed & search';

  @override
  String get settingsGroupRelatedActivity => 'Group related activity';

  @override
  String get settingsGroupRelatedActivityDescription =>
      'Combine related GitHub events into a single feed entry.';

  @override
  String get settingsTimelineFeed => 'Timeline feed';

  @override
  String get settingsTimelineFeedDescription =>
      'Show activity with a continuous timeline instead of plain cards.';

  @override
  String get settingsFuzzySearch => 'Fuzzy local filtering';

  @override
  String get settingsFuzzySearchDescription =>
      'Match approximate text in client-side filters.';

  @override
  String get settingsAppearanceDescription =>
      'Choose the color mode and how profile colors influence the interface.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDescription =>
      'Material 3 colors remain centralized and respond immediately.';

  @override
  String get settingsThemeMode => 'Theme mode';

  @override
  String get settingsThemeModeDescription =>
      'Follow the system or keep DioHub light or dark.';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsMaterialYou => 'Use system colors';

  @override
  String get settingsMaterialYouDescription =>
      'Use dynamic Material You colors when the platform provides them.';

  @override
  String get settingsProfileColors => 'Profile colors';

  @override
  String get settingsProfileColorsDescription =>
      'Optionally blend a profile avatar color into profile pages.';

  @override
  String get settingsProfileTheme => 'Profile-based color';

  @override
  String get settingsProfileThemeDescription =>
      'Apply a scoped color treatment when viewing a profile.';

  @override
  String get settingsProfileThemeIntensity => 'Color intensity';

  @override
  String get settingsProfileThemeIntensityDescription =>
      'Control how strongly the profile color is blended.';

  @override
  String get settingsAccessibilityDescription =>
      'Control motion and physical feedback while preserving platform accessibility preferences.';

  @override
  String get settingsMotion => 'Motion';

  @override
  String get settingsMotionDescription =>
      'The operating system Reduced Motion preference always takes priority.';

  @override
  String get settingsAnimationLevel => 'Animation level';

  @override
  String get settingsAnimationLevelDescription =>
      'Choose how much interface motion DioHub adds.';

  @override
  String get settingsAnimationNone => 'None';

  @override
  String get settingsAnimationReduced => 'Reduced';

  @override
  String get settingsAnimationNormal => 'Normal';

  @override
  String get settingsAnimationEnhanced => 'Enhanced';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsHaptics => 'Haptic feedback';

  @override
  String get settingsHapticsDescription =>
      'Control vibration feedback on supported devices.';

  @override
  String get settingsHapticsOn => 'On';

  @override
  String get settingsHapticsReduced => 'Reduced';

  @override
  String get settingsHapticsOff => 'Off';

  @override
  String get settingsCodeAndRepositoriesDescription =>
      'Set repository entry behavior, file browsing details, and diff readability.';

  @override
  String get settingsRepositoryDefaults => 'Repository defaults';

  @override
  String get settingsDefaultRepositoryTab => 'Default repository tab';

  @override
  String get settingsDefaultRepositoryTabDescription =>
      'Open this tab when a repository link does not specify a destination.';

  @override
  String get settingsCommits => 'Commits';

  @override
  String get settingsCodeBrowser => 'Code browser';

  @override
  String get settingsFileSort => 'File sorting';

  @override
  String get settingsFileSortDescription =>
      'Choose how directories and files are ordered.';

  @override
  String get settingsSortType => 'Type';

  @override
  String get settingsSortNameAscending => 'Name A–Z';

  @override
  String get settingsSortNameDescending => 'Name Z–A';

  @override
  String get settingsSortSize => 'Size';

  @override
  String get settingsSortExtension => 'Extension';

  @override
  String get settingsShowDotfiles => 'Show dotfiles';

  @override
  String get settingsShowDotfilesDescription =>
      'Include files and directories whose names begin with a dot.';

  @override
  String get settingsShowFileMetadata => 'Show file metadata';

  @override
  String get settingsShowFileMetadataDescription =>
      'Display available size and type details in the file list.';

  @override
  String get settingsShowGeneratedFiles => 'Show generated files';

  @override
  String get settingsShowGeneratedFilesDescription =>
      'Include files GitHub identifies as generated.';

  @override
  String get settingsShowLastCommit => 'Show last commit per path';

  @override
  String get settingsShowLastCommitDescription =>
      'Fetch commit information for visible paths. Large directories may require extra requests.';

  @override
  String get settingsDiffViewer => 'Diff viewer';

  @override
  String get settingsDiffLayout => 'Default diff layout';

  @override
  String get settingsDiffLayoutDescription =>
      'Choose a unified or split comparison.';

  @override
  String get settingsDiffUnified => 'Unified';

  @override
  String get settingsDiffSplit => 'Split';

  @override
  String get settingsWrapCode => 'Wrap long lines';

  @override
  String get settingsWrapCodeDescription =>
      'Wrap code and diff lines to the available width.';

  @override
  String get settingsLineNumbers => 'Show line numbers';

  @override
  String get settingsLineNumbersDescription =>
      'Display source line numbers beside code.';

  @override
  String get settingsDiffHighlight => 'Change highlight';

  @override
  String get settingsDiffHighlightDescription =>
      'Adjust the contrast of added and removed lines.';

  @override
  String get settingsHighlightSubtle => 'Subtle';

  @override
  String get settingsHighlightDefault => 'Default';

  @override
  String get settingsHighlightHigh => 'High';

  @override
  String get settingsCodeFontScale => 'Code text size';

  @override
  String get settingsCodeFontScaleDescription =>
      'Scale monospace content independently from interface text.';

  @override
  String get settingsNotificationsDescription =>
      'Control inbox presentation and background notification checks.';

  @override
  String get settingsInbox => 'Inbox';

  @override
  String get settingsAutoMarkRead => 'Auto-mark as read';

  @override
  String get settingsAutoMarkReadDescription =>
      'Mark notifications as read when they become visible.';

  @override
  String get settingsGroupByRepository => 'Group by repository';

  @override
  String get settingsGroupByRepositoryDescription =>
      'Organize loaded notifications under repository headings.';

  @override
  String get settingsBackgroundChecks => 'Background checks';

  @override
  String get settingsBackgroundChecksDescription =>
      'Background availability depends on platform support and operating system permissions.';

  @override
  String get settingsInboxPolling => 'Inbox polling';

  @override
  String get settingsInboxPollingDescription =>
      'Periodically check for new GitHub notifications.';

  @override
  String get settingsPollingInterval => 'Polling interval';

  @override
  String get settingsPollingIntervalDescription =>
      'Choose how often the inbox is checked in the background.';

  @override
  String settingsMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get settingsSystemNotifications => 'System notifications';

  @override
  String get settingsSystemNotificationsDescription =>
      'Show operating system notifications while DioHub is in the background.';

  @override
  String get settingsWorkflowAlerts => 'Workflow run alerts';

  @override
  String get settingsWorkflowAlertsDescription =>
      'Notify when a watched workflow run completes.';

  @override
  String get settingsPrivacyDescription =>
      'Choose which diagnostics DioHub may collect when reporting failures.';

  @override
  String get settingsDiagnostics => 'Diagnostics';

  @override
  String get settingsDiagnosticsDescription =>
      'Diagnostic preferences take effect after the next app launch.';

  @override
  String get settingsCrashReports => 'Crash reports';

  @override
  String get settingsCrashReportsDescription =>
      'Send anonymous stack traces when DioHub crashes.';

  @override
  String get settingsHttpDiagnostics => 'HTTP diagnostics';

  @override
  String get settingsHttpDiagnosticsDescription =>
      'Include anonymized API error patterns and timing.';

  @override
  String get settingsNavigationDiagnostics => 'Navigation diagnostics';

  @override
  String get settingsNavigationDiagnosticsDescription =>
      'Include the sequence of screens visited before a crash.';

  @override
  String get settingsPerformanceDiagnostics => 'Performance monitoring';

  @override
  String get settingsPerformanceDiagnosticsDescription =>
      'Measure responsiveness and slow operations.';

  @override
  String get settingsSessionReplay => 'Session replay';

  @override
  String get settingsSessionReplayDescription =>
      'Record a masked visual trace when a crash occurs.';

  @override
  String get settingsRestartRequired =>
      'Changes to diagnostics take effect after the next app launch.';

  @override
  String get settingsAboutDescription =>
      'Version, release notes, and open-source acknowledgements.';

  @override
  String get settingsApplication => 'Application';

  @override
  String get settingsApplicationName => 'DioHub';

  @override
  String settingsVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get settingsWhatsNew => 'What’s new';

  @override
  String get settingsWhatsNewDescription =>
      'Read the changelog and release history.';

  @override
  String get settingsOpenSourceLicenses => 'Open-source licenses';

  @override
  String get settingsOpenSourceLicensesDescription =>
      'View licenses for Flutter and bundled dependencies.';

  @override
  String get settingsAccessGroup => 'Access';

  @override
  String get settingsCodePlanningAutomation => 'Code, planning, and automation';

  @override
  String get settingsDioHubGroup => 'DioHub app settings';

  @override
  String get settingsPublicProfile => 'Public profile';

  @override
  String get settingsGitHubAccount => 'Account';

  @override
  String get settingsBillingAndLicensing => 'Billing and licensing';

  @override
  String get settingsEmails => 'Emails';

  @override
  String get settingsPasswordAndAuthentication => 'Password and authentication';

  @override
  String get settingsSessions => 'Sessions';

  @override
  String get settingsSshAndGpgKeys => 'SSH and GPG keys';

  @override
  String get settingsOrganizations => 'Organizations';

  @override
  String get settingsEnterprises => 'Enterprises';

  @override
  String get settingsModeration => 'Moderation';

  @override
  String get settingsCodespaces => 'Codespaces';

  @override
  String get settingsSignedOutDescription =>
      'DioHub preferences remain available without a GitHub account.';

  @override
  String get settingsPersonalAccount => 'Your personal account';

  @override
  String get settingsSwitchContext => 'Switch settings context';

  @override
  String get settingsPublicProfileDescription =>
      'Manage the information shown on your GitHub profile.';

  @override
  String get settingsProfileName => 'Name';

  @override
  String get settingsProfilePublicEmail => 'Public email';

  @override
  String get settingsProfilePublicEmailDescription =>
      'This address is visible on your public GitHub profile.';

  @override
  String get settingsProfileEmailHidden => 'Don\'t show my email';

  @override
  String get settingsProfileEmailLoadError =>
      'Verified emails could not be loaded. Your current public email is unchanged.';

  @override
  String get settingsProfileBio => 'Bio';

  @override
  String get settingsProfilePronouns => 'Pronouns';

  @override
  String get settingsProfileUrl => 'URL';

  @override
  String get settingsProfileCompany => 'Company';

  @override
  String get settingsProfileLocation => 'Location';

  @override
  String get settingsProfileTwitter => 'X username';

  @override
  String get settingsProfileAvailableForHire => 'Available for hire';

  @override
  String get settingsProfilePicture => 'Profile picture';

  @override
  String get settingsManageProfilePicture => 'Edit on GitHub';

  @override
  String get settingsUpdateProfile => 'Update profile';

  @override
  String get settingsProfileUpdated => 'Your public profile was updated.';

  @override
  String get settingsPublicProfileLoadError =>
      'DioHub could not load the public profile for this account.';

  @override
  String get settingsManagedByGitHub => 'Continue on GitHub';

  @override
  String get settingsBrowserOnly => 'GitHub web setting';

  @override
  String settingsBrowserOnlyDescription(String setting) {
    return '$setting does not have a supported public API. DioHub opens the matching page for the active server.';
  }

  @override
  String get settingsPartialApiCoverage => 'Partial public API';

  @override
  String settingsPartialApiCoverageDescription(String setting) {
    return 'GitHub exposes only part of $setting through public APIs. DioHub does not present an incomplete subset as the full setting.';
  }

  @override
  String get settingsOAuthScopeRequired => 'Additional authorization required';

  @override
  String settingsOAuthScopeRequiredDescription(String setting) {
    return '$setting has public API coverage, but the current DioHub OAuth scope does not authorize it. Authorization changes are handled separately.';
  }

  @override
  String settingsGitHubManagedDescription(String setting) {
    return '$setting is managed by GitHub. DioHub opens the matching page for the active server instead of imitating unavailable private APIs.';
  }

  @override
  String get settingsOpenOnGitHub => 'Open on GitHub';

  @override
  String get settingsSignInToManageGitHub =>
      'Sign in to manage this GitHub setting.';

  @override
  String settingsOpenOnGitHubDescription(String host) {
    return 'Open this setting on $host.';
  }

  @override
  String get settingsCollectionLoadError =>
      'DioHub could not load this setting. Check the connection and try again.';

  @override
  String get settingsLoadMore => 'Load more';

  @override
  String get settingsRefresh => 'Refresh';

  @override
  String get settingsDelete => 'Delete';

  @override
  String get settingsEmailsDescription =>
      'Manage the email addresses associated with your GitHub account.';

  @override
  String get settingsAddEmail => 'Add email address';

  @override
  String get settingsDeleteEmail => 'Delete email address';

  @override
  String settingsDeleteEmailConfirmation(String email) {
    return 'Remove $email from your GitHub account?';
  }

  @override
  String get settingsPrimaryEmailVisibility => 'Primary email visibility';

  @override
  String get settingsPrimaryEmailVisibilityDescription =>
      'Choose whether your primary email may be shown on your public GitHub profile.';

  @override
  String get settingsNoEmails => 'No email addresses';

  @override
  String get settingsNoEmailsDescription =>
      'Add an email address to use it with your GitHub account.';

  @override
  String get settingsEmailPrimary => 'Primary';

  @override
  String get settingsEmailVerified => 'Verified';

  @override
  String get settingsEmailUnverified => 'Unverified';

  @override
  String get settingsEmailPublic => 'Public';

  @override
  String get settingsEmailPrivate => 'Private';

  @override
  String get settingsEmailAddress => 'Email address';

  @override
  String get settingsEmailInvalid => 'Enter a valid email address.';

  @override
  String get settingsKeysDescription =>
      'Manage the keys GitHub uses for authentication and verified signing.';

  @override
  String get settingsSshKeys => 'SSH keys';

  @override
  String get settingsGpgKeys => 'GPG keys';

  @override
  String get settingsSshSigningKeys => 'Signing keys';

  @override
  String get settingsAddKey => 'New key';

  @override
  String get settingsDeleteKey => 'Delete key';

  @override
  String settingsDeleteKeyConfirmation(String title) {
    return 'Delete “$title”? This cannot be undone.';
  }

  @override
  String get settingsNoSshKeys => 'No SSH keys';

  @override
  String get settingsNoSshKeysDescription =>
      'Add an SSH key to authenticate Git operations.';

  @override
  String get settingsNoGpgKeys => 'No GPG keys';

  @override
  String get settingsNoGpgKeysDescription =>
      'Add a GPG key to mark supported commits and tags as verified.';

  @override
  String get settingsNoSigningKeys => 'No SSH signing keys';

  @override
  String get settingsNoSigningKeysDescription =>
      'Add an SSH signing key for verified Git signatures.';

  @override
  String settingsAddedOn(String date) {
    return 'Added $date';
  }

  @override
  String get settingsKeyNameOptional => 'Name (optional)';

  @override
  String get settingsKeyTitle => 'Title';

  @override
  String get settingsArmoredGpgKey => 'ASCII-armored GPG public key';

  @override
  String get settingsPublicKey => 'Public key';

  @override
  String get settingsFieldRequired => 'This field is required.';

  @override
  String get settingsOrganizationsDescription =>
      'Organizations associated with your GitHub account. Membership changes continue on GitHub.';

  @override
  String get settingsNoOrganizations => 'No organizations';

  @override
  String get settingsNoOrganizationsDescription =>
      'This account does not currently belong to an organization.';

  @override
  String settingsOrganizationSummary(int repositories, int members) {
    return '$repositories repositories · $members members';
  }

  @override
  String get settingsRepositoriesDescription =>
      'Browse repositories available to this account. Administrative controls continue on GitHub.';

  @override
  String get settingsNoRepositories => 'No repositories';

  @override
  String get settingsNoRepositoriesDescription =>
      'No repository is available to this account.';

  @override
  String get settingsFork => 'Fork';

  @override
  String settingsStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String settingsUpdatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String get settingsModerationDescription =>
      'Review and manage users blocked by this GitHub account.';

  @override
  String get settingsBlockUser => 'Block a user';

  @override
  String get settingsGitHubUsername => 'GitHub username';

  @override
  String get settingsBlock => 'Block';

  @override
  String get settingsNoBlockedUsers => 'No blocked users';

  @override
  String get settingsNoBlockedUsersDescription =>
      'Users blocked by this account will appear here.';

  @override
  String get settingsUnblock => 'Unblock';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get repoWorkflowStatusSuccess => 'Succeeded';

  @override
  String get repoWorkflowStatusFailure => 'Failed';

  @override
  String get repoWorkflowStatusTimedOut => 'Timed out';

  @override
  String get repoWorkflowStatusCancelled => 'Cancelled';

  @override
  String get repoWorkflowStatusInProgress => 'In progress';

  @override
  String get repoWorkflowStatusQueued => 'Queued';

  @override
  String get repoWorkflowStatusWaiting => 'Waiting';

  @override
  String get repoWorkflowStatusPending => 'Pending';

  @override
  String get repoWorkflowStatusUnknown => 'Unknown status';

  @override
  String get compareFileStatusAdded => 'Added';

  @override
  String get compareFileStatusRemoved => 'Removed';

  @override
  String get compareFileStatusRenamed => 'Renamed';

  @override
  String get compareFileStatusModified => 'Modified';

  @override
  String get compareTitle => 'Compare';

  @override
  String get compareSelectBaseRef => 'Select base ref';

  @override
  String get compareSelectHeadRef => 'Select head ref';

  @override
  String get compareSelectBase => 'Select base…';

  @override
  String get compareSelectHead => 'Select head…';

  @override
  String get compareSwapBaseHead => 'Swap base and head';

  @override
  String get compareEnterRefs =>
      'Select base and head refs to compare changes.';

  @override
  String compareLoadError(String error) {
    return 'Could not load comparison: $error';
  }

  @override
  String get compareAhead => 'ahead';

  @override
  String get compareBehind => 'behind';

  @override
  String compareFilesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files changed',
      one: '1 file changed',
    );
    return '$_temp0';
  }

  @override
  String get compareCommits => 'Commits';

  @override
  String get compareFiles => 'Files';

  @override
  String get projectPickerLinked => 'Linked';

  @override
  String get projectPickerAddToProject => 'Add to project';
}
