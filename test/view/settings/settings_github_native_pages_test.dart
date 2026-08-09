import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/models/users/email_item.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/users/viewer_settings_session_provider.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/services/users/viewer_settings_service.dart';
import 'package:diohub/view/settings/md3/settings_github_access_pages.dart';
import 'package:diohub/view/settings/md3/settings_github_email_page.dart';
import 'package:diohub/view/settings/md3/settings_github_keys_page.dart';
import 'package:diohub_graphql/queries/users/user_repositories_list.graphql.dart'
    show Query$getUserRepositories$user$repositories$pageInfo;
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_models/models/users/gpg_key_item.dart';
import 'package:diohub_models/models/users/ssh_key_item.dart';
import 'package:diohub_models/models/users/ssh_signing_key_item.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final Size size in <Size>[
    const Size(360, 800),
    const Size(800, 900),
    const Size(1440, 960),
  ]) {
    testWidgets(
      'native email settings render real data at ${size.width.toInt()}px',
      (final WidgetTester tester) async {
        final _EmailPageHarness harness = await _pumpEmailPage(
          tester,
          size: size,
        );

        expect(find.text('octocat@example.com'), findsOneWidget);
        expect(find.text('Primary'), findsOneWidget);
        expect(find.text('Verified'), findsOneWidget);
        expect(harness.service.listCalls, 1);
        expect(tester.takeException(), isNull);

        if (size.width == 360) {
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
          expect(harness.service.visibility, 'public');
          expect(harness.service.listCalls, 2);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  for (final ({
        String name,
        String expected,
        Widget Function(AccountModel account) builder,
      })
      scenario
      in <
        ({
          String name,
          String expected,
          Widget Function(AccountModel account) builder,
        })
      >[
        (
          name: 'keys',
          expected: 'SSH and GPG keys',
          builder: (final AccountModel account) =>
              SettingsGitHubKeysPage(account: account),
        ),
        (
          name: 'organizations',
          expected: 'No organizations',
          builder: (final AccountModel account) =>
              SettingsGitHubOrganizationsPage(account: account),
        ),
        (
          name: 'moderation',
          expected: 'No blocked users',
          builder: (final AccountModel account) =>
              SettingsGitHubModerationPage(account: account),
        ),
        (
          name: 'repositories',
          expected: 'No repositories',
          builder: (final AccountModel account) =>
              SettingsGitHubRepositoriesPage(account: account),
        ),
      ]) {
    testWidgets('native ${scenario.name} settings expose a real empty state', (
      final WidgetTester tester,
    ) async {
      await _pumpNativeSettingsPage(
        tester,
        size: const Size(360, 800),
        builder: scenario.builder,
      );

      expect(find.text(scenario.expected), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

final class _EmailPageHarness {
  const _EmailPageHarness({required this.service});

  final _EmailSettingsService service;
}

Future<_EmailPageHarness> _pumpEmailPage(
  final WidgetTester tester, {
  required final Size size,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(() {
    tester.view
      ..resetDevicePixelRatio()
      ..resetPhysicalSize();
  });

  final AccountModel account = _account();
  final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
  final _EmailSettingsService service = _EmailSettingsService();
  final ViewerSettingsSession session = ViewerSettingsSession(
    runtime: runtime,
    scope: resourceScopeForAccount(account),
    login: account.username,
    viewerSettingsService: service,
    userInfoService: _UnusedUserInfoService(),
  );
  addTearDown(() {
    session.dispose();
    runtime.dispose();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        viewerSettingsSessionProvider.overrideWith(
          (final Ref ref, final ViewerSettingsSessionKey key) => session,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SettingsGitHubEmailPage(account: account),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _EmailPageHarness(service: service);
}

Future<void> _pumpNativeSettingsPage(
  final WidgetTester tester, {
  required final Size size,
  required final Widget Function(AccountModel account) builder,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(() {
    tester.view
      ..resetDevicePixelRatio()
      ..resetPhysicalSize();
  });

  final AccountModel account = _account();
  final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
  final ViewerSettingsSession session = ViewerSettingsSession(
    runtime: runtime,
    scope: resourceScopeForAccount(account),
    login: account.username,
    viewerSettingsService: _EmailSettingsService(),
    userInfoService: _UnusedUserInfoService(),
  );
  addTearDown(() {
    session.dispose();
    runtime.dispose();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        viewerSettingsSessionProvider.overrideWith(
          (final Ref ref, final ViewerSettingsSessionKey key) => session,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: builder(account),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AccountModel _account() => AccountModel(
  nodeId: 'U_octocat',
  username: 'octocat',
  displayName: 'The Octocat',
  addedAt: DateTime.utc(2026),
);

final class _EmailSettingsService implements ViewerSettingsService {
  int listCalls = 0;
  String visibility = 'private';

  @override
  Future<PaginatedResult<EmailItem>> listEmails({
    final int page = 1,
    final int perPage = 30,
  }) async {
    listCalls++;
    return PaginatedResult<EmailItem>(
      items: <EmailItem>[
        EmailItem(
          email: 'octocat@example.com',
          primary: true,
          verified: true,
          visibility: visibility,
        ),
      ],
      hasNextPage: false,
    );
  }

  @override
  Future<void> setEmailVisibility(final String visibility) async {
    this.visibility = visibility;
  }

  @override
  Future<PaginatedResult<SSHKeyItem>> listSSHKeys({
    final int page = 1,
    final int perPage = 30,
  }) async => const PaginatedResult<SSHKeyItem>(
    items: <SSHKeyItem>[],
    hasNextPage: false,
  );

  @override
  Future<PaginatedResult<GpgKeyItem>> listGPGKeys({
    final int page = 1,
    final int perPage = 30,
  }) async => const PaginatedResult<GpgKeyItem>(
    items: <GpgKeyItem>[],
    hasNextPage: false,
  );

  @override
  Future<PaginatedResult<SSHSigningKeyItem>> listSSHSigningKeys({
    final int page = 1,
    final int perPage = 30,
  }) async => const PaginatedResult<SSHSigningKeyItem>(
    items: <SSHSigningKeyItem>[],
    hasNextPage: false,
  );

  @override
  Future<PaginatedResult<SimpleUser>> listBlockedUsers({
    final int page = 1,
    final int perPage = 30,
  }) async => const PaginatedResult<SimpleUser>(
    items: <SimpleUser>[],
    hasNextPage: false,
  );

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}

final class _UnusedUserInfoService implements UserInfoService {
  @override
  Future<PaginatedResult<UserOrgEdge?>> getUserOrganizationsPage(
    final String login, {
    final bool refresh = false,
    final String? after,
    final int first = UserInfoService.profileListPageSize,
  }) async => const PaginatedResult<UserOrgEdge?>(
    items: <UserOrgEdge?>[],
    hasNextPage: false,
  );

  @override
  Future<UserRepositories> getUserRepositories(
    final String user,
    final int first, {
    final bool refresh = false,
    final String? after,
    final dynamic orderField,
    final dynamic orderDirection,
    final dynamic visibility,
  }) async => UserRepositories(
    edges: const <UserRepoEdge?>[],
    pageInfo: Query$getUserRepositories$user$repositories$pageInfo(
      hasNextPage: false,
    ),
  );

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}
