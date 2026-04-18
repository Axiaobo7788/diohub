import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/common/misc/settings_slider.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SurfaceScope {
  global,
  appBar,
}

/// Shared glass/blur/solid sliders for global surface or app bar surface.
/// Shown sliders depend on [surfaceRendering]: glass (5), blur (3), solid (1).
class SurfaceSliderGroup extends ConsumerWidget {
  const SurfaceSliderGroup({
    required this.scope,
    required this.surfaceRendering,
    super.key,
  });

  final SurfaceScope scope;
  final SurfaceRendering surfaceRendering;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AppearanceSettings appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);

    final double blur = scope == SurfaceScope.global
        ? appearance.glassBlur
        : (appearance.appBarGlassBlur ?? appearance.glassBlur);
    final double borderWidth = scope == SurfaceScope.global
        ? appearance.glassBorderWidth
        : (appearance.appBarGlassBorderWidth ?? appearance.glassBorderWidth);
    final double visibility = scope == SurfaceScope.global
        ? appearance.glassVisibility
        : (appearance.appBarGlassVisibility ?? appearance.glassVisibility);
    final double thickness = scope == SurfaceScope.global
        ? appearance.glassThickness
        : (appearance.appBarGlassThickness ?? appearance.glassThickness);
    final double lightIntensity = scope == SurfaceScope.global
        ? appearance.glassLightIntensity
        : (appearance.appBarGlassLightIntensity ?? appearance.glassLightIntensity);

    final List<Widget> sliders = <Widget>[];

    if (surfaceRendering == SurfaceRendering.glass) {
      sliders.addAll(<Widget>[
        SettingsSlider(
          title: 'Blur strength',
          subtitle: 'Frost intensity for glass and blur surfaces',
          value: blur,
          min: 2,
          max: 24,
          divisions: 22,
          icon: Icons.blur_on,
          labelBuilder: (final double v) => v.toStringAsFixed(0),
          onChanged: (final double v) {
            if (scope == SurfaceScope.global) {
              notifier.update((final s) => s.copyWith(glassBlur: v));
            } else {
              notifier.update((final s) => s.copyWith(appBarGlassBlur: v));
            }
          },
        ),
        SettingsSlider(
          title: 'Border width',
          subtitle: 'Outline width on surfaces',
          value: borderWidth,
          min: 0,
          max: 1.5,
          divisions: 15,
          icon: Icons.border_outer,
          labelBuilder: (final double v) => v.toStringAsFixed(1),
          onChanged: (final double v) => scope == SurfaceScope.global
              ? notifier.update((final s) => s.copyWith(glassBorderWidth: v))
              : notifier.update((final s) => s.copyWith(appBarGlassBorderWidth: v)),
        ),
        SettingsSlider(
          title: 'Visibility',
          subtitle: 'Opacity of glass/blur effect',
          value: visibility,
          min: 0.5,
          max: 1,
          divisions: 10,
          icon: Icons.opacity,
          labelBuilder: (final double v) => '${(v * 100).round()}%',
          onChanged: (final double v) => scope == SurfaceScope.global
              ? notifier.update((final s) => s.copyWith(glassVisibility: v))
              : notifier.update((final s) => s.copyWith(appBarGlassVisibility: v)),
        ),
        SettingsSlider(
          title: 'Glass thickness',
          subtitle: 'Depth of liquid glass layer',
          value: thickness,
          min: 4,
          max: 10,
          divisions: 12,
          icon: Icons.layers,
          labelBuilder: (final double v) => v.toStringAsFixed(1),
          onChanged: (final double v) => scope == SurfaceScope.global
              ? notifier.update((final s) => s.copyWith(glassThickness: v))
              : notifier.update((final s) => s.copyWith(appBarGlassThickness: v)),
        ),
        SettingsSlider(
          title: 'Light intensity',
          subtitle: 'Glass highlight strength',
          value: lightIntensity,
          min: 0.2,
          max: 0.6,
          divisions: 8,
          icon: Icons.lightbulb_outline,
          labelBuilder: (final double v) => v.toStringAsFixed(2),
          onChanged: (final double v) => scope == SurfaceScope.global
              ? notifier.update((final s) => s.copyWith(glassLightIntensity: v))
              : notifier.update((final s) => s.copyWith(appBarGlassLightIntensity: v)),
        ),
      ]);
    } else if (surfaceRendering == SurfaceRendering.blur) {
      sliders.addAll(<Widget>[
        SettingsSlider(
          title: 'Blur strength',
          subtitle: 'Frost intensity',
          value: blur,
          min: 2,
          max: 24,
          divisions: 22,
          icon: Icons.blur_on,
          labelBuilder: (final double v) => v.toStringAsFixed(0),
          onChanged: (final double v) {
            if (scope == SurfaceScope.global) {
              notifier.update((final s) => s.copyWith(glassBlur: v));
            } else {
              notifier.update((final s) => s.copyWith(appBarGlassBlur: v));
            }
          },
        ),
        SettingsSlider(
          title: 'Border width',
          value: borderWidth,
          min: 0,
          max: 1.5,
          divisions: 15,
          icon: Icons.border_outer,
          labelBuilder: (final double v) => v.toStringAsFixed(1),
          onChanged: (final double v) => scope == SurfaceScope.global
              ? notifier.update((final s) => s.copyWith(glassBorderWidth: v))
              : notifier.update((final s) => s.copyWith(appBarGlassBorderWidth: v)),
        ),
        SettingsSlider(
          title: 'Visibility',
          value: visibility,
          min: 0.5,
          max: 1,
          divisions: 10,
          icon: Icons.opacity,
          labelBuilder: (final double v) => '${(v * 100).round()}%',
          onChanged: (final double v) => scope == SurfaceScope.global
              ? notifier.update((final s) => s.copyWith(glassVisibility: v))
              : notifier.update((final s) => s.copyWith(appBarGlassVisibility: v)),
        ),
      ]);
    } else {
      sliders.add(
        SettingsSlider(
          title: 'Border width',
          value: borderWidth,
          min: 0,
          max: 1.5,
          divisions: 15,
          icon: Icons.border_outer,
          labelBuilder: (final double v) => v.toStringAsFixed(1),
          onChanged: (final double v) => scope == SurfaceScope.global
              ? notifier.update((final s) => s.copyWith(glassBorderWidth: v))
              : notifier.update((final s) => s.copyWith(appBarGlassBorderWidth: v)),
        ),
      );
    }

    return SettingsGroup(children: sliders);
  }
}
