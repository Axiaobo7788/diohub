// ignore_for_file: avoid_classes_with_only_static_members

/// Helper for merging and deduplicating data
class MergeHelper {
  /// Merge and deduplicate items by key
  ///
  /// **Why this pattern?**
  /// - When using date splitting, same repos appear in multiple chunks
  /// - Need to combine data from same repo across different time periods
  /// - Example: Repo "my-project" appears in Q1 and Q2 chunks
  /// - We merge their contributions instead of having duplicate repos
  ///
  /// **How it works:**
  /// 1. Use a Map to track unique items by key (e.g., repo URL)
  /// 2. If key exists, merge the items (combine contributions)
  /// 3. If key is new, add it to the map
  /// 4. Return deduplicated list
  ///
  /// **Why Map instead of List with contains check?**
  /// - Map provides fast lookup by key
  /// - Much faster for large datasets (50+ repos)
  /// - Map is the standard pattern for deduplication
  ///
  /// [items] - List of items to merge (may contain duplicates)
  /// [getKey] - Function to extract unique key (e.g., repo URL)
  /// [mergeItems] - Function to merge two items with same key
  static List<T> mergeAndDeduplicate<T, K>({
    required List<T> items,
    required K Function(T) getKey,
    required T Function(T existing, T newItem) mergeItems,
  }) {
    // Use Map for O(1) lookup performance
    final itemMap = <K, T>{};

    for (final item in items) {
      final key = getKey(item);
      if (itemMap.containsKey(key)) {
        // Item already exists - merge it with existing data
        // This handles cases where same repo appears in multiple date chunks
        itemMap[key] = mergeItems(itemMap[key]!, item);
      } else {
        // New item - add it to the map
        itemMap[key] = item;
      }
    }

    // Convert map values back to list (now deduplicated)
    return itemMap.values.toList();
  }

  /// Merge multiple sorted lists into one sorted list
  ///
  /// **Why k-way merge algorithm?**
  /// - More efficient than concatenating and sorting
  /// - Each list is already sorted, so we just need to merge them
  /// - Uses iterators to avoid creating intermediate lists
  /// - Processes items one at a time without loading everything into memory
  ///
  /// **How it works:**
  /// 1. Create iterators for each sorted list
  /// 2. Keep track of "current" item from each list
  /// 3. Find the "best" current item (newest for events)
  /// 4. Add it to result and advance that iterator
  /// 5. Repeat until all lists are exhausted
  ///
  /// **Why compare function?**
  /// - Different use cases need different sorting (newest first, oldest first, etc.)
  /// - For timeline events: compare(a, b) => b.date.compareTo(a.date) (newest first)
  /// - Generic enough to work with any comparable type
  ///
  /// **Why this approach?**
  /// - More efficient than concatenating all lists and sorting again
  /// - Only stores current item from each list (low memory usage)
  /// - Works well even with many chunks or large datasets
  ///
  /// [sortedLists] - List of sorted lists to merge (each list must be sorted)
  /// [compare] - Comparison function (returns >0 if first should come before second)
  static List<T> mergeSortedLists<T>({
    required List<List<T>> sortedLists,
    required int Function(T, T) compare,
  }) {
    // Early returns for edge cases
    if (sortedLists.isEmpty) {
      return [];
    }
    if (sortedLists.length == 1) {
      return sortedLists.first;
    }

    final merged = <T>[];
    // Create iterators for each list to avoid index management
    final iterators = sortedLists.map((chunk) => chunk.iterator).toList();
    // Track current item from each list (null means that list is exhausted)
    final currentValues = <T?>[];

    // Initialize: get first item from each list
    for (final iterator in iterators) {
      if (iterator.moveNext()) {
        currentValues.add(iterator.current);
      } else {
        currentValues.add(null);
      }
    }

    // K-way merge: repeatedly find best item and add to result
    while (currentValues.any((v) => v != null)) {
      T? best;
      int bestIndex = -1;

      // Find the "best" item across all current values
      // "Best" depends on compare function (newest date, smallest number, etc.)
      for (var i = 0; i < currentValues.length; i++) {
        final value = currentValues[i];
        if (value != null) {
          // compare(value, best) > 0 means value should come before best
          // For dates: b.date.compareTo(a.date) > 0 means b is newer
          if (best == null || compare(value, best) > 0) {
            best = value;
            bestIndex = i;
          }
        }
      }

      if (best != null && bestIndex >= 0) {
        merged.add(best);
        // Advance iterator for the list we just consumed
        if (iterators[bestIndex].moveNext()) {
          currentValues[bestIndex] = iterators[bestIndex].current;
        } else {
          // This list is exhausted
          currentValues[bestIndex] = null;
        }
      }
    }

    return merged;
  }
}
