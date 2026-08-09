import 'dart:async';

import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/users/email_item.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/settings/md3/settings_md3_layout.dart';
import 'package:diohub/view/settings/settings_screen.dart';
import 'package:diohub_graphql/queries/users/user_info.graphql.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsDestination', () {
    test('keeps GitHub and DioHub route namespaces distinct', () {
      expect(
        SettingsDestination.fromPath('appearance'),
        SettingsDestination.githubAppearance,
      );
      expect(
        SettingsDestination.fromPath('repositories'),
        SettingsDestination.githubRepositories,
      );
      expect(
        SettingsDestination.fromPath('app/appearance'),
        SettingsDestination.dioHubAppearance,
      );
      expect(
        SettingsDestination.fromPath('unknown'),
        SettingsDestination.publicProfile,
      );
    });
  });

  group('SettingsMd3Page responsive layout', () {
    for (final ({Size size, SettingsWindowClass windowClass}) scenario
        in <({Size size, SettingsWindowClass windowClass})>[
          (
            size: const Size(360, 800),
            windowClass: SettingsWindowClass.compact,
          ),
          (size: const Size(800, 900), windowClass: SettingsWindowClass.medium),
          (
            size: const Size(1440, 960),
            windowClass: SettingsWindowClass.expanded,
          ),
        ]) {
      testWidgets('renders ${scenario.windowClass.name} settings at '
          '${scenario.size.width.toInt()}px', (
        final WidgetTester tester,
      ) async {
        await _pumpSettings(tester, size: scenario.size);

        expect(
          find.byKey(
            ValueKey<String>('settings-md3-${scenario.windowClass.name}'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('settings-general-page')),
          findsOneWidget,
        );
        if (scenario.windowClass == SettingsWindowClass.compact) {
          expect(
            find.byKey(
              const ValueKey<String>('settings-compact-navigation-app'),
            ),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey<String>('settings-sidebar')),
            findsNothing,
          );
        } else {
          expect(
            find.byKey(const ValueKey<String>('settings-sidebar')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('wide navigation swaps one content tree and announces it', (
      final WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pumpSettings(tester, size: const Size(1440, 960));

      final Finder destination = find.byKey(
        const ValueKey<String>('settings-nav-app-appearance'),
      );
      await tester.scrollUntilVisible(
        destination,
        240,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey<String>('settings-sidebar')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(destination).height, greaterThanOrEqualTo(48));
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(
                const ValueKey<String>('settings-nav-indicator-app-appearance'),
              ),
            )
            .duration,
        kContentTransitionDuration,
      );
      await tester.tap(destination);
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('settings-appearance-page')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings-general-page')),
        findsNothing,
      );
      final SemanticsNode selectedDestination = tester.getSemantics(
        destination,
      );
      expect(selectedDestination.hasFlag(SemanticsFlag.isSelected), isTrue);
      final SemanticsNode announcement = tester.getSemantics(
        find.byKey(const ValueKey<String>('settings-content-announcement')),
      );
      expect(announcement.label, 'Appearance');
      expect(announcement.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('compact settings menu resists comfortable density shrinking', (
      final WidgetTester tester,
    ) async {
      await _pumpSettings(
        tester,
        size: const Size(360, 800),
        visualDensity: VisualDensity.comfortable,
      );

      final Finder trigger = find.byKey(
        const ValueKey<String>('settings-compact-navigation-app'),
      );
      expect(tester.getSize(trigger).height, greaterThanOrEqualTo(48));
      await tester.tap(trigger);
      await tester.pumpAndSettle();

      final Finder destination = find.byKey(
        const ValueKey<String>('settings-compact-nav-app-appearance'),
      );
      expect(destination, findsOneWidget);
      expect(tester.getSize(destination).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('honors a DioHub deep-linked section on the first frame', (
      final WidgetTester tester,
    ) async {
      await _pumpSettings(
        tester,
        size: const Size(800, 900),
        initialSection: 'app/notifications',
      );

      expect(
        find.byKey(const ValueKey<String>('settings-notifications-page')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders GitHub groups before the DioHub group', (
      final WidgetTester tester,
    ) async {
      await _pumpSettings(tester, size: const Size(1440, 960));

      expect(find.text('Access'), findsOneWidget);
      expect(find.text('Code, planning, and automation'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('settings-group-app')),
        240,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey<String>('settings-sidebar')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.byKey(const ValueKey<String>('settings-group-app')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('signed-in profile keeps the stable GitHub settings shell', (
      final WidgetTester tester,
    ) async {
      final AccountModel account = AccountModel(
        nodeId: 'U_octocat',
        username: 'octocat',
        displayName: 'The Octocat',
        addedAt: DateTime.utc(2026),
      );

      await _pumpSettings(
        tester,
        size: const Size(1440, 960),
        account: account,
        initialSection: 'profile',
      );

      expect(find.text('The Octocat (octocat)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('settings-public-profile-loading')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings-sidebar')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact account header exposes the context switch action', (
      final WidgetTester tester,
    ) async {
      final AccountModel account = _settingsAccount();
      int switchCalls = 0;

      await _pumpSettings(
        tester,
        size: const Size(360, 800),
        account: account,
        onSwitchContext: () => switchCalls++,
      );

      final Finder switchContext = find.byKey(
        const ValueKey<String>('settings-switch-context-compact'),
      );
      expect(switchContext, findsOneWidget);
      expect(find.byTooltip('Switch settings context'), findsOneWidget);
      await tester.tap(switchContext);
      expect(switchCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('public profile submits one atomic update action', (
      final WidgetTester tester,
    ) async {
      final AccountModel account = AccountModel(
        nodeId: 'U_octocat',
        username: 'octocat',
        displayName: 'The Octocat',
        addedAt: DateTime.utc(2026),
      );
      final List<_EditableUserProfileNotifier> notifiers =
          <_EditableUserProfileNotifier>[];

      await _pumpSettings(
        tester,
        size: const Size(1440, 960),
        account: account,
        initialSection: 'profile',
        profileNotifier: (final UserRef userRef) {
          final _EditableUserProfileNotifier notifier =
              _EditableUserProfileNotifier(userRef);
          notifiers.add(notifier);
          return notifier;
        },
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('settings-public-profile-page')),
        findsOneWidget,
      );
      final Finder nameField = find.byKey(
        const ValueKey<String>('settings-profile-name'),
      );
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Octo Cat');
      await tester.pump();
      final Finder update = find.byKey(
        const ValueKey<String>('settings-update-profile'),
      );
      await Scrollable.ensureVisible(tester.element(update), alignment: 0.8);
      expect(tester.widget<FilledButton>(update).onPressed, isNotNull);
      await tester.tap(update);
      await tester.pumpAndSettle();

      expect(
        notifiers.fold<int>(
          0,
          (final int total, final _EditableUserProfileNotifier notifier) =>
              total + notifier.updateCalls,
        ),
        1,
      );
      final _EditableUserProfileNotifier updated = notifiers.singleWhere(
        (final _EditableUserProfileNotifier notifier) =>
            notifier.updateCalls == 1,
      );
      expect(updated.updatedFields?['name'], 'Octo Cat');
      expect(updated.updatedFields, hasLength(8));
      expect(find.text('Your public profile was updated.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses generated Simplified Chinese strings', (
      final WidgetTester tester,
    ) async {
      await _pumpSettings(
        tester,
        size: const Size(360, 800),
        locale: const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
        ),
      );

      expect(find.text('DioHub 应用设置'), findsOneWidget);
      expect(find.text('常规'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('remains usable at 360px with 200 percent text scaling', (
      final WidgetTester tester,
    ) async {
      await _pumpSettings(
        tester,
        size: const Size(360, 800),
        textScaler: const TextScaler.linear(2),
      );

      expect(
        find.byKey(const ValueKey<String>('settings-compact-navigation-app')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('disables destination transition when motion is reduced', (
      final WidgetTester tester,
    ) async {
      await _pumpSettings(
        tester,
        size: const Size(800, 900),
        disableAnimations: true,
      );

      const SettingsDestination currentDestination =
          SettingsDestination.dioHubGeneral;
      final String currentKey = currentDestination.path.replaceAll('/', '-');
      final TweenAnimationBuilder<double> transition = tester
          .widget<TweenAnimationBuilder<double>>(
            find.byKey(
              ValueKey<String>('settings-content-transition-$currentKey'),
            ),
          );
      expect(transition.duration, Duration.zero);
      await tester.scrollUntilVisible(
        find.byKey(ValueKey<String>('settings-nav-$currentKey')),
        240,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey<String>('settings-sidebar')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(
                ValueKey<String>('settings-nav-indicator-$currentKey'),
              ),
            )
            .duration,
        Duration.zero,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpSettings(
  final WidgetTester tester, {
  required final Size size,
  final String? initialSection,
  final AccountModel? account,
  final Locale locale = const Locale('en'),
  final TextScaler textScaler = TextScaler.noScaling,
  final bool disableAnimations = false,
  final VisualDensity visualDensity = VisualDensity.standard,
  final VoidCallback? onSwitchContext,
  final UserProfileNotifier Function(UserRef userRef)? profileNotifier,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(() {
    tester.view
      ..resetDevicePixelRatio()
      ..resetPhysicalSize();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        settingsCacheProvider.overrideWithValue(
          SettingsCache(<String, String>{}),
        ),
        viewerVerifiedEmailsProvider.overrideWith(
          (final Ref ref) async => const <EmailItem>[
            EmailItem(
              email: 'octocat@example.com',
              primary: true,
              verified: true,
            ),
          ],
        ),
        if (account != null)
          userProvider.overrideWith2(
            profileNotifier ?? _PendingUserProfileNotifier.new,
          ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true, visualDensity: visualDensity),
        builder: (final BuildContext context, final Widget? child) =>
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: textScaler,
                disableAnimations: disableAnimations,
              ),
              child: child!,
            ),
        home: Scaffold(
          body: SettingsMd3Page(
            initialSection: initialSection,
            account: account,
            onSwitchContext: onSwitchContext,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

AccountModel _settingsAccount() => AccountModel(
  nodeId: 'U_octocat',
  username: 'octocat',
  displayName: 'The Octocat',
  addedAt: DateTime.utc(2026),
);

final class _PendingUserProfileNotifier extends UserProfileNotifier {
  _PendingUserProfileNotifier(super.userRef);

  @override
  Future<UserProfileData> build() => Completer<UserProfileData>().future;
}

final class _EditableUserProfileNotifier extends UserProfileNotifier {
  _EditableUserProfileNotifier(super.userRef);

  int updateCalls = 0;
  Map<String, dynamic>? updatedFields;

  @override
  Future<UserProfileData> build() async => _settingsProfileFixture();

  @override
  Future<bool> updateProfileFields(final Map<String, dynamic> fields) async {
    updateCalls += 1;
    updatedFields = Map<String, dynamic>.from(fields);
    return true;
  }
}

UserProfileData _settingsProfileFixture() {
  Map<String, dynamic> count(final int value, final String type) =>
      <String, dynamic>{'totalCount': value, '__typename': type};

  final Query$userInfo parsed = Query$userInfo.fromJson(<String, dynamic>{
    'repositoryOwner': <String, dynamic>{
      '__typename': 'User',
      'id': 'U_octocat',
      'login': 'octocat',
      'avatarUrl': '',
      'name': 'The Octocat',
      'bio': 'Building native GitHub tools.',
      'url': 'https://github.com/octocat',
      'location': 'San Francisco',
      'company': '@github',
      'pronouns': 'they/them',
      'isFollowingViewer': false,
      'createdAt': '2011-01-25T18:44:36Z',
      'status': null,
      'viewerIsFollowing': false,
      'viewerCanFollow': true,
      'repositories': count(12, 'RepositoryConnection'),
      'followers': count(7, 'FollowerConnection'),
      'following': count(24, 'FollowingConnection'),
      'websiteUrl': 'https://github.blog',
      'twitterUsername': 'octocat',
      'updatedAt': '2026-07-25T00:00:00Z',
      'isViewer': true,
      'hasSponsorsListing': false,
      'sponsoring': count(0, 'SponsoringConnection'),
      'sponsors': count(0, 'SponsorConnection'),
      'pinnedItems': <String, dynamic>{
        'edges': <dynamic>[],
        '__typename': 'PinnableItemConnection',
      },
      'email': 'octocat@example.com',
      'isHireable': true,
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
