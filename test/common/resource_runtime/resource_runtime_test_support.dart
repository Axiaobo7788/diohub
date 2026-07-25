import 'dart:async';

import 'package:diohub/common/resource_runtime/resource_runtime.dart';

final class ManualResourceClock implements ResourceClock {
  ManualResourceClock([DateTime? initial])
    : _now = initial ?? DateTime.utc(2026, 1, 1);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(final Duration duration) {
    _now = _now.add(duration);
  }
}

final class ControlledResourceLoader<T> {
  final List<Completer<ResourceLoadResult<T>>> _calls =
      <Completer<ResourceLoadResult<T>>>[];
  final List<_CallWaiter> _waiters = <_CallWaiter>[];

  int get callCount => _calls.length;

  Future<ResourceLoadResult<T>> call(final ResourceLoadContext _) {
    final Completer<ResourceLoadResult<T>> completer =
        Completer<ResourceLoadResult<T>>();
    _calls.add(completer);
    _notifyWaiters();
    return completer.future;
  }

  Future<void> waitForCalls(final int count) {
    if (callCount >= count) return Future<void>.value();
    final Completer<void> completer = Completer<void>();
    _waiters.add(_CallWaiter(count, completer));
    return completer.future;
  }

  void succeed(
    final int index,
    final T data, {
    final ResourceOrigin origin = ResourceOrigin.network,
    final int? estimatedWeight,
  }) {
    _calls[index].complete(
      ResourceLoadResult<T>(
        data: data,
        origin: origin,
        estimatedWeight: estimatedWeight,
      ),
    );
  }

  void fail(final int index, final Object error) {
    _calls[index].completeError(error, StackTrace.current);
  }

  void _notifyWaiters() {
    for (final _CallWaiter waiter in _waiters.toList()) {
      if (callCount >= waiter.count) {
        _waiters.remove(waiter);
        waiter.completer.complete();
      }
    }
  }
}

final class _CallWaiter {
  const _CallWaiter(this.count, this.completer);

  final int count;
  final Completer<void> completer;
}

ResourceSpec<T> testResourceSpec<T>({
  required final String key,
  required final Future<ResourceLoadResult<T>> Function(ResourceLoadContext)
  load,
  final ResourceScope scope = const ResourceScope(
    serverId: 'github.com',
    principal: 'account-1',
  ),
  final Duration freshFor = const Duration(minutes: 5),
  final Duration retainFor = const Duration(minutes: 5),
  final int weight = 1,
  final bool allowPrefetch = true,
  final String contract = 'test-loader-v1',
  final Set<ResourceTag>? tags,
  final ResourceWorkKind workKind = ResourceWorkKind.network,
  final Set<ResourceId<dynamic>> dependencies = const <ResourceId<dynamic>>{},
}) => ResourceSpec<T>(
  id: ResourceId<T>(kind: 'test-resource', version: 1, scope: scope, key: key),
  policy: ResourcePolicy(
    freshFor: freshFor,
    retainFor: retainFor,
    estimatedWeight: weight,
    allowPrefetch: allowPrefetch,
  ),
  tags: tags ?? <ResourceTag>{const ResourceTag('test', 'resource')},
  load: load,
  contract: contract,
  workKind: workKind,
  dependencies: dependencies,
);

Future<ResourceData<T>> waitForData<T>(final ResourceLease<T> lease) async {
  final ResourceSnapshot<T> current = lease.value;
  if (current is ResourceData<T> && !current.isRefreshing) return current;
  final ResourceSnapshot<T> next = await lease.changes.firstWhere(
    (final ResourceSnapshot<T> snapshot) =>
        snapshot is ResourceData<T> && !snapshot.isRefreshing,
  );
  return next as ResourceData<T>;
}

Future<ResourceFailure<T>> waitForFailure<T>(
  final ResourceLease<T> lease,
) async {
  final ResourceSnapshot<T> current = lease.value;
  if (current is ResourceFailure<T>) return current;
  final ResourceSnapshot<T> next = await lease.changes.firstWhere(
    (final ResourceSnapshot<T> snapshot) => snapshot is ResourceFailure<T>,
  );
  return next as ResourceFailure<T>;
}

Future<ResourceData<T>> waitForRefreshError<T>(
  final ResourceLease<T> lease,
) async {
  final ResourceSnapshot<T> current = lease.value;
  if (current is ResourceData<T> &&
      !current.isRefreshing &&
      current.lastRefreshError != null) {
    return current;
  }
  final ResourceSnapshot<T> next = await lease.changes.firstWhere(
    (final ResourceSnapshot<T> snapshot) =>
        snapshot is ResourceData<T> &&
        !snapshot.isRefreshing &&
        snapshot.lastRefreshError != null,
  );
  return next as ResourceData<T>;
}
