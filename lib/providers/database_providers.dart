import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub_database/database/database.dart';
import 'package:diohub_models/models/authentication/authenticated_session.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/services/authentication/account_repository.dart';
import 'package:diohub/services/authentication/token_set_io.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:diohub/services/authentication/scope_gate.dart';
import 'package:diohub/services/authentication/token_refresh_service.dart';
import 'package:diohub/services/authentication/token_store.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/global_services.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in main() after DB init. Throws if read before override.
final settingsCacheProvider = Provider<SettingsCache>(
  (_) => throw StateError('settingsCacheProvider not initialized'),
);

/// Global database instance. Initialized in main() before runApp().
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final tokenStoreProvider = Provider<TokenStore>((_) => TokenStore());

/// Scope gate for checking granted OAuth/PAT scopes.
/// Used for per-feature graceful degradation when scopes are missing.
final scopeGateProvider = Provider<ScopeGate>((ref) {
  final sessionAsync = ref.watch(accountProvider);
  final session = sessionAsync.value;
  final scope = session?.activeAccountModel?.scope;
  return ScopeGate.fromScopeString(scope);
});

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(
    ref.read(databaseProvider),
    ref.read(tokenStoreProvider),
  ),
);

/// Authenticated session cache. Reads token once per account switch and
/// holds it in memory along with server config for synchronous API client access.
///
/// Eliminates per-request DB/keychain lookups. Rebuilds on account switch.
/// Returns null if no active account or token is missing.
final authenticatedSessionProvider = FutureProvider<AuthenticatedSession?>((ref) async {
  final session = await ref.watch(accountProvider.future);
  if (session == null || session.activeAccount == null) return null;
  final accountModel = session.activeAccountModel;
  if (accountModel == null) return null;
  final tokenSet = await ref.read(tokenStoreProvider).readTokenSet(
    accountModel.storageKey,
  );
  if (tokenSet?.accessToken == null || tokenSet!.accessToken!.isEmpty) return null;
  return AuthenticatedSession(
    token: tokenSet.accessToken!,
    serverConfig: accountModel.serverConfig,
    storageKey: accountModel.storageKey,
  );
});

/// HTTP API client with dependency injection.
final apiClientProvider = Provider<ApiClient>(
  (ref) {
    final authSession = ref.watch(authenticatedSessionProvider).value;
    return ApiClient(
      notifications: ref.read(notificationServiceProvider),
      tokenStore: ref.read(tokenStoreProvider),
      accountRepository: ref.read(accountRepositoryProvider),
      authenticatedSession: authSession,
      tokenRefreshService: ref.read(tokenRefreshServiceProvider),
    );
  },
);

/// Global services container.
final globalServicesProvider = Provider<GlobalServices>(
  (ref) => GlobalServices(ref.read(apiClientProvider)),
);

/// Auth repository. Composes [TokenStore] and [AccountRepository].
final authServiceProvider = Provider<AuthRepository>((ref) => AuthRepository(
      ref.read(accountRepositoryProvider),
      ref.read(tokenStoreProvider),
    ));

/// Token refresh service. Handles proactive and reactive token refresh.
final tokenRefreshServiceProvider = Provider<TokenRefreshService>(
  (ref) => TokenRefreshService(
    ref.read(tokenStoreProvider),
    onTokenRefreshed: () => ref.invalidate(authenticatedSessionProvider),
  ),
);

/// Active account key for data isolation. Format: serverId/nodeId (e.g. 'github.com/MDQ6VXNlcjEyMzQ1').
/// Used by scoped DAOs to filter all entity-store, drafts, download queries.
final activeAccountKeyProvider = Provider<String>((ref) {
  final session = ref.watch(accountProvider).value;
  final model = session?.activeAccountModel;
  if (model != null) return model.accountKey;
  return 'default';
});

/// Domain DAOs (pre-scoped by construction). Use these instead of raw db getters for account-scoped data.
final entityCacheDaoProvider = Provider<EntityCacheDao>(
    (ref) => ref.watch(databaseProvider).entityCacheDao);
final bookmarkDaoProvider = Provider<BookmarkDao>((ref) => BookmarkDao(
    ref.watch(databaseProvider), ref.watch(activeAccountKeyProvider)));
final collectionDaoProvider = Provider<CollectionDao>((ref) => CollectionDao(
    ref.watch(databaseProvider), ref.watch(activeAccountKeyProvider)));
final historyDaoProvider = Provider<HistoryDao>((ref) => HistoryDao(
    ref.watch(databaseProvider), ref.watch(activeAccountKeyProvider)));
final savedSearchDaoProvider = Provider<SavedSearchDao>((ref) => SavedSearchDao(
    ref.watch(databaseProvider), ref.watch(activeAccountKeyProvider)));
final downloadHistoryDaoProvider = Provider<DownloadHistoryDao>((ref) =>
    DownloadHistoryDao(
        ref.watch(databaseProvider), ref.watch(activeAccountKeyProvider)));
final draftsDaoProvider = Provider<DraftsDao>((ref) => DraftsDao(
    ref.watch(databaseProvider), ref.watch(activeAccountKeyProvider)));
final watcherDaoProvider = Provider<WatcherDao>((ref) => WatcherDao(
    ref.watch(databaseProvider), ref.watch(activeAccountKeyProvider)));

final settingsDaoProvider =
    Provider<SettingsDao>((ref) => ref.watch(databaseProvider).settingsDao);
final searchStateDaoProvider = Provider<SearchStateDao>(
    (ref) => ref.watch(databaseProvider).searchStateDao);
final accountsDaoProvider =
    Provider<AccountsDao>((ref) => ref.watch(databaseProvider).accountsDao);
final appMetaDaoProvider =
    Provider<AppMetaDao>((ref) => ref.watch(databaseProvider).appMetaDao);
final logDaoProvider =
    Provider<LogDao>((ref) => ref.watch(databaseProvider).logDao);
