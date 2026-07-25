import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/common/pagination/patch_overlay.dart';
import 'package:diohub/common/pagination/page_size.dart';
import 'package:flutter/foundation.dart';

/// Unified controller for forward-only and bidirectional paginated lists.
///
/// Uses a [PageSource] (cursor or page-number) and optional [transform]/[filter]
/// for processing. Patches are applied at render time via [PatchOverlay].
class PaginationController<T, R> {
  PaginationController({
    required this.source,
    required this.idOf,
    this.transform,
    this.filter,
    this.boundaryMerger,
    this.containedIdsOf,
    this.pageSize = kDefaultPageSize,
    this.getPatches,
    bool autoFetch = true,
  }) {
    final PageSource<T> currentSource = source;
    if (currentSource is ForwardPageReplacementSource<T>) {
      _sourceReplacementSubscription =
          (currentSource as ForwardPageReplacementSource<T>).pageReplacements
              .listen(_handleSourceReplacement);
    }
    if (autoFetch) {
      Future.microtask(fetchForward);
    }
  }

  final PageSource<T> source;
  final String Function(R) idOf;
  final List<R> Function(List<T> raw)? transform;
  final List<R> Function(List<R> items)? filter;
  final R? Function(R previousLast, R nextFirst)? boundaryMerger;
  final Set<String> Function(R)? containedIdsOf;
  final int pageSize;

  /// When set, patches are read from this callback (single source of truth).
  /// [syncPatches] is then a no-op; use the Riverpod notifier to update patches.
  final Map<String, ItemPatch> Function()? getPatches;

  int _epoch = 0;

  ValueListenable<PaginationState<R>> get state => _state;
  final ValueNotifier<PaginationState<R>> _state = ValueNotifier(
    const PaginationState(),
  );

  final List<R> _items = [];
  int _syntheticTailCount = 0;
  PatchOverlay? _patches;

  PatchOverlay get _overlay {
    if (getPatches != null) {
      final overlay = PatchOverlay();
      overlay.replaceAll(getPatches!());
      return overlay;
    }
    _patches ??= PatchOverlay();
    return _patches!;
  }

  void _clearLocalPatches() {
    if (getPatches == null) {
      _patches ??= PatchOverlay();
      _patches!.clear();
    }
  }

  bool _disposed = false;
  bool _fetchingForward = false;
  bool _fetchingBackward = false;
  Completer<void>? _forwardDone;
  Completer<void>? _backwardDone;
  int _refreshSerial = 0;
  Completer<void>? _refreshCompleter;
  bool _lastForwardFailureWasRefresh = false;
  bool _lastRefreshRetainedItems = true;
  StreamSubscription<ForwardPageReplacement<T>>? _sourceReplacementSubscription;
  ForwardPageReplacement<T>? _pendingSourceReplacement;

  List<R> _process(List<T> raw) {
    final transformed = transform != null ? transform!(raw) : raw as List<R>;
    return filter != null ? filter!(transformed) : transformed;
  }

  /// Re-apply [filter] to current items without refetching. Call when filter
  /// criteria change (e.g. search query). Only has effect when [filter] is non-null.
  void refilter() {
    if (_disposed || filter == null) return;
    _publishState();
  }

  /// Fetch the next page forward. No-op if already loading or no more data.
  Future<void> fetchForward() => _fetchForward();

