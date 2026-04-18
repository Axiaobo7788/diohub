import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/app/talker_log_adapter.dart';
import 'package:diohub_database/database/database.dart';
import 'package:talker/talker.dart';

/// Persists Talker logs to Drift [log_entries] via buffered batch inserts.
class DriftLogObserver extends TalkerObserver {
  DriftLogObserver(this._dao) {
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
  }

  final LogDao _dao;

  static const int _batchSize = 50;
  static const Duration _flushInterval = Duration(seconds: 2);

  final List<LogEntriesCompanion> _buffer = [];
  late final Timer _flushTimer;
  bool _disposed = false;

  @override
  void onLog(TalkerData data) => _enqueue(data);

  @override
  void onError(TalkerError err) => _enqueue(err);

  @override
  void onException(TalkerException err) => _enqueue(err);

  void _enqueue(TalkerData data) {
    if (_disposed) return;
    final companion = TalkerLogAdapter.toCompanion(data);
    _buffer.add(companion);
    if (_buffer.length >= _batchSize) {
      flush();
    }
  }

  /// Flush the buffer to DB in a single batch. Safe to call multiple times.
  Future<void> flush() async {
    if (_buffer.isEmpty) return;
    final batch = List<LogEntriesCompanion>.of(_buffer);
    _buffer.clear();
    try {
      await _dao.insertBatch(batch);
    } catch (e, st) {
      AppLogger.warning(
        'Drift log batch insert failed',
        error: e,
        stackTrace: st,
        tag: 'DriftLogObserver',
      );
      if (_buffer.length + batch.length <= _batchSize * 10) {
        _buffer.addAll(batch);
      }
    }
  }

  /// Call when observer is being torn down (e.g., app lifecycle).
  void dispose() {
    _disposed = true;
    _flushTimer.cancel();
    flush();
  }
}
