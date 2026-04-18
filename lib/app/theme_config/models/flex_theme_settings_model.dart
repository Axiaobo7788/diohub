import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Model representing all FlexColorScheme settings
class FlexThemeSettingsModel {
  FlexThemeSettingsModel({
    // Color scheme selection
    this.scheme,
    this.lightScheme,
    this.darkScheme,
    this.variant,

    // Color blending
    this.blendLevel,
    this.usedColors,

    // Dark theme specific
    this.darkIsTrueBlack,

    // Color swapping
    this.swapColors,
    this.swapLegacyColors,

    // Surface mode
    this.surfaceMode,

    // Custom colors
    this.primary,
    this.onPrimary,
    this.primaryContainer,
    this.onPrimaryContainer,
    this.secondary,
    this.onSecondary,
    this.secondaryContainer,
    this.onSecondaryContainer,
    this.tertiary,
    this.onTertiary,
    this.tertiaryContainer,
    this.onTertiaryContainer,
    this.error,
    this.onError,
    this.errorContainer,
    this.onErrorContainer,
    this.surface,
    this.onSurface,
    this.surfaceContainerHighest,
    this.onSurfaceVariant,
    this.outline,
    this.outlineVariant,
    this.shadow,
    this.scrim,
    this.inverseSurface,
    this.onInverseSurface,
    this.inversePrimary,

    // Typography
    this.fontFamily,

    // Sub-themes
    this.subThemes,

    // ColorScheme override
    this.colorScheme,
  });

  /// Create from JSON
  factory FlexThemeSettingsModel.fromJson(final Map<String, dynamic> json) =>
      FlexThemeSettingsModel(
        scheme: json['scheme'] != null
            ? FlexScheme.values[json['scheme'] as int]
            : null,
        lightScheme: json['lightScheme'] != null
            ? FlexScheme.values[json['lightScheme'] as int]
            : null,
        darkScheme: json['darkScheme'] != null
            ? FlexScheme.values[json['darkScheme'] as int]
            : null,
        variant: json['variant'] != null
            ? FlexSchemeVariant.values[json['variant'] as int]
            : null,
        blendLevel: json['blendLevel'] as int?,
        usedColors: json['usedColors'] as int?,
        darkIsTrueBlack: json['darkIsTrueBlack'] as bool?,
        swapColors: json['swapColors'] as bool?,
        swapLegacyColors: json['swapLegacyColors'] as bool?,
        surfaceMode: json['surfaceMode'] != null
            ? FlexSurfaceMode.values[json['surfaceMode'] as int]
            : null,
        primary: json['primary'] != null ? Color(json['primary'] as int) : null,
        onPrimary:
            json['onPrimary'] != null ? Color(json['onPrimary'] as int) : null,
        primaryContainer: json['primaryContainer'] != null
            ? Color(json['primaryContainer'] as int)
            : null,
        onPrimaryContainer: json['onPrimaryContainer'] != null
            ? Color(json['onPrimaryContainer'] as int)
            : null,
        secondary:
            json['secondary'] != null ? Color(json['secondary'] as int) : null,
        onSecondary: json['onSecondary'] != null
            ? Color(json['onSecondary'] as int)
            : null,
        secondaryContainer: json['secondaryContainer'] != null
            ? Color(json['secondaryContainer'] as int)
            : null,
        onSecondaryContainer: json['onSecondaryContainer'] != null
            ? Color(json['onSecondaryContainer'] as int)
            : null,
        tertiary:
            json['tertiary'] != null ? Color(json['tertiary'] as int) : null,
        onTertiary: json['onTertiary'] != null
            ? Color(json['onTertiary'] as int)
            : null,
        tertiaryContainer: json['tertiaryContainer'] != null
            ? Color(json['tertiaryContainer'] as int)
            : null,
        onTertiaryContainer: json['onTertiaryContainer'] != null
            ? Color(json['onTertiaryContainer'] as int)
            : null,
        error: json['error'] != null ? Color(json['error'] as int) : null,
        onError: json['onError'] != null ? Color(json['onError'] as int) : null,
        errorContainer: json['errorContainer'] != null
            ? Color(json['errorContainer'] as int)
            : null,
        onErrorContainer: json['onErrorContainer'] != null
            ? Color(json['onErrorContainer'] as int)
            : null,
        surface: json['surface'] != null ? Color(json['surface'] as int) : null,
        onSurface:
            json['onSurface'] != null ? Color(json['onSurface'] as int) : null,
        surfaceContainerHighest: json['surfaceContainerHighest'] != null
            ? Color(json['surfaceContainerHighest'] as int)
            : null,
        onSurfaceVariant: json['onSurfaceVariant'] != null
            ? Color(json['onSurfaceVariant'] as int)
            : null,
        outline: json['outline'] != null ? Color(json['outline'] as int) : null,
        outlineVariant: json['outlineVariant'] != null
            ? Color(json['outlineVariant'] as int)
            : null,
        shadow: json['shadow'] != null ? Color(json['shadow'] as int) : null,
        scrim: json['scrim'] != null ? Color(json['scrim'] as int) : null,
        inverseSurface: json['inverseSurface'] != null
            ? Color(json['inverseSurface'] as int)
            : null,
        onInverseSurface: json['onInverseSurface'] != null
            ? Color(json['onInverseSurface'] as int)
            : null,
        inversePrimary: json['inversePrimary'] != null
            ? Color(json['inversePrimary'] as int)
            : null,
        fontFamily: json['fontFamily'] as String?,
      );