  Future<void> _fetchForward({final bool fromRefresh = false}) async {
    if (_disposed) return;
    final refresh = _refreshCompleter;
    if (!fromRefresh && refresh != null) {
      await refresh.future;
      return;
    }
    if (_fetchingForward) {
      await _forwardDone?.future;
      return;
    }
    final current = _state.value;
    if (!fromRefresh && !current.hasMoreForward) return;

    final myEpoch = _epoch;
    final done = Completer<void>();
    _forwardDone = done;
    _fetchingForward = true;
    _publishState(
      phase: fromRefresh ? const Refreshing() : const LoadingForward(),
    );

    try {
      final slice = await source.fetchForward(pageSize);
      if (_disposed || _epoch != myEpoch) return;

      final processed = _process(slice.items);
      if (fromRefresh) {
        _replaceFromRefresh(processed, slice.hasNextPage, slice.totalCount);
      } else {
        _appendForward(processed, slice.hasNextPage, slice.totalCount);
      }
      _lastForwardFailureWasRefresh = false;
      _publishState(phase: const Idle());
      _applyPendingSourceReplacement();
    } catch (e, st) {
      AppLogger.error(
        'PaginationController.fetchForward failed',
        error: e,
        stackTrace: st,
        tag: 'Pagination',
      );
      if (!_disposed && _epoch == myEpoch) {
        _lastForwardFailureWasRefresh = fromRefresh;
        _publishState(phase: Failed(e, FetchDirection.forward));
      }
    } finally {
      if (identical(_forwardDone, done)) {
        _fetchingForward = false;
        _forwardDone = null;
      }
      if (!done.isCompleted) {
        done.complete();
      }
    }
  }

  /// Fetch the previous page backward. No-op if source is forward-only.
  Future<void> fetchBackward() => _fetchBackward();

  Future<void> _fetchBackward() async {
    if (_disposed) return;
    final refresh = _refreshCompleter;
    if (refresh != null) {
      await refresh.future;
      return;
    }
    if (_fetchingBackward) {
      await _backwardDone?.future;
      return;
    }
    final s = source;
    if (s is! BidirectionalSource<T>) return;
    final current = _state.value;
    if (!current.hasMoreBackward) return;

    final myEpoch = _epoch;
    final done = Completer<void>();
    _backwardDone = done;
    _fetchingBackward = true;
    _publishState(phase: const LoadingBackward());

    try {
      final slice = await s.fetchBackward(pageSize);
      if (_disposed || _epoch != myEpoch) return;

      final processed = _process(slice.items);
      _prependBackward(processed, slice.hasNextPage, slice.totalCount);
      _publishState(phase: const Idle());
    } catch (e, st) {
      AppLogger.error(
        'PaginationController.fetchBackward failed',
        error: e,
        stackTrace: st,
        tag: 'Pagination',
      );
      if (!_disposed && _epoch == myEpoch) {
        _publishState(phase: Failed(e, FetchDirection.backward));
      }
    } finally {
      if (identical(_backwardDone, done)) {
        _fetchingBackward = false;
        _backwardDone = null;
      }
      if (!done.isCompleted) {
        done.complete();
      }
    }
  }

  /// Re-fetch from the beginning.
  ///
  /// By default, committed content remains visible until a successful first
  /// page atomically replaces it. Pass [retainItems] as false when the query or
  /// result type changes, because results for the previous scope must not be
  /// shown under the new controls.
  ///
  /// A refresh invalidates any in-flight page immediately, but waits for that
  /// request to settle before resetting the source. This matters for cursor
  /// sources: their request may update an internal cursor after its future
  /// completes, so resetting earlier would let a stale response overwrite the
  /// reset cursor.
  ///
  /// Repeated refresh calls share one operation. If another refresh arrives
  /// while the replacement first page is loading, that response is discarded
  /// and the loop performs one final reset/fetch for the newest request.
  Future<void> refresh({final bool retainItems = true}) {
    if (_disposed) {
      return Future<void>.value();
    }

    _epoch++;
    _refreshSerial++;
    _lastRefreshRetainedItems = retainItems;
    if (!retainItems) {
      _items.clear();
      _syntheticTailCount = 0;
      _clearLocalPatches();
    }
    _publishState(
      phase: const Refreshing(),
      hasMoreForward: true,
      hasMoreBackward: retainItems ? null : false,
      clearTotalCount: !retainItems,
      syntheticTailCount: retainItems ? null : 0,
    );

    final existing = _refreshCompleter;
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<void>();
    _refreshCompleter = completer;
    unawaited(_runRefreshLoop(completer));
    return completer.future;
  }

