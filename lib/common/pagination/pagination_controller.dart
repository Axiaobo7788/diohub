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
  final ValueNotifier<PaginationState<R>> _state =
      ValueNotifier(const PaginationState());

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
  Future<void> fetchForward() async {
    if (_disposed || _fetchingForward) return;
    final current = _state.value;
    if (!current.hasMoreForward) return;

    final myEpoch = _epoch;
    _fetchingForward = true;
    _publishState(phase: const LoadingForward());

    try {
      final slice = await source.fetchForward(pageSize);
      if (_disposed || _epoch != myEpoch) return;

      final processed = _process(slice.items);
      _appendForward(processed, slice.hasNextPage, slice.totalCount);
      _publishState(phase: const Idle());
    } catch (e, st) {
      AppLogger.error(
        'PaginationController.fetchForward failed',
        error: e,
        stackTrace: st,
        tag: 'Pagination',
      );
      if (!_disposed) {
        _publishState(phase: Failed(e, FetchDirection.forward));
      }
    } finally {
      if (!_disposed) _fetchingForward = false;
    }
  }

  /// Fetch the previous page backward. No-op if source is forward-only.
  Future<void> fetchBackward() async {
    if (_disposed || _fetchingBackward) return;
    final s = source;
    if (s is! BidirectionalSource<T>) return;
    final current = _state.value;
    if (!current.hasMoreBackward) return;

    final myEpoch = _epoch;
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
      if (!_disposed) {
        _publishState(phase: Failed(e, FetchDirection.backward));
      }
    } finally {
      if (!_disposed) _fetchingBackward = false;
    }
  }

  /// Clear and re-fetch from the beginning.
  Future<void> refresh() async {
    _epoch++;
    source.reset();
    if (source is BidirectionalSource<T>) {
      (source as BidirectionalSource<T>).resetBackward();
    }
    _items.clear();
    _syntheticTailCount = 0;
    _clearLocalPatches();

    _publishState(
        phase: const Refreshing(),
        hasMoreForward: true,
        hasMoreBackward: false);
    await fetchForward();
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
    _state.dispose();
  }

  // -------------------------------------------------------------------------
  // Internal
  // -------------------------------------------------------------------------

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
    PaginationPhase? phase,
    int? syntheticTailCount,
  }) {
    if (_disposed) return;

    final displayItems = items ?? _getDisplayItems();
    final prev = _state.value;
    final next = PaginationState<R>(
      items: displayItems,
      hasMoreForward: hasMoreForward ?? prev.hasMoreForward,
      hasMoreBackward: hasMoreBackward ?? prev.hasMoreBackward,
      anchorId: anchorId ?? prev.anchorId,
      totalCount: totalCount ?? prev.totalCount,
      phase: phase ?? prev.phase,
      syntheticTailCount: syntheticTailCount ?? _syntheticTailCount,
    );
    if (prev.phase == next.phase &&
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
