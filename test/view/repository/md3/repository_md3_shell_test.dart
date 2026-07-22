import 'package:diohub/view/repository/md3/repository_md3_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpShell(
    final WidgetTester tester, {
    required final Size size,
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
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: DefaultTabController(
          length: 7,
          child: RepositoryMd3Shell(
            repositoryLabel: 'octocat/hello-world',
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
            onBack: () {},
            onSearch: () {},
            onRefresh: () {},
            onOpenLegacy: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('uses compact single-column structure at 360px', (
    final WidgetTester tester,
  ) async {
    await pumpShell(tester, size: const Size(360, 800));

    expect(
      find.byKey(const ValueKey<String>('repository-md3-compact')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDrawer), findsOneWidget);
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

  testWidgets('uses navigation rail without aside at 800px', (
    final WidgetTester tester,
  ) async {
    await pumpShell(tester, size: const Size(800, 900));

    expect(
      find.byKey(const ValueKey<String>('repository-md3-medium')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('repository-md3-navigation-rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('repository-md3-about-panel')),
      findsNothing,
    );
    expect(find.byType(TabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses extended navigation and about panel at 1440px', (
    final WidgetTester tester,
  ) async {
    await pumpShell(tester, size: const Size(1440, 900));

    expect(
      find.byKey(const ValueKey<String>('repository-md3-expanded')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('repository-md3-navigation-rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('repository-md3-about-panel')),
      findsOneWidget,
    );
    expect(find.byType(TabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
