import 'dart:async';

import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/providers/users/user_activity_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/app_chrome/app_chrome_layout.dart';
import 'package:diohub/view/profile/md3/profile_md3_screen.dart';
import 'package:diohub/view/profile/md3/profile_navigation.dart';
import 'package:diohub/view/profile/user_profile_screen.dart';
import 'package:diohub_graphql/queries/users/user_info.graphql.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/activity/activity_timeline_event.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final UserProfileData profile = _profileFixture();

  Future<void> pumpProfile(
    final WidgetTester tester, {
    required final Size size,
    final TextScaler textScaler = TextScaler.noScaling,
    final Locale locale = const Locale('en'),
    final bool pending = false,
    final Object? error,
    final bool useProductionEntry = false,
    final VoidCallback? onTimelineFetch,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        settingsCacheProvider.overrideWithValue(
          SettingsCache(<String, String>{}),
        ),
        accountProvider.overrideWith(_SignedOutAccountNotifier.new),
        userProvider.overrideWith2(
          (final UserRef arg) => _ProfileFixtureNotifier(
            arg,
            profile: profile,
            pending: pending,
            error: error,
          ),
        ),
        userContributionsProvider.overrideWith(
          (final Ref ref, final ContributionQueryKey key) =>
              Completer<ContributionCollectionResult>().future,
        ),
        userActivityTimelineSourceProvider.overrideWith(
          (final Ref ref, final ContributionQueryKey key) =>
              PageNumberForwardSource<TimelineEventWithFlags>(
                fetch:
                    ({
                      required final int page,
                      required final int perPage,
                    }) async {
                      onTimelineFetch?.call();
                      return <TimelineEventWithFlags>[];
                    },
              ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true),
          builder: (final BuildContext context, final Widget? child) =>
              MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                child: child!,
              ),
          home: useProductionEntry
              ? const UserProfileScreen(UserRef(login: 'octocat'))
              : ProfileMd3Screen(
                  userRef: const UserRef(login: 'octocat'),
                  onOpenLegacy: () {},
                ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  for (final Size size in const <Size>[
    Size(360, 800),
    Size(800, 900),
    Size(1440, 900),
  ]) {
    testWidgets('Profile Overview uses the responsive MD3 shell at '
        '${size.width.toInt()}px', (final WidgetTester tester) async {
      await pumpProfile(tester, size: size);

      expect(
        find.byKey(const ValueKey<String>('profile-navigation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('profile-identity-panel')),
        findsOneWidget,
      );
      expect(find.text('The Octocat'), findsOneWidget);
      expect(find.text('octocat'), findsWidgets);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Repositories'), findsOneWidget);
      expect(find.text('Pinned'), findsOneWidget);
      expect(find.text('hello-world'), findsOneWidget);
      if (size.width == 360) {
        for (
          int attempt = 0;
          attempt < 6 && find.text('Contributions').evaluate().isEmpty;
          attempt++
        ) {
          await tester.drag(
            find.byKey(const PageStorageKey<String>('profile-overview-scroll')),
            const Offset(0, -320),
          );
          await tester.pump();
        }
      }
      expect(find.text('Contributions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Production profile entry selects the MD3 page', (
    final WidgetTester tester,
  ) async {
    await pumpProfile(
      tester,
      size: const Size(800, 900),
      useProductionEntry: true,
    );

    expect(find.byType(ProfileMd3Screen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('profile-md3-medium')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity can load while contribution calendar is pending', (
    final WidgetTester tester,
  ) async {
    var timelineRequests = 0;
    await pumpProfile(
      tester,
      size: const Size(800, 900),
      onTimelineFetch: () => timelineRequests++,
    );

    for (var attempt = 0; attempt < 8 && timelineRequests == 0; attempt++) {
      await tester.drag(
        find.byKey(const PageStorageKey<String>('profile-overview-scroll')),
        const Offset(0, -400),
      );
      await tester.pump();
    }

    expect(timelineRequests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile chrome and client labels are localized to zh-Hans', (
    final WidgetTester tester,
  ) async {
    await pumpProfile(
      tester,
      size: const Size(800, 900),
      locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );

    expect(find.text('概览'), findsOneWidget);
    expect(find.text('仓库'), findsOneWidget);
    expect(find.text('置顶'), findsOneWidget);
    expect(find.text('贡献'), findsOneWidget);
    expect(
      find.text('A GitHub-style profile rendered with real profile fields.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile uses the shared compact navigation drawer', (
    final WidgetTester tester,
  ) async {
    await pumpProfile(tester, size: const Size(360, 800));

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Drawer), findsOneWidget);
    expect(
      tester.getSize(find.byType(Drawer)).width,
      AppChromeLayout.drawerWidthFor(360),
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'Profile primary paths use the new shell and extension paths do not',
    () {
      for (final String? path in <String?>[
        null,
        '',
        'overview',
        'readme',
        'activity',
        'repositories',
        'projects',
        'packages',
        'stars',
      ]) {
        expect(ProfileNavigationDestination.supportsPath(path), isTrue);
      }
      expect(ProfileNavigationDestination.supportsPath('gists'), isFalse);
      expect(ProfileNavigationDestination.supportsPath('followers'), isFalse);
    },
  );

  testWidgets('Profile remains usable at 360px with 2x text scaling', (
    final WidgetTester tester,
  ) async {
    await pumpProfile(
      tester,
      size: const Size(360, 800),
      textScaler: const TextScaler.linear(2),
    );

    expect(
      find.byKey(const ValueKey<String>('profile-md3-compact')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('profile-navigation')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile loading keeps global chrome and final page structure', (
    final WidgetTester tester,
  ) async {
    await pumpProfile(tester, size: const Size(800, 900), pending: true);

    expect(find.byKey(const ValueKey<String>('global-header')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('profile-md3-medium')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('profile-navigation')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('profile-identity-panel')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile metadata links are visually and semantically links', (
    final WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpProfile(tester, size: const Size(800, 900));
    await tester.pump(const Duration(milliseconds: 400));

    final Finder website = find.text('https://github.blog');
    expect(website, findsOneWidget);
    await tester.ensureVisible(website);
    await tester.pump();
    final Text websiteText = tester.widget<Text>(website);
    expect(websiteText.style?.decoration, TextDecoration.underline);
    expect(
      websiteText.style?.color,
      Theme.of(tester.element(website)).colorScheme.primary,
    );
    final Finder semanticLink = find.bySemanticsLabel('https://github.blog');
    expect(semanticLink, findsOneWidget);
    final SemanticsNode node = tester.getSemantics(semanticLink);
    expect(node.hasFlag(SemanticsFlag.isLink), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Profile error is retryable inside the stable shell', (
    final WidgetTester tester,
  ) async {
    await pumpProfile(
      tester,
      size: const Size(800, 900),
      error: StateError('Profile unavailable'),
    );

    expect(find.text("Could not load octocat's profile."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('profile-navigation')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

UserProfileData _profileFixture() {
  Map<String, dynamic> count(final int value, final String type) =>
      <String, dynamic>{'totalCount': value, '__typename': type};

  final Query$userInfo parsed = Query$userInfo.fromJson(<String, dynamic>{
    'repositoryOwner': <String, dynamic>{
      '__typename': 'User',
      'id': 'U_octocat',
      'login': 'octocat',
      'avatarUrl': '',
      'name': 'The Octocat',
      'bio': 'A GitHub-style profile rendered with real profile fields.',
      'url': 'https://github.com/octocat',
      'location': 'San Francisco',
      'company': '@github',
      'pronouns': 'they/them',
      'isFollowingViewer': false,
      'createdAt': '2011-01-25T18:44:36Z',
      'status': <String, dynamic>{
        'message': 'Building',
        'emoji': ':hammer:',
        'indicatesLimitedAvailability': false,
        '__typename': 'UserStatus',
      },
      'viewerIsFollowing': false,
      'viewerCanFollow': true,
      'repositories': count(12, 'RepositoryConnection'),
      'followers': count(7, 'FollowerConnection'),
      'following': count(24, 'FollowingConnection'),
      'websiteUrl': 'https://github.blog',
      'twitterUsername': null,
      'updatedAt': '2026-07-23T00:00:00Z',
      'isViewer': false,
      'hasSponsorsListing': false,
      'sponsoring': count(0, 'SponsoringConnection'),
      'sponsors': count(0, 'SponsorConnection'),
      'pinnedItems': <String, dynamic>{
        'edges': <dynamic>[
          <String, dynamic>{
            'node': <String, dynamic>{
              '__typename': 'Repository',
              'id': 'R_hello_world',
              'name': 'hello-world',
              'nameWithOwner': 'octocat/hello-world',
              'description': 'A pinned repository from the profile query.',
              'url': 'https://github.com/octocat/hello-world',
              'stargazerCount': 1500,
              'forkCount': 420,
              'watchers': count(8, 'UserConnection'),
              'issues': count(2, 'IssueConnection'),
              'pullRequests': count(1, 'PullRequestConnection'),
              'repositoryTopics': <String, dynamic>{
                'edges': <dynamic>[],
                'totalCount': 0,
                '__typename': 'RepositoryTopicConnection',
              },
              'defaultBranchRef': <String, dynamic>{
                'name': 'main',
                '__typename': 'Ref',
              },
              'createdAt': '2011-01-26T19:01:12Z',
              'primaryLanguage': <String, dynamic>{
                'name': 'Dart',
                'color': '#00B4AB',
                '__typename': 'Language',
              },
              'owner': <String, dynamic>{
                '__typename': 'User',
                'avatarUrl': '',
                'login': 'octocat',
                'url': 'https://github.com/octocat',
              },
              'isPrivate': false,
              'isFork': false,
              'viewerHasStarred': true,
              'viewerSubscription': null,
              'viewerCanSubscribe': true,
              'forkingAllowed': true,
              'isArchived': false,
              'isMirror': false,
              'isTemplate': false,
              'pushedAt': '2026-07-23T00:00:00Z',
              'licenseInfo': null,
            },
            '__typename': 'PinnableItemEdge',
          },
        ],
        '__typename': 'PinnableItemConnection',
      },
      'email': '',
      'isHireable': false,
      'socialAccounts': <String, dynamic>{
        'nodes': <dynamic>[],
        '__typename': 'SocialAccountConnection',
      },
      'isGitHubStar': false,
      'isCampusExpert': false,
      'isDeveloperProgramMember': false,
      'isEmployee': false,
      'isBountyHunter': false,
      'viewerCanSponsor': false,
      'isSponsoringViewer': false,
      'viewerIsSponsoring': false,
      'pullRequests': count(3, 'PullRequestConnection'),
      'issues': count(2, 'IssueConnection'),
      'starredRepositories': count(95, 'StarredRepositoryConnection'),
      'watching': count(4, 'WatchingConnection'),
      'organizations': count(1, 'OrganizationConnection'),
      'gists': count(0, 'GistConnection'),
      'packages': count(0, 'PackageConnection'),
      'projectsV2': count(0, 'ProjectV2Connection'),
    },
    'ownerStats': null,
    'profileReadme': null,
    'orgProfileReadme': null,
    '__typename': 'Query',
  });
  return UserProfileData(
    owner: parsed.repositoryOwner!,
    repoCount: 12,
    hasProfileReadme: false,
  );
}

final class _SignedOutAccountNotifier extends AccountNotifier {
  @override
  Future<AccountSession?> build() async => null;
}

final class _ProfileFixtureNotifier extends UserProfileNotifier {
  _ProfileFixtureNotifier(
    super.userRef, {
    required this.profile,
    required this.pending,
    required this.error,
  });

  final UserProfileData profile;
  final bool pending;
  final Object? error;

  @override
  Future<UserProfileData> build() {
    if (pending) return Completer<UserProfileData>().future;
    if (error != null) return Future<UserProfileData>.error(error!);
    return Future<UserProfileData>.value(profile);
  }
}
