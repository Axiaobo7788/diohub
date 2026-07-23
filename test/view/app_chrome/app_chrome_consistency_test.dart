import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/github_changelog_item.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/view/app_chrome/app_chrome_layout.dart';
import 'package:diohub/view/home/unified_home_screen.dart';
import 'package:diohub/view/repository/md3/repository_md3_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget homePage() => UnifiedHomeScreen(
    topRepositories: const AsyncData<List<HomeRepositoryItem>>(
      <HomeRepositoryItem>[],
    ),
    changelog: const AsyncData<List<GitHubChangelogItem>>(
      <GitHubChangelogItem>[],
    ),
    onSignIn: () async {},
    onSignOut: () async {},
  );

  Widget repositoryPage() => DefaultTabController(
    length: 1,
    child: RepositoryMd3Shell(
      repositoryLabel: 'octocat/hello-world',
      account: null,
      accountLoading: false,
      topRepositories: const AsyncData<List<HomeRepositoryItem>>(
        <HomeRepositoryItem>[],
      ),
      repositoryNavigation: const TabBar(tabs: <Widget>[Tab(text: 'Code')]),
      body: const SizedBox.expand(
        key: ValueKey<String>('repository-theme-probe'),
      ),
      onGlobalSearch: (final String? _) {},
      onSearchRepositories: () {},
      onRefresh: () {},
      onOpenLegacy: () {},
    ),
  );

  Future<void> pumpPage(
    final WidgetTester tester,
    final Widget page, {
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          settingsCacheProvider.overrideWithValue(
            SettingsCache(<String, String>{}),
          ),
        ],
        child: MaterialApp(
          key: ValueKey<Type>(page.runtimeType),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme ?? ThemeData(useMaterial3: true),
          home: page,
        ),
      ),
    );
    await tester.pump();
  }

  Future<double> openDrawerAndReadWidth(final WidgetTester tester) async {
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    return tester
        .getSize(find.byKey(const ValueKey<String>('global-navigation-drawer')))
        .width;
  }

  for (final ({Size viewport, double expected}) scenario
      in <({Size viewport, double expected})>[
        (viewport: const Size(360, 800), expected: 304),
        (viewport: const Size(800, 900), expected: 360),
        (viewport: const Size(1440, 900), expected: 360),
      ]) {
    testWidgets('Home and Repository use the same drawer width at '
        '${scenario.viewport.width.toInt()}px', (
      final WidgetTester tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = scenario.viewport;
      addTearDown(() {
        tester.view
          ..resetDevicePixelRatio()
          ..resetPhysicalSize();
      });

      await pumpPage(tester, homePage());
      if (scenario.viewport.width >= AppChromeLayout.desktopBreakpoint) {
        expect(
          tester
              .getSize(
                find.byKey(const ValueKey<String>('home-desktop-sidebar')),
              )
              .width,
          AppChromeLayout.navigationDrawerWidth,
        );
      }
      final double homeWidth = await openDrawerAndReadWidth(tester);

      await pumpPage(tester, repositoryPage());
      final double repositoryWidth = await openDrawerAndReadWidth(tester);

      expect(homeWidth, scenario.expected);
      expect(repositoryWidth, scenario.expected);
      expect(repositoryWidth, homeWidth);
      expect(
        repositoryWidth,
        AppChromeLayout.drawerWidthFor(scenario.viewport.width),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Repository page theme does not leak into global chrome', (
    final WidgetTester tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 900);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });

    const VisualDensity rootDensity = VisualDensity(horizontal: 2, vertical: 2);
    final ThemeData rootTheme = ThemeData(useMaterial3: true).copyWith(
      visualDensity: rootDensity,
      dividerTheme: const DividerThemeData(indent: 19, endIndent: 13),
    );
    await pumpPage(tester, repositoryPage(), theme: rootTheme);
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();

    final ThemeData chromeTheme = Theme.of(
      tester.element(
        find.byKey(const ValueKey<String>('global-navigation-drawer')),
      ),
    );
    final ThemeData pageTheme = Theme.of(
      tester.element(
        find.byKey(const ValueKey<String>('repository-theme-probe')),
      ),
    );

    expect(chromeTheme.visualDensity, rootDensity);
    expect(chromeTheme.dividerTheme.indent, 19);
    expect(chromeTheme.dividerTheme.endIndent, 13);
    expect(pageTheme.visualDensity, isNot(rootDensity));
    expect(pageTheme.dividerTheme.indent, isNull);
    expect(pageTheme.dividerTheme.endIndent, isNull);
    expect(tester.takeException(), isNull);
  });
}
