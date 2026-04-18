import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub_database/database/database.dart';

/// Log pruning constants. Single source of truth for retention and cap.
const Duration logRetentionDuration = Duration(days: 7);
const int logMaxEntries = 10000;

const Duration _pruneInterval = Duration(hours: 6);

/// Manages periodic log pruning. Prunes once immediately on creation,
/// then every [_pruneInterval] while alive.
class LogPruneScheduler {
  LogPruneScheduler(this._dao) {
    _prune();
    _timer = Timer.periodic(_pruneInterval, (_) => _prune());
  }

  final LogDao _dao;
  late final Timer _timer;
  bool _pruning = false;

  Future<void> _prune() async {
    if (_pruning) return;
    _pruning = true;
    try {
      await _dao.deleteOlderThan(logRetentionDuration);
      final count = await _dao.countAll();
      if (count > logMaxEntries) {
        await _dao.deleteOldest(count - logMaxEntries);
      }
    } catch (e, st) {
      AppLogger.warning(
        'Log pruning failed (non-fatal)',
        error: e,
        stackTrace: st,
        tag: 'LogPruneScheduler',
      );
    } finally {
      _pruning = false;
    }
  }

  /// Force an immediate prune (e.g., from settings "Clear Logs" action).
  Future<void> pruneNow() => _prune();

  void dispose() {
    _timer.cancel();
  }
}
