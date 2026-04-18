import 'package:diohub/app/log_pruning.dart';
import 'package:diohub_database/database/database.dart';
import 'package:diohub_database/database/enums/enums.dart';
import 'package:diohub/common/logging/structured_log_entry.dart';
import 'package:diohub/providers/logging/log_filter.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:diohub/providers/notifier_update_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _LogFilterNotifier extends Notifier<LogFilter> {
  @override
  LogFilter build() => const LogFilter();
}

final logFilterProvider =
    NotifierProvider<_LogFilterNotifier, LogFilter>(_LogFilterNotifier.new);

/// Notifier for the log viewer search field. Updates [logFilterProvider].searchQuery when changed.
final logSearchQueryNotifierProvider = Provider<ValueNotifier<String>>((ref) {
  final notifier = ValueNotifier<String>('');
  notifier.addListener(() {
    ref.read(logFilterProvider.notifier).update((f) => f.copyWith(
        searchQuery: notifier.value.isEmpty ? null : notifier.value));
  });
  return notifier;
});

/// Converts a Drift [LogEntry] to [StructuredLogEntry].
StructuredLogEntry structuredFromEntry(LogEntry e) {
  return StructuredLogEntry(
    id: e.id,
    level: e.level,
    message: e.message,
    tag: e.tag,
    entityPath: e.entityPath,
    entityType: e.entityType,
    parentPath: e.parentPath,
    httpMethod: e.httpMethod,
    httpPath: e.httpPath,
    httpStatusCode: e.httpStatusCode,
    responseTimeMs: e.responseTimeMs,
    errorMessage: e.errorMessage,
    stackTrace: e.stackTrace,
    detailJson: e.detailJson,
    createdAt: e.createdAt,
  );
}

/// Filtered logs for the global log viewer. Respects [logFilterProvider].
final filteredLogsStreamProvider =
    StreamProvider.autoDispose<List<StructuredLogEntry>>((ref) {
  final dao = ref.watch(logDaoProvider);
  final filter = ref.watch(logFilterProvider);
  final accountKey = ref.watch(activeAccountKeyProvider);

  return dao
      .watchFiltered(
        level: filter.effectiveLevel,
        tag: filter.tag,
        entityPath: filter.entityPath,
        entityType: filter.entityType,
        httpStatusCode: filter.httpStatusCode,
        searchQuery: filter.searchQuery,
        since: filter.timeRange?.since,
        bookmarkedOnly: filter.bookmarkedOnly,
        bookmarkedOnlyAccountKey: filter.bookmarkedOnly ? accountKey : null,
        limit: logViewerLimit,
      )
      .map((entries) => entries.map(structuredFromEntry).toList());
});

/// Logs scoped to a single entity (for entity detail screens).
final entityLogsProvider = StreamProvider.autoDispose
    .family<List<StructuredLogEntry>, String>((ref, entityPath) {
  final dao = ref.watch(logDaoProvider);
  return dao
      .watchFiltered(entityPath: entityPath, limit: 200)
      .map((entries) => entries.map(structuredFromEntry).toList());
});

/// Recent error count (last 24h) for the logs tab badge.
final recentErrorCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final dao = ref.watch(logDaoProvider);
  return dao.countRecentErrors(window: const Duration(hours: 24));
});

/// Log prune scheduler. Read at startup (e.g. in main or root widget) so it runs
/// and is disposed with the Riverpod container.
final logPruneSchedulerProvider = Provider<LogPruneScheduler>((ref) {
  final dao = ref.watch(logDaoProvider);
  final scheduler = LogPruneScheduler(dao);
  ref.onDispose(scheduler.dispose);
  return scheduler;
});
