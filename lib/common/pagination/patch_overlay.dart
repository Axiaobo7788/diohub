import 'package:diohub/common/pagination/item_patch.dart';

/// Manages patches with O(1) lookup by item ID or contained sub-item ID.
/// Used by [PaginationController] to apply optimistic updates at render time.
class PatchOverlay {
  final Map<String, ItemPatch> _patches = <String, ItemPatch>{};

  Map<String, ItemPatch> get all =>
      Map<String, ItemPatch>.unmodifiable(_patches);
  bool get isEmpty => _patches.isEmpty;

  void apply(ItemPatch patch) {
    _patches[patch.itemId] = patch;
  }

  void remove(String patchKey) {
    _patches.remove(patchKey);
  }

  void clear() {
    _patches.clear();
  }

  /// Replace all patches with [patches]. Used when syncing from Riverpod.
  void replaceAll(Map<String, ItemPatch> patches) {
    _patches.clear();
    _patches.addAll(patches);
  }

  /// Resolve the effective patch for a display item.
  /// Checks itemId first, then any containedIds (e.g. comment IDs inside a section).
  ItemPatch? resolve<R>(
    R item,
    String Function(R) idOf, [
    Set<String> Function(R)? containedIdsOf,
  ]) {
    final direct = _patches[idOf(item)];
    if (direct != null) return direct;
    final ids = containedIdsOf?.call(item);
    if (ids != null) {
      for (final id in ids) {
        final p = _patches[id];
        if (p != null) return p;
      }
    }
    return null;
  }

  /// Whether this item (or any of its children) is marked deleted.
  bool isDeleted<R>(
    R item,
    String Function(R) idOf, [
    Set<String> Function(R)? containedIdsOf,
  ]) {
    final p = resolve(item, idOf, containedIdsOf);
    return p is PatchDeleted;
  }
}