  // Color scheme selection
  final FlexScheme? scheme;
  final FlexScheme? lightScheme;
  final FlexScheme? darkScheme;
  final FlexSchemeVariant? variant;

  // Color blending
  final int? blendLevel;
  final int? usedColors;

  // Dark theme specific
  final bool? darkIsTrueBlack;

  // Color swapping
  final bool? swapColors;
  final bool? swapLegacyColors;

  // Surface mode
  final FlexSurfaceMode? surfaceMode;

  // Custom colors
  final Color? primary;
  final Color? onPrimary;
  final Color? primaryContainer;
  final Color? onPrimaryContainer;
  final Color? secondary;
  final Color? onSecondary;
  final Color? secondaryContainer;
  final Color? onSecondaryContainer;
  final Color? tertiary;
  final Color? onTertiary;
  final Color? tertiaryContainer;
  final Color? onTertiaryContainer;
  final Color? error;
  final Color? onError;
  final Color? errorContainer;
  final Color? onErrorContainer;
  final Color? surface;
  final Color? onSurface;
  final Color? surfaceContainerHighest;
  final Color? onSurfaceVariant;
  final Color? outline;
  final Color? outlineVariant;
  final Color? shadow;
  final Color? scrim;
  final Color? inverseSurface;
  final Color? onInverseSurface;
  final Color? inversePrimary;

  // Typography
  final String? fontFamily;

  // Sub-themes
  final FlexSubThemes? subThemes;

  // ColorScheme override
  final ColorScheme? colorScheme;

