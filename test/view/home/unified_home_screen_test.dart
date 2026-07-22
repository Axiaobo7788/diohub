import 'package:diohub/view/home/unified_home_screen.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHome(
    final WidgetTester tester, {
    required final Size size,
    final AccountModel? account,
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
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: UnifiedHomeScreen(
            account: account,
            activityFeedSliver: account == null
                ? null
                : const SliverToBoxAdapter(
                    child: ListTile(title: Text('Activity item')),
                  ),
            onSignIn: () async {},
            onSignOut: () async {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the shared public home without overflow at 360px', (
    final WidgetTester tester,
  ) async {
    await pumpHome(tester, size: const Size(360, 800));

    expect(find.text('DioHub'), findsOneWidget);
    expect(find.text('Explore GitHub'), findsOneWidget);
    expect(find.text('Browsing without an account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the same compact home after sign-in at 360px', (
    final WidgetTester tester,
  ) async {
    final AccountModel account = AccountModel(
      nodeId: 'MDQ6VXNlcjE=',
      username: 'octocat',
      displayName: 'The Octocat',
      addedAt: DateTime.utc(2026),
    );

    await pumpHome(tester, size: const Size(360, 800), account: account);

    expect(find.text('DioHub'), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Following & watched'), findsOneWidget);
    expect(find.text('Activity item'), findsOneWidget);
    expect(find.text('@octocat'), findsOneWidget);
    expect(find.text('Browsing without an account'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the compact structure at 800px', (
    final WidgetTester tester,
  ) async {
    await pumpHome(tester, size: const Size(800, 900));

    expect(find.text('DioHub'), findsOneWidget);
    expect(find.text('Explore GitHub'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders desktop master-detail placeholder at 1440px', (
    final WidgetTester tester,
  ) async {
    await pumpHome(tester, size: const Size(1440, 900));

    expect(find.text('Explore GitHub'), findsOneWidget);
    expect(find.text('Select a repository'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders authenticated activity in the desktop main pane', (
    final WidgetTester tester,
  ) async {
    final AccountModel account = AccountModel(
      nodeId: 'MDQ6VXNlcjE=',
      username: 'octocat',
      addedAt: DateTime.utc(2026),
    );

    await pumpHome(tester, size: const Size(1440, 900), account: account);

    expect(find.text('Explore GitHub'), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Activity item'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
