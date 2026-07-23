import 'dart:async';

import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/repository/public_repository_providers.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/repository/wiki_providers.dart';
import 'package:diohub/services/repositories/public_repository_service.dart';
import 'package:diohub/view/repository/md3/repository_navigation.dart';
import 'package:diohub/view/repository/repository_screen.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/wiki_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<
    ({int repositoryBuilds, int cardBuilds, int Function() publicSearches})
  >
  pumpRepository(
    final WidgetTester tester, {
    required final Override accountOverride,
    required final RepoRef repoRef,
    final Size size = const Size(800, 900),
    final TextScaler textScaler = TextScaler.noScaling,
  }) async {
    var repositoryBuilds = 0;
    var cardBuilds = 0;
    var publicSearches = 0;
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        accountOverride,
        settingsCacheProvider.overrideWithValue(
          SettingsCache(<String, String>{}),
        ),
        repositoryProvider.overrideWith2(
          (final RepoRef arg) => _CountingRepositoryNotifier(
            arg,
            onBuild: () => repositoryBuilds++,
          ),
        ),
        wikiProvider.overrideWith2(_TestWikiNotifier.new),
        repoCardProvider.overrideWith((final Ref ref, final RepoRef arg) {
          cardBuilds++;
          return Completer<RepoCardData>().future;
        }),
        publicRepositoryServiceProvider.overrideWithValue(
          PublicRepositoryService.withGet((
            final String path,
            final Map<String, dynamic>? query,
          ) async {
            if (path != '/search/issues') {
              throw StateError('Unexpected public request: $path');
            }
            publicSearches++;
            return <String, dynamic>{
              'total_count': 0,
              'items': <Map<String, dynamic>>[],
            };
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true),
          builder: (final BuildContext context, final Widget? child) =>
              MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                child: child!,
              ),
          home: RepositoryScreen(repo: repoRef),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    return (
      repositoryBuilds: repositoryBuilds,
      cardBuilds: cardBuilds,
      publicSearches: () => publicSearches,
    );
  }

  testWidgets(
    'cold account loading keeps the repository shell without GraphQL or sign-in',
    (final WidgetTester tester) async {
      final counts = await pumpRepository(
        tester,
        accountOverride: accountProvider.overrideWith(
          _PendingAccountNotifier.new,
        ),
        repoRef: const RepoRef(
          owner: 'octocat',
          name: 'hello-world',
          location: RepoLocation.issues(),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('repository-md3-medium')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('repository-account-loading')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('repository-issue-pull-sign-in')),
        findsNothing,
      );
      expect(counts.repositoryBuilds, 0);
      expect(counts.cardBuilds, 0);
      expect(counts.publicSearches(), 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'signed-out Code keeps production chrome and never constructs GraphQL',
    (final WidgetTester tester) async {
      final counts = await pumpRepository(
        tester,
        accountOverride: accountProvider.overrideWith(
          _SignedOutAccountNotifier.new,
        ),
        repoRef: const RepoRef(owner: 'octocat', name: 'hello-world'),
      );

      expect(
        find.byKey(const ValueKey<String>('repository-md3-medium')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('repository-code-sign-in')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Public repository search remains available without an account.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('repository-file-table')),
        findsNothing,
      );
      expect(counts.repositoryBuilds, 0);
      expect(counts.cardBuilds, 0);
      expect(counts.publicSearches(), 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account load failure is retryable and is not treated as a guest session',
    (final WidgetTester tester) async {
      final counts = await pumpRepository(
        tester,
        accountOverride: accountProvider.overrideWith(
          _ErrorAccountNotifier.new,
        ),
        repoRef: const RepoRef(
          owner: 'octocat',
          name: 'hello-world',
          location: RepoLocation.issues(),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('repository-account-error')),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('repository-issue-pull-sign-in')),
        findsNothing,
      );
      expect(counts.repositoryBuilds, 0);
      expect(counts.cardBuilds, 0);
      expect(counts.publicSearches(), 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'visited Repository tabs retain local state without constructing GraphQL',
    (final WidgetTester tester) async {
      final counts = await pumpRepository(
        tester,
        accountOverride: accountProvider.overrideWith(
          _SignedOutAccountNotifier.new,
        ),
        repoRef: const RepoRef(owner: 'octocat', name: 'hello-world'),
      );

      expect(
        find.byKey(
          const ValueKey<String>('repository-issue-pull-sign-in'),
          skipOffstage: false,
        ),
        findsNothing,
        reason: 'unvisited tabs must not be constructed eagerly',
      );

      await tester.tap(find.text('Issues'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('repository-issue-pull-sign-in')),
        findsNothing,
      );
      expect(counts.publicSearches(), 1);

      final Finder issueSearch = find.byKey(
        const ValueKey<String>('repository-issues-search'),
      );
      await tester.enterText(issueSearch, 'keep this issue filter');

      await tester.tap(find.text('Pull requests'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('repository-issue-pull-sign-in'),
          skipOffstage: false,
        ),
        findsNothing,
      );
      expect(
        counts.publicSearches(),
        3,
        reason:
            'Issues refreshes for the entered query and Pull requests loads '
            'its own first public page',
      );

      await tester.tap(find.text('Code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Issues'));
      await tester.pumpAndSettle();

      final TextField restoredSearch = tester.widget<TextField>(issueSearch);
      expect(restoredSearch.controller?.text, 'keep this issue filter');
      expect(
        find.byKey(const ValueKey<String>('repository-issue-pull-loading')),
        findsNothing,
        reason: 'a retained tab must not flash its first-page skeleton again',
      );
      expect(
        counts.publicSearches(),
        3,
        reason: 'returning to a retained tab must not refetch its first page',
      );
      expect(counts.repositoryBuilds, 0);
      expect(counts.cardBuilds, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('signed-out Repository stays usable at 800px and 1.3x text', (
    final WidgetTester tester,
  ) async {
    final counts = await pumpRepository(
      tester,
      accountOverride: accountProvider.overrideWith(
        _SignedOutAccountNotifier.new,
      ),
      repoRef: const RepoRef(owner: 'octocat', name: 'hello-world'),
      textScaler: const TextScaler.linear(1.3),
    );

    await tester.tap(find.text('Issues'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('repository-md3-medium')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('repository-issues-search')),
      findsOneWidget,
    );
    expect(counts.repositoryBuilds, 0);
    expect(counts.cardBuilds, 0);
    expect(counts.publicSearches(), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Repository wiki deep link opens the real retained Wiki tab', (
    final WidgetTester tester,
  ) async {
    final counts = await pumpRepository(
      tester,
      accountOverride: accountProvider.overrideWith(
        _SignedOutAccountNotifier.new,
      ),
      repoRef: const RepoRef(
        owner: 'octocat',
        name: 'hello-world',
        location: RepoLocation.wiki(page: 'Home'),
      ),
    );
    await tester.pumpAndSettle();

    final TabController controller = tester
        .widget<TabBar>(
          find.byKey(const ValueKey<String>('repository-primary-navigation')),
        )
        .controller!;
    expect(controller.index, RepositoryNavigationDestination.wiki.index);
    expect(find.text('Project wiki'), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('wiki-page-Home')),
      findsOneWidget,
    );
    expect(counts.repositoryBuilds, 0);
    expect(counts.cardBuilds, 0);
    expect(counts.publicSearches(), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-out Repository stays usable at 360px and 2x text scale', (
    final WidgetTester tester,
  ) async {
    final counts = await pumpRepository(
      tester,
      accountOverride: accountProvider.overrideWith(
        _SignedOutAccountNotifier.new,
      ),
      repoRef: const RepoRef(owner: 'octocat', name: 'hello-world'),
      size: const Size(360, 800),
      textScaler: const TextScaler.linear(2),
    );

    final TabController controller = tester
        .widget<TabBar>(find.byType(TabBar))
        .controller!;
    controller.animateTo(1);
    await tester.pumpAndSettle();

    expect(controller.index, 1);
    expect(
      tester
          .widget<IndexedStack>(
            find.byKey(
              const ValueKey<String>(
                'repository-primary-tabs-octocat/hello-world',
              ),
            ),
          )
          .index,
      1,
    );
    expect(
      find.byKey(
        const ValueKey<String>('repository-unvisited-tab-1'),
        skipOffstage: false,
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('repository-md3-compact')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey<String>('repository-issues-scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    final ScrollableState issuesScrollState = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey<String>('repository-issues-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final double issuesScrollOffset = issuesScrollState.position.pixels;
    expect(issuesScrollOffset, greaterThan(0));
    expect(
      find.byKey(const ValueKey<String>('repository-issue-pull-sign-in')),
      findsNothing,
    );

    controller.animateTo(0);
    await tester.pumpAndSettle();
    controller.animateTo(1);
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(
                const ValueKey<String>('repository-issues-scroll'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      ),
      same(issuesScrollState),
    );
    expect(issuesScrollState.position.pixels, issuesScrollOffset);
    expect(counts.repositoryBuilds, 0);
    expect(counts.cardBuilds, 0);
    expect(counts.publicSearches(), 1);
    expect(tester.takeException(), isNull);
  });
}

final class _PendingAccountNotifier extends AccountNotifier {
  @override
  Future<AccountSession?> build() => Completer<AccountSession?>().future;
}

final class _SignedOutAccountNotifier extends AccountNotifier {
  @override
  Future<AccountSession?> build() async => null;
}

final class _ErrorAccountNotifier extends AccountNotifier {
  @override
  Future<AccountSession?> build() async {
    throw StateError('Could not read local account state');
  }
}

final class _CountingRepositoryNotifier extends RepositoryNotifier {
  _CountingRepositoryNotifier(super.arg, {required this.onBuild});

  final VoidCallback onBuild;

  @override
  Future<RepoInfoData> build() {
    onBuild();
    return Completer<RepoInfoData>().future;
  }
}

final class _TestWikiNotifier extends WikiNotifier {
  _TestWikiNotifier(super.arg);

  @override
  Future<WikiBrowseState> build() async => const WikiBrowseState(
    pageStack: <WikiPage>[
      WikiPage(
        slug: 'Home',
        title: 'Project wiki',
        rawMarkdown: '# Project wiki',
        renderedHtml:
            '<h1>Project wiki</h1><p>Welcome from the repository wiki.</p>',
        sha: 'home-sha',
      ),
    ],
    pageList: <WikiPageListItem>[
      WikiPageListItem(name: 'Home.md', path: 'Home.md', sha: 'home-sha'),
    ],
  );
}
