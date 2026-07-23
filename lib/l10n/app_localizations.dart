import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The application name.
  ///
  /// In en, this message translates to:
  /// **'DioHub'**
  String get appName;

  /// Title for language and regional preferences.
  ///
  /// In en, this message translates to:
  /// **'Language & region'**
  String get languageAndRegion;

  /// Use the operating system language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// English language option, written in English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Simplified Chinese language option.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get languageSimplifiedChinese;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get commonSignIn;

  /// No description provided for @commonShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get commonShowMore;

  /// No description provided for @commonNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get commonNew;

  /// No description provided for @commonCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get commonCode;

  /// No description provided for @commonFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get commonFilter;

  /// No description provided for @commonAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get commonAuto;

  /// No description provided for @commonFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get commonFree;

  /// No description provided for @homeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get homeDashboard;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeSearchGitHub.
  ///
  /// In en, this message translates to:
  /// **'Search GitHub'**
  String get homeSearchGitHub;

  /// No description provided for @homeSearchRepositories.
  ///
  /// In en, this message translates to:
  /// **'Search GitHub repositories'**
  String get homeSearchRepositories;

  /// No description provided for @homeSearchRepositoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Owner, repository, topic...'**
  String get homeSearchRepositoriesHint;

  /// No description provided for @homeBackToSearch.
  ///
  /// In en, this message translates to:
  /// **'Back to search'**
  String get homeBackToSearch;

  /// No description provided for @homeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get homeNotifications;

  /// No description provided for @homeCouldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get homeCouldNotOpenLink;

  /// No description provided for @homeFeatureNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'{feature} is not connected in this phase yet.'**
  String homeFeatureNotAvailable(String feature);

  /// No description provided for @homeNoSystemBrowser.
  ///
  /// In en, this message translates to:
  /// **'No system browser is available.'**
  String get homeNoSystemBrowser;

  /// No description provided for @homeOpenRepositoryOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'Open repository on GitHub'**
  String get homeOpenRepositoryOnGitHub;

  /// No description provided for @homeDirectoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'This directory is empty.'**
  String get homeDirectoryEmpty;

  /// No description provided for @homeParentDirectory.
  ///
  /// In en, this message translates to:
  /// **'Parent directory'**
  String get homeParentDirectory;

  /// No description provided for @homeBackToDirectory.
  ///
  /// In en, this message translates to:
  /// **'Back to directory'**
  String get homeBackToDirectory;

  /// No description provided for @homeOpenFileOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'Open file on GitHub'**
  String get homeOpenFileOnGitHub;

  /// No description provided for @homeOpenOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'Open on GitHub'**
  String get homeOpenOnGitHub;

  /// No description provided for @homeBrowsingGitHubPublicly.
  ///
  /// In en, this message translates to:
  /// **'Browsing GitHub publicly'**
  String get homeBrowsingGitHubPublicly;

  /// No description provided for @homePublicBrowsing.
  ///
  /// In en, this message translates to:
  /// **'Public browsing'**
  String get homePublicBrowsing;

  /// No description provided for @homeAskAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask anything or type @ to add context'**
  String get homeAskAnything;

  /// No description provided for @homeAgent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get homeAgent;

  /// No description provided for @homeCreateIssue.
  ///
  /// In en, this message translates to:
  /// **'Create issue'**
  String get homeCreateIssue;

  /// No description provided for @homeWriteCode.
  ///
  /// In en, this message translates to:
  /// **'Write code'**
  String get homeWriteCode;

  /// No description provided for @homePullRequests.
  ///
  /// In en, this message translates to:
  /// **'Pull requests'**
  String get homePullRequests;

  /// No description provided for @homeTopRepositories.
  ///
  /// In en, this message translates to:
  /// **'Top repositories'**
  String get homeTopRepositories;

  /// No description provided for @homeTopRepositoriesSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see repositories you have recently contributed to or created.'**
  String get homeTopRepositoriesSignInBody;

  /// No description provided for @homeFindRepository.
  ///
  /// In en, this message translates to:
  /// **'Find a repository...'**
  String get homeFindRepository;

  /// No description provided for @homeFindRepositoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Find a repository'**
  String get homeFindRepositoryTooltip;

  /// No description provided for @homeRepositoriesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load repositories.'**
  String get homeRepositoriesLoadError;

  /// No description provided for @homeNoRepositoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No repositories found.'**
  String get homeNoRepositoriesFound;

  /// No description provided for @homeRepositorySearch.
  ///
  /// In en, this message translates to:
  /// **'Repository search'**
  String get homeRepositorySearch;

  /// No description provided for @homeCloseSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get homeCloseSearch;

  /// No description provided for @homeSignInToPersonalizeFeed.
  ///
  /// In en, this message translates to:
  /// **'Sign in to personalize your feed'**
  String get homeSignInToPersonalizeFeed;

  /// No description provided for @homePublicSearchAvailable.
  ///
  /// In en, this message translates to:
  /// **'Public repository search remains available without an account.'**
  String get homePublicSearchAvailable;

  /// No description provided for @homeFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get homeFeed;

  /// No description provided for @homeRefreshActivity.
  ///
  /// In en, this message translates to:
  /// **'Refresh activity'**
  String get homeRefreshActivity;

  /// No description provided for @homeActivityNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Activity feed is not connected.'**
  String get homeActivityNotConnected;

  /// No description provided for @homeFollowingAndWatched.
  ///
  /// In en, this message translates to:
  /// **'Following & watched'**
  String get homeFollowingAndWatched;

  /// No description provided for @homeSignInToPersonalize.
  ///
  /// In en, this message translates to:
  /// **'Sign in to personalize'**
  String get homeSignInToPersonalize;

  /// No description provided for @homeTopRepositoriesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Top repositories are unavailable.'**
  String get homeTopRepositoriesUnavailable;

  /// No description provided for @navClose.
  ///
  /// In en, this message translates to:
  /// **'Close navigation'**
  String get navClose;

  /// No description provided for @navAllIssues.
  ///
  /// In en, this message translates to:
  /// **'All issues'**
  String get navAllIssues;

  /// No description provided for @navAllPullRequests.
  ///
  /// In en, this message translates to:
  /// **'All pull requests'**
  String get navAllPullRequests;

  /// No description provided for @navAllRepositories.
  ///
  /// In en, this message translates to:
  /// **'All repositories'**
  String get navAllRepositories;

  /// No description provided for @navProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get navProjects;

  /// No description provided for @navDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Discussions'**
  String get navDiscussions;

  /// No description provided for @navCodespaces.
  ///
  /// In en, this message translates to:
  /// **'Codespaces'**
  String get navCodespaces;

  /// No description provided for @navCopilot.
  ///
  /// In en, this message translates to:
  /// **'Copilot'**
  String get navCopilot;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get navMarketplace;

  /// No description provided for @navMcpRegistry.
  ///
  /// In en, this message translates to:
  /// **'MCP registry'**
  String get navMcpRegistry;

  /// No description provided for @accountSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get accountSwitch;

  /// No description provided for @accountSetStatus.
  ///
  /// In en, this message translates to:
  /// **'Set status'**
  String get accountSetStatus;

  /// No description provided for @accountProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get accountProfile;

  /// No description provided for @accountRepositories.
  ///
  /// In en, this message translates to:
  /// **'Repositories'**
  String get accountRepositories;

  /// No description provided for @accountStars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get accountStars;

  /// No description provided for @accountGists.
  ///
  /// In en, this message translates to:
  /// **'Gists'**
  String get accountGists;

  /// No description provided for @accountOrganizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get accountOrganizations;

  /// No description provided for @accountEnterprises.
  ///
  /// In en, this message translates to:
  /// **'Enterprises'**
  String get accountEnterprises;

  /// No description provided for @accountSponsors.
  ///
  /// In en, this message translates to:
  /// **'Sponsors'**
  String get accountSponsors;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountSettings;

  /// No description provided for @accountCopilotSettings.
  ///
  /// In en, this message translates to:
  /// **'Copilot settings'**
  String get accountCopilotSettings;

  /// No description provided for @accountFeaturePreview.
  ///
  /// In en, this message translates to:
  /// **'Feature preview'**
  String get accountFeaturePreview;

  /// No description provided for @accountAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get accountAppearance;

  /// No description provided for @accountAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accountAccessibility;

  /// No description provided for @accountTryEnterprise.
  ///
  /// In en, this message translates to:
  /// **'Try Enterprise'**
  String get accountTryEnterprise;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignOutAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all accounts?'**
  String get accountSignOutAllTitle;

  /// No description provided for @accountSignOutAllBody.
  ///
  /// In en, this message translates to:
  /// **'This removes every saved DioHub account and its local access token from this device.'**
  String get accountSignOutAllBody;

  /// No description provided for @changelogLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest from our changelog'**
  String get changelogLatest;

  /// No description provided for @changelogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No changelog entries are available.'**
  String get changelogEmpty;

  /// No description provided for @changelogViewAll.
  ///
  /// In en, this message translates to:
  /// **'View changelog →'**
  String get changelogViewAll;

  /// No description provided for @changelogLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the GitHub changelog.'**
  String get changelogLoadError;

  /// No description provided for @relativeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get relativeJustNow;

  /// No description provided for @relativeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String relativeMinutesAgo(int count);

  /// No description provided for @relativeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String relativeHoursAgo(int count);

  /// No description provided for @relativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get relativeYesterday;

  /// No description provided for @relativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String relativeDaysAgo(int count);

  /// No description provided for @relativeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String relativeWeeksAgo(int count);

  /// No description provided for @relativeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String relativeMonthsAgo(int count);

  /// No description provided for @relativeYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String relativeYearsAgo(int count);

  /// No description provided for @repoDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get repoDashboard;

  /// No description provided for @repoRepository.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get repoRepository;

  /// No description provided for @repoLegacyView.
  ///
  /// In en, this message translates to:
  /// **'Legacy view'**
  String get repoLegacyView;

  /// No description provided for @repoOpenNavigation.
  ///
  /// In en, this message translates to:
  /// **'Open navigation'**
  String get repoOpenNavigation;

  /// No description provided for @repoSearchGitHub.
  ///
  /// In en, this message translates to:
  /// **'Search GitHub'**
  String get repoSearchGitHub;

  /// No description provided for @repoRefreshRepository.
  ///
  /// In en, this message translates to:
  /// **'Refresh repository'**
  String get repoRefreshRepository;

  /// No description provided for @repoOptions.
  ///
  /// In en, this message translates to:
  /// **'Repository options'**
  String get repoOptions;

  /// No description provided for @repoOpenLegacyLayout.
  ///
  /// In en, this message translates to:
  /// **'Open legacy layout'**
  String get repoOpenLegacyLayout;

  /// No description provided for @repoOpenNewLayout.
  ///
  /// In en, this message translates to:
  /// **'Open new layout'**
  String get repoOpenNewLayout;

  /// No description provided for @repoLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading repository…'**
  String get repoLoading;

  /// No description provided for @repoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Repository unavailable'**
  String get repoUnavailable;

  /// No description provided for @repoLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading repository: {error}'**
  String repoLoadError(String error);

  /// No description provided for @repoCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get repoCode;

  /// No description provided for @repoIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get repoIssues;

  /// No description provided for @repoPullRequests.
  ///
  /// In en, this message translates to:
  /// **'Pull requests'**
  String get repoPullRequests;

  /// No description provided for @repoActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get repoActions;

  /// No description provided for @repoProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get repoProjects;

  /// No description provided for @repoSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get repoSecurity;

  /// No description provided for @repoInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get repoInsights;

  /// No description provided for @repoPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get repoPublic;

  /// No description provided for @repoPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get repoPrivate;

  /// No description provided for @repoArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get repoArchived;

  /// No description provided for @repoForkedFrom.
  ///
  /// In en, this message translates to:
  /// **'Forked from {repository}'**
  String repoForkedFrom(String repository);

  /// No description provided for @repoAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get repoAbout;

  /// No description provided for @repoNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get repoNoDescription;

  /// No description provided for @repoContributing.
  ///
  /// In en, this message translates to:
  /// **'Contributing'**
  String get repoContributing;

  /// No description provided for @repoSecurityPolicy.
  ///
  /// In en, this message translates to:
  /// **'Security policy'**
  String get repoSecurityPolicy;

  /// No description provided for @repoStarsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stars'**
  String repoStarsCount(String count);

  /// No description provided for @repoForksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} forks'**
  String repoForksCount(String count);

  /// No description provided for @repoWatchingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} watching'**
  String repoWatchingCount(String count);

  /// No description provided for @repoBranchesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} branches'**
  String repoBranchesCount(String count);

  /// No description provided for @repoTagsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tags'**
  String repoTagsCount(String count);

  /// No description provided for @repoReleases.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get repoReleases;

  /// No description provided for @repoLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get repoLatest;

  /// No description provided for @repoSponsorProject.
  ///
  /// In en, this message translates to:
  /// **'Sponsor this project'**
  String get repoSponsorProject;

  /// No description provided for @repoLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get repoLanguages;

  /// No description provided for @repoContributors.
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get repoContributors;

  /// No description provided for @repoLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get repoLicense;

  /// No description provided for @repoDocumentNotFound.
  ///
  /// In en, this message translates to:
  /// **'This document is not available on the selected branch.'**
  String get repoDocumentNotFound;

  /// No description provided for @repoDocumentLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this document: {error}'**
  String repoDocumentLoadError(String error);

  /// No description provided for @repoFunding.
  ///
  /// In en, this message translates to:
  /// **'Funding'**
  String get repoFunding;

  /// No description provided for @repoWatchCount.
  ///
  /// In en, this message translates to:
  /// **'Watch {count}'**
  String repoWatchCount(String count);

  /// No description provided for @repoForkCount.
  ///
  /// In en, this message translates to:
  /// **'Fork {count}'**
  String repoForkCount(String count);

  /// No description provided for @repoStarCount.
  ///
  /// In en, this message translates to:
  /// **'Star {count}'**
  String repoStarCount(String count);

  /// No description provided for @repoAllActivity.
  ///
  /// In en, this message translates to:
  /// **'All activity'**
  String get repoAllActivity;

  /// No description provided for @repoNotWatching.
  ///
  /// In en, this message translates to:
  /// **'Not watching'**
  String get repoNotWatching;

  /// No description provided for @repoIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get repoIgnore;

  /// No description provided for @repoNotMigrated.
  ///
  /// In en, this message translates to:
  /// **'{tab} is not migrated yet'**
  String repoNotMigrated(String tab);

  /// No description provided for @repoPhaseCodeOnly.
  ///
  /// In en, this message translates to:
  /// **'This phase only rewrites the Repository Code page. Use the legacy layout for the existing implementation.'**
  String get repoPhaseCodeOnly;

  /// No description provided for @repoReadme.
  ///
  /// In en, this message translates to:
  /// **'README'**
  String get repoReadme;

  /// No description provided for @repoEditReadme.
  ///
  /// In en, this message translates to:
  /// **'Edit README on GitHub'**
  String get repoEditReadme;

  /// No description provided for @repoEditReadmeRequiresWrite.
  ///
  /// In en, this message translates to:
  /// **'Write permission is required to edit README'**
  String get repoEditReadmeRequiresWrite;

  /// No description provided for @repoReadmeOutlineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'README outline is not available in this phase.'**
  String get repoReadmeOutlineUnavailable;

  /// No description provided for @repoOpenSubmoduleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Opening submodules is not available in this phase.'**
  String get repoOpenSubmoduleUnavailable;

  /// No description provided for @repoFileSearchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Repository-wide file search is not available in this phase.'**
  String get repoFileSearchUnavailable;

  /// No description provided for @repoGoToFile.
  ///
  /// In en, this message translates to:
  /// **'Go to file'**
  String get repoGoToFile;

  /// No description provided for @repoClearFileFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear file filter'**
  String get repoClearFileFilter;

  /// No description provided for @repoFilterCurrentDirectory.
  ///
  /// In en, this message translates to:
  /// **'Filter current directory'**
  String get repoFilterCurrentDirectory;

  /// No description provided for @repoGoToFileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Go to file (not available)'**
  String get repoGoToFileUnavailable;

  /// No description provided for @repoCreateNewFile.
  ///
  /// In en, this message translates to:
  /// **'Create new file'**
  String get repoCreateNewFile;

  /// No description provided for @repoCodeOptions.
  ///
  /// In en, this message translates to:
  /// **'Code options'**
  String get repoCodeOptions;

  /// No description provided for @repoBrowsingCommit.
  ///
  /// In en, this message translates to:
  /// **'Browsing commit {commit}. Editing is disabled.'**
  String repoBrowsingCommit(String commit);

  /// No description provided for @repoDefaultBranch.
  ///
  /// In en, this message translates to:
  /// **'Default branch'**
  String get repoDefaultBranch;

  /// No description provided for @repoSwitchBranch.
  ///
  /// In en, this message translates to:
  /// **'Switch branch…'**
  String get repoSwitchBranch;

  /// No description provided for @repoSwitchTag.
  ///
  /// In en, this message translates to:
  /// **'Switch tag…'**
  String get repoSwitchTag;

  /// No description provided for @repoUploadFilesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Upload files (not available)'**
  String get repoUploadFilesUnavailable;

  /// No description provided for @repoAddFile.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get repoAddFile;

  /// No description provided for @repoViewUpstream.
  ///
  /// In en, this message translates to:
  /// **'View upstream'**
  String get repoViewUpstream;

  /// No description provided for @repoLoadingLatestCommit.
  ///
  /// In en, this message translates to:
  /// **'Loading latest commit…'**
  String get repoLoadingLatestCommit;

  /// No description provided for @repoLatestCommitUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Latest commit unavailable'**
  String get repoLatestCommitUnavailable;

  /// No description provided for @repoRetryLatestCommit.
  ///
  /// In en, this message translates to:
  /// **'Retry latest commit'**
  String get repoRetryLatestCommit;

  /// No description provided for @repoNoCommitInformation.
  ///
  /// In en, this message translates to:
  /// **'No commit information for this directory'**
  String get repoNoCommitInformation;

  /// No description provided for @repoUnknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown author'**
  String get repoUnknownAuthor;

  /// No description provided for @repoNameColumn.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get repoNameColumn;

  /// No description provided for @repoLastCommitColumn.
  ///
  /// In en, this message translates to:
  /// **'Last commit'**
  String get repoLastCommitColumn;

  /// No description provided for @repoUpdatedColumn.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get repoUpdatedColumn;

  /// No description provided for @repoCouldNotLoadFiles.
  ///
  /// In en, this message translates to:
  /// **'Could not load repository files'**
  String get repoCouldNotLoadFiles;

  /// No description provided for @repoNoMatchingFiles.
  ///
  /// In en, this message translates to:
  /// **'No matching files'**
  String get repoNoMatchingFiles;

  /// No description provided for @repoDirectoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'This directory is empty'**
  String get repoDirectoryEmpty;

  /// No description provided for @repoClearFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Clear the file filter to show every entry.'**
  String get repoClearFilterHint;

  /// No description provided for @repoCloneRepository.
  ///
  /// In en, this message translates to:
  /// **'Clone repository'**
  String get repoCloneRepository;

  /// No description provided for @repoDirectory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get repoDirectory;

  /// No description provided for @repoSubmodule.
  ///
  /// In en, this message translates to:
  /// **'Submodule'**
  String get repoSubmodule;

  /// No description provided for @repoReadmeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load README: {error}'**
  String repoReadmeLoadError(String error);

  /// No description provided for @repoNoReadme.
  ///
  /// In en, this message translates to:
  /// **'No README'**
  String get repoNoReadme;

  /// No description provided for @repoNoReadmeBody.
  ///
  /// In en, this message translates to:
  /// **'This repository doesn\'t have a README file.'**
  String get repoNoReadmeBody;

  /// No description provided for @repoSearchBranches.
  ///
  /// In en, this message translates to:
  /// **'Search branches…'**
  String get repoSearchBranches;

  /// No description provided for @repoSearchTags.
  ///
  /// In en, this message translates to:
  /// **'Search tags…'**
  String get repoSearchTags;

  /// No description provided for @repoDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get repoDefault;

  /// No description provided for @repoCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get repoCurrent;

  /// No description provided for @repoCopyCloneUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy clone URL'**
  String get repoCopyCloneUrl;

  /// No description provided for @repoOtherLanguages.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get repoOtherLanguages;

  /// No description provided for @repoAllIssues.
  ///
  /// In en, this message translates to:
  /// **'All issues'**
  String get repoAllIssues;

  /// No description provided for @repoNewIssue.
  ///
  /// In en, this message translates to:
  /// **'New issue'**
  String get repoNewIssue;

  /// No description provided for @repoNewPullRequest.
  ///
  /// In en, this message translates to:
  /// **'New pull request'**
  String get repoNewPullRequest;

  /// No description provided for @repoFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get repoFilters;

  /// No description provided for @repoSearchIssues.
  ///
  /// In en, this message translates to:
  /// **'Search issues'**
  String get repoSearchIssues;

  /// No description provided for @repoSearchPullRequests.
  ///
  /// In en, this message translates to:
  /// **'Search pull requests'**
  String get repoSearchPullRequests;

  /// No description provided for @repoOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get repoOpen;

  /// No description provided for @repoClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get repoClosed;

  /// No description provided for @repoSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get repoSort;

  /// No description provided for @repoAssignedToMe.
  ///
  /// In en, this message translates to:
  /// **'Assigned to me'**
  String get repoAssignedToMe;

  /// No description provided for @repoCreatedByMe.
  ///
  /// In en, this message translates to:
  /// **'Created by me'**
  String get repoCreatedByMe;

  /// No description provided for @repoMentioned.
  ///
  /// In en, this message translates to:
  /// **'Mentioned'**
  String get repoMentioned;

  /// No description provided for @repoRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get repoRecentActivity;

  /// No description provided for @repoViews.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get repoViews;

  /// No description provided for @repoMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get repoMilestones;

  /// No description provided for @repoLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get repoLabels;

  /// No description provided for @repoAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get repoAuthor;

  /// No description provided for @repoReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get repoReviews;

  /// No description provided for @repoAssignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get repoAssignee;

  /// No description provided for @filterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get filterClearAll;

  /// No description provided for @filterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get filterDone;

  /// No description provided for @filterMoreFilters.
  ///
  /// In en, this message translates to:
  /// **'More filters'**
  String get filterMoreFilters;

  /// No description provided for @filterAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get filterAdvanced;

  /// No description provided for @filterAdvancedQueryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. is:open label:bug'**
  String get filterAdvancedQueryHint;

  /// No description provided for @filterSelect.
  ///
  /// In en, this message translates to:
  /// **'Select {section}'**
  String filterSelect(String section);

  /// No description provided for @filterSearch.
  ///
  /// In en, this message translates to:
  /// **'Search {section}…'**
  String filterSearch(String section);

  /// No description provided for @filterEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter {section}…'**
  String filterEnter(String section);

  /// No description provided for @filterSearchLabels.
  ///
  /// In en, this message translates to:
  /// **'Search labels…'**
  String get filterSearchLabels;

  /// No description provided for @filterSearchAssignees.
  ///
  /// In en, this message translates to:
  /// **'Search assignees…'**
  String get filterSearchAssignees;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @filterAfter.
  ///
  /// In en, this message translates to:
  /// **'After…'**
  String get filterAfter;

  /// No description provided for @filterBefore.
  ///
  /// In en, this message translates to:
  /// **'Before…'**
  String get filterBefore;

  /// No description provided for @filterRange.
  ///
  /// In en, this message translates to:
  /// **'Range…'**
  String get filterRange;

  /// No description provided for @filterMinimum.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get filterMinimum;

  /// No description provided for @filterMaximum.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get filterMaximum;

  /// No description provided for @filterNoOptions.
  ///
  /// In en, this message translates to:
  /// **'No options'**
  String get filterNoOptions;

  /// No description provided for @filterOptionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load options'**
  String get filterOptionsLoadError;

  /// No description provided for @filterNoMilestone.
  ///
  /// In en, this message translates to:
  /// **'No milestone'**
  String get filterNoMilestone;

  /// No description provided for @filterUnsupportedPicker.
  ///
  /// In en, this message translates to:
  /// **'This filter is not supported yet.'**
  String get filterUnsupportedPicker;

  /// No description provided for @filterNoItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get filterNoItemsFound;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// No description provided for @filterLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get filterLabel;

  /// No description provided for @filterMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get filterMilestone;

  /// No description provided for @filterBaseBranch.
  ///
  /// In en, this message translates to:
  /// **'Base branch'**
  String get filterBaseBranch;

  /// No description provided for @filterHeadBranch.
  ///
  /// In en, this message translates to:
  /// **'Head branch'**
  String get filterHeadBranch;

  /// No description provided for @filterCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get filterCreated;

  /// No description provided for @filterUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get filterUpdated;

  /// No description provided for @filterComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get filterComments;

  /// No description provided for @filterReactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get filterReactions;

  /// No description provided for @filterInteractions.
  ///
  /// In en, this message translates to:
  /// **'Interactions'**
  String get filterInteractions;

  /// No description provided for @filterDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get filterDraft;

  /// No description provided for @filterReviewStatus.
  ///
  /// In en, this message translates to:
  /// **'Review status'**
  String get filterReviewStatus;

  /// No description provided for @filterReviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by'**
  String get filterReviewedBy;

  /// No description provided for @filterReviewRequested.
  ///
  /// In en, this message translates to:
  /// **'Review requested'**
  String get filterReviewRequested;

  /// No description provided for @filterTeamRequested.
  ///
  /// In en, this message translates to:
  /// **'Team requested'**
  String get filterTeamRequested;

  /// No description provided for @filterLinkedIssue.
  ///
  /// In en, this message translates to:
  /// **'Linked issue'**
  String get filterLinkedIssue;

  /// No description provided for @filterExclude.
  ///
  /// In en, this message translates to:
  /// **'Exclude'**
  String get filterExclude;

  /// No description provided for @filterClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get filterClosed;

  /// No description provided for @filterMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get filterMerged;

  /// No description provided for @filterOptionMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get filterOptionMerged;

  /// No description provided for @filterOptionBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best match'**
  String get filterOptionBestMatch;

  /// No description provided for @filterOptionNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get filterOptionNewest;

  /// No description provided for @filterOptionOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get filterOptionOldest;

  /// No description provided for @filterOptionMostComments.
  ///
  /// In en, this message translates to:
  /// **'Most comments'**
  String get filterOptionMostComments;

  /// No description provided for @filterOptionRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get filterOptionRecentlyUpdated;

  /// No description provided for @filterOptionNoReview.
  ///
  /// In en, this message translates to:
  /// **'No review'**
  String get filterOptionNoReview;

  /// No description provided for @filterOptionReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Review required'**
  String get filterOptionReviewRequired;

  /// No description provided for @filterOptionApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get filterOptionApproved;

  /// No description provided for @filterOptionChangesRequested.
  ///
  /// In en, this message translates to:
  /// **'Changes requested'**
  String get filterOptionChangesRequested;

  /// No description provided for @filterOptionDraftOnly.
  ///
  /// In en, this message translates to:
  /// **'Draft only'**
  String get filterOptionDraftOnly;

  /// No description provided for @filterOptionNonDraftOnly.
  ///
  /// In en, this message translates to:
  /// **'Non-draft only'**
  String get filterOptionNonDraftOnly;

  /// No description provided for @filterOptionHasLinkedPullRequest.
  ///
  /// In en, this message translates to:
  /// **'Has linked pull request'**
  String get filterOptionHasLinkedPullRequest;

  /// No description provided for @filterOptionHasLinkedIssue.
  ///
  /// In en, this message translates to:
  /// **'Has linked issue'**
  String get filterOptionHasLinkedIssue;

  /// No description provided for @filterOptionNoLabels.
  ///
  /// In en, this message translates to:
  /// **'No labels'**
  String get filterOptionNoLabels;

  /// No description provided for @filterOptionNoMilestone.
  ///
  /// In en, this message translates to:
  /// **'No milestone'**
  String get filterOptionNoMilestone;

  /// No description provided for @filterOptionNoAssignee.
  ///
  /// In en, this message translates to:
  /// **'No assignee'**
  String get filterOptionNoAssignee;

  /// No description provided for @repoIssuesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Issues unavailable'**
  String get repoIssuesUnavailable;

  /// No description provided for @repoIssuesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Issues are disabled for this repository.'**
  String get repoIssuesDisabled;

  /// No description provided for @repoNoOpenIssues.
  ///
  /// In en, this message translates to:
  /// **'There aren’t any open issues.'**
  String get repoNoOpenIssues;

  /// No description provided for @repoNoClosedIssues.
  ///
  /// In en, this message translates to:
  /// **'There aren’t any closed issues.'**
  String get repoNoClosedIssues;

  /// No description provided for @repoNoOpenPullRequests.
  ///
  /// In en, this message translates to:
  /// **'There aren’t any open pull requests.'**
  String get repoNoOpenPullRequests;

  /// No description provided for @repoNoClosedPullRequests.
  ///
  /// In en, this message translates to:
  /// **'There aren’t any closed pull requests.'**
  String get repoNoClosedPullRequests;

  /// No description provided for @repoAdjustSearchFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search filters.'**
  String get repoAdjustSearchFilters;

  /// No description provided for @repoIssuePullLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this list.'**
  String get repoIssuePullLoadError;

  /// No description provided for @repoSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get repoSignInRequired;

  /// No description provided for @repoAccountStateLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the local account state.'**
  String get repoAccountStateLoadError;

  /// No description provided for @repoSignInToBrowseIssues.
  ///
  /// In en, this message translates to:
  /// **'Sign in to browse and filter this repository\'s issues.'**
  String get repoSignInToBrowseIssues;

  /// No description provided for @repoSignInToBrowsePullRequests.
  ///
  /// In en, this message translates to:
  /// **'Sign in to browse and filter this repository\'s pull requests.'**
  String get repoSignInToBrowsePullRequests;

  /// No description provided for @repoListOpened.
  ///
  /// In en, this message translates to:
  /// **'opened'**
  String get repoListOpened;

  /// No description provided for @repoListClosed.
  ///
  /// In en, this message translates to:
  /// **'closed'**
  String get repoListClosed;

  /// No description provided for @repoListDraft.
  ///
  /// In en, this message translates to:
  /// **'draft'**
  String get repoListDraft;

  /// No description provided for @repoListMerged.
  ///
  /// In en, this message translates to:
  /// **'merged'**
  String get repoListMerged;

  /// No description provided for @repoIssuePullListMetadata.
  ///
  /// In en, this message translates to:
  /// **'#{number} · {author} {action} {time}'**
  String repoIssuePullListMetadata(
    int number,
    String author,
    String action,
    String time,
  );

  /// No description provided for @repoCommentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String repoCommentsCount(int count);

  /// No description provided for @activityNoRecent.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get activityNoRecent;

  /// No description provided for @activityNoRecentBody.
  ///
  /// In en, this message translates to:
  /// **'Activity from people and repositories you follow will appear here.'**
  String get activityNoRecentBody;

  /// No description provided for @activityRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get activityRefresh;

  /// No description provided for @activityLoadMoreError.
  ///
  /// In en, this message translates to:
  /// **'Could not load more activity: {error}'**
  String activityLoadMoreError(String error);

  /// No description provided for @activityIssueState.
  ///
  /// In en, this message translates to:
  /// **'{action, select, opened{{count, plural, =1{opened an issue} other{opened {count} issues}}} closed{{count, plural, =1{closed an issue} other{closed {count} issues}}} reopened{{count, plural, =1{reopened an issue} other{reopened {count} issues}}} readyForReview{{count, plural, =1{marked an issue as ready} other{marked {count} issues as ready}}} convertedToDraft{{count, plural, =1{converted an issue to draft} other{converted {count} issues to draft}}} other{{count, plural, =1{updated an issue} other{updated {count} issues}}}}'**
  String activityIssueState(String action, int count);

  /// No description provided for @activityPullRequestState.
  ///
  /// In en, this message translates to:
  /// **'{action, select, opened{{count, plural, =1{opened a pull request} other{opened {count} pull requests}}} closed{{count, plural, =1{closed a pull request} other{closed {count} pull requests}}} reopened{{count, plural, =1{reopened a pull request} other{reopened {count} pull requests}}} merged{{count, plural, =1{merged a pull request} other{merged {count} pull requests}}} readyForReview{{count, plural, =1{marked a pull request as ready} other{marked {count} pull requests as ready}}} convertedToDraft{{count, plural, =1{converted a pull request to draft} other{converted {count} pull requests to draft}}} other{{count, plural, =1{updated a pull request} other{updated {count} pull requests}}}}'**
  String activityPullRequestState(String action, int count);

  /// No description provided for @activityPush.
  ///
  /// In en, this message translates to:
  /// **'{branches, plural, =1{{commits, plural, =1{pushed a commit} other{pushed {commits} commits}}} other{pushed {commits} commits to {branches} branches}}'**
  String activityPush(int commits, int branches);

  /// No description provided for @activityLabelsUpdated.
  ///
  /// In en, this message translates to:
  /// **'updated labels'**
  String get activityLabelsUpdated;

  /// No description provided for @activityLabelsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{added a label} other{added {count} labels}}'**
  String activityLabelsAdded(int count);

  /// No description provided for @activityLabelsRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{removed a label} other{removed {count} labels}}'**
  String activityLabelsRemoved(int count);

  /// No description provided for @activityComments.
  ///
  /// In en, this message translates to:
  /// **'{action, select, created{{count, plural, =1{added a comment} other{added {count} comments}}} edited{{count, plural, =1{edited a comment} other{edited {count} comments}}} deleted{{count, plural, =1{deleted a comment} other{deleted {count} comments}}} other{{count, plural, =1{updated a comment} other{updated {count} comments}}}}'**
  String activityComments(String action, int count);

  /// No description provided for @activityReferences.
  ///
  /// In en, this message translates to:
  /// **'{action, select, created{{kind, select, branch{{count, plural, =1{created a branch} other{created {count} branches}}} tag{{count, plural, =1{created a tag} other{created {count} tags}}} other{{count, plural, =1{created a reference} other{created {count} references}}}}} deleted{{kind, select, branch{{count, plural, =1{deleted a branch} other{deleted {count} branches}}} tag{{count, plural, =1{deleted a tag} other{deleted {count} tags}}} other{{count, plural, =1{deleted a reference} other{deleted {count} references}}}}} other{{count, plural, =1{updated a reference} other{updated {count} references}}}}'**
  String activityReferences(String action, String kind, int count);

  /// No description provided for @activityStarredRepositories.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{starred a repository} other{starred {count} repositories}}'**
  String activityStarredRepositories(int count);

  /// No description provided for @activityForkedRepositories.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{forked a repository} other{forked {count} repositories}}'**
  String activityForkedRepositories(int count);

  /// No description provided for @activityMadeRepositoriesPublic.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{made a repository public} other{made {count} repositories public}}'**
  String activityMadeRepositoriesPublic(int count);

  /// No description provided for @activityMembers.
  ///
  /// In en, this message translates to:
  /// **'{action, select, removed{{count, plural, =1{removed a member} other{removed {count} members}}} other{{count, plural, =1{added a member} other{added {count} members}}}}'**
  String activityMembers(String action, int count);

  /// No description provided for @activityAssignedIssues.
  ///
  /// In en, this message translates to:
  /// **'{action, select, unassigned{{count, plural, =1{unassigned an issue} other{unassigned {count} issues}}} other{{count, plural, =1{assigned an issue} other{assigned {count} issues}}}}'**
  String activityAssignedIssues(String action, int count);

  /// No description provided for @activityReviews.
  ///
  /// In en, this message translates to:
  /// **'{state, select, approved{{count, plural, =1{approved a pull request} other{approved {count} pull requests}}} changesRequested{{count, plural, =1{requested changes on a pull request} other{requested changes on {count} pull requests}}} dismissed{{count, plural, =1{dismissed a review on a pull request} other{dismissed reviews on {count} pull requests}}} other{{count, plural, =1{reviewed a pull request} other{reviewed {count} pull requests}}}}'**
  String activityReviews(String state, int count);

  /// No description provided for @activityPublishedReleases.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{published a release} other{published {count} releases}}'**
  String activityPublishedReleases(int count);

  /// No description provided for @activityStartedDiscussions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{started a discussion} other{started {count} discussions}}'**
  String activityStartedDiscussions(int count);

  /// No description provided for @activityUpdatedWikiPages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{updated wiki pages} =1{updated a wiki page} other{updated {count} wiki pages}}'**
  String activityUpdatedWikiPages(int count);

  /// No description provided for @activityPerformedActions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{performed an action} other{performed {count} actions}}'**
  String activityPerformedActions(int count);

  /// No description provided for @activityJoinTwo.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String activityJoinTwo(String first, String second);

  /// No description provided for @activityJoinMany.
  ///
  /// In en, this message translates to:
  /// **'{head}, and {last}'**
  String activityJoinMany(String head, String last);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
