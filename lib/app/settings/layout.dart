import 'package:diohub/app/settings/settings_descriptor.dart';

/// Layout-related settings: sticky section headers, density.
class LayoutSettings {
  const LayoutSettings({
    this.stickyHeaders = true,
    this.density = LayoutDensity.default_,
  });

  factory LayoutSettings.fromJson(final Map<String, dynamic> json) =>
      LayoutSettings(
        stickyHeaders: json['stickyHeaders'] as bool? ?? true,
        density: _densityFromJson(json['density']),
      );

  final bool stickyHeaders;
  final LayoutDensity density;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'stickyHeaders': stickyHeaders,
        'density': density.name,
      };

  static LayoutDensity _densityFromJson(final dynamic v) {
    if (v is! String) return LayoutDensity.default_;
    for (final LayoutDensity e in LayoutDensity.values) {
      if (e.name == v) return e;
    }
    return LayoutDensity.default_;
  }

  LayoutSettings copyWith({
    final bool? stickyHeaders,
    final LayoutDensity? density,
  }) =>
      LayoutSettings(
        stickyHeaders: stickyHeaders ?? this.stickyHeaders,
        density: density ?? this.density,
      );
}

enum LayoutDensity {
  compact,
  default_,
  spacious;

  String get name => switch (this) {
        LayoutDensity.compact => 'compact',
        LayoutDensity.default_ => 'default',
        LayoutDensity.spacious => 'spacious',
      };

  static LayoutDensity fromName(final String name) =>
      LayoutDensity.values.firstWhere(
        (final LayoutDensity e) => e.name == name,
        orElse: () => LayoutDensity.default_,
      );
}

Map<String, dynamic> _layoutToJson(final LayoutSettings v) => v.toJson();

const SettingsDescriptor<LayoutSettings> layoutDescriptor =
    SettingsDescriptor<LayoutSettings>(
  key: 'app_layout',
  defaultValue: LayoutSettings(),
  fromJson: LayoutSettings.fromJson,
  toJson: _layoutToJson,
);