  /// Retry the last forward operation without confusing a failed refresh with
  /// an ordinary next-page request.
  Future<void> retryForward() {
    return _lastForwardFailureWasRefresh
        ? refresh(retainItems: _lastRefreshRetainedItems)
        : fetchForward();
  }

  /// Find item index by id, or resolve via anchor if source is bidirectional.
  Future<int?> navigateToItem(String itemId) async {
    final index = findItem(itemId);
    if (index != null) return index;
    final s = source;
    if (s is BidirectionalSource<T>) {
      await navigateToAnchor(itemId);
      return findItem(itemId);
    }
    return null;
  }

  /// Re-anchor to the page containing [itemId]. Full reset.
  Future<void> navigateToAnchor(String itemId) async {
    final s = source;
    if (s is! BidirectionalSource<T>) return;

    _epoch++;
    source.reset();
    s.resetBackward();
    _items.clear();
    _syntheticTailCount = 0;
    _clearLocalPatches();
    _publishState(phase: const Refreshing());

    try {
      final result = await s.resolveAnchor(itemId);
      if (_disposed) return;

      final processed = _process(result.items);
      _items.addAll(processed);
      _publishState(
        anchorId: itemId,
        hasMoreForward: result.hasMoreForward,
        hasMoreBackward: result.hasMoreBackward,
        totalCount: result.totalCount,
        phase: const Idle(),
      );
    } catch (e, st) {
      AppLogger.error(
        'PaginationController.navigateToAnchor failed for $itemId',
        error: e,
        stackTrace: st,
        tag: 'Pagination',
      );
      if (!_disposed) {
        _publishState(phase: Failed(e, FetchDirection.forward));
      }
    }
  }

  /// Clear and re-fetch from the end. Used when user posts a comment mid-timeline.
  Future<void> jumpToLatest({R? synthetic}) async {
    _epoch++;
    source.reset();
    if (source is BidirectionalSource<T>) {
      (source as BidirectionalSource<T>).resetBackward();
    }
    _items.clear();
    _syntheticTailCount = 0;
    _overlay.clear();

    final s = source;
    if (s is BidirectionalSource<T>) {
      _publishState(
        phase: const Refreshing(),
        hasMoreForward: false,
        hasMoreBackward: true,
      );

      final myEpoch = _epoch;
      try {
        final slice = await s.fetchBackward(pageSize);
        if (_disposed || _epoch != myEpoch) return;

        final processed = _process(slice.items);
        _items.addAll(processed);

        if (synthetic != null &&
            !_items.any((i) => idOf(i) == idOf(synthetic))) {
          _items.add(synthetic);
          _syntheticTailCount = 1;
        }

        _publishState(
          hasMoreForward: false,
          hasMoreBackward: slice.hasNextPage,
          phase: const Idle(),
        );
      } catch (e, st) {
        AppLogger.error(
          'PaginationController.jumpToLatest failed',
          error: e,
          stackTrace: st,
          tag: 'Pagination',
        );
        if (!_disposed) {
          _publishState(phase: Failed(e, FetchDirection.backward));
        }
      }
    } else {
      await refresh();
      if (synthetic != null) appendSynthetic(synthetic);
    }
  }

  void appendSynthetic(R item) {
    _items.add(item);
    _syntheticTailCount++;
    _publishState();
  }

  void removeSynthetic(String itemId) {
    final index = _items.lastIndexWhere((i) => idOf(i) == itemId);
    if (index >= 0) {
      _items.removeAt(index);
      if (_syntheticTailCount > 0) _syntheticTailCount--;
      _publishState();
    }
  }

  void applyPatch(ItemPatch patch) {
    if (getPatches == null) {
      _patches ??= PatchOverlay();
      _patches!.apply(patch);
    }
    _publishState();
  }

  void removePatch(String patchKey) {
    if (getPatches == null) {
      _patches ??= PatchOverlay();
      _patches!.remove(patchKey);
    }
    _publishState();
  }

  void clearPatches() {
    _clearLocalPatches();
    _publishState();
  }

