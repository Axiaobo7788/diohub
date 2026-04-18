part of '../database.dart';

/// Keys: iap_max_tier, active_account, theme_mode.
@DriftAccessor(tables: [AppMetaEntries])
class AppMetaDao extends DatabaseAccessor<AppDatabase> with _$AppMetaDaoMixin {
  AppMetaDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(appMetaEntries)..where((a) => a.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) =>
      into(appMetaEntries).insertOnConflictUpdate(AppMetaEntriesCompanion(
        key: Value(key),
        value: Value(value),
      ));

  Future<void> deleteKey(String key) =>
      (delete(appMetaEntries)..where((a) => a.key.equals(key))).go();

  // ── IAP max tier ────────────────────────────────────────────────────────

  static const String _keyIapMaxTier = 'iap_max_tier';

  Future<AppConfig> getIapMaxTier() async {
    final raw = await getValue(_keyIapMaxTier);
    return switch (raw) {
      'pro' || 'proGit' => AppConfig.pro,
      _ => AppConfig.free,
    };
  }

  Future<void> setIapMaxTier(AppConfig tier) async {
    final raw = switch (tier) {
      AppConfig.free => 'free',
      AppConfig.pro => 'pro',
    };
    await setValue(_keyIapMaxTier, raw);
  }

  // ── Pro purchase date ───────────────────────────────────────────────────────

  static const String _keyProPurchaseDate = 'pro_purchase_date';

  Future<DateTime?> getProPurchaseDate() async {
    final raw = await getValue(_keyProPurchaseDate);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> setProPurchaseDate(DateTime date) async {
    await setValue(_keyProPurchaseDate, date.toIso8601String());
  }

  // ── Active account (username) ─────────────────────────────────────────────

  static const String _keyActiveAccount = 'active_account';

  Future<String?> getActiveAccount() async {
    final raw = await getValue(_keyActiveAccount);
    return raw == null || raw.isEmpty ? null : raw;
  }

  Future<void> setActiveAccount(String username) =>
      setValue(_keyActiveAccount, username);

  Future<void> clearActiveAccount() => setValue(_keyActiveAccount, '');

  // ── Legacy: active account key (serverId/nodeId) for scoped DAOs ─────────

  static const String _activeAccountKey = 'activeAccountKey';

  Future<void> setActiveAccountKey(String accountKey) =>
      setValue(_activeAccountKey, accountKey);

  Future<String?> getActiveAccountKey() => getValue(_activeAccountKey);
}
