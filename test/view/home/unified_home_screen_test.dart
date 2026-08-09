import 'dart:async';

import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/github_changelog_item.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/view/home/unified_home_screen.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHome(
    final WidgetTester tester, {
    required final Size size,
    final AccountModel? account,
    final Widget? activityFeedSliver,
    final Future<bool> Function()? onLoadMoreActivity,
    final List<HomeRepositoryItem> topRepositories =
        const <HomeRepositoryItem>[],
    final AsyncValue<List<GitHubChangelogItem>> changelog =
        const AsyncData<List<GitHubChangelogItem>>(<GitHubChangelogItem>[]),
    final VoidCallback? onRefreshChangelog,
    final String? statusEmoji,
    final String? statusMessage,
    final Locale locale = const Locale('en'),
    final TextScaler textScaler = TextScaler.noScaling,
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
        ],
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
          home: UnifiedHomeScreen(
            account: account,
            activityFeedSliver:
                activityFeedSliver ??
                (account == null
                    ? null
                    : const SliverToBoxAdapter(
                        child: ListTile(title: Text('Activity item')),
                      )),
            onLoadMoreActivity: onLoadMoreActivity,
            topRepositories: AsyncData<List<HomeRepositoryItem>>(
              topRepositories,
            ),
            changelog: changelog,
            onRefreshChangelog: onRefreshChangelog,
            statusEmoji: statusEmoji,
            statusMessage: statusMessage,
            onSignIn: () async {},
            onSignOut: () async {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the shared public home without overflow at 360px', (
    final WidgetTester tester,
  ) async {
    await pumpHome(tester, size: const Size(360, 800));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    final Text homeTitle = tester.widget<Text>(find.text('Home'));
    expect(homeTitle.style?.fontSize, 24);
    expect(homeTitle.style?.height, closeTo(32 / 24, 0.0001));
    expect(homeTitle.style?.fontWeight, FontWeight.w700);
    expect(find.text('Ask anything or type @ to add context'), findsOneWidget);
    for (final String key in <String>[
      'home-command-ask',
      'home-command-add-context',
      'home-command-model',
      'home-command-send',
    ]) {
      expect(
        tester.getSize(find.byKey(ValueKey<String>(key))).height,
        greaterThanOrEqualTo(48),
      );
    }
    expect(find.text('Top repositories'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('home-mobile-top-repositories')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the same compact home after sign-in at 360px', (
    final WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final AccountModel account = AccountModel(
      nodeId: 'MDQ6VXNlcjE=',
      username: 'octocat',
      displayName: 'The Octocat',
      addedAt: DateTime.utc(2026),
    );

    await pumpHome(
      tester,
      size: const Size(360, 800),
      account: account,
      topRepositories: const <HomeRepositoryItem>[
        HomeRepositoryItem(
          fullName: 'octocat/hello-world',
          name: 'hello-world',
          owner: 'octocat',
          ownerAvatarUrl: null,
          isPrivate: false,
        ),
      ],
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Top repositories'), findsOneWidget);
    expect(find.text('octocat/hello-world'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Feed'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey<String>('home-activity-feed')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.byType(UserAvatar), findsWidgets);
    final Finder accountSwitch = find.byKey(
      const ValueKey<String>('home-mobile-account-switch'),
    );
    expect(tester.getSize(accountSwitch).height, greaterThanOrEqualTo(48));
    expect(
      tester
          .getSemantics(accountSwitch)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('renders the primary home chrome in Simplified Chinese', (
    final WidgetTester tester,
  ) async {
    await pumpHome(
      tester,
      size: const Size(360, 800),
      locale: const Locale('zh'),
    );

    expect(find.text('仪表板'), findsOneWidget);
    expect(find.text('主页'), findsOneWidget);
    expect(find.text('常用仓库'), findsOneWidget);
    expect(find.text('询问任何内容，或输入 @ 添加上下文'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest can open language settings before signing in', (
    final WidgetTester tester,
  ) async {
    await pumpHome(tester, size: const Size(360, 800));

    await tester.tap(find.byTooltip('Language & region'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-language-dialog')),
      findsOneWidget,
    );
    expect(find.text('System default'), findsWidgets);
    expect(find.text('Simplified Chinese'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the compact structure at 800px', (
    final WidgetTester tester,
  ) async {
    await pumpHome(tester, size: const Size(800, 900));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Top repositories'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the 800px Home usable at 1.3x text scale', (
    final WidgetTester tester,
  ) async {
    await pumpHome(
      tester,
      size: const Size(800, 900),
      textScaler: const TextScaler.linear(1.3),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Top repositories'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the 360px Home usable at 2x text scale', (
    final WidgetTester tester,
  ) async {
    await pumpHome(
      tester,
      size: const Size(360, 800),
      textScaler: const TextScaler.linear(2),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Top repositories'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the GitHub-style three-column home at 1440px', (
    final WidgetTester tester,
  ) async {
    await pumpHome(
      tester,
      size: const Size(1440, 900),
      changelog: AsyncData<List<GitHubChangelogItem>>(<GitHubChangelogItem>[
        GitHubChangelogItem(
          title: 'GitHub Code Quality is now generally available',
          link: Uri.parse('https://github.blog/changelog/code-quality'),
          publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ]),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Top repositories'), findsOneWidget);
    expect(find.text('Latest from our changelog'), findsOneWidget);
    expect(
      find.text('GitHub Code Quality is now generally available'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-desktop-sidebar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-desktop-aside')),
      findsOneWidget,
    );
    expect(find.byType(VerticalDivider), findsAtLeastNWidgets(1));
    expect(find.byType(AppLogoWidget), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders authenticated activity in the desktop main pane', (
    final WidgetTester tester,
  ) async {
    final AccountModel account = AccountModel(
      nodeId: 'MDQ6VXNlcjE=',
      username: 'octocat',
      addedAt: DateTime.utc(2026),
    );

    await pumpHome(tester, size: const Size(1440, 900), account: account);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Top repositories'), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Activity item'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an explicit changelog failure and retries', (
    final WidgetTester tester,
  ) async {
    int retryCalls = 0;
    await pumpHome(
      tester,
      size: const Size(1440, 900),
      changelog: AsyncError<List<GitHubChangelogItem>>(
        StateError('offline'),
        StackTrace.empty,
      ),
      onRefreshChangelog: () {
        retryCalls += 1;
      },
    );

    expect(find.text('Could not load the GitHub changelog.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    expect(retryCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the GitHub-style global navigation drawer', (
    final WidgetTester tester,
  ) async {
    final AccountModel account = AccountModel(
      nodeId: 'MDQ6VXNlcjE=',
      username: 'octocat',
      addedAt: DateTime.utc(2026),
    );
    await pumpHome(
      tester,
      size: const Size(1440, 900),
      account: account,
      topRepositories: const <HomeRepositoryItem>[
        HomeRepositoryItem(
          fullName: 'flutter/flutter',
          name: 'flutter',
          owner: 'flutter',
          ownerAvatarUrl: null,
          isPrivate: false,
        ),
      ],
    );

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('global-navigation-drawer')),
      findsOneWidget,
    );
    expect(find.text('All issues'), findsOneWidget);
    expect(find.text('All pull requests'), findsOneWidget);
    expect(find.text('MCP registry'), findsOneWidget);
    expect(find.text('flutter/flutter'), findsWidgets);
    expect(find.byType(AppLogoWidget), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the global navigation drawer usable at 360px', (
    final WidgetTester tester,
  ) async {
    await pumpHome(tester, size: const Size(360, 800));

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('global-navigation-drawer')),
      findsOneWidget,
    );
    expect(find.text('All repositories'), findsOneWidget);
    expect(find.text('MCP registry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the account menu with profile and settings actions', (
    final WidgetTester tester,
  ) async {
    final AccountModel account = AccountModel(
      nodeId: 'MDQ6VXNlcjE=',
      username: 'octocat',
      displayName: 'The Octocat',
      addedAt: DateTime.utc(2026),
    );
    await pumpHome(
      tester,
      size: const Size(1440, 900),
      account: account,
      statusEmoji: '🌙',
      statusMessage: 'Sleeping',
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('global-account-menu-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('The Octocat'), findsOneWidget);
    expect(find.text('Sleeping'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Repositories'), findsOneWidget);
    expect(find.text('Enterprises'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Copilot settings'), findsOneWidget);
    expect(find.text('Feature preview'), findsOneWidget);
    expect(find.text('Language & region'), findsOneWidget);
    expect(find.text('Try Enterprise'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the account language selector', (
    final WidgetTester tester,
  ) async {
    final AccountModel account = AccountModel(
      nodeId: 'MDQ6VXNlcjE=',
      username: 'octocat',
      addedAt: DateTime.utc(2026),
    );
    await pumpHome(tester, size: const Size(1440, 900), account: account);

    await tester.tap(
      find.byKey(const ValueKey<String>('global-account-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('global-language-menu-item')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('global-language-menu-item')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-language-dialog')),
      findsOneWidget,
    );
    expect(find.text('System default'), findsWidgets);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Simplified Chinese'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the account menu usable at 360px without a status', (
    final WidgetTester tester,
  ) async {
    final AccountModel account = AccountModel(
      nodeId: 'MDQ6VXNlcjE=',
      username: 'octocat',
      addedAt: DateTime.utc(2026),
    );
    await pumpHome(tester, size: const Size(360, 800), account: account);

    await tester.tap(
      find.byKey(const ValueKey<String>('global-account-menu-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set status'), findsOneWidget);
    expect(find.text('Enterprises'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the centralized desktop and aside breakpoints', (
    final WidgetTester tester,
  ) async {
    await pumpHome(tester, size: const Size(1039, 900));
    expect(
      find.byKey(const ValueKey<String>('home-desktop-sidebar')),
      findsNothing,
    );

    await pumpHome(tester, size: const Size(1040, 900));
    expect(
      find.byKey(const ValueKey<String>('home-desktop-sidebar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('home-desktop-aside')),
      findsNothing,
    );

    await pumpHome(tester, size: const Size(1360, 900));
    expect(
      find.byKey(const ValueKey<String>('home-desktop-aside')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('prefetches more activity before reaching the end', (
    final WidgetTester tester,
  ) async {
    final AccountModel account = AccountModel(
      nodeId: 'MDQ6VXNlcjE=',
      username: 'octocat',
      addedAt: DateTime.utc(2026),
    );
    final Completer<bool> pendingLoad = Completer<bool>();
    int loadCalls = 0;

    await pumpHome(
      tester,
      size: const Size(360, 800),
      account: account,
      activityFeedSliver: SliverList.builder(
        itemCount: 12,
        itemBuilder: (final BuildContext context, final int index) =>
            SizedBox(height: 160, child: Text('Activity $index')),
      ),
      onLoadMoreActivity: () {
        loadCalls += 1;
        return pendingLoad.future;
      },
    );

    expect(loadCalls, 0);
    await tester.drag(
      find.byKey(const ValueKey<String>('home-activity-feed')),
      const Offset(0, -1800),
    );
    await tester.pump();

    expect(loadCalls, 1);
    pendingLoad.complete(false);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
