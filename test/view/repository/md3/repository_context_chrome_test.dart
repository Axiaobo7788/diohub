import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/view/repository/md3/repository_context_chrome.dart';
import 'package:diohub/view/repository/md3/repository_navigation.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpChrome(
    final WidgetTester tester, {
    required final Size size,
    final RepositoryNavigationDestination selectedDestination =
        RepositoryNavigationDestination.issues,
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
          accountProvider.overrideWith(_SignedOutAccountNotifier.new),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true),
          home: RepositoryContextChrome(
            repoRef: const RepoRef(owner: 'octocat', name: 'hello-world'),
            selectedDestination: selectedDestination,
            onRefresh: () {},
            body: const SizedBox.expand(key: ValueKey<String>('detail-body')),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  for (final Size size in <Size>[
    const Size(360, 800),
    const Size(800, 900),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'repository detail chrome stays shared at ${size.width.toInt()}px',
      (final WidgetTester tester) async {
        await pumpChrome(tester, size: size);

        expect(
          find.byKey(const ValueKey<String>('global-header')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('repository-primary-navigation')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('detail-body')),
          findsOneWidget,
        );
        expect(find.text('Wiki'), findsOneWidget);
        expect(
          DefaultTabController.of(
            tester.element(
              find.byKey(
                const ValueKey<String>('repository-primary-navigation'),
              ),
            ),
          ).index,
          RepositoryNavigationDestination.issues.index,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('completed repository tabs can be selected in shared chrome', (
    final WidgetTester tester,
  ) async {
    await pumpChrome(
      tester,
      size: const Size(800, 900),
      selectedDestination: RepositoryNavigationDestination.actions,
    );

    final TabController controller = DefaultTabController.of(
      tester.element(
        find.byKey(const ValueKey<String>('repository-primary-navigation')),
      ),
    );
    expect(controller.index, RepositoryNavigationDestination.actions.index);
    expect(find.text('Actions is not migrated yet'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final class _SignedOutAccountNotifier extends AccountNotifier {
  @override
  Future<AccountSession?> build() async => null;
}
