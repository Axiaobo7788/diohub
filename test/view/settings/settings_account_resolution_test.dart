import 'dart:async';

import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/dashboard/home_top_repositories_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/settings/settings_screen.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsScreen account resolution', () {
    for (final ({Size size, String windowClass}) scenario
        in <({Size size, String windowClass})>[
          (size: const Size(360, 800), windowClass: 'compact'),
          (size: const Size(800, 900), windowClass: 'medium'),
          (size: const Size(1440, 960), windowClass: 'expanded'),
        ]) {
      testWidgets('keeps account initialization distinct from signed out at '
          '${scenario.size.width.toInt()}px', (
        final WidgetTester tester,
      ) async {
        await _pumpSettingsScreen(
          tester,
          size: scenario.size,
          accountOverride: accountProvider.overrideWith(
            _PendingAccountNotifier.new,
          ),
        );

        expect(
          find.byKey(ValueKey<String>('settings-md3-${scenario.windowClass}')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('settings-account-loading')),
          findsOneWidget,
        );
        expect(find.text(_signedOutDescription), findsNothing);
        expect(
          find.byKey(const ValueKey<String>('settings-general-page')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders confirmed signed out settings at '
          '${scenario.size.width.toInt()}px', (
        final WidgetTester tester,
      ) async {
        await _pumpSettingsScreen(
          tester,
          size: scenario.size,
          accountOverride: accountProvider.overrideWith(
            _SignedOutAccountNotifier.new,
          ),
        );

        expect(find.text(_signedOutDescription), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('settings-general-page')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('settings-account-loading')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders the resolved account context at '
          '${scenario.size.width.toInt()}px', (
        final WidgetTester tester,
      ) async {
        final AccountModel account = _settingsAccount();
        await _pumpSettingsScreen(
          tester,
          size: scenario.size,
          accountOverride: accountProvider.overrideWith(
            () => _ResolvedAccountNotifier(
              AccountSession(
                accounts: <AccountModel>[account],
                activeAccount: account.username,
              ),
            ),
          ),
        );

        expect(find.text('The Octocat (octocat)'), findsOneWidget);
        expect(find.text(_signedOutDescription), findsNothing);
        expect(
          find.byKey(
            ValueKey<String>(
              'settings-switch-context-'
              '${scenario.windowClass == 'compact' ? 'compact' : 'wide'}',
            ),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('account load failure is retryable and never renders guest', (
      final WidgetTester tester,
    ) async {
      int builds = 0;
      await _pumpSettingsScreen(
        tester,
        size: const Size(800, 900),
        accountOverride: accountProvider.overrideWith(
          () => _ErrorAccountNotifier(() => builds++),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('settings-account-error')),
        findsOneWidget,
      );
      expect(
        find.text('Could not read the local account state.'),
        findsWidgets,
      );
      expect(find.text(_signedOutDescription), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('settings-general-page')),
        findsNothing,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byTooltip('Sign in'), findsNothing);
      expect(builds, 1);

      await tester.tap(
        find.byKey(const ValueKey<String>('settings-account-retry')),
      );
      await tester.pump();
      await tester.pump();
      expect(builds, 2);
      expect(tester.takeException(), isNull);
    });
  });
}

const String _signedOutDescription =
    'DioHub preferences remain available without a GitHub account.';

Future<void> _pumpSettingsScreen(
  final WidgetTester tester, {
  required final Size size,
  required final Override accountOverride,
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
        accountOverride,
        settingsCacheProvider.overrideWithValue(
          SettingsCache(<String, String>{}),
        ),
        currentUserProvider.overrideWithBuild((final _, final _) async => null),
        homeTopRepositoriesProvider.overrideWith(
          (final Ref _, final _) async => const <HomeRepositoryItem>[],
        ),
        userProvider.overrideWith2(_PendingUserProfileNotifier.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

AccountModel _settingsAccount() => AccountModel(
  nodeId: 'U_octocat',
  username: 'octocat',
  displayName: 'The Octocat',
  addedAt: DateTime.utc(2026),
);

final class _PendingAccountNotifier extends AccountNotifier {
  @override
  Future<AccountSession?> build() => Completer<AccountSession?>().future;
}

final class _SignedOutAccountNotifier extends AccountNotifier {
  @override
  Future<AccountSession?> build() async => null;
}

final class _ResolvedAccountNotifier extends AccountNotifier {
  _ResolvedAccountNotifier(this.session);

  final AccountSession? session;

  @override
  Future<AccountSession?> build() async => session;
}

final class _ErrorAccountNotifier extends AccountNotifier {
  _ErrorAccountNotifier(this.onBuild);

  final VoidCallback onBuild;

  @override
  Future<AccountSession?> build() async {
    onBuild();
    throw StateError('Could not read local account state');
  }
}

final class _PendingUserProfileNotifier extends UserProfileNotifier {
  _PendingUserProfileNotifier(super.userRef);

  @override
  Future<UserProfileData> build() => Completer<UserProfileData>().future;
}
