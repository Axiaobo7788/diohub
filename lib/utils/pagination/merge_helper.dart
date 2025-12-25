// ignore_for_file: avoid_classes_with_only_static_members

/// Helper for merging and deduplicating data
class MergeHelper {
  /// Merges items by key, combining duplicates (e.g., same repo across date chunks).
  static List<T> mergeAndDeduplicate<T, K>({
    required List<T> items,
    required K Function(T) getKey,
    required T Function(T existing, T newItem) mergeItems,
  }) {
    final itemMap = <K, T>{};

    for (final item in items) {
      final key = getKey(item);
      if (itemMap.containsKey(key)) {
        itemMap[key] = mergeItems(itemMap[key]!, item);
      } else {
        itemMap[key] = item;
      }
    }

    return itemMap.values.toList();
  }

  /// Merges multiple sorted lists using k-way merge algorithm.
  static List<T> mergeSortedLists<T>({
    required List<List<T>> sortedLists,
    required int Function(T, T) compare,
  }) {
    if (sortedLists.isEmpty) {
      return [];
    }
    if (sortedLists.length == 1) {
      return sortedLists.first;
    }

    final merged = <T>[];
    final iterators = sortedLists.map((chunk) => chunk.iterator).toList();
    final currentValues = <T?>[];

    for (final iterator in iterators) {
      if (iterator.moveNext()) {
        currentValues.add(iterator.current);
      } else {
        currentValues.add(null);
      }
    }

    while (currentValues.any((v) => v != null)) {
      T? best;
      int bestIndex = -1;

      for (var i = 0; i < currentValues.length; i++) {
        final value = currentValues[i];
        if (value != null) {
          if (best == null || compare(value, best) > 0) {
            best = value;
            bestIndex = i;
          }
        }
      }

      if (best != null && bestIndex >= 0) {
        merged.add(best);
        if (iterators[bestIndex].moveNext()) {
          currentValues[bestIndex] = iterators[bestIndex].current;
        } else {
          currentValues[bestIndex] = null;
        }
      }
    }

    return merged;
  }
}
