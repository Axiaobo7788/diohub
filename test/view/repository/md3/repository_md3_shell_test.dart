import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/view/repository/md3/repository_md3_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpShell(
    final WidgetTester tester, {
    required final Size size,
    final Locale locale = const Locale('en'),
  }) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });

    try {
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
            home: DefaultTabController(
              length: 7,
              child: RepositoryMd3Shell(
                repositoryLabel: 'octocat/hello-world',
                account: null,
                accountLoading: false,
                topRepositories: const AsyncData<List<HomeRepositoryItem>>(
                  <HomeRepositoryItem>[],
                ),
                header: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('octocat / hello-world'),
                ),
                repositoryNavigation: const TabBar(
                  isScrollable: true,
                  tabs: <Widget>[
                    Tab(text: 'Code'),
                    Tab(text: 'Issues'),
                    Tab(text: 'Pull requests'),
                    Tab(text: 'Actions'),
                    Tab(text: 'Projects'),
                    Tab(text: 'Security'),
                    Tab(text: 'Insights'),
                  ],
                ),
                body: ListView(
                  children: const <Widget>[
                    ListTile(title: Text('README.md')),
                    ListTile(title: Text('lib')),
                  ],
                ),
                aside: const Text('About'),
                onGlobalSearch: (final String? _) {},
                onSearchRepositories: () {},
                onRefresh: () {},
                onOpenLegacy: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    } finally {
      semantics.dispose();
    }
  }

  testWidgets('uses compact single-column structure at 360px', (
    final WidgetTester tester,
  ) async {
    await pumpShell(tester, size: const Size(360, 800));

    expect(
      find.byKey(const ValueKey<String>('repository-md3-compact')),
      findsOneWidget,
    );
    expect(
      find.byIcon(Icons.arrow_drop_down),
      findsNothing,
      reason: 'the repository title has no dropdown action to advertise',
    );
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('global-navigation-drawer')),
      findsOneWidget,
    );
    expect(find.text('All issues'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('repository-md3-navigation-rail')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('repository-md3-about-panel')),
      findsNothing,
    );
    expect(find.byType(TabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses centered single-column content at 800px', (
    final WidgetTester tester,
  ) async {
    await pumpShell(tester, size: const Size(800, 900));

    expect(
      find.byKey(const ValueKey<String>('repository-md3-medium')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('repository-md3-navigation-rail')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('repository-md3-about-panel')),
      findsNothing,
    );
    expect(find.byType(TabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses code and about columns at 1440px', (
    final WidgetTester tester,
  ) async {
    await pumpShell(tester, size: const Size(1440, 900));

    expect(
      find.byKey(const ValueKey<String>('repository-md3-expanded')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('repository-md3-navigation-rail')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('repository-md3-about-panel')),
      findsOneWidget,
    );
    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repository shell follows the selected Chinese locale', (
    final WidgetTester tester,
  ) async {
    await pumpShell(
      tester,
      size: const Size(800, 900),
      locale: const Locale('zh'),
    );

    await tester.tap(find.byTooltip('打开导航'));
    await tester.pumpAndSettle();

    expect(find.text('主页'), findsOneWidget);
    expect(find.text('所有议题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
