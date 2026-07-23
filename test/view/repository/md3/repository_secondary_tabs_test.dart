import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/repository/insights_providers.dart';
import 'package:diohub/view/repository/md3/repository_actions_md3.dart';
import 'package:diohub/view/repository/md3/repository_insights_md3.dart';
import 'package:diohub/view/repository/md3/repository_projects_md3.dart';
import 'package:diohub/view/repository/md3/repository_security_md3.dart';
import 'package:diohub/view/repository/md3/repository_tab_scaffold.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/participation_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAt(
    final WidgetTester tester, {
    required final Size size,
    required final Widget child,
    final double textScale = 1,
    final bool disableAnimations = false,
    final List<Override> overrides = const <Override>[],
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
        overrides: overrides,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true),
          builder: (final BuildContext context, final Widget? appChild) {
            final MediaQueryData media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: disableAnimations,
              ),
              child: appChild!,
            );
          },
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('page-local navigation collapses without changing global width', (
    final WidgetTester tester,
  ) async {
    Widget buildScaffold() => RepositoryTabScaffold(
      title: 'Actions',
      navigation: RepositoryTabNavigation(
        title: 'Actions',
        destinations: const <RepositoryTabNavigationDestination>[
          RepositoryTabNavigationDestination(
            icon: Icons.play_circle_outline,
            label: 'All workflows',
          ),
        ],
        selectedIndex: 0,
        onSelected: (final int value) {},
      ),
      compactNavigation: const Text(
        'Workflow picker',
        key: ValueKey<String>('compact-picker'),
      ),
      slivers: const <Widget>[
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: Text('Run list', key: ValueKey<String>('run-list')),
          ),
        ),
      ],
    );

    await pumpAt(tester, size: const Size(360, 800), child: buildScaffold());
    expect(
      find.byKey(const ValueKey<String>('compact-picker')),
      findsOneWidget,
    );
    expect(find.text('All workflows'), findsNothing);
    expect(tester.takeException(), isNull);

    await pumpAt(tester, size: const Size(1440, 900), child: buildScaffold());
    expect(find.byKey(const ValueKey<String>('compact-picker')), findsNothing);
    expect(find.text('All workflows'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('run-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final Size size in <Size>[
    const Size(360, 800),
    const Size(800, 900),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'signed-out secondary repository tabs are stable at ${size.width}px',
      (final WidgetTester tester) async {
        const RepoRef repoRef = RepoRef(owner: 'octocat', name: 'hello-world');
        final List<Widget> pages = <Widget>[
          RepositoryActionsMd3Page(
            repoRef: repoRef,
            signedIn: false,
            onRefreshReady: (final Future<void> Function()? callback) {},
          ),
          RepositoryProjectsMd3Page(
            repoRef: repoRef,
            signedIn: false,
            onRefreshReady: (final Future<void> Function()? callback) {},
          ),
          RepositorySecurityMd3Page(
            repoRef: repoRef,
            signedIn: false,
            onRefreshReady: (final Future<void> Function()? callback) {},
          ),
          RepositoryInsightsMd3Page(
            repoRef: repoRef,
            signedIn: false,
            onRefreshReady: (final Future<void> Function()? callback) {},
          ),
        ];
        for (final Widget page in pages) {
          await pumpAt(tester, size: size, child: page);
          expect(find.text('Sign in to continue'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('secondary tab scaffold supports 2x text and reduced motion', (
    final WidgetTester tester,
  ) async {
    await pumpAt(
      tester,
      size: const Size(360, 800),
      textScale: 2,
      disableAnimations: true,
      child: RepositoryTabScaffold(
        title: 'Security overview',
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: RepositoryTabStateCard(
              icon: Icons.shield_outlined,
              title: 'Security data unavailable',
              message:
                  'GitHub may require repository administration permission.',
              action: OutlinedButton(
                onPressed: () {},
                child: const Text('Retry'),
              ),
            ),
          ),
        ],
      ),
    );
    expect(find.text('Security overview'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Insights pulse renders real activity and language proportions', (
    final WidgetTester tester,
  ) async {
    const RepoRef repoRef = RepoRef(owner: 'octocat', name: 'hello-world');
    await pumpAt(
      tester,
      size: const Size(360, 800),
      child: RepositoryInsightsMd3Page(
        repoRef: repoRef,
        signedIn: true,
        onRefreshReady: (final Future<void> Function()? callback) {},
      ),
      overrides: <Override>[
        participationProvider.overrideWith(
          (final Ref ref, final RepoRef arg) async =>
              const ParticipationResponse(
                all: <int>[0, 2, 0, 5, 1, 0, 4],
                owner: <int>[0, 1, 0, 4, 1, 0, 3],
              ),
        ),
        languagesProvider.overrideWith(
          (final Ref ref, final RepoRef arg) =>
              const AsyncData<List<RepoLanguageEntry>>(<RepoLanguageEntry>[
                (name: 'Dart', size: 80),
                (name: 'C++', size: 20),
              ]),
        ),
      ],
    );
    expect(tester.takeException(), isNull);
    await tester.pump();

    expect(find.text('12 commits in the last year'), findsOneWidget);
    expect(find.text('Dart 80.0%'), findsOneWidget);
    expect(find.text('C++ 20.0%'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
