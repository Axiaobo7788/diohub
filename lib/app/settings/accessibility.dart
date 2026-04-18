import 'package:diohub/app/settings/settings_descriptor.dart';

/// Accessibility settings: haptic feedback level.
enum HapticFeedbackLevel {
  on,
  reduced,
  off;

  String get name => switch (this) {
        HapticFeedbackLevel.on => 'on',
        HapticFeedbackLevel.reduced => 'reduced',
        HapticFeedbackLevel.off => 'off',
      };

  static HapticFeedbackLevel fromName(final String name) =>
      HapticFeedbackLevel.values.firstWhere(
        (final HapticFeedbackLevel e) => e.name == name,
        orElse: () => HapticFeedbackLevel.on,
      );
}

class AccessibilitySettings {
  const AccessibilitySettings({
    this.hapticFeedback = HapticFeedbackLevel.on,
  });

  factory AccessibilitySettings.fromJson(final Map<String, dynamic> json) =>
      AccessibilitySettings(
        hapticFeedback: json['hapticFeedback'] is String
            ? HapticFeedbackLevel.fromName(json['hapticFeedback'] as String)
            : HapticFeedbackLevel.on,
      );

  final HapticFeedbackLevel hapticFeedback;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'hapticFeedback': hapticFeedback.name};

  AccessibilitySettings copyWith({final HapticFeedbackLevel? hapticFeedback}) =>
      AccessibilitySettings(
        hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      );
}

Map<String, dynamic> _accessibilityToJson(final AccessibilitySettings v) =>
    v.toJson();

const SettingsDescriptor<AccessibilitySettings> accessibilityDescriptor =
    SettingsDescriptor<AccessibilitySettings>(
  key: 'app_accessibility',
  defaultValue: AccessibilitySettings(),
  fromJson: AccessibilitySettings.fromJson,
  toJson: _accessibilityToJson,
);
