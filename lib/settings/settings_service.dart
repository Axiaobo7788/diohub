import 'settings_types.dart';

typedef SettingsRegistry = Map<String, SettingDefinition<dynamic>>;

/// Migration transforms a stored values map to a new shape/version.
/// Simple helpers are provided at the bottom for common cases.
typedef Migration = Map<String, dynamic> Function(Map<String, dynamic> values);

class SettingsResolver {
  /// Resolve settings by merging defaults, validating, then applying dependency
  /// predicates to compute enable/visible flags. Does not persist anything.
  static Map<String, EffectiveSetting<dynamic>> resolve(
    SettingsRegistry registry,
    Map<String, dynamic> rawValues,
  ) {
    final snapshot = <String, dynamic>{};

    // Merge defaults and provided values with validation.
    for (final def in registry.values) {
      final candidate = rawValues[def.key] ?? def.defaultValue;
      final validator = def.validate;
      if (validator != null) {
        final result = validator(candidate as dynamic);
        snapshot[def.key] = result.isValid ? candidate : def.defaultValue;
      } else {
        snapshot[def.key] = candidate;
      }
    }

    // Multi-pass dependency resolution to allow chained rules.
    final effective = <String, EffectiveSetting<dynamic>>{};
    var changed = true;
    var iterations = 0;
    const maxIterations = 8;
    while (changed && iterations < maxIterations) {
      changed = false;
      iterations += 1;
      final snapshotWrapper = SettingsSnapshot(snapshot);
      for (final def in registry.values) {
        final dep = def.dependencies;
        final isDisabled = dep?.disableWhen?.call(snapshotWrapper) ?? false;
        final isEnabled =
            dep?.enableWhen != null ? dep!.enableWhen!(snapshotWrapper) && !isDisabled : !isDisabled;
        final isVisible = dep?.visibleWhen?.call(snapshotWrapper) ?? true;
        final current = effective[def.key];
        if (current == null ||
            current.isEnabled != isEnabled ||
            current.isVisible != isVisible ||
            current.value != snapshot[def.key]) {
          changed = true;
        }
        effective[def.key] = EffectiveSetting(
          value: snapshot[def.key],
          isEnabled: isEnabled,
          isVisible: isVisible,
        );
      }
    }

    if (iterations >= maxIterations) {
      throw StateError('Circular dependency detected in settings resolution');
    }

    return effective;
  }
}

class StoredSettings {
  final int version;
  final Map<String, dynamic> values;

  const StoredSettings({
    required this.version,
    required this.values,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'values': values,
      };

  factory StoredSettings.fromJson(Map<String, dynamic> json) {
    return StoredSettings(
      version: json['version'] as int? ?? 0,
      values: Map<String, dynamic>.from(json['values'] as Map? ?? {}),
    );
  }
}

class SettingsMigrator {
  final int currentVersion;
  final List<Migration> migrations;

  const SettingsMigrator({
    required this.currentVersion,
    this.migrations = const [],
  });

  StoredSettings migrate(StoredSettings stored) {
    var version = stored.version;
    var values = Map<String, dynamic>.from(stored.values);
    while (version < currentVersion && version < migrations.length) {
      values = migrations[version](values);
      version += 1;
    }
    return StoredSettings(version: currentVersion, values: values);
  }
}

class SettingsService {
  final SettingsRegistry _registry;
  final SettingsMigrator _migrator;
  final List<CrossValidator> _crossValidators;
  final Map<String, dynamic> _values = {};
  final SettingChangeBus _bus = SettingChangeBus();

  Map<String, EffectiveSetting<dynamic>>? _cache;
  bool _dirty = true;

  SettingsService(
    this._registry, {
    SettingsMigrator? migrator,
    List<CrossValidator> crossValidators = const [],
  })  : _migrator = migrator ?? const SettingsMigrator(currentVersion: 1),
        _crossValidators = crossValidators;

  Stream<SettingChange> get onChange => _bus.stream;

  SettingsRegistry get registry => _registry;

  /// Load settings from storage, apply migrations and cross-validators.
  /// If cross-validation fails after migration, values are reset to defaults
  /// to avoid starting in an invalid state.
  void loadFromStorage(StoredSettings stored) {
    final migrated = _migrator.migrate(stored);
    _values
      ..clear()
      ..addAll(migrated.values);
    final crossResult = _runCrossValidators(_values);
    if (!crossResult.isValid) {
      // If invalid, reset offending values to defaults.
      for (final def in _registry.values) {
        _values[def.key] = def.defaultValue;
      }
    }
    _dirty = true;
  }

  StoredSettings saveToStorage() {
    return StoredSettings(
      version: _migrator.currentVersion,
      values: Map<String, dynamic>.from(_values),
    );
  }

  Map<String, EffectiveSetting<dynamic>> getEffectiveSettings() {
    if (!_dirty && _cache != null) {
      return _cache!;
    }
    _cache = SettingsResolver.resolve(_registry, _values);
    _dirty = false;
    return _cache!;
  }

  T? getValue<T>(String key) {
    final effective = getEffectiveSettings()[key];
    return effective?.value as T?;
  }

