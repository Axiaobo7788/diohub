import 'settings_service.dart';
import 'settings_types.dart';

/// Collapsed options granularity for toolbar/tab UIs.
enum CollapsedOptionsLevel { minimal, medium, full }

extension CollapsedOptionsLevelX on CollapsedOptionsLevel {
  String get asKey => toString().split('.').last;

  static CollapsedOptionsLevel fromKey(String key) {
    return CollapsedOptionsLevel.values.firstWhere((e) => e.asKey == key,
        orElse: () => CollapsedOptionsLevel.medium);
  }
}

/// Application settings registry covering theme and tab behavior.
/// Add new settings here; keep keys stable for migrations.
///
/// Example service wiring (not executed here):
/// ```dart
/// final service = SettingsService(
///   appSettingsRegistry,
///   migrator: SettingsMigrator(
///     currentVersion: 1,
///     migrations: [
///       // renameKey('old', 'new'),
///       // transformValue('animation.durationMs', (v) => (v as int?) ?? 300),
///     ],
///   ),
///   crossValidators: appCrossValidators,
/// );
/// final settings = AppSettings(service);
/// ```
final SettingsRegistry appSettingsRegistry = SettingsRegistryBuilder()
    // Theme settings
    .define<bool>(
      key: 'theme.useDynamicColor',
      category: 'Theme',
      type: SettingType.boolean,
      defaultValue: true,
      label: 'Use dynamic color',
      description: 'Use platform dynamic color when available.',
    )
    .define<String>(
      key: 'theme.primarySeed',
      category: 'Theme',
      type: SettingType.stringType,
      defaultValue: '#5B86FF',
      label: 'Primary seed color',
      description: 'Hex color seed when dynamic color is off.',
      validate: (value) {
        final hex = value.toUpperCase();
        final isHex = RegExp(r'^#(?:[0-9A-F]{6}|[0-9A-F]{8})$').hasMatch(hex);
        return isHex
            ? const ValidationResult.valid()
            : const ValidationResult.invalid('Must be #RRGGBB or #RRGGBBAA');
      },
      dependencies: SettingDependencies(
        disableWhen: (s) => s.getBool('theme.useDynamicColor'),
        dependsOnKeys: const ['theme.useDynamicColor'],
      ),
    )
    .define<bool>(
      key: 'theme.borderRadius.useGlobal',
      category: 'Theme',
      type: SettingType.boolean,
      defaultValue: true,
      label: 'Use global border radius',
      description: 'Apply a single radius to all components.',
    )
    .define<double>(
      key: 'theme.borderRadius.small',
      category: 'Theme',
      type: SettingType.doubleType,
      defaultValue: 8.0,
      label: 'Border radius (small)',
      dependencies: SettingDependencies(
        disableWhen: (s) => s.getBool('theme.borderRadius.useGlobal'),
        dependsOnKeys: const ['theme.borderRadius.useGlobal'],
      ),
      validate: (value) => value >= 0
          ? const ValidationResult.valid()
          : const ValidationResult.invalid('Must be >= 0'),
    )
    .define<double>(
      key: 'theme.borderRadius.medium',
      category: 'Theme',
      type: SettingType.doubleType,
      defaultValue: 12.0,
      label: 'Border radius (medium)',
      dependencies: SettingDependencies(
        disableWhen: (s) => s.getBool('theme.borderRadius.useGlobal'),
        dependsOnKeys: const ['theme.borderRadius.useGlobal'],
      ),
      validate: (value) => value >= 0
          ? const ValidationResult.valid()
          : const ValidationResult.invalid('Must be >= 0'),
    )
    .define<double>(
      key: 'theme.borderRadius.large',
      category: 'Theme',
      type: SettingType.doubleType,
      defaultValue: 16.0,
      label: 'Border radius (large)',
      dependencies: SettingDependencies(
        disableWhen: (s) => s.getBool('theme.borderRadius.useGlobal'),
        dependsOnKeys: const ['theme.borderRadius.useGlobal'],
      ),
      validate: (value) => value >= 0
          ? const ValidationResult.valid()
          : const ValidationResult.invalid('Must be >= 0'),
    )
    .define<bool>(
      key: 'theme.animation.disableAll',
      category: 'Theme',
      type: SettingType.boolean,
      defaultValue: false,
      label: 'Disable animations',
    )
    .define<int>(
      key: 'theme.animation.durationMs',
      category: 'Theme',
      type: SettingType.integer,
      defaultValue: 300,
      label: 'Animation duration (ms)',
      dependencies: SettingDependencies(
        disableWhen: (s) => s.getBool('theme.animation.disableAll'),
        dependsOnKeys: const ['theme.animation.disableAll'],
      ),
      validate: (value) => value >= 0 && value <= 2000
          ? const ValidationResult.valid()
          : const ValidationResult.invalid('Must be between 0 and 2000 ms'),
    )
    // Tabs / Dynamic tabs behavior
    .define<List<String>>(
      key: 'tabs.defaultOpenIds',
      category: 'Tabs',
      type: SettingType.stringList,
      defaultValue: const [],
      label: 'Default open tab ids',
      description: 'Identifiers to open by default in dynamic tabs.',
      validate: (value) {
        final uniqueCount = value.toSet().length;
        return uniqueCount == value.length
            ? const ValidationResult.valid()
            : const ValidationResult.invalid('Tab identifiers must be unique');
      },
    )
    .define<String>(
      key: 'tabs.initialFocusedId',
      category: 'Tabs',
      type: SettingType.stringType,
      defaultValue: '',
      label: 'Initial focused tab id',
      description: 'Must be present in default open tab ids.',
      dependencies: SettingDependencies(
        disableWhen: (s) => s.getStringList('tabs.defaultOpenIds').isEmpty,
        dependsOnKeys: const ['tabs.defaultOpenIds'],
      ),
      validate: (value) {
        if (value.isEmpty) return const ValidationResult.valid();
        return const ValidationResult.valid();
      },
    )
    .define<bool>(
      key: 'tabs.persistAcrossSessions',
      category: 'Tabs',
      type: SettingType.boolean,
      defaultValue: true,
      label: 'Restore tabs on launch',
    )
    .define<String>(
      key: 'tabs.collapsedOptionsLevel',
      category: 'Tabs',
      type: SettingType.enumeration,
      defaultValue: CollapsedOptionsLevel.medium.asKey,
      options: CollapsedOptionsLevel.values.map((e) => e.asKey).toList(),
      label: 'Collapsed toolbar options level',
      description:
          'Controls how many options to show when toolbar is collapsed.',
    )
    .build();

