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
}
