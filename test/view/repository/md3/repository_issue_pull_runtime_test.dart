import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/repository/repository_issue_pull_page_resource.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/repository/md3/repository_issue_pull_md3.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const RepoRef _repoRef = RepoRef(owner: 'octocat', name: 'hello-world');
const ResourceScope _firstResourceScope = ResourceScope(
  serverId: 'github.com',
  principal: 'test-account-1',
);
const ResourceScope _secondResourceScope = ResourceScope(
  serverId: 'github.com',
  principal: 'test-account-2',
);

void main() {
  testWidgets(
    'production runtime source retains Open/Closed and refreshes explicitly',
    (final WidgetTester tester) async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final _RuntimePageBackend backend = _RuntimePageBackend();
      final ProviderContainer container = _runtimePageContainer(
        runtime: runtime,
        backend: backend,
      );
      addTearDown(() {
        container.dispose();
        runtime.dispose();
      });
      Future<void> Function()? refresh;

      await _pumpRuntimePage(
        tester,
        container: container,
        signedIn: true,
        onRefreshReady: (final Future<void> Function()? callback) {
          refresh = callback;
        },
      );
      await tester.pumpAndSettle();

      expect(backend.loadCalls, 1);
      expect(backend.transports, <RepositoryIssuePullPageTransport>[
        RepositoryIssuePullPageTransport.authenticatedGraphql,
      ]);
      expect(backend.queries.single.split(' '), contains('is:open'));

      await tester.tap(find.text('Closed'));
      await tester.pumpAndSettle();
      expect(backend.loadCalls, 2);
      expect(backend.queries.last.split(' '), contains('is:closed'));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        backend.loadCalls,
        2,
        reason: 'the retained Open controller must reuse its loaded page',
      );

      await refresh!.call();
      await tester.pumpAndSettle();
      expect(
        backend.loadCalls,
        3,
        reason: 'explicit refresh must invalidate and replace the Open page',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a rebuilt public controller reuses the fresh REST page from Runtime',
    (final WidgetTester tester) async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final _RuntimePageBackend backend = _RuntimePageBackend();
      final ProviderContainer container = _runtimePageContainer(
        runtime: runtime,
        backend: backend,
      );
      addTearDown(() {
        container.dispose();
        runtime.dispose();
      });

      await _pumpRuntimePage(tester, container: container, signedIn: false);
      await tester.pumpAndSettle();
      expect(backend.loadCalls, 1);
      expect(
        backend.transports.single,
        RepositoryIssuePullPageTransport.publicRest,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox.shrink(),
        ),
      );
      await tester.pump();
      await _pumpRuntimePage(tester, container: container, signedIn: false);
      await tester.pumpAndSettle();

      expect(
        backend.loadCalls,
        1,
        reason: 'a new controller must reuse the fresh immutable REST page',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('account scope change replaces the retained query source', (
    final WidgetTester tester,
  ) async {
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final _RuntimePageBackend backend = _RuntimePageBackend();
    final ProviderContainer container = _runtimePageContainer(
      runtime: runtime,
      backend: backend,
    );
    addTearDown(() {
      container.dispose();
      runtime.dispose();
    });

    await _pumpRuntimePage(tester, container: container, signedIn: true);
    await tester.pumpAndSettle();
    expect(backend.loadCalls, 1);
    expect(backend.scopes.single, _firstResourceScope);

    container
        .read(_testResourceScopeProvider.notifier)
        .setScope(_secondResourceScope);
    await tester.pumpAndSettle();

    expect(
      backend.loadCalls,
      2,
      reason: 'the old account controller must not serve the new scope',
    );
    expect(backend.scopes.last, _secondResourceScope);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public Runtime source advances explicit REST page keys', (
    final WidgetTester tester,
  ) async {
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final _RuntimePageBackend backend = _RuntimePageBackend(
      includeSecondPage: true,
    );
    final ProviderContainer container = _runtimePageContainer(
      runtime: runtime,
      backend: backend,
    );
    addTearDown(() {
      container.dispose();
      runtime.dispose();
    });

    await _pumpRuntimePage(tester, container: container, signedIn: false);
    await tester.pumpAndSettle();

    expect(backend.loadCalls, 2);
    expect(backend.pageKeys, const <RepositoryIssuePullPageKey>[
      RepositoryIssuePullPageKey.rest(1),
      RepositoryIssuePullPageKey.rest(2),
    ]);
    expect(tester.takeException(), isNull);
  });
}

final class _RuntimePageBackend {
  _RuntimePageBackend({this.includeSecondPage = false});

  final bool includeSecondPage;
  final List<String> queries = <String>[];
  final List<RepositoryIssuePullPageTransport> transports =
      <RepositoryIssuePullPageTransport>[];
  final List<ResourceScope> scopes = <ResourceScope>[];
  final List<RepositoryIssuePullPageKey> pageKeys =
      <RepositoryIssuePullPageKey>[];
  int loadCalls = 0;

  RepositoryIssuePullPageResourceSpecFactory get specFactory =>
      ({
        required final RepoRef repo,
        required final String query,
        required final RepositoryIssuePullPageTransport transport,
        required final RepositoryIssuePullPageKey pageKey,
        required final int pageSize,
        required final ResourceScope scope,
      }) =>
          ResourceSpec<
            PaginatedResourcePage<Object, RepositoryIssuePullPageKey>
          >(
            id:
                ResourceId<
                  PaginatedResourcePage<Object, RepositoryIssuePullPageKey>
                >(
                  kind: 'test-repository-issue-pull-page',
                  version: 1,
                  scope: scope,
                  key:
                      '${transport.name}/${Uri.encodeComponent(query)}/'
                      '${pageKey.identity}/$pageSize',
                ),
            policy: repositoryIssuePullPageResourcePolicy,
            tags: <ResourceTag>{
              ResourceTag('repository', repo.fullName),
              ResourceTag(
                'repository-issue-pull-query',
                repositoryIssuePullQueryIdentity(
                  repo: repo,
                  query: query,
                  transport: transport,
                ),
              ),
            },
            contract: 'test-repository-issue-pull-${transport.name}-v1',
            load: (final ResourceLoadContext _) async {
              loadCalls += 1;
              queries.add(query);
              transports.add(transport);
              scopes.add(scope);
              pageKeys.add(pageKey);
              final bool hasNextPage =
                  includeSecondPage &&
                  transport == RepositoryIssuePullPageTransport.publicRest &&
                  pageKey.page == 1;
              return ResourceLoadResult<
                PaginatedResourcePage<Object, RepositoryIssuePullPageKey>
              >(
                data: PaginatedResourcePage<Object, RepositoryIssuePullPageKey>(
                  items: const <Object>[],
                  hasNextPage: hasNextPage,
                  nextPageKey: hasNextPage
                      ? const RepositoryIssuePullPageKey.rest(2)
                      : null,
                  totalCount: 0,
                ),
              );
            },
          );
}

ProviderContainer _runtimePageContainer({
  required final InMemoryResourceRuntime runtime,
  required final _RuntimePageBackend backend,
}) {
  return ProviderContainer(
    overrides: <Override>[
      currentUserProvider.overrideWithBuild((_, __) async => null),
      settingsCacheProvider.overrideWithValue(
        SettingsCache(<String, String>{}),
      ),
      activeResourceScopeProvider.overrideWith(
        (final Ref ref) => ref.watch(_testResourceScopeProvider),
      ),
      resourceRuntimeProvider.overrideWithValue(runtime),
      repositoryIssuePullPageResourceSpecFactoryProvider.overrideWithValue(
        backend.specFactory,
      ),
    ],
  );
}

final _testResourceScopeProvider =
    NotifierProvider<_TestResourceScopeNotifier, ResourceScope>(
      _TestResourceScopeNotifier.new,
    );

final class _TestResourceScopeNotifier extends Notifier<ResourceScope> {
  @override
  ResourceScope build() => _firstResourceScope;

  void setScope(final ResourceScope scope) {
    state = scope;
  }
}

Future<void> _pumpRuntimePage(
  final WidgetTester tester, {
  required final ProviderContainer container,
  required final bool signedIn,
  final ValueChanged<Future<void> Function()?>? onRefreshReady,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(800, 900);
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
        home: Scaffold(
          body: RepositoryIssuesMd3Page(
            repoRef: _repoRef,
            repo: null,
            details: null,
            signedIn: signedIn,
            onRefreshReady: onRefreshReady,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