  /// Replace all patches (e.g. from Riverpod). When [getPatches] is set,
  /// patches are the single source of truth so this is a no-op; otherwise
  /// updates local overlay and notifies.
  void syncPatches(Map<String, ItemPatch> patches) {
    if (getPatches != null) return;
    _patches ??= PatchOverlay();
    _patches!.replaceAll(patches);
    _publishState();
  }

  /// When using [getPatches], call this when the notifier updates so display items re-read patches.
  void notifyPatchesChanged() {
    if (getPatches != null) _publishState();
  }

  /// Index of the item with [itemId], or null if not loaded.
  int? findItem(String itemId) {
    for (var i = 0; i < _items.length; i++) {
      if (idOf(_items[i]) == itemId) return i;
      final ids = containedIdsOf?.call(_items[i]);
      if (ids != null && ids.contains(itemId)) return i;
    }
    return null;
  }

  void dispose() {
    _disposed = true;
    unawaited(_sourceReplacementSubscription?.cancel());
    source.dispose();
    final refreshCompleter = _refreshCompleter;
    if (refreshCompleter != null && !refreshCompleter.isCompleted) {
      refreshCompleter.complete();
    }
    _state.dispose();
  }

  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

  void _handleSourceReplacement(final ForwardPageReplacement<T> update) {
    if (_disposed) {
      return;
    }
    if (_fetchingForward || _refreshCompleter != null) {
      _pendingSourceReplacement = update;
      return;
    }
    _applySourceReplacement(update);
  }

  void _applyPendingSourceReplacement() {
    final ForwardPageReplacement<T>? pending = _pendingSourceReplacement;
    if (pending == null || _fetchingBackward || _refreshCompleter != null) {
      return;
    }
    _pendingSourceReplacement = null;
    _applySourceReplacement(pending);
  }

  void _applySourceReplacement(final ForwardPageReplacement<T> update) {
    final List<R> previousItems = _process(update.previous.items);
    final List<R> replacementItems = _process(update.replacement.items);

    // Runtime currently emits only first-page replacements. Apply it
    // atomically only while the controller still represents exactly that
    // stale page; if the user already paged, the refreshed Runtime value is
    // retained for the next query session instead of risking page overlap.
    if (_items.length != previousItems.length ||
        !_itemsIdsEqual(_items, previousItems)) {
      return;
    }
    _items
      ..clear()
      ..addAll(replacementItems);
    _clearLocalPatches();
    _publishState(
      hasMoreForward: update.replacement.hasNextPage,
      totalCount: update.replacement.totalCount,
      clearTotalCount: true,
      force: true,
    );
  }