  /// Create a copy with updated values
  FlexThemeSettingsModel copyWith({
    final FlexScheme? scheme,
    final FlexScheme? lightScheme,
    final FlexScheme? darkScheme,
    final FlexSchemeVariant? variant,
    final int? blendLevel,
    final int? usedColors,
    final bool? darkIsTrueBlack,
    final bool? swapColors,
    final bool? swapLegacyColors,
    final FlexSurfaceMode? surfaceMode,
    final Color? primary,
    final Color? onPrimary,
    final Color? primaryContainer,
    final Color? onPrimaryContainer,
    final Color? secondary,
    final Color? onSecondary,
    final Color? secondaryContainer,
    final Color? onSecondaryContainer,
    final Color? tertiary,
    final Color? onTertiary,
    final Color? tertiaryContainer,
    final Color? onTertiaryContainer,
    final Color? error,
    final Color? onError,
    final Color? errorContainer,
    final Color? onErrorContainer,
    final Color? surface,
    final Color? onSurface,
    final Color? surfaceContainerHighest,
    final Color? onSurfaceVariant,
    final Color? outline,
    final Color? outlineVariant,
    final Color? shadow,
    final Color? scrim,
    final Color? inverseSurface,
    final Color? onInverseSurface,
    final Color? inversePrimary,
    final String? fontFamily,
    final FlexSubThemes? subThemes,
    final ColorScheme? colorScheme,
    final bool? clearScheme,
    final bool? clearVariant,
    final bool? clearBlendLevel,
    final bool? clearUsedColors,
    final bool? clearDarkIsTrueBlack,
    final bool? clearSwapColors,
    final bool? clearSwapLegacyColors,
    final bool? clearSurfaceMode,
    final bool? clearFontFamily,
    final bool? clearSubThemes,
    final bool? clearColorScheme,
  }) =>
      FlexThemeSettingsModel(
        scheme: (clearScheme ?? false) ? null : (scheme ?? this.scheme),
        lightScheme: lightScheme ?? this.lightScheme,
        darkScheme: darkScheme ?? this.darkScheme,
        variant: (clearVariant ?? false) ? null : (variant ?? this.variant),
        blendLevel:
            (clearBlendLevel ?? false) ? null : (blendLevel ?? this.blendLevel),
        usedColors:
            (clearUsedColors ?? false) ? null : (usedColors ?? this.usedColors),
        darkIsTrueBlack: (clearDarkIsTrueBlack ?? false)
            ? null
            : (darkIsTrueBlack ?? this.darkIsTrueBlack),
        swapColors:
            (clearSwapColors ?? false) ? null : (swapColors ?? this.swapColors),
        swapLegacyColors: (clearSwapLegacyColors ?? false)
            ? null
            : (swapLegacyColors ?? this.swapLegacyColors),
        surfaceMode: (clearSurfaceMode ?? false)
            ? null
            : (surfaceMode ?? this.surfaceMode),
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        primaryContainer: primaryContainer ?? this.primaryContainer,
        onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
        secondary: secondary ?? this.secondary,
        onSecondary: onSecondary ?? this.onSecondary,
        secondaryContainer: secondaryContainer ?? this.secondaryContainer,
        onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
        tertiary: tertiary ?? this.tertiary,
        onTertiary: onTertiary ?? this.onTertiary,
        tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
        error: error ?? this.error,
        onError: onError ?? this.onError,
        errorContainer: errorContainer ?? this.errorContainer,
        onErrorContainer: onErrorContainer ?? this.onErrorContainer,
        surface: surface ?? this.surface,
        onSurface: onSurface ?? this.onSurface,
        surfaceContainerHighest:
            surfaceContainerHighest ?? this.surfaceContainerHighest,
        onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
        outline: outline ?? this.outline,
        outlineVariant: outlineVariant ?? this.outlineVariant,
        shadow: shadow ?? this.shadow,
        scrim: scrim ?? this.scrim,
        inverseSurface: inverseSurface ?? this.inverseSurface,
        onInverseSurface: onInverseSurface ?? this.onInverseSurface,
        inversePrimary: inversePrimary ?? this.inversePrimary,
        fontFamily:
            (clearFontFamily ?? false) ? null : (fontFamily ?? this.fontFamily),
        subThemes:
            (clearSubThemes ?? false) ? null : (subThemes ?? this.subThemes),
        colorScheme: (clearColorScheme ?? false)
            ? null
            : (colorScheme ?? this.colorScheme),
      );

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => <String, dynamic>{
        if (scheme != null) 'scheme': scheme!.index,
        if (lightScheme != null) 'lightScheme': lightScheme!.index,
        if (darkScheme != null) 'darkScheme': darkScheme!.index,
        if (variant != null) 'variant': variant!.index,
        if (blendLevel != null) 'blendLevel': blendLevel,
        if (usedColors != null) 'usedColors': usedColors,
        if (darkIsTrueBlack != null) 'darkIsTrueBlack': darkIsTrueBlack,
        if (swapColors != null) 'swapColors': swapColors,
        if (swapLegacyColors != null) 'swapLegacyColors': swapLegacyColors,
        if (surfaceMode != null) 'surfaceMode': surfaceMode!.index,
        if (primary != null) 'primary': primary!.value,
        if (onPrimary != null) 'onPrimary': onPrimary!.value,
        if (primaryContainer != null)
          'primaryContainer': primaryContainer!.value,
        if (onPrimaryContainer != null)
          'onPrimaryContainer': onPrimaryContainer!.value,
        if (secondary != null) 'secondary': secondary!.value,
        if (onSecondary != null) 'onSecondary': onSecondary!.value,
        if (secondaryContainer != null)
          'secondaryContainer': secondaryContainer!.value,
        if (onSecondaryContainer != null)
          'onSecondaryContainer': onSecondaryContainer!.value,
        if (tertiary != null) 'tertiary': tertiary!.value,
        if (onTertiary != null) 'onTertiary': onTertiary!.value,
        if (tertiaryContainer != null)
          'tertiaryContainer': tertiaryContainer!.value,
        if (onTertiaryContainer != null)
          'onTertiaryContainer': onTertiaryContainer!.value,
        if (error != null) 'error': error!.value,
        if (onError != null) 'onError': onError!.value,
        if (errorContainer != null) 'errorContainer': errorContainer!.value,
        if (onErrorContainer != null)
          'onErrorContainer': onErrorContainer!.value,
        if (surface != null) 'surface': surface!.value,
        if (onSurface != null) 'onSurface': onSurface!.value,
        if (surfaceContainerHighest != null)
          'surfaceContainerHighest': surfaceContainerHighest!.value,
        if (onSurfaceVariant != null)
          'onSurfaceVariant': onSurfaceVariant!.value,
        if (outline != null) 'outline': outline!.value,
        if (outlineVariant != null) 'outlineVariant': outlineVariant!.value,
        if (shadow != null) 'shadow': shadow!.value,
        if (scrim != null) 'scrim': scrim!.value,
        if (inverseSurface != null) 'inverseSurface': inverseSurface!.value,
        if (onInverseSurface != null)
          'onInverseSurface': onInverseSurface!.value,
        if (inversePrimary != null) 'inversePrimary': inversePrimary!.value,
        if (fontFamily != null) 'fontFamily': fontFamily,
      };

  /// Default settings
  static FlexThemeSettingsModel get defaults => FlexThemeSettingsModel();
}
