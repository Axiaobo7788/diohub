import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/view/app_chrome/global_navigation_drawer.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final ({String key, GlobalNavigationDestination destination}) scenario
      in <({String key, GlobalNavigationDestination destination})>[
        (
          key: 'global-nav-issues',
          destination: GlobalNavigationDestination.issues,
        ),
        (
          key: 'global-nav-pull-requests',
          destination: GlobalNavigationDestination.pullRequests,
        ),
        (
          key: 'global-nav-repositories',
          destination: GlobalNavigationDestination.repositories,
        ),
        (
          key: 'global-nav-projects',
          destination: GlobalNavigationDestination.projects,
        ),
        (
          key: 'global-nav-discussions',
          destination: GlobalNavigationDestination.discussions,
        ),
      ]) {
    testWidgets('${scenario.destination.name} invokes the formal destination', (
      final WidgetTester tester,
    ) async {
      GlobalNavigationDestination? selected;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              drawer: GlobalNavigationDrawer(
                account: null,
                topRepositories: const AsyncData<List<HomeRepositoryItem>>(
                  <HomeRepositoryItem>[],
                ),
                onDestination:
                    (final GlobalNavigationDestination destination) =>
                        selected = destination,
                onSearchRepositories: () {},
                onSignIn: () async {},
                onOpenTopRepository: (final HomeRepositoryItem repository) {},
                onStagedAction: (final String action) {},
              ),
              body: Builder(
                builder: (final BuildContext context) => IconButton(
                  onPressed: Scaffold.of(context).openDrawer,
                  icon: const Icon(Icons.menu),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey<String>(scenario.key)));
      await tester.pumpAndSettle();

      expect(selected, scenario.destination);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('top repository rows keep a 48 pixel hit target', (
    final WidgetTester tester,
  ) async {
    final AccountModel account = AccountModel(
      nodeId: 'U_octocat',
      username: 'octocat',
      addedAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            visualDensity: VisualDensity.compact,
          ),
          home: Scaffold(
            drawer: GlobalNavigationDrawer(
              account: account,
              topRepositories: const AsyncData<List<HomeRepositoryItem>>(
                <HomeRepositoryItem>[
                  HomeRepositoryItem(
                    fullName: 'octocat/hello-world',
                    name: 'hello-world',
                    owner: 'octocat',
                    ownerAvatarUrl: null,
                    isPrivate: false,
                  ),
                ],
              ),
              onDestination: (final GlobalNavigationDestination destination) {},
              onSearchRepositories: () {},
              onSignIn: () async {},
              onOpenTopRepository: (final HomeRepositoryItem repository) {},
              onStagedAction: (final String action) {},
            ),
            body: Builder(
              builder: (final BuildContext context) => IconButton(
                onPressed: Scaffold.of(context).openDrawer,
                icon: const Icon(Icons.menu),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('octocat/hello-world'),
      240,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey<String>('global-navigation-drawer')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final Finder repositoryTile = find.ancestor(
      of: find.text('octocat/hello-world'),
      matching: find.byType(ListTile),
    );
    expect(tester.getSize(repositoryTile).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  for (final Brightness brightness in Brightness.values) {
    testWidgets('selected drawer destination uses container contrast in '
        '${brightness.name} mode', (final WidgetTester tester) async {
      final ThemeData theme = ThemeData(
        useMaterial3: true,
        brightness: brightness,
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: theme,
            home: Scaffold(
              drawer: GlobalNavigationDrawer(
                account: null,
                topRepositories: const AsyncData<List<HomeRepositoryItem>>(
                  <HomeRepositoryItem>[],
                ),
                selectedDestination: GlobalNavigationDestination.issues,
                onDestination:
                    (final GlobalNavigationDestination destination) {},
                onSearchRepositories: () {},
                onSignIn: () async {},
                onOpenTopRepository: (final HomeRepositoryItem repository) {},
                onStagedAction: (final String action) {},
              ),
              body: Builder(
                builder: (final BuildContext context) => IconButton(
                  onPressed: Scaffold.of(context).openDrawer,
                  icon: const Icon(Icons.menu),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      final Finder issuesTile = find.descendant(
        of: find.byKey(const ValueKey<String>('global-nav-issues')),
        matching: find.byType(ListTile),
      );
      final ListTile tile = tester.widget<ListTile>(issuesTile);
      expect(tile.selected, isTrue);
      expect(tile.selectedTileColor, theme.colorScheme.secondaryContainer);
      expect(tile.selectedColor, theme.colorScheme.onSecondaryContainer);
      expect(tile.shape, isA<RoundedRectangleBorder>());
      expect(tester.takeException(), isNull);
    });
  }
}
