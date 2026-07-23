import 'dart:async';

import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_type_config.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/repository/md3/repository_issue_pull_md3.dart';
import 'package:diohub/view/repository/md3/repository_issue_pull_row.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const RepoRef _repoRef = RepoRef(owner: 'octocat', name: 'hello-world');
const PageSlice<Object> _emptyPage = PageSlice<Object>(
  items: <Object>[],
  hasNextPage: false,
  totalCount: 0,
);

void main() {
  group('Repository Issues responsive layout', () {
    for (final double width in <double>[360, 800, 1440]) {
      testWidgets(
        'uses the expected sidebar and scoped open query at ${width}px',
        (final WidgetTester tester) async {
          final _FakeSearchBackend backend = _FakeSearchBackend(
            <_SearchResponse>[() async => _emptyPage],
          );

          await _pumpPage(
            tester,
            width: width,
            kind: RepositoryIssuePullKind.issues,
            backend: backend,
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const ValueKey<String>('repository-issues-sidebar')),
            width >= 768 ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(const ValueKey<String>('repository-issues-scroll')),
            findsOneWidget,
          );
          _expectFirstQuery(backend, typeQualifier: 'type:issue');
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Repository Pull requests responsive layout', () {
    for (final double width in <double>[360, 800, 1440]) {
      testWidgets(
        'never uses the Issues sidebar and keeps its scoped open query at '
        '${width}px',
        (final WidgetTester tester) async {
          final _FakeSearchBackend backend = _FakeSearchBackend(
            <_SearchResponse>[() async => _emptyPage],
          );

          await _pumpPage(
            tester,
            width: width,
            kind: RepositoryIssuePullKind.pullRequests,
            backend: backend,
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const ValueKey<String>('repository-issues-sidebar')),
            findsNothing,
          );
          expect(
            find.byKey(
              const ValueKey<String>('repository-pull-requests-scroll'),
            ),
            findsOneWidget,
          );
          _expectFirstQuery(backend, typeQualifier: 'type:pr');
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  testWidgets('shows an honest first-page loading state', (
    final WidgetTester tester,
  ) async {
    final Completer<PageSlice<Object>> response =
        Completer<PageSlice<Object>>();
    final _FakeSearchBackend backend = _FakeSearchBackend(<_SearchResponse>[
      () => response.future,
    ]);

    await _pumpPage(
      tester,
      width: 800,
      kind: RepositoryIssuePullKind.issues,
      backend: backend,
    );
    await tester.pump();

    expect(backend.fetchCalls, 1);
    expect(
      find.byKey(const ValueKey<String>('repository-issue-pull-loading')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('repository-issue-pull-empty')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    response.complete(_emptyPage);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('repository-issue-pull-empty')),
      findsOneWidget,
    );
  });

  testWidgets('renders the empty state after an empty page', (
    final WidgetTester tester,
  ) async {
    final _FakeSearchBackend backend = _FakeSearchBackend(<_SearchResponse>[
      () async => _emptyPage,
    ]);

    await _pumpPage(
      tester,
      width: 800,
      kind: RepositoryIssuePullKind.pullRequests,
      backend: backend,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('repository-issue-pull-empty')),
      findsOneWidget,
    );
    expect(find.text('There aren’t any open pull requests.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retries a failed page and then renders the empty state', (
    final WidgetTester tester,
  ) async {
    final _FakeSearchBackend backend = _FakeSearchBackend(<_SearchResponse>[
      () => Future<PageSlice<Object>>.error(StateError('search failed')),
      () async => _emptyPage,
    ]);

    await _pumpPage(
      tester,
      width: 800,
      kind: RepositoryIssuePullKind.issues,
      backend: backend,
    );
    await tester.pumpAndSettle();

    expect(backend.fetchCalls, 1);
    expect(
      find.byKey(const ValueKey<String>('repository-issue-pull-error')),
      findsOneWidget,
    );
    expect(find.text('Could not load this list.'), findsOneWidget);
    expect(find.textContaining('search failed'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(backend.fetchCalls, 2);
    expect(
      find.byKey(const ValueKey<String>('repository-issue-pull-error')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('repository-issue-pull-empty')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('RefreshIndicator resets and fetches the list again', (
    final WidgetTester tester,
  ) async {
    final _FakeSearchBackend backend = _FakeSearchBackend(<_SearchResponse>[
      () async => _emptyPage,
      () async => _emptyPage,
    ]);

    await _pumpPage(
      tester,
      width: 800,
      kind: RepositoryIssuePullKind.issues,
      backend: backend,
    );
    await tester.pumpAndSettle();
    expect(backend.fetchCalls, 1);

    final RefreshIndicatorState indicator = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );
    unawaited(indicator.show());
    await tester.pumpAndSettle();

    expect(backend.resetCalls, 1);
    expect(backend.fetchCalls, 2);
    expect(
      find.byKey(const ValueKey<String>('repository-issue-pull-empty')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('search debounce issues only one request for the final text', (
    final WidgetTester tester,
  ) async {
    final _FakeSearchBackend backend = _FakeSearchBackend(<_SearchResponse>[
      () async => _emptyPage,
      () async => _emptyPage,
    ]);

    await _pumpPage(
      tester,
      width: 800,
      kind: RepositoryIssuePullKind.issues,
      backend: backend,
    );
    await tester.pumpAndSettle();
    expect(backend.fetchCalls, 1);

    final Finder searchField = find.byKey(
      const ValueKey<String>('repository-issues-search'),
    );
    await tester.enterText(searchField, 'r');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(searchField, 're');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(searchField, 'render');
    await tester.pump(const Duration(milliseconds: 299));

    expect(backend.fetchCalls, 1);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(backend.fetchCalls, 2);
    expect(backend.queries.last.split(' '), contains('render'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('onRefreshReady refreshes the list exactly once', (
    final WidgetTester tester,
  ) async {
    final _FakeSearchBackend backend = _FakeSearchBackend(<_SearchResponse>[
      () async => _emptyPage,
      () async => _emptyPage,
    ]);
    Future<void> Function()? refresh;

    await _pumpPage(
      tester,
      width: 800,
      kind: RepositoryIssuePullKind.pullRequests,
      backend: backend,
      onRefreshReady: (final Future<void> Function()? callback) {
        refresh = callback;
      },
    );
    await tester.pumpAndSettle();

    expect(backend.fetchCalls, 1);
    expect(refresh, isNotNull);

    final Future<void> refreshFuture = refresh!.call();
    await tester.pump();
    await refreshFuture;
    await tester.pumpAndSettle();

    expect(backend.resetCalls, 1);
    expect(backend.fetchCalls, 2);
    expect(
      find.byKey(const ValueKey<String>('repository-issue-pull-empty')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-out page shows its limitation without fetching', (
    final WidgetTester tester,
  ) async {
    final _FakeSearchBackend backend = _FakeSearchBackend(<_SearchResponse>[
      () async => _emptyPage,
    ]);

    await _pumpPage(
      tester,
      width: 800,
      kind: RepositoryIssuePullKind.issues,
      backend: backend,
      signedIn: false,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('repository-issue-pull-sign-in')),
      findsOneWidget,
    );
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('repository-issues-scroll')),
      findsOneWidget,
    );
    expect(backend.fetchCalls, 0);
    expect(backend.queries, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'long Issue content stays overflow-free at 360px and is not translated',
    (final WidgetTester tester) async {
      const String userTitle =
          'Keep this exact user-authored issue title in its original language '
          'even when the application locale changes';
      final RepositoryIssuePullRowData data = RepositoryIssuePullRowData(
        ref: const IssueRef(repo: _repoRef, number: 42),
        title: userTitle,
        number: 42,
        author: 'octocat',
        timestamp: DateTime.utc(2026, 7, 23, 8),
        commentsCount: 128,
        visualState: IssueVisualState.open,
        labels: const <RepositoryIssuePullLabelData>[
          RepositoryIssuePullLabelData(
            name: 'accessibility regression',
            color: 'd73a4a',
          ),
          RepositoryIssuePullLabelData(
            name: 'needs detailed investigation',
            color: '0366d6',
          ),
        ],
      );

      await _pumpRow(tester, data: data, locale: const Locale('zh'));

      expect(
        find.byKey(const ValueKey<String>('repository-list-row-issue-42')),
        findsOneWidget,
      );
      expect(find.text(userTitle), findsOneWidget);
      expect(find.textContaining('已开启'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('long Pull request content stays overflow-free at 360px', (
    final WidgetTester tester,
  ) async {
    const String userTitle =
        'Refactor the repository loading pipeline without losing navigation '
        'state across narrow desktop windows';
    final RepositoryIssuePullRowData data = RepositoryIssuePullRowData(
      ref: const PullRequestRef(repo: _repoRef, number: 73),
      title: userTitle,
      number: 73,
      author: 'hubot',
      timestamp: DateTime.utc(2026, 7, 23, 9),
      commentsCount: 64,
      visualState: PrVisualState.merged,
      labels: const <RepositoryIssuePullLabelData>[
        RepositoryIssuePullLabelData(
          name: 'desktop and mobile',
          color: '8250df',
        ),
        RepositoryIssuePullLabelData(name: 'performance', color: '1a7f37'),
      ],
    );

    await _pumpRow(tester, data: data);

    expect(
      find.byKey(const ValueKey<String>('repository-list-row-pr-73')),
      findsOneWidget,
    );
    expect(find.text(userTitle), findsOneWidget);
    expect(find.textContaining('merged'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

typedef _SearchResponse = Future<PageSlice<Object>> Function();

final class _FakeSearchBackend {
  _FakeSearchBackend(this._responses);

  final List<_SearchResponse> _responses;
  final List<String> queries = <String>[];
  int fetchCalls = 0;
  int resetCalls = 0;

  Future<PageSlice<Object>> next(final String query) {
    queries.add(query);
    if (fetchCalls >= _responses.length) {
      throw StateError('Unexpected search request ${fetchCalls + 1}: $query');
    }
    final _SearchResponse response = _responses[fetchCalls];
    fetchCalls += 1;
    return response();
  }
}

final class _FakeIssuePullAdapter extends SearchTypeAdapter<Object> {
  _FakeIssuePullAdapter(super.ref, this.backend);

  final _FakeSearchBackend backend;

  @override
  Future<PageSlice<Object>> fetchSlice({
    required final String query,
    required final int count,
    final void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) {
    return backend.next(query);
  }

  @override
  void resetState() {
    backend.resetCalls += 1;
  }

  @override
  Widget buildItem(
    final BuildContext context,
    final Object item,
    final int index,
  ) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildLoadingShimmer(final BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  String itemId(final Object item) => identityHashCode(item).toString();
}

Future<void> _pumpPage(
  final WidgetTester tester, {
  required final double width,
  required final RepositoryIssuePullKind kind,
  required final _FakeSearchBackend backend,
  final bool signedIn = true,
  final Locale locale = const Locale('en'),
  final ValueChanged<Future<void> Function()?>? onRefreshReady,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, 900);
  addTearDown(() {
    tester.view
      ..resetDevicePixelRatio()
      ..resetPhysicalSize();
  });

  final SearchTypeConfigFactory factory =
      (final WidgetRef ref, final SearchScope _) =>
          SearchTypeConfig(_FakeIssuePullAdapter(ref, backend));
  final Widget page = switch (kind) {
    RepositoryIssuePullKind.issues => RepositoryIssuesMd3Page(
      repoRef: _repoRef,
      repo: null,
      details: null,
      signedIn: signedIn,
      searchConfigFactory: factory,
      onRefreshReady: onRefreshReady,
    ),
    RepositoryIssuePullKind.pullRequests => RepositoryPullRequestsMd3Page(
      repoRef: _repoRef,
      repo: null,
      details: null,
      signedIn: signedIn,
      searchConfigFactory: factory,
      onRefreshReady: onRefreshReady,
    ),
  };

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        currentUserProvider.overrideWithBuild((_, __) async => null),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(body: page),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpRow(
  final WidgetTester tester, {
  required final RepositoryIssuePullRowData data,
  final Locale locale = const Locale('en'),
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(360, 800);
  addTearDown(() {
    tester.view
      ..resetDevicePixelRatio()
      ..resetPhysicalSize();
  });

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: RepositoryIssuePullRow(data: data, onTap: () {}),
      ),
    ),
  );
  await tester.pump();
}

void _expectFirstQuery(
  final _FakeSearchBackend backend, {
  required final String typeQualifier,
}) {
  expect(backend.fetchCalls, 1);
  expect(backend.queries, hasLength(1));
  final Set<String> terms = backend.queries.single.split(' ').toSet();
  expect(
    terms,
    containsAll(<String>[
      typeQualifier,
      'repo:${_repoRef.fullName}',
      'is:open',
    ]),
  );
  expect(terms.any((final String term) => term.startsWith('base:')), isFalse);
  expect(terms.any((final String term) => term.startsWith('head:')), isFalse);
}
