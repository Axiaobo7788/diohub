part of '../database.dart';

@DriftAccessor(tables: [SettingsEntries])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Load all settings into memory. Called once at startup.
  Future<Map<String, String>> getAll() async {
    final rows = await select(settingsEntries).get();
    return {for (final row in rows) row.key: row.value};
  }

  Future<String?> getValue(String key) async {
    final row = await (select(settingsEntries)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchValue(String key) =>
      (select(settingsEntries)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Future<void> setValue(String key, String value) =>
      into(settingsEntries).insertOnConflictUpdate(SettingsEntriesCompanion(
        key: Value(key),
        value: Value(value),
      ));

  Future<void> deleteKey(String key) =>
      (delete(settingsEntries)..where((s) => s.key.equals(key))).go();

  Future<void> deleteAll() => delete(settingsEntries).go();

  static const String _keyShowThinkingBlocks = 'show_thinking_blocks';
  static const String _keyLensToolSource = 'lens_tool_source';
  static const String _githubModelsCatalogKey = 'github_models_catalog';
  static const String _discoveredModelsKey = 'discovered_models_cache';

  Future<List<Map<String, dynamic>>?> getGitHubModelsCatalog() async {
    final json = await getValue(_githubModelsCatalogKey);
    if (json == null) return null;
    final list = tryDecodeList(json, tag: 'SettingsDao.getGitHubModelsCatalog');
    return list?.cast<Map<String, dynamic>>();
  }

  Future<void> setGitHubModelsCatalog(
      List<Map<String, dynamic>> entries) async {
    await setValue(_githubModelsCatalogKey, jsonEncode(entries));
  }

  Future<Map<String, dynamic>?> getDiscoveredModelsCache() async {
    final json = await getValue(_discoveredModelsKey);
    if (json == null) return null;
    return tryDecodeMap(json, tag: 'SettingsDao.getDiscoveredModelsCache');
  }

  Future<void> setDiscoveredModelsCache(Map<String, dynamic> cache) async {
    await setValue(_discoveredModelsKey, jsonEncode(cache));
  }

  Future<bool> getShowThinkingBlocks() async =>
      (await getValue(_keyShowThinkingBlocks)) != 'false';

  Future<void> updateShowThinkingBlocks(bool value) =>
      setValue(_keyShowThinkingBlocks, value.toString());

  /// Get lens tool source preference ('native' or 'githubMcp').
  /// Returns null if not set (defaults to 'native' in provider).
  Future<String?> getLensToolSource() async =>
      await getValue(_keyLensToolSource);

  /// Set lens tool source preference.
  Future<void> setLensToolSource(String value) =>
      setValue(_keyLensToolSource, value);
}
