/// Type-safe sort specification for a domain enum T.
///
/// Instead of converting domain enums to stringly-typed SortOption keys,
/// this preserves the type parameter T throughout the sort flow.
///
/// Example:
/// ```dart
/// final tagSortSpec = SortSpec<TagSortOrder>(
///   options: TagSortOrder.values,
///   defaultValue: TagSortOrder.byDate,
///   labelOf: (o) => switch (o) {
///     TagSortOrder.byDate => 'Recent',
///     TagSortOrder.byName => 'Name',
///   },
/// );
/// ```
class SortSpec<T> {
  const SortSpec({
    required this.options,
    required this.defaultValue,
    required this.labelOf,
  });

  /// All available sort options.
  final List<T> options;

  /// The default sort option (used to determine idle vs hint pill phase).
  final T defaultValue;

  /// Display label for each option (shown in sort chip popup).
  final String Function(T) labelOf;
}
