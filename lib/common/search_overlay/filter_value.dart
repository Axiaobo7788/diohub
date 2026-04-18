import 'package:collection/collection.dart';

/// Type-safe filter value wrapper for FilterStateAdapter.
///
/// Eliminates `dynamic` by representing the three possible value types:
/// - [FilterValue.singleSelect] for String? (one choice from options)
/// - [FilterValue.multiSelect] for List<String> (multiple choices)
/// - [FilterValue.toggle] for bool (on/off switch)
sealed class FilterValue {
  const FilterValue();

  /// Single-select filter (String? value, used for dropdowns/choice chips with null = none selected)
  const factory FilterValue.singleSelect(String? value) = _SingleSelectFilterValue;

  /// Multi-select filter (List<String> value, used for multi-choice chips)
  const factory FilterValue.multiSelect(List<String> values) = _MultiSelectFilterValue;

  /// Toggle filter (bool value, used for switches)
  const factory FilterValue.toggle(bool value) = _ToggleFilterValue;

  /// Pattern matching helper
  T when<T>({
    required T Function(String? value) singleSelect,
    required T Function(List<String> values) multiSelect,
    required T Function(bool value) toggle,
  }) {
    return switch (this) {
      _SingleSelectFilterValue(:final value) => singleSelect(value),
      _MultiSelectFilterValue(:final values) => multiSelect(values),
      _ToggleFilterValue(:final value) => toggle(value),
    };
  }

  /// Pattern matching helper with orElse fallback
  T maybeWhen<T>({
    T Function(String? value)? singleSelect,
    T Function(List<String> values)? multiSelect,
    T Function(bool value)? toggle,
    required T Function() orElse,
  }) {
    return switch (this) {
      _SingleSelectFilterValue(:final value) => singleSelect?.call(value) ?? orElse(),
      _MultiSelectFilterValue(:final values) => multiSelect?.call(values) ?? orElse(),
      _ToggleFilterValue(:final value) => toggle?.call(value) ?? orElse(),
    };
  }
}

class _SingleSelectFilterValue extends FilterValue {
  const _SingleSelectFilterValue(this.value);
  final String? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SingleSelectFilterValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class _MultiSelectFilterValue extends FilterValue {
  const _MultiSelectFilterValue(this.values);
  final List<String> values;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MultiSelectFilterValue &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(values, other.values);

  @override
  int get hashCode => const ListEquality().hashCode ^ values.hashCode;
}

class _ToggleFilterValue extends FilterValue {
  const _ToggleFilterValue(this.value);
  final bool value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ToggleFilterValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