  ValidationResult setValue(String key, dynamic value) {
    final def = _registry[key];
    if (def == null) {
      return ValidationResult.invalid('Unknown setting: $key');
    }

    // Type checking for enums and list of strings.
    if (def.type == SettingType.enumeration && def.options != null) {
      if (!def.options!.contains(value)) {
        return ValidationResult.invalid('Value for $key is not in allowed options.');
      }
    }
    if (def.type == SettingType.stringList) {
      if (value is! List) {
        return ValidationResult.invalid('Value for $key must be a list of strings.');
      }
      final asStrings = value.whereType<String>().toList();
      if (asStrings.length != value.length) {
        return ValidationResult.invalid('All entries for $key must be strings.');
      }
      value = asStrings;
    }

    if (def.validate != null) {
      final result = def.validate!(value as dynamic);
      if (!result.isValid) return result;
    }

    // Run cross-validators with the prospective new value.
    final prospective = Map<String, dynamic>.from(_values)..[key] = value;
    final crossResult = _runCrossValidators(prospective);
    if (!crossResult.isValid) return crossResult;

    final oldValue = _values[key];
    final wasEnabled = getEffectiveSettings()[key]?.isEnabled ?? true;

    _values[key] = value;
    _dirty = true;
    final newEnabled = getEffectiveSettings()[key]?.isEnabled ?? true;
    _bus.emit(
      SettingChange(
        key: key,
        oldValue: oldValue,
        newValue: value,
        wasEnabled: wasEnabled,
        isEnabled: newEnabled,
      ),
    );
    return const ValidationResult.valid();
  }

  Map<String, EffectiveSetting<dynamic>> getGroup(String prefix) {
    return getEffectiveSettings()
        .entries
        .where((e) => e.key.startsWith('$prefix.'))
        .fold<Map<String, EffectiveSetting<dynamic>>>({}, (acc, entry) {
      acc[entry.key.replaceFirst('$prefix.', '')] = entry.value;
      return acc;
    });
  }

  Map<String, EffectiveSetting<dynamic>> getCategory(String category) {
    return _registry.entries
        .where((e) => e.value.category == category)
        .fold<Map<String, EffectiveSetting<dynamic>>>({}, (acc, entry) {
      final effective = getEffectiveSettings()[entry.key];
      if (effective != null) acc[entry.key] = effective;
      return acc;
    });
  }

  void resetToDefaults() {
    for (final def in _registry.values) {
      _values[def.key] = def.defaultValue;
    }
    _dirty = true;
  }

  void dispose() {
    _bus.dispose();
  }

  ValidationResult _runCrossValidators(Map<String, dynamic> values) {
    for (final validator in _crossValidators) {
      final result = validator(values);
      if (!result.isValid) return result;
    }
    return const ValidationResult.valid();
  }
}

/// Convenience wrapper to build a registry fluently.
class SettingsRegistryBuilder {
  final SettingsRegistry _definitions = {};

  /// Define a setting. Use dot notation in key for grouping (e.g., theme.primary).
  SettingsRegistryBuilder define<T>({
    required String key,
    required String category,
    required SettingType type,
    required T defaultValue,
    Validator<T>? validate,
    List<T>? options,
    SettingDependencies? dependencies,
    String? label,
    String? description,
  }) {
    _definitions[key] = SettingDefinition<T>(
      key: key,
      category: category,
      type: type,
      defaultValue: defaultValue,
      validate: validate,
      options: options,
      dependencies: dependencies,
      label: label,
      description: description,
    );
    return this;
  }

  SettingsRegistry build() {
    _validateDependencies();
    return Map.unmodifiable(_definitions);
  }

  void _validateDependencies() {
    // Ensure dependsOnKeys exist.
    for (final def in _definitions.values) {
      final deps = def.dependencies?.dependsOnKeys ?? const [];
      for (final key in deps) {
        if (!_definitions.containsKey(key)) {
          throw ArgumentError(
            'Setting ${def.key} depends on missing key $key',
          );
        }
      }
    }

    // Detect cycles using DFS on dependsOnKeys.
    final visiting = <String>{};
    final visited = <String>{};

    bool dfs(String key) {
      if (visiting.contains(key)) return true; // cycle
      if (visited.contains(key)) return false;
      visiting.add(key);
      final deps = _definitions[key]?.dependencies?.dependsOnKeys ?? const [];
      for (final dep in deps) {
        if (dfs(dep)) return true;
      }
      visiting.remove(key);
      visited.add(key);
      return false;
    }

    for (final key in _definitions.keys) {
      if (dfs(key)) {
        throw ArgumentError('Cycle detected in setting dependencies starting at $key');
      }
    }
  }
}

// Helpers for common migration patterns.
// Example usage:
// final migrator = SettingsMigrator(
//   currentVersion: 3,
//   migrations: [
//     renameKey('oldKey', 'newKey'),               // v0 -> v1
//     transformValue('timeoutMs', (v) => v ?? 300),// v1 -> v2
//     (values) {                                  // v2 -> v3
//       values.remove('deprecated.flag');
//       return values;
//     },
//   ],
// );
Migration renameKey(String oldKey, String newKey) {
  return (values) {
    if (values.containsKey(oldKey)) {
      values[newKey] = values.remove(oldKey);
    }
    return values;
  };
}

Migration transformValue(String key, dynamic Function(dynamic) transform) {
  return (values) {
    if (values.containsKey(key)) {
      values[key] = transform(values[key]);
    }
    return values;
  };
}

