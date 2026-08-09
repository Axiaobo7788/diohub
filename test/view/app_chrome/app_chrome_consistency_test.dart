import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/github_changelog_item.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/view/app_chrome/app_chrome.dart';
import 'package:diohub/view/app_chrome/app_chrome_layout.dart';
import 'package:diohub/view/app_chrome/global_header.dart';
import 'package:diohub/view/home/unified_home_screen.dart';
import 'package:diohub/view/repository/md3/repository_md3_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
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

  Widget chromePage({
    required final ValueChanged<String?> onGlobalSearch,
    final Widget body = const SizedBox.expand(),
  }) => AppChrome(
    title: const GlobalHeaderTitle(title: 'DioHub'),
    body: body,
    account: null,
    accountLoading: false,
    topRepositories: const AsyncData<List<HomeRepositoryItem>>(
      <HomeRepositoryItem>[],
    ),
    onSignIn: () async {},
    onSignOut: () async {},
    onGlobalSearch: onGlobalSearch,
  );

  Future<void> pumpPage(
    final WidgetTester tester,
    final Widget page, {
    ThemeData? theme,
    TextScaler textScaler = TextScaler.noScaling,
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
          home: Builder(
            builder: (final BuildContext context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: page,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final ({double expectedHeight, double width}) scenario
      in <({double expectedHeight, double width})>[
        (
          width: AppChromeLayout.desktopBreakpoint - 1,
          expectedHeight: AppChromeLayout.compactToolbarHeight,
        ),
        (
          width: AppChromeLayout.desktopBreakpoint,
          expectedHeight: AppChromeLayout.desktopToolbarHeight,
        ),
      ]) {
    testWidgets(
      'global header uses the centralized height at ${scenario.width}px',
      (final WidgetTester tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = Size(scenario.width, 900);
        addTearDown(() {
          tester.view
            ..resetDevicePixelRatio()
            ..resetPhysicalSize();
        });

        await pumpPage(tester, homePage());

        expect(
          tester
              .getSize(find.byKey(const ValueKey<String>('global-header')))
              .height,
          scenario.expectedHeight,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final ({Size viewport, TextScaler textScaler}) scenario
      in <({Size viewport, TextScaler textScaler})>[
        (
          viewport: const Size(360, 800),
          textScaler: const TextScaler.linear(2),
        ),
        (
          viewport: const Size(800, 900),
          textScaler: const TextScaler.linear(1.3),
        ),
      ]) {
    testWidgets(
      'global header does not overflow at ${scenario.viewport.width}px '
      'with scaled text',
      (final WidgetTester tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = scenario.viewport;
        addTearDown(() {
          tester.view
            ..resetDevicePixelRatio()
            ..resetPhysicalSize();
        });

        await pumpPage(tester, homePage(), textScaler: scenario.textScaler);

        expect(
          tester
              .getSize(find.byKey(const ValueKey<String>('global-header')))
              .height,
          AppChromeLayout.compactToolbarHeight,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('compact title exposes a named header instead of an image', (
    final WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpPage(
      tester,
      const Center(
        child: SizedBox(
          width: 80,
          child: GlobalHeaderTitle(title: 'hello-world', owner: 'octocat'),
        ),
      ),
    );

    final SemanticsNode node = tester.getSemantics(
      find.byKey(
        const ValueKey<String>('global-header-compact-title-semantics'),
      ),
    );
    expect(node.label, 'octocat / hello-world');
    expect(node.hasFlag(SemanticsFlag.isHeader), isTrue);
    expect(node.hasFlag(SemanticsFlag.isImage), isFalse);
    semantics.dispose();
  });

  testWidgets('global header uses a stable outline instead of elevation', (
    final WidgetTester tester,
  ) async {
    await pumpPage(tester, homePage());

    final AppBar header = tester.widget<AppBar>(find.byType(AppBar));
    expect(header.elevation, 0);
    expect(header.scrolledUnderElevation, 0);
    expect(header.surfaceTintColor, Colors.transparent);
    final Border border = header.shape! as Border;
    expect(
      border.bottom.color,
      Theme.of(
        tester.element(find.byKey(const ValueKey<String>('global-header'))),
      ).colorScheme.outlineVariant,
    );
  });

  testWidgets('slash focuses the desktop global search', (
    final WidgetTester tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1440, 900);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });
    int searchCalls = 0;
    await pumpPage(
      tester,
      chromePage(onGlobalSearch: (final String? query) => searchCalls++),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();

    final EditableText searchEditor = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(SearchBar),
        matching: find.byType(EditableText),
      ),
    );
    expect(searchEditor.focusNode.hasFocus, isTrue);
    expect(searchCalls, 0);
  });

  testWidgets('slash opens global search at compact width', (
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
    int searchCalls = 0;
    String? capturedQuery = 'unchanged';
    await pumpPage(
      tester,
      chromePage(
        onGlobalSearch: (final String? query) {
          searchCalls++;
          capturedQuery = query;
        },
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();

    expect(searchCalls, 1);
    expect(capturedQuery, isNull);
  });

  testWidgets('slash is not intercepted while an editor owns focus', (
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
    int searchCalls = 0;
    await pumpPage(
      tester,
      chromePage(
        onGlobalSearch: (final String? query) => searchCalls++,
        body: const TextField(key: ValueKey<String>('app-chrome-editor-probe')),
      ),
    );
    final Finder editor = find.byKey(
      const ValueKey<String>('app-chrome-editor-probe'),
    );
    await tester.tap(editor);
    await tester.pump();
    final EditableText editableText = tester.widget<EditableText>(
      find.descendant(of: editor, matching: find.byType(EditableText)),
    );
    expect(editableText.focusNode.hasFocus, isTrue);

    final bool handled = await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();

    expect(handled, isFalse);
    expect(editableText.focusNode.hasFocus, isTrue);
    expect(searchCalls, 0);
  });

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
    final Divider chromeDivider = tester.widget<Divider>(
      find.byKey(const ValueKey<String>('app-chrome-secondary-divider')),
    );
    expect(chromeDivider.indent, 0);
    expect(chromeDivider.endIndent, 0);
    expect(pageTheme.visualDensity, isNot(rootDensity));
    expect(pageTheme.dividerTheme.indent, isNull);
    expect(pageTheme.dividerTheme.endIndent, isNull);
    expect(tester.takeException(), isNull);
  });
}
