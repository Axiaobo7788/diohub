import 'dart:async';

import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';

/// Immutable page value retained by [ResourceRuntime].
///
/// [K] is an explicit page identity rather than hidden mutable cursor state.
/// It can represent a GraphQL cursor, REST page number, or another stable
/// continuation token.
final class PaginatedResourcePage<T, K> {
  const PaginatedResourcePage({
    required this.items,
    required this.hasNextPage,
    this.nextPageKey,
    this.totalCount,
  }) : assert(
         !hasNextPage || nextPageKey != null,
         'A page with more data must provide its next page key.',
       );

  final List<T> items;
  final bool hasNextPage;
  final K? nextPageKey;
  final int? totalCount;
}

typedef RuntimePageResourceSpecFactory<T, K> =
    ResourceSpec<PaginatedResourcePage<T, K>> Function({
      required K pageKey,
      required int pageSize,
    });

/// Forward pagination source backed by immutable Runtime page resources.
///
/// The surrounding [PaginationController] still owns query-session state,
/// ordering, refresh intent, and its current flattened items. This source owns
/// only the continuation key and bridges each page load into Runtime
/// Single Flight, freshness, scheduling, retention, and invalidation.
final class RuntimeForwardPageSource<T, K> extends ForwardSource<T>
    implements ForwardPageReplacementSource<T> {
  RuntimeForwardPageSource({
    required this.runtime,
    required this.firstPageKey,
    required this.specFactory,
    required this.refreshSelector,
  }) : _nextPageKey = firstPageKey;

  final ResourceRuntime runtime;
  final K firstPageKey;
  final RuntimePageResourceSpecFactory<T, K> specFactory;
  final ResourceSelector refreshSelector;

  K _nextPageKey;
  bool _hasNextPage = true;
  bool _forceRefresh = false;
  bool _disposed = false;
  int _generation = 0;
  Future<void>? _backgroundRefresh;
  final StreamController<ForwardPageReplacement<T>> _pageReplacements =
      StreamController<ForwardPageReplacement<T>>.broadcast(sync: true);

  @override
  Stream<ForwardPageReplacement<T>> get pageReplacements =>
      _pageReplacements.stream;

  @override
  Future<PageSlice<T>> fetchForward(final int count) async {
    final Future<void>? backgroundRefresh = _backgroundRefresh;
    if (backgroundRefresh != null) {
      await backgroundRefresh;
    }
    if (_disposed) {
      return PageSlice<T>(items: <T>[], hasNextPage: false);
    }
    if (!_hasNextPage) {
      return PageSlice<T>(items: <T>[], hasNextPage: false);
    }

    final K pageKey = _nextPageKey;
    final ResourceSpec<PaginatedResourcePage<T, K>> spec = specFactory(
      pageKey: pageKey,
      pageSize: count,
    );
    final bool forceRefresh = _forceRefresh;
    final ResourceLease<PaginatedResourcePage<T, K>> lease = runtime.acquire(
      spec,
      presence: ResourcePresence.retained,
    );
    bool releaseLease = true;
    try {
      final ResourceSnapshot<PaginatedResourcePage<T, K>> initial = lease.value;
      if (!forceRefresh &&
          initial is ResourceData<PaginatedResourcePage<T, K>> &&
          initial.freshness == ResourceFreshness.stale) {
        final PaginatedResourcePage<T, K> stalePage = initial.data;
        _acceptPage(stalePage);
        lease.setPresence(ResourcePresence.visible);
        releaseLease = false;
        final int generation = _generation;
        final Future<void> refresh = _revalidateStalePage(
          lease: lease,
          pageKey: pageKey,
          stalePage: stalePage,
          generation: generation,
        );
        _backgroundRefresh = refresh;
        unawaited(
          refresh.whenComplete(() {
            if (identical(_backgroundRefresh, refresh)) {
              _backgroundRefresh = null;
            }
          }),
        );
        return _slice(stalePage);
      }
      final ResourceData<PaginatedResourcePage<T, K>> settled;
      if (!forceRefresh &&
          initial is ResourceData<PaginatedResourcePage<T, K>> &&
          initial.freshness == ResourceFreshness.fresh &&
          !initial.isRefreshing) {
        settled = initial;
      } else {
        lease.setPresence(ResourcePresence.visible);
        if (forceRefresh ||
            initial is ResourceData<PaginatedResourcePage<T, K>>) {
          await lease.refresh();
        }
        settled = await _waitForSettledData(lease);
      }

      if (forceRefresh && settled.lastRefreshError != null) {
        Error.throwWithStackTrace(
          settled.lastRefreshError!,
          StackTrace.current,
        );
      }

      final PaginatedResourcePage<T, K> page = settled.data;
      _acceptPage(page);
      _forceRefresh = false;
      return _slice(page);
    } finally {
      if (releaseLease) {
        lease.release();
      }
    }
  }

  @override
  void reset() {
    _generation += 1;
    runtime.invalidate(refreshSelector);
    _nextPageKey = firstPageKey;
    _hasNextPage = true;
    _forceRefresh = true;
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _generation += 1;
    unawaited(_pageReplacements.close());
  }

  Future<void> _revalidateStalePage({
    required final ResourceLease<PaginatedResourcePage<T, K>> lease,
    required final K pageKey,
    required final PaginatedResourcePage<T, K> stalePage,
    required final int generation,
  }) async {
    try {
      final ResourceData<PaginatedResourcePage<T, K>> refreshed =
          await _waitForSettledData(lease);
      if (_disposed ||
          generation != _generation ||
          refreshed.lastRefreshError != null) {
        return;
      }
      final PaginatedResourcePage<T, K> page = refreshed.data;
      if (pageKey == firstPageKey) {
        _acceptPage(page);
        _pageReplacements.add(
          ForwardPageReplacement<T>(
            previous: _slice(stalePage),
            replacement: _slice(page),
          ),
        );
      }
    } catch (_) {
      // Runtime preserves stale data and records refresh failure telemetry.
      // A background refresh must not turn an already delivered page into an
      // unhandled asynchronous error.
    } finally {
      lease.release();
    }
  }

  void _acceptPage(final PaginatedResourcePage<T, K> page) {
    _hasNextPage = page.hasNextPage;
    if (page.hasNextPage) {
      _nextPageKey = page.nextPageKey as K;
    }
  }

  PageSlice<T> _slice(final PaginatedResourcePage<T, K> page) => PageSlice<T>(
    items: page.items,
    hasNextPage: page.hasNextPage,
    totalCount: page.totalCount,
  );
}

Future<ResourceData<T>> _waitForSettledData<T>(
  final ResourceLease<T> lease,
) async {
  final ResourceSnapshot<T> current = lease.value;
  switch (current) {
    case ResourceData<T>() when !current.isRefreshing:
      return current;
    case ResourceFailure<T>(:final error, :final stackTrace):
      Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
    case ResourceLoading<T>() || ResourceData<T>():
      break;
  }

  final ResourceSnapshot<T> settled = await lease.changes.firstWhere(
    (final ResourceSnapshot<T> snapshot) =>
        snapshot is ResourceFailure<T> ||
        snapshot is ResourceData<T> && !snapshot.isRefreshing,
  );
  return switch (settled) {
    final ResourceData<T> data => data,
    ResourceFailure<T>(:final error, :final stackTrace) =>
      Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
    ResourceLoading<T>() => throw StateError(
      'Resource page settled without data or failure',
    ),
  };
}
