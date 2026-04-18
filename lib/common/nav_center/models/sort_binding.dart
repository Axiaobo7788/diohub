import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub_models/models/search/sort_spec.dart';

/// Sealed binding that pairs a SortSpec<T> with typed read/write callbacks.
///
/// Captures the generic parameter so the pill and dispatcher never lose type info.
/// This replaces the stringly-typed SortConfig + raw Function callbacks pattern
/// with a single, type-safe object.
sealed class SortBinding {
  const SortBinding();

  /// Convenience factory for typed bindings.
  ///
  /// Example:
  /// ```dart
  /// sort: SortBinding.typed<TagSortOrder>(
  ///   spec: SortSpec(
  ///     options: TagSortOrder.values,
  ///     defaultValue: TagSortOrder.byDate,
  ///     labelOf: (o) => switch (o) { ... },
  ///   ),
  ///   getValue: (ref) => ref.watch(tagSortOrderProvider(repoRef)),
  ///   onSelected: (ref, order) {
  ///     ref.read(tagSortOrderProvider(repoRef).notifier).state = order;
  ///   },
  /// ),
  /// ```
  static SortBinding typed<T>({
    required SortSpec<T> spec,
    required T Function(WidgetRef) getValue,
    required void Function(WidgetRef, T) onSelected,
  }) =>
      TypedSortBinding<T>(
        spec: spec,
        getValue: getValue,
        onSelected: onSelected,
      );
}

/// Concrete typed binding — preserves T at compile time.
///
/// Pattern matching on this variant extracts the type parameter T,
/// allowing type-safe access to the sort spec and callbacks.
class TypedSortBinding<T> extends SortBinding {
  const TypedSortBinding({
    required this.spec,
    required this.getValue,
    required this.onSelected,
  });

  final SortSpec<T> spec;
  final T Function(WidgetRef) getValue;
  final void Function(WidgetRef, T) onSelected;
}
