import 'package:drift/drift.dart';

/// Key-value settings store. Replaces 17 SharedPreferences keys.
class SettingsEntries extends Table {
  /// Settings key (e.g. 'app_appearance', 'app_theme_mode').
  TextColumn get key => text()();

  /// JSON-serialized settings value.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
