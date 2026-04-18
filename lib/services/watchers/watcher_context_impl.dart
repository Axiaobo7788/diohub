/// Persistent per-watcher key-value store.
///
/// Implementations: [AppMetaWatcherContext] (AppMetaDao), [DriftWatcherContext] (DAO).
library;

import 'dart:convert';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub_database/database/database.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/utils/json_decode_safe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _storageKey(String watcherId) => '_watcher_ctx:$watcherId';

/// [WatcherContext] implementation backed by [AppMetaDao].
/// One key per watcher; value is JSON map of key->value.
/// Prefer [DriftWatcherContext] when [WatcherDao] is available.
class AppMetaWatcherContext implements WatcherContext {
  AppMetaWatcherContext(this._watcherId, this._dao, this.apiClient);

  final String _watcherId;
  final AppMetaDao _dao;

  @override
  final WatcherApiClient apiClient;

  Future<Map<String, Object?>> _getMap() async {
    final raw = await _dao.getValue(_storageKey(_watcherId));
    if (raw == null || raw.isEmpty) return <String, Object?>{};
    try {
      final decoded = tryDecodeMap(raw, tag: 'WatcherContextImpl._getMap');
      return decoded != null ? Map<String, Object?>.from(decoded) : <String, Object?>{};
    } catch (e, st) {
      AppLogger.warning(
        'Failed to decode watcher context JSON',
        error: e,
        stackTrace: st,
        tag: 'WatcherContext',
      );
      return <String, Object?>{};
    }
  }

  Future<void> _setMap(Map<String, Object?> map) async {
    await _dao.setValue(_storageKey(_watcherId), jsonEncode(map));
  }

  @override
  Future<T?> read<T>(String key) async {
    final map = await _getMap();
    final raw = map[key];
    if (raw == null) return null;
    if (raw is! T) {
      throw StateError('WatcherContext: stored value for "$key" is ${raw.runtimeType}, expected $T');
    }
    return raw as T;
  }

  @override
  Future<void> write<T>(String key, T value) async {
    final map = await _getMap();
    map[key] = value;
    await _setMap(map);
  }

  @override
  Future<void> remove(String key) async {
    final map = await _getMap();
    map.remove(key);
    await _setMap(map);
  }

  @override
  Future<void> clear() async {
    await _dao.deleteKey(_storageKey(_watcherId));
  }
}

/// [WatcherContext] implementation backed by [WatcherDao].
/// Uses [nodeId] (e.g. watcher.watcherId) and [watcherType] (e.g. watcher key) for scoping.
class DriftWatcherContext implements WatcherContext {
  DriftWatcherContext(this._dao, this._nodeId, this._watcherType, this.apiClient);

  final WatcherDao _dao;
  final String _nodeId;
  final String _watcherType;

  @override
  final WatcherApiClient apiClient;

  @override
  Future<T?> read<T>(String key) async {
    final raw = await _dao.read(_nodeId, _watcherType, key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! T) {
      throw StateError('WatcherContext: stored value for "$key" is ${decoded.runtimeType}, expected $T');
    }
    return decoded as T;
  }

  @override
  Future<void> write<T>(String key, T value) async {
    await _dao.write(
      nodeId: _nodeId,
      watcherType: _watcherType,
      key: key,
      value: jsonEncode(value),
    );
  }

  @override
  Future<void> remove(String key) async {
    await _dao.deleteKey(_nodeId, _watcherType, key);
  }

  /// Remove all KV entries for this watcher instance.
  Future<void> clear() async {
    await _dao.deleteForWatcher(_nodeId, _watcherType);
  }
}
