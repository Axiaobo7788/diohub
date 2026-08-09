import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/global_list_destination.dart';
import 'package:diohub/models/global_repository_browse_query.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/search/global_search_page_resource.dart';
import 'package:diohub/providers/search/global_search_session_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/global_lists/global_lists_screen.dart';
import 'package:diohub_graphql/fragments/issue_card_fields.graphql.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/search/issue_or_pull.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const ResourceScope _scope = ResourceScope(
  serverId: 'github.com',
  principal: 'account-1',
);

void main() {
  final AccountModel account = AccountModel(
    nodeId: 'account-1',
    username: 'octocat',
    addedAt: DateTime.utc(2026),
  );

  for (final ({Size size, bool wide, double textScale}) scenario
      in <({Size size, bool wide, double textScale})>[
        (size: const Size(360, 800), wide: false, textScale: 1.3),
        (size: const Size(800, 900), wide: false, textScale: 1),
        (size: const Size(1440, 900), wide: true, textScale: 2),
      ]) {
    testWidgets(
      'issues page is responsive at ${scenario.size.width.toInt()}px',
      (final WidgetTester tester) async {
        final _EmptySearchBackend backend = _EmptySearchBackend();
        await _pumpPage(
          tester,
          size: scenario.size,
          page: GlobalListsPage(
            destination: GlobalListDestination.issues,
            account: account,
            scope: _scope,
          ),
          backend: backend,
          textScale: scenario.textScale,
        );

        expect(find.text('All issues'), findsWidgets);
        expect(find.text('No issues match these filters'), findsOneWidget);
        expect(
          find.byKey(
            ValueKey<String>(
              'global-lists-issues-${scenario.wide ? 'wide' : 'compact'}',
            ),
          ),
          findsOneWidget,
        );
        expect(
          backend.issueQueries.single,
          contains('involves:octocat'),
          reason: 'the personal page must never fall back to a global query',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Open and Closed restore their retained query sessions', (
    final WidgetTester tester,
  ) async {
    final _EmptySearchBackend backend = _EmptySearchBackend();
    await _pumpPage(
      tester,
      size: const Size(800, 900),
      page: GlobalListsPage(
        destination: GlobalListDestination.pullRequests,
        account: account,
        scope: _scope,
      ),
      backend: backend,
    );
    expect(backend.issueQueries.length, 1);
    expect(backend.issueQueries.single, contains('is:open'));

    await tester.tap(find.text('Closed'));
    await tester.pumpAndSettle();
    expect(backend.issueQueries.length, 2);
    expect(backend.issueQueries.last, contains('is:closed'));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      backend.issueQueries.length,
      2,
      reason: 'returning to Open must not replay its first-page request',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'query transition never keeps the outgoing pagination tree mounted',
    (final WidgetTester tester) async {
      final _EmptySearchBackend backend = _EmptySearchBackend();
      await _pumpPage(
        tester,
        size: const Size(800, 900),
        page: GlobalListsPage(
          destination: GlobalListDestination.pullRequests,
          account: account,
          scope: _scope,
        ),
        backend: backend,
      );

      expect(find.byType(CustomScrollView), findsOneWidget);
      await tester.tap(find.text('Closed'));
      await tester.pump();

      expect(
        find.byType(CustomScrollView),
        findsOneWidget,
        reason:
            'a visual transition must not retain two live pagination sentinels',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed first page exposes a working retry in the real page', (
    final WidgetTester tester,
  ) async {
    final _EmptySearchBackend backend = _EmptySearchBackend(
      failFirstIssueRequest: true,
    );
    await _pumpPage(
      tester,
      size: const Size(800, 900),
      page: GlobalListsPage(
        destination: GlobalListDestination.issues,
        account: account,
        scope: _scope,
      ),
      backend: backend,
    );

    expect(find.text('Could not load results.'), findsOneWidget);
    expect(backend.issueQueries.length, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('No issues match these filters'), findsOneWidget);
    expect(backend.issueQueries.length, 2);
    expect(tester.takeException(), isNull);
  });

  for (final GlobalListDestination destination in <GlobalListDestination>[
    GlobalListDestination.pullRequests,
    GlobalListDestination.repositories,
  ]) {
    for (final ({Size size, bool wide, double textScale}) scenario
        in <({Size size, bool wide, double textScale})>[
          (size: const Size(360, 800), wide: false, textScale: 1.3),
          (size: const Size(800, 900), wide: false, textScale: 1),
          (size: const Size(1440, 900), wide: true, textScale: 2),
        ]) {
      testWidgets('${destination.name} page is responsive at '
          '${scenario.size.width.toInt()}px', (
        final WidgetTester tester,
      ) async {
        final _EmptySearchBackend backend = _EmptySearchBackend();
        await _pumpPage(
          tester,
          size: scenario.size,
          page: GlobalListsPage(
            destination: destination,
            account: account,
            scope: _scope,
          ),
          backend: backend,
          textScale: scenario.textScale,
        );

        expect(
          find.byKey(
            ValueKey<String>(
              'global-lists-${destination.name}-'
              '${scenario.wide ? 'wide' : 'compact'}',
            ),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'drawer destination switching retains query session and search state',
    (final WidgetTester tester) async {
      final _EmptySearchBackend backend = _EmptySearchBackend();
      await _pumpPage(
        tester,
        size: const Size(800, 900),
        page: GlobalListsShell(
          initialDestination: GlobalListDestination.issues,
          account: account,
          accountLoading: false,
          topRepositories: const AsyncData<List<HomeRepositoryItem>>(
            <HomeRepositoryItem>[],
          ),
        ),
        backend: backend,
      );
      expect(backend.issueQueries.length, 1);
      expect(backend.issueQueries.single, contains('is:open'));

      await tester.enterText(
        find.byKey(const ValueKey<String>('global-lists-search-issues')),
        'flutter',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(backend.issueQueries.length, 2);

      await _selectDrawerDestination(
        tester,
        const ValueKey<String>('global-nav-pull-requests'),
      );
      expect(backend.issueQueries.length, 3);
      expect(backend.issueQueries.last, contains('type:pr'));

      await _selectDrawerDestination(
        tester,
        const ValueKey<String>('global-nav-issues'),
      );
      expect(
        backend.issueQueries.length,
        3,
        reason:
            'returning to a mounted destination must not replay its first page',
      );
      final TextField issueSearch = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('global-lists-search-issues')),
      );
      expect(issueSearch.controller?.text, 'flutter');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('drawer destination switching restores list scroll position', (
    final WidgetTester tester,
  ) async {
    final _EmptySearchBackend backend = _EmptySearchBackend(
      issueItems: List<IssueOrPull>.generate(
        40,
        (final int index) => _issue(index + 1),
      ),
    );
    await _pumpPage(
      tester,
      size: const Size(800, 700),
      page: GlobalListsShell(
        initialDestination: GlobalListDestination.issues,
        account: account,
        accountLoading: false,
        topRepositories: const AsyncData<List<HomeRepositoryItem>>(
          <HomeRepositoryItem>[],
        ),
      ),
      backend: backend,
    );

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    final double issueOffset = _activeVerticalOffset(tester);
    expect(issueOffset, greaterThan(100));

    await _selectDrawerDestination(
      tester,
      const ValueKey<String>('global-nav-pull-requests'),
    );
    await _selectDrawerDestination(
      tester,
      const ValueKey<String>('global-nav-issues'),
    );

    expect(_activeVerticalOffset(tester), closeTo(issueOffset, 1));
    expect(
      backend.issueQueries.length,
      2,
      reason: 'each destination should issue only its own first request',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('repositories use the affiliated query and real empty state', (
    final WidgetTester tester,
  ) async {
    final _EmptySearchBackend backend = _EmptySearchBackend();
    await _pumpPage(
      tester,
      size: const Size(1440, 900),
      page: GlobalListsPage(
        destination: GlobalListDestination.repositories,
        account: account,
        scope: _scope,
      ),
      backend: backend,
    );

    expect(find.text('All repositories'), findsWidgets);
    expect(find.text('Repositories available to @octocat'), findsOneWidget);
    expect(find.text('No repositories match these filters'), findsOneWidget);
    expect(backend.repositoryQueries.single.login, 'octocat');
    expect(
      backend.repositoryQueries.single.visibility,
      GlobalRepositoryVisibility.all,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('comment count exposes one combined readable semantic label', (
    final WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final _EmptySearchBackend backend = _EmptySearchBackend(
      issueItems: <IssueOrPull>[_issue(1, commentsCount: 3)],
    );
    await _pumpPage(
      tester,
      size: const Size(800, 900),
      page: GlobalListsPage(
        destination: GlobalListDestination.issues,
        account: account,
        scope: _scope,
      ),
      backend: backend,
    );

    final Finder workItem = find.bySemanticsLabel(RegExp(r'.*3 comments.*'));
    expect(workItem, findsOneWidget);
    final SemanticsNode node = tester.getSemantics(workItem);
    expect(node.hasFlag(SemanticsFlag.isLink), isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('repository text projection reuses the retained remote page', (
    final WidgetTester tester,
  ) async {
    final _EmptySearchBackend backend = _EmptySearchBackend();
    await _pumpPage(
      tester,
      size: const Size(800, 900),
      page: GlobalListsPage(
        destination: GlobalListDestination.repositories,
        account: account,
        scope: _scope,
      ),
      backend: backend,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('global-lists-search-repositories')),
      'flutter',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(
      backend.repositoryQueries.length,
      1,
      reason:
          'client text projection must reuse the same affiliated Runtime page',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('new issue opens the real affiliated repository picker', (
    final WidgetTester tester,
  ) async {
    final _EmptySearchBackend backend = _EmptySearchBackend();
    await _pumpPage(
      tester,
      size: const Size(800, 900),
      page: GlobalListsPage(
        destination: GlobalListDestination.issues,
        account: account,
        scope: _scope,
      ),
      backend: backend,
    );

    await tester.tap(find.text('New issue'));
    await tester.pumpAndSettle();

    expect(find.text('Select a repository'), findsOneWidget);
    expect(backend.repositoryQueries.single.login, 'octocat');
    expect(tester.takeException(), isNull);
  });
}

Future<void> _selectDrawerDestination(
  final WidgetTester tester,
  final ValueKey<String> destinationKey,
) async {
  await tester.tap(find.byTooltip('Open navigation'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(destinationKey));
  await tester.pumpAndSettle();
}

double _activeVerticalOffset(final WidgetTester tester) {
  final Finder finder = find.byWidgetPredicate(
    (final Widget widget) =>
        widget is Scrollable &&
        (widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up),
  );
  return tester.state<ScrollableState>(finder.last).position.pixels;
}

IssueResult _issue(final int number, {final int commentsCount = 0}) =>
    IssueResult(
      Fragment$issueCardFields.fromJson(<String, dynamic>{
        'id': 'issue-$number',
        'title': 'Retained issue $number',
        'number': number,
        'issueState': 'OPEN',
        'stateReason': null,
        'url': 'https://github.com/octocat/hello-world/issues/$number',
        'body': '',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'closedAt': null,
        'authorAssociation': 'NONE',
        'comments': <String, dynamic>{
          'totalCount': commentsCount,
          '__typename': 'IssueCommentConnection',
        },
        'author': null,
        'labels': null,
        'assignees': <String, dynamic>{
          'nodes': <dynamic>[],
          '__typename': 'UserConnection',
        },
        'repository': <String, dynamic>{
          'name': 'hello-world',
          'nameWithOwner': 'octocat/hello-world',
          'owner': <String, dynamic>{
            'login': 'octocat',
            'avatarUrl': 'https://avatars.githubusercontent.com/u/1',
            '__typename': 'User',
          },
          'url': 'https://github.com/octocat/hello-world',
          'viewerHasStarred': false,
          '__typename': 'Repository',
        },
        'milestone': null,
        'locked': false,
        'activeLockReason': null,
        'isPinned': false,
        'trackedIssues': <String, dynamic>{
          'totalCount': 0,
          'nodes': <dynamic>[],
          '__typename': 'IssueConnection',
        },
        'subIssuesSummary': <String, dynamic>{
          'completed': 0,
          'total': 0,
          'percentCompleted': 0,
          '__typename': 'SubIssuesSummary',
        },
        'parent': null,
        'projectItems': null,
        'reactionGroups': null,
        'viewerCanSubscribe': false,
        'viewerSubscription': null,
        'isReadByViewer': false,
        'closedByPRsSummary': null,
        '__typename': 'Issue',
      }),
    );

Future<void> _pumpPage(
  final WidgetTester tester, {
  required final Size size,
  required final Widget page,
  required final _EmptySearchBackend backend,
  final double textScale = 1,
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
        currentUserProvider.overrideWithBuild((final _, final _) async => null),
        resourceRuntimeProvider.overrideWith(
          (final Ref ref) => InMemoryResourceRuntime(),
        ),
        globalIssuePullPageSpecFactoryProvider.overrideWithValue(
          backend.issueSpecFactory,
        ),
        globalRepositoryPageSpecFactoryProvider.overrideWithValue(
          backend.repositorySpecFactory,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        builder: (final BuildContext context, final Widget? child) =>
            MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
        home: Scaffold(body: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _EmptySearchBackend {
  _EmptySearchBackend({
    this.issueItems = const <IssueOrPull>[],
    this.failFirstIssueRequest = false,
  });

  final List<IssueOrPull> issueItems;
  final bool failFirstIssueRequest;
  final List<String> issueQueries = <String>[];
  final List<GlobalRepositoryBrowseQuery> repositoryQueries =
      <GlobalRepositoryBrowseQuery>[];

  ResourceSpec<PaginatedResourcePage<IssueOrPull, GlobalSearchPageKey>>
  issueSpecFactory({
    required final ResourceScope scope,
    required final String query,
    required final GlobalSearchPageKey pageKey,
    required final int pageSize,
  }) => ResourceSpec<PaginatedResourcePage<IssueOrPull, GlobalSearchPageKey>>(
    id: ResourceId<PaginatedResourcePage<IssueOrPull, GlobalSearchPageKey>>(
      kind: 'test-global-issue-page',
      version: 1,
      scope: scope,
      key: '$query/${pageKey.identity}/$pageSize',
    ),
    policy: globalSearchPagePolicy,
    tags: <ResourceTag>{globalSearchQueryTag(kind: 'issue-pull', query: query)},
    contract: 'test-global-issue-page-v1',
    load: (final ResourceLoadContext _) async {
      issueQueries.add(query);
      if (failFirstIssueRequest && issueQueries.length == 1) {
        throw StateError('first page failed');
      }
      return ResourceLoadResult<
        PaginatedResourcePage<IssueOrPull, GlobalSearchPageKey>
      >(
        data: PaginatedResourcePage<IssueOrPull, GlobalSearchPageKey>(
          items: issueItems,
          hasNextPage: false,
          totalCount: issueItems.length,
        ),
      );
    },
  );

  ResourceSpec<PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>>
  repositorySpecFactory({
    required final ResourceScope scope,
    required final GlobalRepositoryBrowseQuery query,
    required final GlobalSearchPageKey pageKey,
    required final int pageSize,
  }) => ResourceSpec<PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>>(
    id: ResourceId<PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>>(
      kind: 'test-global-repository-page',
      version: 1,
      scope: scope,
      key: '${query.remoteIdentity}/${pageKey.identity}/$pageSize',
    ),
    policy: globalSearchPagePolicy,
    tags: <ResourceTag>{globalRepositoryQueryTag(query)},
    contract: 'test-global-repository-page-v1',
    load: (final ResourceLoadContext _) async {
      repositoryQueries.add(query);
      return const ResourceLoadResult<
        PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>
      >(
        data: PaginatedResourcePage<UserRepoEdge, GlobalSearchPageKey>(
          items: <UserRepoEdge>[],
          hasNextPage: false,
          totalCount: 0,
        ),
      );
    },
  );
}
