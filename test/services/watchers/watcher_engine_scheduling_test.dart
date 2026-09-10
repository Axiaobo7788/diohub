import 'dart:async';

import 'package:dio/dio.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';
import 'package:diohub/services/watchers/watcher_engine.dart';
import 'package:diohub/services/watchers/watcher_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'a suppressed watcher is not scheduled until ownership returns',
    () async {
      int checks = 0;
      final _CountingWatcher watcher = _CountingWatcher(() => checks++);
      final WatcherEngine engine = WatcherEngine(
        dispatcher: (final List<AlertPayload> _) async {},
        contextFactory: (final WatcherDefinition _) => _FakeWatcherContext(),
      );
      addTearDown(engine.dispose);

      engine
        ..register(watcher)
        ..suppressScheduling(watcher.watcherId)
        ..start();
      await Future<void>.delayed(Duration.zero);

      expect(checks, 0);

      engine.resumeScheduling(watcher.watcherId);
      expect(
        checks,
        0,
        reason: 'handoff must not immediately duplicate the visible fetch',
      );
      await Future<void>.delayed(const Duration(milliseconds: 12));

      expect(checks, greaterThan(0));
    },
  );

  test(
    'dispose drops an in-flight result without touching closed state',
    () async {
      final Completer<void> started = Completer<void>();
      final Completer<CheckResult> result = Completer<CheckResult>();
      int dispatchedAlerts = 0;
      final _PendingWatcher watcher = _PendingWatcher(started, result);
      final WatcherEngine engine = WatcherEngine(
        dispatcher: (final List<AlertPayload> alerts) async {
          dispatchedAlerts += alerts.length;
        },
        contextFactory: (final WatcherDefinition _) => _FakeWatcherContext(),
      );

      engine.register(watcher);
      final Future<void> check = engine.checkNow(watcher.watcherId);
      await started.future;
      await engine.dispose();
      result.complete(
        CheckFired(<AlertPayload>[
          AlertPayload(
            id: 'late-alert',
            title: 'Late alert',
            watcherKey: watcher.key,
            body: 'Must be discarded after teardown',
          ),
        ]),
      );

      await expectLater(check, completes);
      expect(dispatchedAlerts, 0);
    },
  );
}

final class _PendingWatcher extends WatcherDefinition {
  const _PendingWatcher(this._started, this._result)
    : super(interval: const Duration(minutes: 1));

  final Completer<void> _started;
  final Completer<CheckResult> _result;

  @override
  String get displayName => 'Pending watcher';

  @override
  String get instanceId => 'default';

  @override
  String get key => 'pending';

  @override
  Future<CheckResult> check(final WatcherContext ctx) {
    if (!_started.isCompleted) _started.complete();
    return _result.future;
  }
}

final class _CountingWatcher extends WatcherDefinition {
  const _CountingWatcher(this._onCheck)
    : super(interval: const Duration(milliseconds: 5));

  final void Function() _onCheck;

  @override
  String get displayName => 'Counting watcher';

  @override
  String get instanceId => 'default';

  @override
  String get key => 'counting';

  @override
  Future<CheckResult> check(final WatcherContext ctx) async {
    _onCheck();
    return const CheckIdle();
  }
}

final class _FakeWatcherContext implements WatcherContext {
  final Map<String, Object?> _values = <String, Object?>{};

  @override
  WatcherApiClient get apiClient => _FakeWatcherApiClient();

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<void> remove(final String key) async => _values.remove(key);

  @override
  Future<T?> read<T>(final String key) async => _values[key] as T?;

  @override
  Future<void> write<T>(final String key, final T value) async {
    _values[key] = value;
  }
}

final class _FakeWatcherApiClient implements WatcherApiClient {
  @override
  Future<Response<dynamic>> get(
    final String path, {
    final Map<String, dynamic>? queryParameters,
  }) => throw UnimplementedError();
}