/// Cross-setting validators to keep related values consistent.
/// They run on load (after migration) and on every setValue call.
final List<CrossValidator> appCrossValidators = [
  // Ensure initial focused tab (if set) exists in defaultOpenIds.
  (values) {
    final open = (values['tabs.defaultOpenIds'] as List?)
            ?.whereType<String>()
            .toList() ??
        [];
    final focused = values['tabs.initialFocusedId'] as String? ?? '';
    if (focused.isEmpty) return const ValidationResult.valid();
    if (!open.contains(focused)) {
      return const ValidationResult.invalid(
          'Initial focused tab must be in default open tab ids.');
    }
    return const ValidationResult.valid();
  },
  // Ensure border radii are non-decreasing when not using global radius.
  (values) {
    final useGlobal = values['theme.borderRadius.useGlobal'] as bool? ?? true;
    if (useGlobal) return const ValidationResult.valid();
    final s = (values['theme.borderRadius.small'] as num?)?.toDouble() ?? 0;
    final m = (values['theme.borderRadius.medium'] as num?)?.toDouble() ?? 0;
    final l = (values['theme.borderRadius.large'] as num?)?.toDouble() ?? 0;
    if (s <= m && m <= l) return const ValidationResult.valid();
    return const ValidationResult.invalid(
        'Border radius should be small <= medium <= large.');
  },
];

/// Type-safe accessors for the app settings registry.
class AppSettings {
  final SettingsService _service;

  const AppSettings(this._service);

  // Theme
  bool get useDynamicColor =>
      _service.getValue<bool>('theme.useDynamicColor') ?? true;
  set useDynamicColor(bool value) =>
      _service.setValue('theme.useDynamicColor', value);

  String get primarySeed =>
      _service.getValue<String>('theme.primarySeed') ?? '#5B86FF';
  set primarySeed(String value) =>
      _service.setValue('theme.primarySeed', value);

  bool get useGlobalRadius =>
      _service.getValue<bool>('theme.borderRadius.useGlobal') ?? true;
  set useGlobalRadius(bool value) =>
      _service.setValue('theme.borderRadius.useGlobal', value);

  double get radiusSmall =>
      _service.getValue<double>('theme.borderRadius.small') ?? 8.0;
  set radiusSmall(double value) =>
      _service.setValue('theme.borderRadius.small', value);

  double get radiusMedium =>
      _service.getValue<double>('theme.borderRadius.medium') ?? 12.0;
  set radiusMedium(double value) =>
      _service.setValue('theme.borderRadius.medium', value);

  double get radiusLarge =>
      _service.getValue<double>('theme.borderRadius.large') ?? 16.0;
  set radiusLarge(double value) =>
      _service.setValue('theme.borderRadius.large', value);

  bool get disableAnimations =>
      _service.getValue<bool>('theme.animation.disableAll') ?? false;
  set disableAnimations(bool value) =>
      _service.setValue('theme.animation.disableAll', value);

  int get animationDurationMs =>
      _service.getValue<int>('theme.animation.durationMs') ?? 300;
  set animationDurationMs(int value) =>
      _service.setValue('theme.animation.durationMs', value);

  // Tabs
  List<String> get defaultOpenIds =>
      _service.getValue<List<String>>('tabs.defaultOpenIds') ?? const [];
  set defaultOpenIds(List<String> value) =>
      _service.setValue('tabs.defaultOpenIds', value);

  String get initialFocusedId =>
      _service.getValue<String>('tabs.initialFocusedId') ?? '';
  set initialFocusedId(String value) =>
      _service.setValue('tabs.initialFocusedId', value);

  bool get persistAcrossSessions =>
      _service.getValue<bool>('tabs.persistAcrossSessions') ?? true;
  set persistAcrossSessions(bool value) =>
      _service.setValue('tabs.persistAcrossSessions', value);

  CollapsedOptionsLevel get collapsedOptionsLevel =>
      CollapsedOptionsLevelX.fromKey(_service
              .getValue<String>('tabs.collapsedOptionsLevel') ??
          CollapsedOptionsLevel.medium.asKey);
  set collapsedOptionsLevel(CollapsedOptionsLevel value) =>
      _service.setValue('tabs.collapsedOptionsLevel', value.asKey);
}
