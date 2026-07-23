import 'dart:async';

import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/view/repository/repository_screen.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<({int repositoryBuilds, int cardBuilds})> pumpRepository(
    final WidgetTester tester, {
    required final Override accountOverride,
    required final RepoRef repoRef,
  }) async {
    var repositoryBuilds = 0;
    var cardBuilds = 0;
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
        repoCardProvider.overrideWith((final Ref ref, final RepoRef arg) {
          cardBuilds++;
          return Completer<RepoCardData>().future;
        }),
      ],
    );
    addTearDown(container.dispose);
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
          home: RepositoryScreen(repo: repoRef),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    return (repositoryBuilds: repositoryBuilds, cardBuilds: cardBuilds);
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
      expect(tester.takeException(), isNull);
    },
  );
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
