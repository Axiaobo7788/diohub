import 'dart:async';
import 'dart:collection';

import 'resource_models.dart';

final class ResourceSchedulerConfig {
  const ResourceSchedulerConfig({
    this.maxConcurrent = 4,
    this.reservedInteractive = 1,
  }) : assert(maxConcurrent > 0),
       assert(reservedInteractive >= 0),
       assert(reservedInteractive < maxConcurrent);

  final int maxConcurrent;
  final int reservedInteractive;
}

final class ResourceTaskCanceled implements Exception {
  const ResourceTaskCanceled();

  @override
  String toString() => 'Queued resource task was canceled';
}

/// Independent scheduling-lane budgets coordinated by one ResourceRuntime.
///
/// These schedulers only control admission and priority. A compute task runs on
/// the caller isolate unless its loader explicitly uses
/// [ResourceLoadContext.runInWorker].
final class ResourceExecutorPool {
  ResourceExecutorPool({
    final ResourceScheduler? network,
    final ResourceScheduler? compute,
    final ResourceScheduler? decode,
  }) : _schedulers = <ResourceWorkKind, ResourceScheduler>{
         ResourceWorkKind.network:
             network ??
             ResourceScheduler(
               config: const ResourceSchedulerConfig(
                 maxConcurrent: 4,
                 reservedInteractive: 1,
               ),
             ),
         ResourceWorkKind.compute:
             compute ??
             ResourceScheduler(
               config: const ResourceSchedulerConfig(
                 maxConcurrent: 2,
                 reservedInteractive: 1,
               ),
             ),
         ResourceWorkKind.decode:
             decode ??
             ResourceScheduler(
               config: const ResourceSchedulerConfig(
                 maxConcurrent: 2,
                 reservedInteractive: 1,
               ),
             ),
       };

  final Map<ResourceWorkKind, ResourceScheduler> _schedulers;

  ResourceScheduler operator [](final ResourceWorkKind kind) =>
      _schedulers[kind]!;

  int cancelQueuedPrefetches() => _schedulers.values.fold<int>(
    0,
    (final int total, final ResourceScheduler scheduler) =>
        total + scheduler.cancelQueuedPrefetches(),
  );

  void dispose() {
    for (final ResourceScheduler scheduler in _schedulers.values) {
      scheduler.dispose();
    }
  }
}

abstract interface class ScheduledResourceTask<T> {
  Future<T> get result;
  ResourcePriority get priority;
  bool get hasStarted;

  bool promote(ResourcePriority priority);
  bool cancel();
}

/// Central three-priority scheduler with interactive capacity reservation.
final class ResourceScheduler {
  ResourceScheduler({this.config = const ResourceSchedulerConfig()});

  final ResourceSchedulerConfig config;
  final ListQueue<_QueuedResourceTask<dynamic>> _queue =
      ListQueue<_QueuedResourceTask<dynamic>>();
  int _sequence = 0;
  int _active = 0;
  int _activeNonInteractive = 0;
  bool _drainScheduled = false;
  bool _disposed = false;

  ScheduledResourceTask<T> schedule<T>({
    required final ResourcePriority priority,
    required final Future<T> Function() operation,
  }) {
    if (_disposed) {
      throw StateError('ResourceScheduler is disposed');
    }
    final _QueuedResourceTask<T> task = _QueuedResourceTask<T>(
      owner: this,
      priority: priority,
      sequence: _sequence++,
      operation: operation,
    );
    _queue.add(task);
    _scheduleDrain();
    return task;
  }

