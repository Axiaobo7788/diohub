import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'utils/json_decode_safe.dart';
import 'tables/accounts_table.dart';
import 'tables/app_meta_table.dart';
import 'tables/bookmark_entries_table.dart';
import 'tables/entity_cache_entries_table.dart';
import 'tables/repo_snapshot_entries_table.dart';
import 'tables/issue_snapshot_entries_table.dart';
import 'tables/pr_snapshot_entries_table.dart';
import 'tables/collection_entries_table.dart';
import 'tables/download_history_table.dart';
import 'tables/drafts_table.dart';
import 'tables/history_entries_table.dart';
import 'tables/log_entries_table.dart';
import 'tables/saved_search_entries_table.dart';
import 'tables/search_states_table.dart';
import 'tables/settings_table.dart';
import 'tables/watcher_states_table.dart';
import 'tables/watcher_config_entries_table.dart';

import 'package:diohub_models/models/app_config.dart';
import 'package:diohub_models/models/download/download_item.dart';

import 'enums/enums.dart';
import 'models/entity_type_snapshot.dart';
import 'utils/like_escape.dart';

part 'database.g.dart';
part 'models/result_types.dart';
part 'dao_base/entity_columns.dart';
part 'dao_base/account_dao.dart';
part 'dao_base/bookmark_lookup.dart';
part 'daos/settings_dao.dart';
part 'daos/entity_cache_dao.dart';
part 'daos/snapshot_dao.dart';
part 'daos/collection_dao.dart';
part 'daos/bookmark_dao.dart';
part 'daos/history_dao.dart';
part 'daos/saved_search_dao.dart';
part 'daos/drafts_dao.dart';
part 'daos/download_history_dao.dart';
part 'daos/watcher_dao.dart';
part 'daos/search_state_dao.dart';
part 'daos/accounts_dao.dart';
part 'daos/app_meta_dao.dart';
part 'daos/log_dao.dart';

@DriftDatabase(
  tables: [
    SettingsEntries,
    EntityCacheEntries,
    RepoSnapshotEntries,
    IssueSnapshotEntries,
    PRSnapshotEntries,
    BookmarkEntries,
    HistoryEntries,
    SavedSearchEntries,
    DraftEntries,
    DownloadHistoryEntries,
    WatcherStateEntries,
    WatcherConfigEntries,
    CollectionEntries,
    SearchStateEntries,
    AccountEntries,
    AppMetaEntries,
    LogEntries,
  ],
  daos: [
    SettingsDao,
    EntityCacheDao,
    SnapshotDao,
    CollectionDao,
    BookmarkDao,
    HistoryDao,
    SavedSearchDao,
    DraftsDao,
    DownloadHistoryDao,
    WatcherDao,
    SearchStateDao,
    AccountsDao,
    AppMetaDao,
    LogDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase._background(QueryExecutor e) : super(e);

  /// Open the same DB file from a background isolate (e.g. workmanager).
  static Future<AppDatabase> openForBackground() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'diohub.db'));
    final conn = await NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
    return AppDatabase._background(conn);
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
      );

  /// Call once in main() before runApp().
  static late final AppDatabase instance;

  static Future<void> initialize() async {
    instance = AppDatabase();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'diohub.db'));
    return NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  });
}
