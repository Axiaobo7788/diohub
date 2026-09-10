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

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

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

  /// No description provided for @notificationsInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get notificationsInbox;

  /// No description provided for @notificationsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get notificationsSaved;

  /// No description provided for @notificationsDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get notificationsDone;

  /// No description provided for @notificationsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsAll;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsUnread;

  /// No description provided for @notificationsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notifications'**
  String get notificationsSearchHint;

  /// No description provided for @notificationsClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear notification search'**
  String get notificationsClearSearch;

  /// No description provided for @notificationsSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by: {value}'**
  String notificationsSortLabel(String value);

  /// No description provided for @notificationsGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group by: {value}'**
  String notificationsGroupLabel(String value);

  /// No description provided for @notificationsNewestToOldest.
  ///
  /// In en, this message translates to:
  /// **'Newest to oldest'**
  String get notificationsNewestToOldest;

  /// No description provided for @notificationsOldestToNewest.
  ///
  /// In en, this message translates to:
  /// **'Oldest to newest'**
  String get notificationsOldestToNewest;

  /// No description provided for @notificationsRepository.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get notificationsRepository;

  /// No description provided for @notificationsRepositories.
  ///
  /// In en, this message translates to:
  /// **'Repositories'**
  String get notificationsRepositories;

  /// No description provided for @notificationsAllRepositories.
  ///
  /// In en, this message translates to:
  /// **'All repositories'**
  String get notificationsAllRepositories;

  /// No description provided for @notificationsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get notificationsDate;

  /// No description provided for @notificationsDateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get notificationsDateUnknown;

  /// No description provided for @notificationsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh notifications'**
  String get notificationsRefresh;

  /// No description provided for @notificationsSyncing.
  ///
  /// In en, this message translates to:
  /// **'Checking for notification updates'**
  String get notificationsSyncing;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get notificationsMarkRead;

  /// No description provided for @notificationsMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get notificationsMarkDone;

  /// No description provided for @notificationsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all loaded notifications'**
  String get notificationsSelectAll;

  /// No description provided for @notificationsClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get notificationsClearSelection;

  /// No description provided for @notificationsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String notificationsSelectedCount(int count);

  /// No description provided for @notificationsBulkDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 notification marked as done.} other{{count} notifications marked as done.}}'**
  String notificationsBulkDone(int count);

  /// No description provided for @notificationsBulkFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 notification could not be updated.} other{{count} notifications could not be updated.}}'**
  String notificationsBulkFailed(int count);

  /// No description provided for @notificationsFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get notificationsFilters;

  /// No description provided for @notificationsFilterReasons.
  ///
  /// In en, this message translates to:
  /// **'Reasons'**
  String get notificationsFilterReasons;

  /// No description provided for @notificationsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get notificationsClearFilters;

  /// No description provided for @notificationsAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get notificationsAssigned;

  /// No description provided for @notificationsParticipating.
  ///
  /// In en, this message translates to:
  /// **'Participating'**
  String get notificationsParticipating;

  /// No description provided for @notificationsAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get notificationsAuthor;

  /// No description provided for @notificationsComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get notificationsComment;

  /// No description provided for @notificationsInvitation.
  ///
  /// In en, this message translates to:
  /// **'Invitation'**
  String get notificationsInvitation;

  /// No description provided for @notificationsFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get notificationsFollowing;

  /// No description provided for @notificationsMentioned.
  ///
  /// In en, this message translates to:
  /// **'Mentioned'**
  String get notificationsMentioned;

  /// No description provided for @notificationsReviewRequested.
  ///
  /// In en, this message translates to:
  /// **'Review requested'**
  String get notificationsReviewRequested;

  /// No description provided for @notificationsSecurityAlert.
  ///
  /// In en, this message translates to:
  /// **'Security alert'**
  String get notificationsSecurityAlert;

  /// No description provided for @notificationsStateChange.
  ///
  /// In en, this message translates to:
  /// **'State change'**
  String get notificationsStateChange;

  /// No description provided for @notificationsSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get notificationsSubscribed;

  /// No description provided for @notificationsTeamMention.
  ///
  /// In en, this message translates to:
  /// **'Team mention'**
  String get notificationsTeamMention;

  /// No description provided for @notificationsCiActivity.
  ///
  /// In en, this message translates to:
  /// **'CI activity'**
  String get notificationsCiActivity;

  /// No description provided for @notificationsReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String notificationsReason(String reason);

  /// No description provided for @notificationsCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up'**
  String get notificationsCaughtUp;

  /// No description provided for @notificationsNoUnread.
  ///
  /// In en, this message translates to:
  /// **'You have no unread notifications.'**
  String get notificationsNoUnread;

  /// No description provided for @notificationsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No notifications match the selected filters.'**
  String get notificationsNoResults;

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Notifications could not be loaded.'**
  String get notificationsLoadError;

  /// No description provided for @notificationsRefreshError.
  ///
  /// In en, this message translates to:
  /// **'New notification state could not be checked. Existing notifications are unchanged.'**
  String get notificationsRefreshError;

  /// No description provided for @notificationsUpdateError.
  ///
  /// In en, this message translates to:
  /// **'The notification could not be updated.'**
  String get notificationsUpdateError;

  /// No description provided for @notificationsSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view notifications'**
  String get notificationsSignInTitle;

  /// No description provided for @notificationsSignInBody.
  ///
  /// In en, this message translates to:
  /// **'GitHub notifications are private to your account.'**
  String get notificationsSignInBody;

  /// No description provided for @notificationsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open notification'**
  String get notificationsOpen;

  /// No description provided for @notificationsAddFilter.
  ///
  /// In en, this message translates to:
  /// **'Add new filter'**
  String get notificationsAddFilter;

  /// No description provided for @notificationsFilterName.
  ///
  /// In en, this message translates to:
  /// **'Filter name'**
  String get notificationsFilterName;

  /// No description provided for @notificationsFilterQuery.
  ///
  /// In en, this message translates to:
  /// **'Filter query'**
  String get notificationsFilterQuery;

  /// No description provided for @notificationsSaveFilter.
  ///
  /// In en, this message translates to:
  /// **'Save filter'**
  String get notificationsSaveFilter;

  /// No description provided for @notificationsCleanupTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear out the clutter.'**
  String get notificationsCleanupTitle;

  /// No description provided for @notificationsCleanupBody.
  ///
  /// In en, this message translates to:
  /// **'Select the read notifications currently loaded so you can mark them as done.'**
  String get notificationsCleanupBody;

  /// No description provided for @notificationsDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get notificationsDismiss;

  /// No description provided for @notificationsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get notificationsGetStarted;

  /// No description provided for @notificationsSectionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{section} cannot be listed through the current GitHub API.'**
  String notificationsSectionUnavailable(String section);

  /// No description provided for @notificationsSavedHistoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The public GitHub API cannot list or change saved notifications.'**
  String get notificationsSavedHistoryUnavailable;

  /// No description provided for @notificationsDoneHistoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Marking a notification as done syncs with GitHub, but the public API cannot list completed history.'**
  String get notificationsDoneHistoryUnavailable;

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

  /// No description provided for @homeAddContext.
  ///
  /// In en, this message translates to:
  /// **'Add context'**
  String get homeAddContext;

  /// No description provided for @homeSelectModel.
  ///
  /// In en, this message translates to:
  /// **'Select model'**
  String get homeSelectModel;

  /// No description provided for @homeSendPrompt.
  ///
  /// In en, this message translates to:
  /// **'Send prompt'**
  String get homeSendPrompt;

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

  /// No description provided for @globalListsSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your work'**
  String get globalListsSignInTitle;

  /// No description provided for @globalListsSignInDescription.
  ///
  /// In en, this message translates to:
  /// **'Issues, pull requests, repositories, projects, and discussions associated with your account are available after sign-in.'**
  String get globalListsSignInDescription;

  /// No description provided for @globalListsSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get globalListsSignInAction;

  /// No description provided for @globalListsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get globalListsAll;

  /// No description provided for @globalListsSearchIssues.
  ///
  /// In en, this message translates to:
  /// **'Search your issues'**
  String get globalListsSearchIssues;

  /// No description provided for @globalListsSearchPullRequests.
  ///
  /// In en, this message translates to:
  /// **'Search your pull requests'**
  String get globalListsSearchPullRequests;

  /// No description provided for @globalListsSearchRepositories.
  ///
  /// In en, this message translates to:
  /// **'Find a repository'**
  String get globalListsSearchRepositories;

  /// No description provided for @globalListsSearchProjects.
  ///
  /// In en, this message translates to:
  /// **'Find a project'**
  String get globalListsSearchProjects;

  /// No description provided for @globalListsSearchDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Search discussions involving you'**
  String get globalListsSearchDiscussions;

  /// No description provided for @globalListsResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String globalListsResultsCount(int count);

  /// No description provided for @globalListsNoIssues.
  ///
  /// In en, this message translates to:
  /// **'No issues match these filters'**
  String get globalListsNoIssues;

  /// No description provided for @globalListsNoPullRequests.
  ///
  /// In en, this message translates to:
  /// **'No pull requests match these filters'**
  String get globalListsNoPullRequests;

  /// No description provided for @globalListsNoRepositories.
  ///
  /// In en, this message translates to:
  /// **'No repositories match these filters'**
  String get globalListsNoRepositories;

  /// No description provided for @globalListsNoResultsDescription.
  ///
  /// In en, this message translates to:
  /// **'Try changing the search text or filters.'**
  String get globalListsNoResultsDescription;

  /// No description provided for @globalListsRepositoriesFor.
  ///
  /// In en, this message translates to:
  /// **'Repositories available to @{login}'**
  String globalListsRepositoriesFor(String login);

  /// No description provided for @globalListsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String globalListsUpdated(String time);

  /// No description provided for @globalListsIssueMetadata.
  ///
  /// In en, this message translates to:
  /// **'{repository} #{number} {action} by {author} {time}'**
  String globalListsIssueMetadata(
    String repository,
    int number,
    String action,
    String author,
    String time,
  );

  /// No description provided for @globalListsBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best match'**
  String get globalListsBestMatch;

  /// No description provided for @globalListsNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get globalListsNewest;

  /// No description provided for @globalListsOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get globalListsOldest;

  /// No description provided for @globalListsMostComments.
  ///
  /// In en, this message translates to:
  /// **'Most comments'**
  String get globalListsMostComments;

  /// No description provided for @globalListsRecentlyPushed.
  ///
  /// In en, this message translates to:
  /// **'Recently pushed'**
  String get globalListsRecentlyPushed;

  /// No description provided for @globalListsRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get globalListsRecentlyUpdated;

  /// No description provided for @globalListsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get globalListsName;

  /// No description provided for @globalListsMostStars.
  ///
  /// In en, this message translates to:
  /// **'Most stars'**
  String get globalListsMostStars;

  /// No description provided for @globalListsMostForks.
  ///
  /// In en, this message translates to:
  /// **'Most forks'**
  String get globalListsMostForks;

  /// No description provided for @globalListsMirrors.
  ///
  /// In en, this message translates to:
  /// **'Mirrors'**
  String get globalListsMirrors;

  /// No description provided for @globalListsForks.
  ///
  /// In en, this message translates to:
  /// **'Forks'**
  String get globalListsForks;

  /// No description provided for @globalListsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get globalListsClearFilters;

  /// No description provided for @globalListsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh results'**
  String get globalListsRefresh;

  /// No description provided for @globalListsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load results.'**
  String get globalListsLoadError;

  /// No description provided for @globalListsNewIssue.
  ///
  /// In en, this message translates to:
  /// **'New issue'**
  String get globalListsNewIssue;

  /// No description provided for @globalListsNewPullRequest.
  ///
  /// In en, this message translates to:
  /// **'New pull request'**
  String get globalListsNewPullRequest;

  /// No description provided for @globalProjectsOwnedBy.
  ///
  /// In en, this message translates to:
  /// **'Projects owned by @{login}'**
  String globalProjectsOwnedBy(String login);

  /// No description provided for @globalProjectsNew.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get globalProjectsNew;

  /// No description provided for @globalProjectsOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open this project.'**
  String get globalProjectsOpenError;

  /// No description provided for @globalProjectsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No projects match this search'**
  String get globalProjectsEmpty;

  /// No description provided for @globalProjectsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get globalProjectsOpen;

  /// No description provided for @globalProjectsClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get globalProjectsClosed;

  /// No description provided for @globalProjectsMetadata.
  ///
  /// In en, this message translates to:
  /// **'#{number} · {state} · {updated}'**
  String globalProjectsMetadata(int number, String state, String updated);

  /// No description provided for @globalProjectsPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Project access required'**
  String get globalProjectsPermissionTitle;

  /// No description provided for @globalProjectsPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'This account token does not include the project permission required to read your GitHub Projects.'**
  String get globalProjectsPermissionDescription;

  /// No description provided for @globalProjectsReauthorize.
  ///
  /// In en, this message translates to:
  /// **'Re-authorize account'**
  String get globalProjectsReauthorize;

  /// No description provided for @globalDiscussionsInvolving.
  ///
  /// In en, this message translates to:
  /// **'Discussions authored, mentioned, or commented on by @{login}'**
  String globalDiscussionsInvolving(String login);

  /// No description provided for @globalDiscussionsAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get globalDiscussionsAnswered;

  /// No description provided for @globalDiscussionsUnanswered.
  ///
  /// In en, this message translates to:
  /// **'Unanswered'**
  String get globalDiscussionsUnanswered;

  /// No description provided for @globalDiscussionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No discussions match this search'**
  String get globalDiscussionsEmpty;

  /// No description provided for @globalDiscussionsOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open this discussion.'**
  String get globalDiscussionsOpenError;

  /// No description provided for @globalDiscussionsMetadata.
  ///
  /// In en, this message translates to:
  /// **'{repository} · {author} · Updated {time}'**
  String globalDiscussionsMetadata(
    String repository,
    String author,
    String time,
  );

  /// No description provided for @globalListsSelectRepository.
  ///
  /// In en, this message translates to:
  /// **'Select a repository'**
  String get globalListsSelectRepository;

  /// No description provided for @globalListsChooseIssueTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose an issue template'**
  String get globalListsChooseIssueTemplate;

  /// No description provided for @globalListsBlankIssue.
  ///
  /// In en, this message translates to:
  /// **'Blank issue'**
  String get globalListsBlankIssue;

  /// No description provided for @globalListsCreateFlowError.
  ///
  /// In en, this message translates to:
  /// **'Could not start the create flow.'**
  String get globalListsCreateFlowError;

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

  /// No description provided for @profileOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get profileOverview;

  /// No description provided for @profileRepositories.
  ///
  /// In en, this message translates to:
  /// **'Repositories'**
  String get profileRepositories;

  /// No description provided for @profileProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get profileProjects;

  /// No description provided for @profilePackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get profilePackages;

  /// No description provided for @profileStars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get profileStars;

  /// No description provided for @profileRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh profile'**
  String get profileRefresh;

  /// No description provided for @profileOptions.
  ///
  /// In en, this message translates to:
  /// **'Profile options'**
  String get profileOptions;

  /// No description provided for @profileOpenLegacyLayout.
  ///
  /// In en, this message translates to:
  /// **'Open legacy profile'**
  String get profileOpenLegacyLayout;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get profileFollow;

  /// No description provided for @profileUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get profileUnfollow;

  /// No description provided for @profileFollowersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 follower} other{{count} followers}}'**
  String profileFollowersCount(int count);

  /// No description provided for @profileFollowingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} following'**
  String profileFollowingCount(int count);

  /// No description provided for @profilePinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get profilePinned;

  /// No description provided for @profileContributions.
  ///
  /// In en, this message translates to:
  /// **'Contributions'**
  String get profileContributions;

  /// No description provided for @profileContributionActivity.
  ///
  /// In en, this message translates to:
  /// **'Contribution activity'**
  String get profileContributionActivity;

  /// No description provided for @profileContributionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load contributions.'**
  String get profileContributionsLoadError;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load {login}\'s profile.'**
  String profileLoadError(String login);

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

  /// No description provided for @repoWiki.
  ///
  /// In en, this message translates to:
  /// **'Wiki'**
  String get repoWiki;

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

  /// No description provided for @wikiPages.
  ///
  /// In en, this message translates to:
  /// **'Wiki pages'**
  String get wikiPages;

  /// No description provided for @wikiCurrentPage.
  ///
  /// In en, this message translates to:
  /// **'Current page: {page}'**
  String wikiCurrentPage(String page);

  /// No description provided for @wikiNoPages.
  ///
  /// In en, this message translates to:
  /// **'No wiki pages'**
  String get wikiNoPages;

  /// No description provided for @wikiNoPagesDescription.
  ///
  /// In en, this message translates to:
  /// **'This repository does not have a wiki yet.'**
  String get wikiNoPagesDescription;

  /// No description provided for @wikiCreateOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'Create wiki on GitHub'**
  String get wikiCreateOnGitHub;

  /// No description provided for @wikiOpenOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'Open wiki on GitHub'**
  String get wikiOpenOnGitHub;

  /// No description provided for @wikiLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this repository wiki.'**
  String get wikiLoadError;

  /// No description provided for @wikiPageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the wiki page.'**
  String get wikiPageLoadError;

  /// No description provided for @issueDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this issue.'**
  String get issueDetailLoadError;

  /// No description provided for @pullRequestDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this pull request.'**
  String get pullRequestDetailLoadError;

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

  /// No description provided for @repoStarredFeedback.
  ///
  /// In en, this message translates to:
  /// **'Repository starred'**
  String get repoStarredFeedback;

  /// No description provided for @repoUnstarredFeedback.
  ///
  /// In en, this message translates to:
  /// **'Repository unstarred'**
  String get repoUnstarredFeedback;

  /// No description provided for @repoStarUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Could not update the repository star.'**
  String get repoStarUpdateError;

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

  /// No description provided for @publicGitHubRateLimitReached.
  ///
  /// In en, this message translates to:
  /// **'GitHub\'s unsigned API limit has been reached. Sign in for a higher limit or try again later.'**
  String get publicGitHubRateLimitReached;

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

  /// No description provided for @repoSecondaryTabSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Repository Actions, Projects, Security, and Insights use authenticated GitHub endpoints.'**
  String get repoSecondaryTabSignInBody;

  /// No description provided for @repoAllWorkflows.
  ///
  /// In en, this message translates to:
  /// **'All workflows'**
  String get repoAllWorkflows;

  /// No description provided for @repoWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get repoWorkflow;

  /// No description provided for @repoWorkflowRun.
  ///
  /// In en, this message translates to:
  /// **'Workflow run'**
  String get repoWorkflowRun;

  /// No description provided for @repoWorkflowRunsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workflow run} other{{count} workflow runs}}'**
  String repoWorkflowRunsCount(int count);

  /// No description provided for @repoFilterBranch.
  ///
  /// In en, this message translates to:
  /// **'Filter by branch'**
  String get repoFilterBranch;

  /// No description provided for @repoNoWorkflowRuns.
  ///
  /// In en, this message translates to:
  /// **'No workflow runs found'**
  String get repoNoWorkflowRuns;

  /// No description provided for @repoNoWorkflowRunsBody.
  ///
  /// In en, this message translates to:
  /// **'This workflow has no runs matching the current branch filter.'**
  String get repoNoWorkflowRunsBody;

  /// No description provided for @repoActionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load workflow runs'**
  String get repoActionsLoadError;

  /// No description provided for @repoWorkflowsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load workflows'**
  String get repoWorkflowsLoadError;

  /// No description provided for @repoProjectsDescription.
  ///
  /// In en, this message translates to:
  /// **'Repository projects track work across issues and pull requests.'**
  String get repoProjectsDescription;

  /// No description provided for @repoProjectsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load projects'**
  String get repoProjectsLoadError;

  /// No description provided for @repoNoProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get repoNoProjects;

  /// No description provided for @repoNoProjectsBody.
  ///
  /// In en, this message translates to:
  /// **'This repository has no projects matching the selected order.'**
  String get repoNoProjectsBody;

  /// No description provided for @repoSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get repoSortTitle;

  /// No description provided for @repoProjectItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String repoProjectItemsCount(int count);

  /// No description provided for @repoUpdatedTime.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String repoUpdatedTime(String time);

  /// No description provided for @repoSecurityOverview.
  ///
  /// In en, this message translates to:
  /// **'Security overview'**
  String get repoSecurityOverview;

  /// No description provided for @repoSecurityPolicyChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking the default branch for a security policy.'**
  String get repoSecurityPolicyChecking;

  /// No description provided for @repoSecurityPolicyMissing.
  ///
  /// In en, this message translates to:
  /// **'No SECURITY.md policy was found on the default branch.'**
  String get repoSecurityPolicyMissing;

  /// No description provided for @repoSecurityPolicyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The security policy could not be checked.'**
  String get repoSecurityPolicyUnavailable;

  /// No description provided for @repoSecurityPolicyFound.
  ///
  /// In en, this message translates to:
  /// **'Security policy detected at {path}'**
  String repoSecurityPolicyFound(String path);

  /// No description provided for @repoDependabot.
  ///
  /// In en, this message translates to:
  /// **'Dependabot'**
  String get repoDependabot;

  /// No description provided for @repoCodeScanning.
  ///
  /// In en, this message translates to:
  /// **'Code scanning'**
  String get repoCodeScanning;

  /// No description provided for @repoSecretScanning.
  ///
  /// In en, this message translates to:
  /// **'Secret scanning'**
  String get repoSecretScanning;

  /// No description provided for @repoNoDependabotAlerts.
  ///
  /// In en, this message translates to:
  /// **'No Dependabot alerts'**
  String get repoNoDependabotAlerts;

  /// No description provided for @repoNoCodeScanningAlerts.
  ///
  /// In en, this message translates to:
  /// **'No code scanning alerts'**
  String get repoNoCodeScanningAlerts;

  /// No description provided for @repoNoSecretScanningAlerts.
  ///
  /// In en, this message translates to:
  /// **'No secret scanning alerts'**
  String get repoNoSecretScanningAlerts;

  /// No description provided for @repoSecurityNoAlertsBody.
  ///
  /// In en, this message translates to:
  /// **'No alerts are currently visible for this repository and account.'**
  String get repoSecurityNoAlertsBody;

  /// No description provided for @repoSecurityDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Security data unavailable'**
  String get repoSecurityDataUnavailable;

  /// No description provided for @repoSecurityPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'GitHub may require repository administration permission or the feature may be disabled. {error}'**
  String repoSecurityPermissionBody(String error);

  /// No description provided for @repoSecurityAlertsLoaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 visible alert} other{{count} visible alerts}}'**
  String repoSecurityAlertsLoaded(int count);

  /// No description provided for @repoSecurityAlertsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Open to load alerts'**
  String get repoSecurityAlertsNotLoaded;

  /// No description provided for @repoUnknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get repoUnknownLocation;

  /// No description provided for @repoSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get repoSecret;

  /// No description provided for @repoPulse.
  ///
  /// In en, this message translates to:
  /// **'Pulse'**
  String get repoPulse;

  /// No description provided for @repoTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get repoTraffic;

  /// No description provided for @repoCommunityStandards.
  ///
  /// In en, this message translates to:
  /// **'Community standards'**
  String get repoCommunityStandards;

  /// No description provided for @repoCommitActivity.
  ///
  /// In en, this message translates to:
  /// **'Commit activity'**
  String get repoCommitActivity;

  /// No description provided for @repoCommitsLastYear.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 commit in the last year} other{{count} commits in the last year}}'**
  String repoCommitsLastYear(int count);

  /// No description provided for @repoNoContributors.
  ///
  /// In en, this message translates to:
  /// **'No contributor statistics are available.'**
  String get repoNoContributors;

  /// No description provided for @repoUnknownContributor.
  ///
  /// In en, this message translates to:
  /// **'Unknown contributor'**
  String get repoUnknownContributor;

  /// No description provided for @repoContributionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contribution} other{{count} contributions}}'**
  String repoContributionsCount(int count);

  /// No description provided for @repoClones.
  ///
  /// In en, this message translates to:
  /// **'Clones'**
  String get repoClones;

  /// No description provided for @repoTopReferrers.
  ///
  /// In en, this message translates to:
  /// **'Top referrers'**
  String get repoTopReferrers;

  /// No description provided for @repoPopularContent.
  ///
  /// In en, this message translates to:
  /// **'Popular content'**
  String get repoPopularContent;

  /// No description provided for @repoTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get repoTotal;

  /// No description provided for @repoUnique.
  ///
  /// In en, this message translates to:
  /// **'Unique'**
  String get repoUnique;

  /// No description provided for @repoUniqueVisitors.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unique visitor} other{{count} unique visitors}}'**
  String repoUniqueVisitors(int count);

  /// No description provided for @repoNoInsightData.
  ///
  /// In en, this message translates to:
  /// **'No data is available for this section.'**
  String get repoNoInsightData;

  /// No description provided for @repoInsightsDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Insights data unavailable'**
  String get repoInsightsDataUnavailable;

  /// No description provided for @repoInsightsPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Some repository statistics are delayed or require push access. {error}'**
  String repoInsightsPermissionBody(String error);

  /// No description provided for @repoCommunityHealth.
  ///
  /// In en, this message translates to:
  /// **'Community profile health: {percent}%'**
  String repoCommunityHealth(int percent);

  /// No description provided for @repoCodeOfConduct.
  ///
  /// In en, this message translates to:
  /// **'Code of conduct'**
  String get repoCodeOfConduct;

  /// No description provided for @repoIssueTemplate.
  ///
  /// In en, this message translates to:
  /// **'Issue template'**
  String get repoIssueTemplate;

  /// No description provided for @repoPullRequestTemplate.
  ///
  /// In en, this message translates to:
  /// **'Pull request template'**
  String get repoPullRequestTemplate;

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

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsPageDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your GitHub account and DioHub preferences in one place.'**
  String get settingsPageDescription;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsCategory.
  ///
  /// In en, this message translates to:
  /// **'Settings category'**
  String get settingsCategory;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get settingsAccessibility;

  /// No description provided for @settingsCodeAndRepositories.
  ///
  /// In en, this message translates to:
  /// **'Code & repositories'**
  String get settingsCodeAndRepositories;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & diagnostics'**
  String get settingsPrivacy;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'The setting could not be saved.'**
  String get settingsSaveError;

  /// No description provided for @settingsGeneralDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language, information density, and default browsing behavior.'**
  String get settingsGeneralDescription;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsAppLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow the operating system or choose a language for DioHub.'**
  String get settingsAppLanguageDescription;

  /// No description provided for @settingsLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get settingsLayout;

  /// No description provided for @settingsLayoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Use one density across shared Android and desktop layouts.'**
  String get settingsLayoutDescription;

  /// No description provided for @settingsDensity.
  ///
  /// In en, this message translates to:
  /// **'Information density'**
  String get settingsDensity;

  /// No description provided for @settingsDensityDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust spacing without shrinking text or touch targets.'**
  String get settingsDensityDescription;

  /// No description provided for @settingsDensityCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get settingsDensityCompact;

  /// No description provided for @settingsDensityDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsDensityDefault;

  /// No description provided for @settingsDensitySpacious.
  ///
  /// In en, this message translates to:
  /// **'Spacious'**
  String get settingsDensitySpacious;

  /// No description provided for @settingsStickyHeaders.
  ///
  /// In en, this message translates to:
  /// **'Sticky section headers'**
  String get settingsStickyHeaders;

  /// No description provided for @settingsStickyHeadersDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep section context visible while scrolling supported legacy views.'**
  String get settingsStickyHeadersDescription;

  /// No description provided for @settingsFeedAndSearch.
  ///
  /// In en, this message translates to:
  /// **'Feed & search'**
  String get settingsFeedAndSearch;

  /// No description provided for @settingsGroupRelatedActivity.
  ///
  /// In en, this message translates to:
  /// **'Group related activity'**
  String get settingsGroupRelatedActivity;

  /// No description provided for @settingsGroupRelatedActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Combine related GitHub events into a single feed entry.'**
  String get settingsGroupRelatedActivityDescription;

  /// No description provided for @settingsTimelineFeed.
  ///
  /// In en, this message translates to:
  /// **'Timeline feed'**
  String get settingsTimelineFeed;

  /// No description provided for @settingsTimelineFeedDescription.
  ///
  /// In en, this message translates to:
  /// **'Show activity with a continuous timeline instead of plain cards.'**
  String get settingsTimelineFeedDescription;

  /// No description provided for @settingsFuzzySearch.
  ///
  /// In en, this message translates to:
  /// **'Fuzzy local filtering'**
  String get settingsFuzzySearch;

  /// No description provided for @settingsFuzzySearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Match approximate text in client-side filters.'**
  String get settingsFuzzySearchDescription;

  /// No description provided for @settingsAppearanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the color mode and how profile colors influence the interface.'**
  String get settingsAppearanceDescription;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Material 3 colors remain centralized and respond immediately.'**
  String get settingsThemeDescription;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow the system or keep DioHub light or dark.'**
  String get settingsThemeModeDescription;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsMaterialYou.
  ///
  /// In en, this message translates to:
  /// **'Use system colors'**
  String get settingsMaterialYou;

  /// No description provided for @settingsMaterialYouDescription.
  ///
  /// In en, this message translates to:
  /// **'Use dynamic Material You colors when the platform provides them.'**
  String get settingsMaterialYouDescription;

  /// No description provided for @settingsProfileColors.
  ///
  /// In en, this message translates to:
  /// **'Profile colors'**
  String get settingsProfileColors;

  /// No description provided for @settingsProfileColorsDescription.
  ///
  /// In en, this message translates to:
  /// **'Optionally blend a profile avatar color into profile pages.'**
  String get settingsProfileColorsDescription;

  /// No description provided for @settingsProfileTheme.
  ///
  /// In en, this message translates to:
  /// **'Profile-based color'**
  String get settingsProfileTheme;

  /// No description provided for @settingsProfileThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Apply a scoped color treatment when viewing a profile.'**
  String get settingsProfileThemeDescription;

  /// No description provided for @settingsProfileThemeIntensity.
  ///
  /// In en, this message translates to:
  /// **'Color intensity'**
  String get settingsProfileThemeIntensity;

  /// No description provided for @settingsProfileThemeIntensityDescription.
  ///
  /// In en, this message translates to:
  /// **'Control how strongly the profile color is blended.'**
  String get settingsProfileThemeIntensityDescription;

  /// No description provided for @settingsAccessibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Control motion and physical feedback while preserving platform accessibility preferences.'**
  String get settingsAccessibilityDescription;

  /// No description provided for @settingsMotion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get settingsMotion;

  /// No description provided for @settingsMotionDescription.
  ///
  /// In en, this message translates to:
  /// **'The operating system Reduced Motion preference always takes priority.'**
  String get settingsMotionDescription;

  /// No description provided for @settingsAnimationLevel.
  ///
  /// In en, this message translates to:
  /// **'Animation level'**
  String get settingsAnimationLevel;

  /// No description provided for @settingsAnimationLevelDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how much interface motion DioHub adds.'**
  String get settingsAnimationLevelDescription;

  /// No description provided for @settingsAnimationNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get settingsAnimationNone;

  /// No description provided for @settingsAnimationReduced.
  ///
  /// In en, this message translates to:
  /// **'Reduced'**
  String get settingsAnimationReduced;

  /// No description provided for @settingsAnimationNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get settingsAnimationNormal;

  /// No description provided for @settingsAnimationEnhanced.
  ///
  /// In en, this message translates to:
  /// **'Enhanced'**
  String get settingsAnimationEnhanced;

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsHaptics;

  /// No description provided for @settingsHapticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Control vibration feedback on supported devices.'**
  String get settingsHapticsDescription;

  /// No description provided for @settingsHapticsOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsHapticsOn;

  /// No description provided for @settingsHapticsReduced.
  ///
  /// In en, this message translates to:
  /// **'Reduced'**
  String get settingsHapticsReduced;

  /// No description provided for @settingsHapticsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsHapticsOff;

  /// No description provided for @settingsCodeAndRepositoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Set repository entry behavior, file browsing details, and diff readability.'**
  String get settingsCodeAndRepositoriesDescription;

  /// No description provided for @settingsRepositoryDefaults.
  ///
  /// In en, this message translates to:
  /// **'Repository defaults'**
  String get settingsRepositoryDefaults;

  /// No description provided for @settingsDefaultRepositoryTab.
  ///
  /// In en, this message translates to:
  /// **'Default repository tab'**
  String get settingsDefaultRepositoryTab;

  /// No description provided for @settingsDefaultRepositoryTabDescription.
  ///
  /// In en, this message translates to:
  /// **'Open this tab when a repository link does not specify a destination.'**
  String get settingsDefaultRepositoryTabDescription;

  /// No description provided for @settingsCommits.
  ///
  /// In en, this message translates to:
  /// **'Commits'**
  String get settingsCommits;

  /// No description provided for @settingsCodeBrowser.
  ///
  /// In en, this message translates to:
  /// **'Code browser'**
  String get settingsCodeBrowser;

  /// No description provided for @settingsFileSort.
  ///
  /// In en, this message translates to:
  /// **'File sorting'**
  String get settingsFileSort;

  /// No description provided for @settingsFileSortDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how directories and files are ordered.'**
  String get settingsFileSortDescription;

  /// No description provided for @settingsSortType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get settingsSortType;

  /// No description provided for @settingsSortNameAscending.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get settingsSortNameAscending;

  /// No description provided for @settingsSortNameDescending.
  ///
  /// In en, this message translates to:
  /// **'Name Z–A'**
  String get settingsSortNameDescending;

  /// No description provided for @settingsSortSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get settingsSortSize;

  /// No description provided for @settingsSortExtension.
  ///
  /// In en, this message translates to:
  /// **'Extension'**
  String get settingsSortExtension;

  /// No description provided for @settingsShowDotfiles.
  ///
  /// In en, this message translates to:
  /// **'Show dotfiles'**
  String get settingsShowDotfiles;

  /// No description provided for @settingsShowDotfilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Include files and directories whose names begin with a dot.'**
  String get settingsShowDotfilesDescription;

  /// No description provided for @settingsShowFileMetadata.
  ///
  /// In en, this message translates to:
  /// **'Show file metadata'**
  String get settingsShowFileMetadata;

  /// No description provided for @settingsShowFileMetadataDescription.
  ///
  /// In en, this message translates to:
  /// **'Display available size and type details in the file list.'**
  String get settingsShowFileMetadataDescription;

  /// No description provided for @settingsShowGeneratedFiles.
  ///
  /// In en, this message translates to:
  /// **'Show generated files'**
  String get settingsShowGeneratedFiles;

  /// No description provided for @settingsShowGeneratedFilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Include files GitHub identifies as generated.'**
  String get settingsShowGeneratedFilesDescription;

  /// No description provided for @settingsShowLastCommit.
  ///
  /// In en, this message translates to:
  /// **'Show last commit per path'**
  String get settingsShowLastCommit;

  /// No description provided for @settingsShowLastCommitDescription.
  ///
  /// In en, this message translates to:
  /// **'Fetch commit information for visible paths. Large directories may require extra requests.'**
  String get settingsShowLastCommitDescription;

  /// No description provided for @settingsDiffViewer.
  ///
  /// In en, this message translates to:
  /// **'Diff viewer'**
  String get settingsDiffViewer;

  /// No description provided for @settingsDiffLayout.
  ///
  /// In en, this message translates to:
  /// **'Default diff layout'**
  String get settingsDiffLayout;

  /// No description provided for @settingsDiffLayoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a unified or split comparison.'**
  String get settingsDiffLayoutDescription;

  /// No description provided for @settingsDiffUnified.
  ///
  /// In en, this message translates to:
  /// **'Unified'**
  String get settingsDiffUnified;

  /// No description provided for @settingsDiffSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get settingsDiffSplit;

  /// No description provided for @settingsWrapCode.
  ///
  /// In en, this message translates to:
  /// **'Wrap long lines'**
  String get settingsWrapCode;

  /// No description provided for @settingsWrapCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Wrap code and diff lines to the available width.'**
  String get settingsWrapCodeDescription;

  /// No description provided for @settingsLineNumbers.
  ///
  /// In en, this message translates to:
  /// **'Show line numbers'**
  String get settingsLineNumbers;

  /// No description provided for @settingsLineNumbersDescription.
  ///
  /// In en, this message translates to:
  /// **'Display source line numbers beside code.'**
  String get settingsLineNumbersDescription;

  /// No description provided for @settingsDiffHighlight.
  ///
  /// In en, this message translates to:
  /// **'Change highlight'**
  String get settingsDiffHighlight;

  /// No description provided for @settingsDiffHighlightDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust the contrast of added and removed lines.'**
  String get settingsDiffHighlightDescription;

  /// No description provided for @settingsHighlightSubtle.
  ///
  /// In en, this message translates to:
  /// **'Subtle'**
  String get settingsHighlightSubtle;

  /// No description provided for @settingsHighlightDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsHighlightDefault;

  /// No description provided for @settingsHighlightHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get settingsHighlightHigh;

  /// No description provided for @settingsCodeFontScale.
  ///
  /// In en, this message translates to:
  /// **'Code text size'**
  String get settingsCodeFontScale;

  /// No description provided for @settingsCodeFontScaleDescription.
  ///
  /// In en, this message translates to:
  /// **'Scale monospace content independently from interface text.'**
  String get settingsCodeFontScaleDescription;

  /// No description provided for @settingsNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Control inbox presentation and background notification checks.'**
  String get settingsNotificationsDescription;

  /// No description provided for @settingsInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get settingsInbox;

  /// No description provided for @settingsAutoMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Auto-mark as read'**
  String get settingsAutoMarkRead;

  /// No description provided for @settingsAutoMarkReadDescription.
  ///
  /// In en, this message translates to:
  /// **'Mark notifications as read when they become visible.'**
  String get settingsAutoMarkReadDescription;

  /// No description provided for @settingsGroupByRepository.
  ///
  /// In en, this message translates to:
  /// **'Group by repository'**
  String get settingsGroupByRepository;

  /// No description provided for @settingsGroupByRepositoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Organize loaded notifications under repository headings.'**
  String get settingsGroupByRepositoryDescription;

  /// No description provided for @settingsBackgroundChecks.
  ///
  /// In en, this message translates to:
  /// **'Background checks'**
  String get settingsBackgroundChecks;

  /// No description provided for @settingsBackgroundChecksDescription.
  ///
  /// In en, this message translates to:
  /// **'Background availability depends on platform support and operating system permissions.'**
  String get settingsBackgroundChecksDescription;

  /// No description provided for @settingsInboxPolling.
  ///
  /// In en, this message translates to:
  /// **'Inbox polling'**
  String get settingsInboxPolling;

  /// No description provided for @settingsInboxPollingDescription.
  ///
  /// In en, this message translates to:
  /// **'Periodically check for new GitHub notifications.'**
  String get settingsInboxPollingDescription;

  /// No description provided for @settingsPollingInterval.
  ///
  /// In en, this message translates to:
  /// **'Polling interval'**
  String get settingsPollingInterval;

  /// No description provided for @settingsPollingIntervalDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how often the inbox is checked in the background.'**
  String get settingsPollingIntervalDescription;

  /// No description provided for @settingsMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String settingsMinutes(int count);

  /// No description provided for @settingsSystemNotifications.
  ///
  /// In en, this message translates to:
  /// **'System notifications'**
  String get settingsSystemNotifications;

  /// No description provided for @settingsSystemNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Show operating system notifications while DioHub is in the background.'**
  String get settingsSystemNotificationsDescription;

  /// No description provided for @settingsWorkflowAlerts.
  ///
  /// In en, this message translates to:
  /// **'Workflow run alerts'**
  String get settingsWorkflowAlerts;

  /// No description provided for @settingsWorkflowAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Notify when a watched workflow run completes.'**
  String get settingsWorkflowAlertsDescription;

  /// No description provided for @settingsPrivacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which diagnostics DioHub may collect when reporting failures.'**
  String get settingsPrivacyDescription;

  /// No description provided for @settingsDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settingsDiagnostics;

  /// No description provided for @settingsDiagnosticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic preferences take effect after the next app launch.'**
  String get settingsDiagnosticsDescription;

  /// No description provided for @settingsCrashReports.
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get settingsCrashReports;

  /// No description provided for @settingsCrashReportsDescription.
  ///
  /// In en, this message translates to:
  /// **'Send anonymous stack traces when DioHub crashes.'**
  String get settingsCrashReportsDescription;

  /// No description provided for @settingsHttpDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'HTTP diagnostics'**
  String get settingsHttpDiagnostics;

  /// No description provided for @settingsHttpDiagnosticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Include anonymized API error patterns and timing.'**
  String get settingsHttpDiagnosticsDescription;

  /// No description provided for @settingsNavigationDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Navigation diagnostics'**
  String get settingsNavigationDiagnostics;

  /// No description provided for @settingsNavigationDiagnosticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Include the sequence of screens visited before a crash.'**
  String get settingsNavigationDiagnosticsDescription;

  /// No description provided for @settingsPerformanceDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Performance monitoring'**
  String get settingsPerformanceDiagnostics;

  /// No description provided for @settingsPerformanceDiagnosticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Measure responsiveness and slow operations.'**
  String get settingsPerformanceDiagnosticsDescription;

  /// No description provided for @settingsSessionReplay.
  ///
  /// In en, this message translates to:
  /// **'Session replay'**
  String get settingsSessionReplay;

  /// No description provided for @settingsSessionReplayDescription.
  ///
  /// In en, this message translates to:
  /// **'Record a masked visual trace when a crash occurs.'**
  String get settingsSessionReplayDescription;

  /// No description provided for @settingsRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'Changes to diagnostics take effect after the next app launch.'**
  String get settingsRestartRequired;

  /// No description provided for @settingsAboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Version, release notes, and open-source acknowledgements.'**
  String get settingsAboutDescription;

  /// No description provided for @settingsApplication.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get settingsApplication;

  /// No description provided for @settingsApplicationName.
  ///
  /// In en, this message translates to:
  /// **'DioHub'**
  String get settingsApplicationName;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String settingsVersion(String version, String build);

  /// No description provided for @settingsWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What’s new'**
  String get settingsWhatsNew;

  /// No description provided for @settingsWhatsNewDescription.
  ///
  /// In en, this message translates to:
  /// **'Read the changelog and release history.'**
  String get settingsWhatsNewDescription;

  /// No description provided for @settingsOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsOpenSourceLicenses;

  /// No description provided for @settingsOpenSourceLicensesDescription.
  ///
  /// In en, this message translates to:
  /// **'View licenses for Flutter and bundled dependencies.'**
  String get settingsOpenSourceLicensesDescription;

  /// No description provided for @settingsAccessGroup.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get settingsAccessGroup;

  /// No description provided for @settingsCodePlanningAutomation.
  ///
  /// In en, this message translates to:
  /// **'Code, planning, and automation'**
  String get settingsCodePlanningAutomation;

  /// No description provided for @settingsDioHubGroup.
  ///
  /// In en, this message translates to:
  /// **'DioHub app settings'**
  String get settingsDioHubGroup;

  /// No description provided for @settingsPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get settingsPublicProfile;

  /// No description provided for @settingsGitHubAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsGitHubAccount;

  /// No description provided for @settingsBillingAndLicensing.
  ///
  /// In en, this message translates to:
  /// **'Billing and licensing'**
  String get settingsBillingAndLicensing;

  /// No description provided for @settingsEmails.
  ///
  /// In en, this message translates to:
  /// **'Emails'**
  String get settingsEmails;

  /// No description provided for @settingsPasswordAndAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Password and authentication'**
  String get settingsPasswordAndAuthentication;

  /// No description provided for @settingsSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get settingsSessions;

  /// No description provided for @settingsSshAndGpgKeys.
  ///
  /// In en, this message translates to:
  /// **'SSH and GPG keys'**
  String get settingsSshAndGpgKeys;

  /// No description provided for @settingsOrganizations.
  ///
  /// In en, this message translates to:
  /// **'Organizations'**
  String get settingsOrganizations;

  /// No description provided for @settingsEnterprises.
  ///
  /// In en, this message translates to:
  /// **'Enterprises'**
  String get settingsEnterprises;

  /// No description provided for @settingsModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get settingsModeration;

  /// No description provided for @settingsCodespaces.
  ///
  /// In en, this message translates to:
  /// **'Codespaces'**
  String get settingsCodespaces;

  /// No description provided for @settingsSignedOutDescription.
  ///
  /// In en, this message translates to:
  /// **'DioHub preferences remain available without a GitHub account.'**
  String get settingsSignedOutDescription;

  /// No description provided for @settingsPersonalAccount.
  ///
  /// In en, this message translates to:
  /// **'Your personal account'**
  String get settingsPersonalAccount;

  /// No description provided for @settingsSwitchContext.
  ///
  /// In en, this message translates to:
  /// **'Switch settings context'**
  String get settingsSwitchContext;

  /// No description provided for @settingsPublicProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the information shown on your GitHub profile.'**
  String get settingsPublicProfileDescription;

  /// No description provided for @settingsProfileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsProfileName;

  /// No description provided for @settingsProfilePublicEmail.
  ///
  /// In en, this message translates to:
  /// **'Public email'**
  String get settingsProfilePublicEmail;

  /// No description provided for @settingsProfilePublicEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'This address is visible on your public GitHub profile.'**
  String get settingsProfilePublicEmailDescription;

  /// No description provided for @settingsProfileEmailHidden.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show my email'**
  String get settingsProfileEmailHidden;

  /// No description provided for @settingsProfileEmailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Verified emails could not be loaded. Your current public email is unchanged.'**
  String get settingsProfileEmailLoadError;

  /// No description provided for @settingsProfileBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get settingsProfileBio;

  /// No description provided for @settingsProfilePronouns.
  ///
  /// In en, this message translates to:
  /// **'Pronouns'**
  String get settingsProfilePronouns;

  /// No description provided for @settingsProfileUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get settingsProfileUrl;

  /// No description provided for @settingsProfileCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get settingsProfileCompany;

  /// No description provided for @settingsProfileLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settingsProfileLocation;

  /// No description provided for @settingsProfileTwitter.
  ///
  /// In en, this message translates to:
  /// **'X username'**
  String get settingsProfileTwitter;

  /// No description provided for @settingsProfileAvailableForHire.
  ///
  /// In en, this message translates to:
  /// **'Available for hire'**
  String get settingsProfileAvailableForHire;

  /// No description provided for @settingsProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile picture'**
  String get settingsProfilePicture;

  /// No description provided for @settingsManageProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Edit on GitHub'**
  String get settingsManageProfilePicture;

  /// No description provided for @settingsUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update profile'**
  String get settingsUpdateProfile;

  /// No description provided for @settingsProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your public profile was updated.'**
  String get settingsProfileUpdated;

  /// No description provided for @settingsPublicProfileLoadError.
  ///
  /// In en, this message translates to:
  /// **'DioHub could not load the public profile for this account.'**
  String get settingsPublicProfileLoadError;

  /// No description provided for @settingsManagedByGitHub.
  ///
  /// In en, this message translates to:
  /// **'Continue on GitHub'**
  String get settingsManagedByGitHub;

  /// No description provided for @settingsBrowserOnly.
  ///
  /// In en, this message translates to:
  /// **'GitHub web setting'**
  String get settingsBrowserOnly;

  /// No description provided for @settingsBrowserOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'{setting} does not have a supported public API. DioHub opens the matching page for the active server.'**
  String settingsBrowserOnlyDescription(String setting);

  /// No description provided for @settingsPartialApiCoverage.
  ///
  /// In en, this message translates to:
  /// **'Partial public API'**
  String get settingsPartialApiCoverage;

  /// No description provided for @settingsPartialApiCoverageDescription.
  ///
  /// In en, this message translates to:
  /// **'GitHub exposes only part of {setting} through public APIs. DioHub does not present an incomplete subset as the full setting.'**
  String settingsPartialApiCoverageDescription(String setting);

  /// No description provided for @settingsOAuthScopeRequired.
  ///
  /// In en, this message translates to:
  /// **'Additional authorization required'**
  String get settingsOAuthScopeRequired;

  /// No description provided for @settingsOAuthScopeRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'{setting} has public API coverage, but the current DioHub OAuth scope does not authorize it. Authorization changes are handled separately.'**
  String settingsOAuthScopeRequiredDescription(String setting);

  /// No description provided for @settingsGitHubManagedDescription.
  ///
  /// In en, this message translates to:
  /// **'{setting} is managed by GitHub. DioHub opens the matching page for the active server instead of imitating unavailable private APIs.'**
  String settingsGitHubManagedDescription(String setting);

  /// No description provided for @settingsOpenOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'Open on GitHub'**
  String get settingsOpenOnGitHub;

  /// No description provided for @settingsSignInToManageGitHub.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage this GitHub setting.'**
  String get settingsSignInToManageGitHub;

  /// No description provided for @settingsOpenOnGitHubDescription.
  ///
  /// In en, this message translates to:
  /// **'Open this setting on {host}.'**
  String settingsOpenOnGitHubDescription(String host);

  /// No description provided for @settingsCollectionLoadError.
  ///
  /// In en, this message translates to:
  /// **'DioHub could not load this setting. Check the connection and try again.'**
  String get settingsCollectionLoadError;

  /// No description provided for @settingsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get settingsLoadMore;

  /// No description provided for @settingsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get settingsRefresh;

  /// No description provided for @settingsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDelete;

  /// No description provided for @settingsEmailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the email addresses associated with your GitHub account.'**
  String get settingsEmailsDescription;

  /// No description provided for @settingsAddEmail.
  ///
  /// In en, this message translates to:
  /// **'Add email address'**
  String get settingsAddEmail;

  /// No description provided for @settingsDeleteEmail.
  ///
  /// In en, this message translates to:
  /// **'Delete email address'**
  String get settingsDeleteEmail;

  /// No description provided for @settingsDeleteEmailConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Remove {email} from your GitHub account?'**
  String settingsDeleteEmailConfirmation(String email);

  /// No description provided for @settingsPrimaryEmailVisibility.
  ///
  /// In en, this message translates to:
  /// **'Primary email visibility'**
  String get settingsPrimaryEmailVisibility;

  /// No description provided for @settingsPrimaryEmailVisibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose whether your primary email may be shown on your public GitHub profile.'**
  String get settingsPrimaryEmailVisibilityDescription;

  /// No description provided for @settingsNoEmails.
  ///
  /// In en, this message translates to:
  /// **'No email addresses'**
  String get settingsNoEmails;

  /// No description provided for @settingsNoEmailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add an email address to use it with your GitHub account.'**
  String get settingsNoEmailsDescription;

  /// No description provided for @settingsEmailPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get settingsEmailPrimary;

  /// No description provided for @settingsEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get settingsEmailVerified;

  /// No description provided for @settingsEmailUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get settingsEmailUnverified;

  /// No description provided for @settingsEmailPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get settingsEmailPublic;

  /// No description provided for @settingsEmailPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get settingsEmailPrivate;

  /// No description provided for @settingsEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get settingsEmailAddress;

  /// No description provided for @settingsEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get settingsEmailInvalid;

  /// No description provided for @settingsKeysDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage the keys GitHub uses for authentication and verified signing.'**
  String get settingsKeysDescription;

  /// No description provided for @settingsSshKeys.
  ///
  /// In en, this message translates to:
  /// **'SSH keys'**
  String get settingsSshKeys;

  /// No description provided for @settingsGpgKeys.
  ///
  /// In en, this message translates to:
  /// **'GPG keys'**
  String get settingsGpgKeys;

  /// No description provided for @settingsSshSigningKeys.
  ///
  /// In en, this message translates to:
  /// **'Signing keys'**
  String get settingsSshSigningKeys;

  /// No description provided for @settingsAddKey.
  ///
  /// In en, this message translates to:
  /// **'New key'**
  String get settingsAddKey;

  /// No description provided for @settingsDeleteKey.
  ///
  /// In en, this message translates to:
  /// **'Delete key'**
  String get settingsDeleteKey;

  /// No description provided for @settingsDeleteKeyConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}”? This cannot be undone.'**
  String settingsDeleteKeyConfirmation(String title);

  /// No description provided for @settingsNoSshKeys.
  ///
  /// In en, this message translates to:
  /// **'No SSH keys'**
  String get settingsNoSshKeys;

  /// No description provided for @settingsNoSshKeysDescription.
  ///
  /// In en, this message translates to:
  /// **'Add an SSH key to authenticate Git operations.'**
  String get settingsNoSshKeysDescription;

  /// No description provided for @settingsNoGpgKeys.
  ///
  /// In en, this message translates to:
  /// **'No GPG keys'**
  String get settingsNoGpgKeys;

  /// No description provided for @settingsNoGpgKeysDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a GPG key to mark supported commits and tags as verified.'**
  String get settingsNoGpgKeysDescription;

  /// No description provided for @settingsNoSigningKeys.
  ///
  /// In en, this message translates to:
  /// **'No SSH signing keys'**
  String get settingsNoSigningKeys;

  /// No description provided for @settingsNoSigningKeysDescription.
  ///
  /// In en, this message translates to:
  /// **'Add an SSH signing key for verified Git signatures.'**
  String get settingsNoSigningKeysDescription;

  /// No description provided for @settingsAddedOn.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String settingsAddedOn(String date);

  /// No description provided for @settingsKeyNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get settingsKeyNameOptional;

  /// No description provided for @settingsKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get settingsKeyTitle;

  /// No description provided for @settingsArmoredGpgKey.
  ///
  /// In en, this message translates to:
  /// **'ASCII-armored GPG public key'**
  String get settingsArmoredGpgKey;

  /// No description provided for @settingsPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Public key'**
  String get settingsPublicKey;

  /// No description provided for @settingsFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get settingsFieldRequired;

  /// No description provided for @settingsOrganizationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Organizations associated with your GitHub account. Membership changes continue on GitHub.'**
  String get settingsOrganizationsDescription;

  /// No description provided for @settingsNoOrganizations.
  ///
  /// In en, this message translates to:
  /// **'No organizations'**
  String get settingsNoOrganizations;

  /// No description provided for @settingsNoOrganizationsDescription.
  ///
  /// In en, this message translates to:
  /// **'This account does not currently belong to an organization.'**
  String get settingsNoOrganizationsDescription;

  /// No description provided for @settingsOrganizationSummary.
  ///
  /// In en, this message translates to:
  /// **'{repositories} repositories · {members} members'**
  String settingsOrganizationSummary(int repositories, int members);

  /// No description provided for @settingsRepositoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse repositories available to this account. Administrative controls continue on GitHub.'**
  String get settingsRepositoriesDescription;

  /// No description provided for @settingsNoRepositories.
  ///
  /// In en, this message translates to:
  /// **'No repositories'**
  String get settingsNoRepositories;

  /// No description provided for @settingsNoRepositoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'No repository is available to this account.'**
  String get settingsNoRepositoriesDescription;

  /// No description provided for @settingsFork.
  ///
  /// In en, this message translates to:
  /// **'Fork'**
  String get settingsFork;

  /// No description provided for @settingsStars.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String settingsStars(int count);

  /// No description provided for @settingsUpdatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String settingsUpdatedOn(String date);

  /// No description provided for @settingsModerationDescription.
  ///
  /// In en, this message translates to:
  /// **'Review and manage users blocked by this GitHub account.'**
  String get settingsModerationDescription;

  /// No description provided for @settingsBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block a user'**
  String get settingsBlockUser;

  /// No description provided for @settingsGitHubUsername.
  ///
  /// In en, this message translates to:
  /// **'GitHub username'**
  String get settingsGitHubUsername;

  /// No description provided for @settingsBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get settingsBlock;

  /// No description provided for @settingsNoBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get settingsNoBlockedUsers;

  /// No description provided for @settingsNoBlockedUsersDescription.
  ///
  /// In en, this message translates to:
  /// **'Users blocked by this account will appear here.'**
  String get settingsNoBlockedUsersDescription;

  /// No description provided for @settingsUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get settingsUnblock;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @repoWorkflowStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get repoWorkflowStatusSuccess;

  /// No description provided for @repoWorkflowStatusFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get repoWorkflowStatusFailure;

  /// No description provided for @repoWorkflowStatusTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Timed out'**
  String get repoWorkflowStatusTimedOut;

  /// No description provided for @repoWorkflowStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get repoWorkflowStatusCancelled;

  /// No description provided for @repoWorkflowStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get repoWorkflowStatusInProgress;

  /// No description provided for @repoWorkflowStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get repoWorkflowStatusQueued;

  /// No description provided for @repoWorkflowStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get repoWorkflowStatusWaiting;

  /// No description provided for @repoWorkflowStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get repoWorkflowStatusPending;

  /// No description provided for @repoWorkflowStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown status'**
  String get repoWorkflowStatusUnknown;

  /// No description provided for @compareFileStatusAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get compareFileStatusAdded;

  /// No description provided for @compareFileStatusRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get compareFileStatusRemoved;

  /// No description provided for @compareFileStatusRenamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get compareFileStatusRenamed;

  /// No description provided for @compareFileStatusModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get compareFileStatusModified;

  /// No description provided for @compareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compareTitle;

  /// No description provided for @compareSelectBaseRef.
  ///
  /// In en, this message translates to:
  /// **'Select base ref'**
  String get compareSelectBaseRef;

  /// No description provided for @compareSelectHeadRef.
  ///
  /// In en, this message translates to:
  /// **'Select head ref'**
  String get compareSelectHeadRef;

  /// No description provided for @compareSelectBase.
  ///
  /// In en, this message translates to:
  /// **'Select base…'**
  String get compareSelectBase;

  /// No description provided for @compareSelectHead.
  ///
  /// In en, this message translates to:
  /// **'Select head…'**
  String get compareSelectHead;

  /// No description provided for @compareSwapBaseHead.
  ///
  /// In en, this message translates to:
  /// **'Swap base and head'**
  String get compareSwapBaseHead;

  /// No description provided for @compareEnterRefs.
  ///
  /// In en, this message translates to:
  /// **'Select base and head refs to compare changes.'**
  String get compareEnterRefs;

  /// No description provided for @compareLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load comparison: {error}'**
  String compareLoadError(String error);

  /// No description provided for @compareAhead.
  ///
  /// In en, this message translates to:
  /// **'ahead'**
  String get compareAhead;

  /// No description provided for @compareBehind.
  ///
  /// In en, this message translates to:
  /// **'behind'**
  String get compareBehind;

  /// No description provided for @compareFilesChanged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file changed} other{{count} files changed}}'**
  String compareFilesChanged(int count);

  /// No description provided for @compareCommits.
  ///
  /// In en, this message translates to:
  /// **'Commits'**
  String get compareCommits;

  /// No description provided for @compareFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get compareFiles;

  /// No description provided for @projectPickerLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get projectPickerLinked;

  /// No description provided for @projectPickerAddToProject.
  ///
  /// In en, this message translates to:
  /// **'Add to project'**
  String get projectPickerAddToProject;
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