  int cancelQueuedPrefetches() {
    final List<_QueuedResourceTask<dynamic>> candidates = _queue
        .where(
          (final _QueuedResourceTask<dynamic> task) =>
              task.priority == ResourcePriority.prefetch && !task.hasStarted,
        )
        .toList();
    for (final _QueuedResourceTask<dynamic> task in candidates) {
      task.cancel();
    }
    return candidates.length;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final _QueuedResourceTask<dynamic> task in _queue.toList()) {
      task.cancel();
    }
  }

  bool _promote(
    final _QueuedResourceTask<dynamic> task,
    final ResourcePriority priority,
  ) {
    if (task.hasStarted || task._completed || !_queue.contains(task)) {
      return false;
    }
    if (_rank(priority) >= _rank(task.priority)) return false;
    task._priority = priority;
    _scheduleDrain();
    return true;
  }

  bool _cancel(final _QueuedResourceTask<dynamic> task) {
    if (task.hasStarted || task._completed || !_queue.remove(task)) {
      return false;
    }
    task._completeCanceled();
    return true;
  }

  void _scheduleDrain() {
    if (_drainScheduled || _disposed) return;
    _drainScheduled = true;
    scheduleMicrotask(() {
      _drainScheduled = false;
      _drain();
    });
  }

  void _drain() {
    if (_disposed || _queue.isEmpty) return;
    final List<_QueuedResourceTask<dynamic>> ordered = _queue.toList()
      ..sort((
        final _QueuedResourceTask<dynamic> a,
        final _QueuedResourceTask<dynamic> b,
      ) {
        final int priority = _rank(a.priority).compareTo(_rank(b.priority));
        return priority != 0 ? priority : a.sequence.compareTo(b.sequence);
      });

    bool startedAny = false;
    for (final _QueuedResourceTask<dynamic> task in ordered) {
      if (!_canStart(task.priority)) continue;
      _queue.remove(task);
      _start(task);
      startedAny = true;
    }
    if (startedAny && _queue.isNotEmpty) {
      _scheduleDrain();
    }
  }

  bool _canStart(final ResourcePriority priority) {
    if (_active >= config.maxConcurrent) return false;
    if (priority == ResourcePriority.interactive) return true;
    final int nonInteractiveLimit =
        config.maxConcurrent - config.reservedInteractive;
    return _activeNonInteractive < nonInteractiveLimit;
  }

  void _start(final _QueuedResourceTask<dynamic> task) {
    _active++;
    if (task.priority != ResourcePriority.interactive) {
      _activeNonInteractive++;
    }
    task._started = true;
    final ResourcePriority startedPriority = task.priority;
    Future<dynamic>.sync(
      task.operation,
    ).then(task._complete, onError: task._completeError).whenComplete(() {
      _active--;
      if (startedPriority != ResourcePriority.interactive) {
        _activeNonInteractive--;
      }
      _scheduleDrain();
    });
  }

  static int _rank(final ResourcePriority priority) => switch (priority) {
    ResourcePriority.interactive => 0,
    ResourcePriority.refresh => 1,
    ResourcePriority.prefetch => 2,
  };
}

final class _QueuedResourceTask<T> implements ScheduledResourceTask<T> {
  _QueuedResourceTask({
    required this.owner,
    required ResourcePriority priority,
    required this.sequence,
    required this.operation,
  }) : _priority = priority;

  final ResourceScheduler owner;
  ResourcePriority _priority;
  final int sequence;
  final Future<T> Function() operation;
  final Completer<T> _completer = Completer<T>();
  bool _started = false;
  bool _completed = false;

  @override
  Future<T> get result => _completer.future;

  @override
  ResourcePriority get priority => _priority;

  @override
  bool get hasStarted => _started;

  @override
  bool promote(final ResourcePriority priority) =>
      owner._promote(this, priority);

  @override
  bool cancel() => owner._cancel(this);

  void _complete(final dynamic value) {
    if (_completed) return;
    _completed = true;
    _completer.complete(value as T);
  }

  void _completeError(final Object error, final StackTrace stackTrace) {
    if (_completed) return;
    _completed = true;
    _completer.completeError(error, stackTrace);
  }

  void _completeCanceled() {
    if (_completed) return;
    _completed = true;
    _completer.completeError(const ResourceTaskCanceled(), StackTrace.current);
  }
}