  Future<void> _runRefreshLoop(final Completer<void> completer) async {
    try {
      while (!_disposed) {
        final requestedSerial = _refreshSerial;
        await _waitForInFlightPageRequests();
        if (_disposed) return;

        // Several calls made while the old request was settling coalesce into
        // the latest serial and therefore only require one source reset.
        if (requestedSerial != _refreshSerial) {
          continue;
        }

        source.reset();
        final s = source;
        if (s is BidirectionalSource<T>) {
          s.resetBackward();
        }

        await _fetchForward(fromRefresh: true);
        if (requestedSerial == _refreshSerial) {
          return;
        }
      }
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> _waitForInFlightPageRequests() async {
    final requests = <Future<void>>[
      if (_forwardDone case final forward?) forward.future,
      if (_backwardDone case final backward?) backward.future,
    ];
    if (requests.isNotEmpty) {
      await Future.wait(requests);
    }
  }

  void _appendForward(List<R> newItems, bool hasMore, int? totalCount) {
    if (newItems.isEmpty) {
      _publishState(hasMoreForward: hasMore, totalCount: totalCount);
      return;
    }

    final insertIndex = _syntheticTailCount > 0
        ? _items.length - _syntheticTailCount
        : _items.length;

    if (insertIndex > 0 && _items.isNotEmpty && boundaryMerger != null) {
      final last = _items[insertIndex - 1];
      final merged = boundaryMerger!(last, newItems.first);
      if (merged != null) {
        _items[insertIndex - 1] = merged;
        _items.insertAll(insertIndex, newItems.sublist(1));
      } else {
        _items.insertAll(insertIndex, newItems);
      }
    } else {
      _items.insertAll(insertIndex, newItems);
    }

    _publishState(
      hasMoreForward: hasMore,
      totalCount: totalCount ?? _state.value.totalCount,
    );
  }

  void _replaceFromRefresh(
    final List<R> newItems,
    final bool hasMore,
    final int? totalCount,
  ) {
    _items
      ..clear()
      ..addAll(newItems);
    _syntheticTailCount = 0;
    _clearLocalPatches();
    _publishState(
      hasMoreForward: hasMore,
      hasMoreBackward: false,
      totalCount: totalCount,
      clearTotalCount: true,
      syntheticTailCount: 0,
    );
  }

  void _prependBackward(List<R> newItems, bool hasMore, int? totalCount) {
    if (newItems.isEmpty) {
      _publishState(hasMoreBackward: hasMore, totalCount: totalCount);
      return;
    }

    if (_items.isNotEmpty && boundaryMerger != null) {
      final merged = boundaryMerger!(newItems.last, _items.first);
      if (merged != null) {
        _items[0] = merged;
        _items.insertAll(0, newItems.sublist(0, newItems.length - 1));
      } else {
        _items.insertAll(0, newItems);
      }
    } else {
      _items.insertAll(0, newItems);
    }

    _publishState(
      hasMoreBackward: hasMore,
      totalCount: totalCount ?? _state.value.totalCount,
    );
  }

  List<R> _getBaseItems() {
    return filter != null ? filter!(List<R>.from(_items)) : _items;
  }

  List<R> _applyPatches(List<R> baseItems) {
    final result = <R>[];
    final patches = _patches;
    if (patches == null) return baseItems;
    for (final item in baseItems) {
      if (patches.isDeleted(item, idOf, containedIdsOf)) continue;
      final patch = patches.resolve(item, idOf, containedIdsOf);
      final resolved = switch (patch) {
        PatchReplaced<R>(:final replacement) => replacement,
        PatchTransformed<R>(:final transform) => transform(item),
        _ => item,
      };
      result.add(resolved);
    }
    return result;
  }

  List<R> _getDisplayItems() {
    final base = _getBaseItems();
    if (_patches?.isEmpty ?? true) return base;
    return _applyPatches(base);
  }

  void _publishState({
    List<R>? items,
    bool? hasMoreForward,
    bool? hasMoreBackward,
    String? anchorId,
    int? totalCount,
    bool clearTotalCount = false,
    PaginationPhase? phase,
    int? syntheticTailCount,
    bool force = false,
  }) {
    if (_disposed) return;

    final displayItems = items ?? _getDisplayItems();
    final prev = _state.value;
    final next = PaginationState<R>(
      items: displayItems,
      hasMoreForward: hasMoreForward ?? prev.hasMoreForward,
      hasMoreBackward: hasMoreBackward ?? prev.hasMoreBackward,
      anchorId: anchorId ?? prev.anchorId,
      totalCount: clearTotalCount ? totalCount : totalCount ?? prev.totalCount,
      phase: phase ?? prev.phase,
      syntheticTailCount: syntheticTailCount ?? _syntheticTailCount,
    );
    if (!force &&
        prev.phase == next.phase &&
        prev.hasMoreForward == next.hasMoreForward &&
        prev.hasMoreBackward == next.hasMoreBackward &&
        prev.anchorId == next.anchorId &&
        prev.totalCount == next.totalCount &&
        prev.syntheticTailCount == next.syntheticTailCount &&
        prev.items.length == next.items.length &&
        (identical(prev.items, next.items) ||
            _itemsIdsEqual(prev.items, next.items))) {
      return;
    }
    _state.value = next;
  }

  bool _itemsIdsEqual(List<R> a, List<R> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (idOf(a[i]) != idOf(b[i])) return false;
    }
    return true;
  }
}
