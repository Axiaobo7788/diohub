import 'dart:async';

/// Supported primitive setting types.
/// Pick the closest primitive; domain meaning should live in names/labels.
enum SettingType {
  boolean,
  integer,
  doubleType,
  stringType,
  enumeration,
  stringList
}

typedef DependencyPredicate = bool Function(SettingsSnapshot snapshot);
typedef Validator<T> = ValidationResult Function(T value);
typedef CrossValidator = ValidationResult Function(Map<String, dynamic> values);

/// Result of a validation step.
/// Use `ValidationResult.invalid('reason')` to surface a message to callers.
class ValidationResult {
  final bool isValid;
  final String? message;

  const ValidationResult._(this.isValid, this.message);
  const ValidationResult.valid() : this._(true, null);
  const ValidationResult.invalid(String message) : this._(false, message);
}

/// Dependency rules for a single setting.
/// All predicates receive a SettingsSnapshot of current values.
/// dependsOnKeys is used for validation and cycle detection at registry build time.
class SettingDependencies {
  final DependencyPredicate? disableWhen;
  final DependencyPredicate? enableWhen;
  final DependencyPredicate? visibleWhen;
  final String? description;
  final List<String> dependsOnKeys;

  const SettingDependencies({
    this.disableWhen,
    this.enableWhen,
    this.visibleWhen,
    this.description,
    this.dependsOnKeys = const [],
  });
}

/// A setting definition inside the registry.
class SettingDefinition<T> {
  final String key;
  final String category;
  final SettingType type;
  final T defaultValue;
  final Validator<T>? validate;
  final List<T>? options; // for enumerations
  final SettingDependencies? dependencies;
  final String? label;
  final String? description;

  const SettingDefinition({
    required this.key,
    required this.category,
    required this.type,
    required this.defaultValue,
    this.validate,
    this.options,
    this.dependencies,
    this.label,
    this.description,
  });
}

/// Snapshot view used by dependency predicates.
class SettingsSnapshot {
  final Map<String, dynamic> _values;

  const SettingsSnapshot(this._values);

  T? get<T>(String key) => _values[key] as T?;
  bool has(String key) => _values.containsKey(key);

  bool getBool(String key, {bool fallback = false}) {
    final value = _values[key];
    if (value is bool) return value;
    return fallback;
  }

  int getInt(String key, {int fallback = 0}) {
    final value = _values[key];
    if (value is int) return value;
    return fallback;
  }

  double getDouble(String key, {double fallback = 0.0}) {
    final value = _values[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return fallback;
  }

  String getString(String key, {String fallback = ''}) {
    final value = _values[key];
    if (value is String) return value;
    return fallback;
  }

  List<String> getStringList(String key, {List<String> fallback = const []}) {
    final value = _values[key];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return fallback;
  }
}

/// The resolved state of a setting.
class EffectiveSetting<T> {
  final T value;
  final bool isEnabled;
  final bool isVisible;

  const EffectiveSetting({
    required this.value,
    required this.isEnabled,
    required this.isVisible,
  });
}

/// Change event emitted by the settings service.
class SettingChange {
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  final bool wasEnabled;
  final bool isEnabled;

  SettingChange({
    required this.key,
    required this.oldValue,
    required this.newValue,
    required this.wasEnabled,
    required this.isEnabled,
  });
}

/// Simple pub-sub wrapper to avoid leaking StreamController outside.
class SettingChangeBus {
  final _controller = StreamController<SettingChange>.broadcast();

  Stream<SettingChange> get stream => _controller.stream;

  void emit(SettingChange change) => _controller.add(change);

  void dispose() => _controller.close();
}
