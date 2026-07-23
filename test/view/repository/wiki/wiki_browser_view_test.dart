import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/repository/wiki_providers.dart';
import 'package:diohub/view/repository/wiki/wiki_browser_view.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/wiki_page.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RepoRef repoRef = RepoRef(owner: 'octocat', name: 'hello-world');
  const WikiPage home = WikiPage(
    slug: 'Home',
    title: 'Home',
    rawMarkdown: '# Home',
    renderedHtml: '<h1>Home</h1><p>Welcome to the project wiki.</p>',
    sha: 'home-sha',
  );
  const WikiPage guide = WikiPage(
    slug: 'Getting-Started',
    title: 'Getting Started',
    rawMarkdown: '# Getting Started',
    renderedHtml: '<h1>Getting Started</h1><p>Install the application.</p>',
    sha: 'guide-sha',
  );
  const List<WikiPageListItem> pages = <WikiPageListItem>[
    WikiPageListItem(name: 'Home.md', path: 'Home.md', sha: 'home-sha'),
    WikiPageListItem(
      name: 'Getting-Started.md',
      path: 'Getting-Started.md',
      sha: 'guide-sha',
    ),
  ];

  Future<void> pumpWiki(
    final WidgetTester tester, {
    required final Size size,
    required final AsyncValue<WikiBrowseState> value,
    final bool disableAnimations = false,
    final TextScaler textScaler = TextScaler.noScaling,
    final ValueChanged<String>? onOpenPage,
    final ValueChanged<int>? onPopToPage,
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
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true),
          builder: (final BuildContext context, final Widget? child) =>
              MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: disableAnimations,
                  textScaler: textScaler,
                ),
                child: child!,
              ),
          home: Scaffold(
            body: Builder(
              builder: (final BuildContext context) => CustomScrollView(
                slivers: buildWikiViewSlivers(
                  context,
                  value: value,
                  repoRef: repoRef,
                  serverConfig: ServerConfig.gitHubDotCom,
                  onRetry: () {},
                  onOpenPage: onOpenPage ?? (final String _) {},
                  onPopPage: () {},
                  onPopToPage: onPopToPage ?? (final int _) {},
                  onOpenGitHub: (final String? _) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final Size size in <Size>[
    const Size(360, 800),
    const Size(800, 900),
    const Size(1440, 900),
  ]) {
    testWidgets('wiki content is responsive at ${size.width.toInt()}px', (
      final WidgetTester tester,
    ) async {
      await pumpWiki(
        tester,
        size: size,
        textScaler: size.width == 360
            ? const TextScaler.linear(2)
            : TextScaler.noScaling,
        value: const AsyncData<WikiBrowseState>(
          WikiBrowseState(pageStack: <WikiPage>[home], pageList: pages),
        ),
      );

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Wiki pages'), findsOneWidget);
      expect(find.text('Open wiki on GitHub'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('wiki page menu and breadcrumbs keep user content unchanged', (
    final WidgetTester tester,
  ) async {
    String? openedSlug;
    int? breadcrumbIndex;
    await pumpWiki(
      tester,
      size: const Size(800, 900),
      value: const AsyncData<WikiBrowseState>(
        WikiBrowseState(pageStack: <WikiPage>[home, guide], pageList: pages),
      ),
      onOpenPage: (final String slug) => openedSlug = slug,
      onPopToPage: (final int index) => breadcrumbIndex = index,
    );

    await tester.tap(find.text('Home').first);
    await tester.pump();
    expect(breadcrumbIndex, 0);

    await tester.tap(find.text('Wiki pages'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Home'));
    await tester.pump();
    expect(openedSlug, 'Home');
    expect(find.text('Getting Started'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wiki title transition respects Reduced Motion', (
    final WidgetTester tester,
  ) async {
    await pumpWiki(
      tester,
      size: const Size(800, 900),
      disableAnimations: true,
      value: const AsyncData<WikiBrowseState>(
        WikiBrowseState(pageStack: <WikiPage>[home], pageList: pages),
      ),
    );

    final AnimatedSwitcher switcher = tester.widget<AnimatedSwitcher>(
      find.byKey(const ValueKey<String>('wiki-title-switcher')),
    );
    expect(switcher.duration, Duration.zero);
    expect(kContentTransitionDuration, const Duration(milliseconds: 180));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wiki loading, error, and empty states are explicit', (
    final WidgetTester tester,
  ) async {
    await pumpWiki(
      tester,
      size: const Size(800, 900),
      value: const AsyncLoading<WikiBrowseState>(),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await pumpWiki(
      tester,
      size: const Size(800, 900),
      value: AsyncError<WikiBrowseState>(
        StateError('wiki unavailable'),
        StackTrace.empty,
      ),
    );
    expect(find.text('Could not load this repository wiki.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await pumpWiki(
      tester,
      size: const Size(800, 900),
      value: const AsyncData<WikiBrowseState>(WikiBrowseState()),
    );
    expect(find.text('No wiki pages'), findsOneWidget);
    expect(find.text('Create wiki on GitHub'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
