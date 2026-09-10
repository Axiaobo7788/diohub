import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/global_list_destination.dart';
import 'package:diohub/models/global_project_browse_query.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/search/global_search_page_resource.dart';
import 'package:diohub/providers/search/global_search_session_provider.dart';
import 'package:diohub/view/global_lists/global_lists_screen.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:flutter/material.dart';
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
    scope: 'repo user project',
  );

  for (final ({Size size, bool compact, double textScale}) scenario
      in <({Size size, bool compact, double textScale})>[
        (size: const Size(360, 800), compact: true, textScale: 1.3),
        (size: const Size(800, 900), compact: false, textScale: 1),
        (size: const Size(1440, 900), compact: false, textScale: 2),
      ]) {
    testWidgets('Projects is responsive at ${scenario.size.width.toInt()}px', (
      final WidgetTester tester,
    ) async {
      final _CommunityBackend backend = _CommunityBackend();
      await _pump(
        tester,
        size: scenario.size,
        textScale: scenario.textScale,
        backend: backend,
        page: GlobalProjectsPage(account: account, scope: _scope),
      );

      expect(find.text('Projects'), findsWidgets);
      expect(find.text('No projects match this search'), findsOneWidget);
      expect(backend.projectQueries.single.login, 'octocat');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Discussions is responsive at ${scenario.size.width.toInt()}px',
      (final WidgetTester tester) async {
        final _CommunityBackend backend = _CommunityBackend();
        await _pump(
          tester,
          size: scenario.size,
          textScale: scenario.textScale,
          backend: backend,
          page: GlobalDiscussionsPage(account: account, scope: _scope),
        );

        expect(find.text('Discussions'), findsWidgets);
        expect(find.text('No discussions match this search'), findsOneWidget);
        expect(backend.discussionQueries.single, contains('involves:octocat'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Project title search is server-backed and retained', (
    final WidgetTester tester,
  ) async {
    final _CommunityBackend backend = _CommunityBackend();
    await _pump(
      tester,
      size: const Size(800, 900),
      backend: backend,
      page: GlobalProjectsPage(account: account, scope: _scope),
    );
    expect(backend.projectQueries.length, 1);

    await tester.enterText(
      find.byKey(const ValueKey<String>('global-projects-search')),
      'roadmap',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(backend.projectQueries.length, 2);
    expect(backend.projectQueries.last.normalizedText, 'roadmap');

    await tester.enterText(
      find.byKey(const ValueKey<String>('global-projects-search')),
      '',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(
      backend.projectQueries.length,
      2,
      reason: 'returning to the retained empty query must not fetch again',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Discussion filters produce official search qualifiers', (
    final WidgetTester tester,
  ) async {
    final _CommunityBackend backend = _CommunityBackend();
    await _pump(
      tester,
      size: const Size(800, 900),
      backend: backend,
      page: GlobalDiscussionsPage(account: account, scope: _scope),
    );

    await tester.tap(find.text('All').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Answered').last);
    await tester.pumpAndSettle();

    expect(backend.discussionQueries.length, 2);
    expect(backend.discussionQueries.last, contains('is:answered'));
    expect(backend.discussionQueries.last, contains('involves:octocat'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer switching retains both community sessions', (
    final WidgetTester tester,
  ) async {
    final _CommunityBackend backend = _CommunityBackend();
    await _pump(
      tester,
      size: const Size(800, 900),
      backend: backend,
      page: GlobalListsShell(
        initialDestination: GlobalListDestination.projects,
        account: account,
        accountLoading: false,
        topRepositories: const AsyncData<List<HomeRepositoryItem>>(
          <HomeRepositoryItem>[],
        ),
      ),
    );
    expect(backend.projectQueries.length, 1);

    await _selectDrawer(
      tester,
      const ValueKey<String>('global-nav-discussions'),
    );
    expect(backend.discussionQueries.length, 1);
    await _selectDrawer(tester, const ValueKey<String>('global-nav-projects'));

    expect(
      backend.projectQueries.length,
      1,
      reason: 'returning to Projects must not replay the first page',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Projects explains a missing OAuth project scope', (
    final WidgetTester tester,
  ) async {
    final _CommunityBackend backend = _CommunityBackend();
    await _pump(
      tester,
      size: const Size(360, 800),
      backend: backend,
      page: GlobalProjectsPage(
        account: AccountModel(
          nodeId: 'account-1',
          username: 'octocat',
          addedAt: DateTime.utc(2026),
          scope: 'repo user',
        ),
        scope: _scope,
      ),
    );

    expect(find.text('Project access required'), findsOneWidget);
    expect(backend.projectQueries, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Projects exposes a working retry after a failed first page', (
    final WidgetTester tester,
  ) async {
    final _CommunityBackend backend = _CommunityBackend(
      failFirstProjectRequest: true,
    );
    await _pump(
      tester,
      size: const Size(800, 900),
      backend: backend,
      page: GlobalProjectsPage(account: account, scope: _scope),
    );

    expect(find.text('Could not load results.'), findsOneWidget);
    expect(backend.projectQueries.length, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('No projects match this search'), findsOneWidget);
    expect(backend.projectQueries.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Projects and Discussions expose localized Chinese chrome', (
    final WidgetTester tester,
  ) async {
    final _CommunityBackend backend = _CommunityBackend();
    await _pump(
      tester,
      size: const Size(800, 900),
      locale: const Locale('zh'),
      backend: backend,
      page: GlobalListsShell(
        initialDestination: GlobalListDestination.projects,
        account: account,
        accountLoading: false,
        topRepositories: const AsyncData<List<HomeRepositoryItem>>(
          <HomeRepositoryItem>[],
        ),
      ),
    );

    expect(find.text('没有与搜索条件匹配的项目'), findsOneWidget);
    await tester.tap(find.byTooltip('打开导航'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('global-nav-discussions')),
    );
    await tester.pumpAndSettle();

    expect(find.text('没有与搜索条件匹配的讨论'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _selectDrawer(
  final WidgetTester tester,
  final ValueKey<String> destinationKey,
) async {
  await tester.tap(find.byTooltip('Open navigation'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(destinationKey));
  await tester.pumpAndSettle();
}

Future<void> _pump(
  final WidgetTester tester, {
  required final Size size,
  required final Widget page,
  required final _CommunityBackend backend,
  final double textScale = 1,
  final Locale locale = const Locale('en'),
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
        resourceRuntimeProvider.overrideWith(
          (final Ref ref) => InMemoryResourceRuntime(),
        ),
        globalProjectPageSpecFactoryProvider.overrideWithValue(
          backend.projectSpecFactory,
        ),
        globalDiscussionPageSpecFactoryProvider.overrideWithValue(
          backend.discussionSpecFactory,
        ),
      ],
      child: MaterialApp(
        locale: locale,
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

final class _CommunityBackend {
  _CommunityBackend({this.failFirstProjectRequest = false});

  final bool failFirstProjectRequest;
  final List<GlobalProjectBrowseQuery> projectQueries =
      <GlobalProjectBrowseQuery>[];
  final List<String> discussionQueries = <String>[];

  ResourceSpec<PaginatedResourcePage<UserProjectV2Edge, GlobalSearchPageKey>>
  projectSpecFactory({
    required final ResourceScope scope,
    required final GlobalProjectBrowseQuery query,
    required final GlobalSearchPageKey pageKey,
    required final int pageSize,
  }) =>
      ResourceSpec<
        PaginatedResourcePage<UserProjectV2Edge, GlobalSearchPageKey>
      >(
        id:
            ResourceId<
              PaginatedResourcePage<UserProjectV2Edge, GlobalSearchPageKey>
            >(
              kind: 'test-global-project-page',
              version: 1,
              scope: scope,
              key: '${query.identity}/${pageKey.identity}/$pageSize',
            ),
        policy: globalSearchPagePolicy,
        tags: <ResourceTag>{globalProjectQueryTag(query)},
        contract: 'test-global-project-page-v1',
        load: (final ResourceLoadContext _) async {
          projectQueries.add(query);
          if (failFirstProjectRequest && projectQueries.length == 1) {
            throw StateError('project request failed');
          }
          return const ResourceLoadResult<
            PaginatedResourcePage<UserProjectV2Edge, GlobalSearchPageKey>
          >(
            data: PaginatedResourcePage<UserProjectV2Edge, GlobalSearchPageKey>(
              items: <UserProjectV2Edge>[],
              hasNextPage: false,
              totalCount: 0,
            ),
          );
        },
      );

  ResourceSpec<PaginatedResourcePage<DiscussionCardData, GlobalSearchPageKey>>
  discussionSpecFactory({
    required final ResourceScope scope,
    required final String query,
    required final GlobalSearchPageKey pageKey,
    required final int pageSize,
  }) =>
      ResourceSpec<
        PaginatedResourcePage<DiscussionCardData, GlobalSearchPageKey>
      >(
        id:
            ResourceId<
              PaginatedResourcePage<DiscussionCardData, GlobalSearchPageKey>
            >(
              kind: 'test-global-discussion-page',
              version: 1,
              scope: scope,
              key: '$query/${pageKey.identity}/$pageSize',
            ),
        policy: globalSearchPagePolicy,
        tags: <ResourceTag>{
          globalSearchQueryTag(kind: 'discussion', query: query),
        },
        contract: 'test-global-discussion-page-v1',
        load: (final ResourceLoadContext _) async {
          discussionQueries.add(query);
          return const ResourceLoadResult<
            PaginatedResourcePage<DiscussionCardData, GlobalSearchPageKey>
          >(
            data:
                PaginatedResourcePage<DiscussionCardData, GlobalSearchPageKey>(
                  items: <DiscussionCardData>[],
                  hasNextPage: false,
                  totalCount: 0,
                ),
          );
        },
      );
}
