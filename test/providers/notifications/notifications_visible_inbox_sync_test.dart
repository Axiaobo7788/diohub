import 'dart:async';

import 'package:diohub/providers/notifications/notifications_inbox_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visible sync reschedules from the latest server interval', () async {
    final List<Duration> intervals = <Duration>[];
    final List<_FakeTimer> timers = <_FakeTimer>[];
    final List<Duration> recommendations = <Duration>[
      const Duration(seconds: 60),
      const Duration(seconds: 180),
    ];
    int refreshes = 0;
    final NotificationsVisibleInboxSyncCoordinator coordinator =
        NotificationsVisibleInboxSyncCoordinator(
          synchronize: () async => refreshes++,
          nextInterval: () => recommendations.removeAt(0),
          scheduleTimer:
              (final Duration duration, final void Function() callback) {
                intervals.add(duration);
                final _FakeTimer timer = _FakeTimer(callback);
                timers.add(timer);
                return timer;
              },
        )..start();

    expect(intervals, <Duration>[const Duration(seconds: 60)]);

    timers.single.fire();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(refreshes, 1);
    expect(intervals, <Duration>[
      const Duration(seconds: 60),
      const Duration(seconds: 180),
    ]);

    coordinator.dispose();
    expect(timers.last.isActive, isFalse);
  });

  test(
    'visible sync contains failures and continues on the next window',
    () async {
      final List<_FakeTimer> timers = <_FakeTimer>[];
      final List<Object> errors = <Object>[];
      int refreshes = 0;
      final NotificationsVisibleInboxSyncCoordinator coordinator =
          NotificationsVisibleInboxSyncCoordinator(
            synchronize: () async {
              refreshes++;
              throw StateError('offline');
            },
            nextInterval: () => const Duration(seconds: 60),
            onError: (final Object error, final StackTrace stackTrace) {
              errors.add(error);
            },
            scheduleTimer:
                (final Duration duration, final void Function() callback) {
                  final _FakeTimer timer = _FakeTimer(callback);
                  timers.add(timer);
                  return timer;
                },
          )..start();

      timers.single.fire();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(refreshes, 1);
      expect(errors.single, isA<StateError>());
      expect(
        timers.length,
        2,
        reason: 'a transient refresh failure must not stop convergence polling',
      );

      coordinator.dispose();
      expect(timers.last.isActive, isFalse);
    },
  );

  test('disposing during a refresh prevents another schedule', () async {
    final List<_FakeTimer> timers = <_FakeTimer>[];
    final Completer<void> refresh = Completer<void>();
    final NotificationsVisibleInboxSyncCoordinator coordinator =
        NotificationsVisibleInboxSyncCoordinator(
          synchronize: () => refresh.future,
          nextInterval: () => const Duration(seconds: 60),
          scheduleTimer:
              (final Duration duration, final void Function() callback) {
                final _FakeTimer timer = _FakeTimer(callback);
                timers.add(timer);
                return timer;
              },
        )..start();

    timers.single.fire();
    await Future<void>.delayed(Duration.zero);
    coordinator.dispose();
    refresh.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(timers.length, 1);
    expect(timers.single.isActive, isFalse);
  });

  test(
    'inactive lifecycle releases ownership and cancels future work',
    () async {
      final List<_FakeTimer> timers = <_FakeTimer>[];
      int refreshes = 0;
      int acquisitions = 0;
      int releases = 0;
      final NotificationsVisibleInboxSyncCoordinator coordinator =
          NotificationsVisibleInboxSyncCoordinator(
            synchronize: () async => refreshes++,
            nextInterval: () => const Duration(seconds: 60),
            acquireOwnership: () => acquisitions++,
            releaseOwnership: () => releases++,
            scheduleTimer:
                (final Duration duration, final void Function() callback) {
                  final _FakeTimer timer = _FakeTimer(callback);
                  timers.add(timer);
                  return timer;
                },
          );

      coordinator.setActive(active: true);
      expect(acquisitions, 1);
      expect(timers.length, 1);

      coordinator.setActive(active: false);
      expect(releases, 1);
      expect(timers.single.isActive, isFalse);
      timers.single.fire();
      await Future<void>.delayed(Duration.zero);
      expect(
        refreshes,
        0,
        reason: 'paused apps must not start a network refresh',
      );

      coordinator.setActive(active: true);
      expect(acquisitions, 2);
      expect(timers.length, 2);
      timers.last.fire();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(
        refreshes,
        1,
        reason: 'a visible route resumes after the app resumes',
      );

      coordinator.dispose();
      expect(releases, 2);
    },
  );
}

final class _FakeTimer implements Timer {
  _FakeTimer(this._callback);

  final void Function() _callback;
  bool _active = true;

  void fire() {
    if (!_active) {
      return;
    }
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _active ? 0 : 1;
}
