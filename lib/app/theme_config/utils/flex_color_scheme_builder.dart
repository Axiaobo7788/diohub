import 'package:diohub/app/theme_config/models/flex_theme_settings_model.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Utility class to build FlexColorScheme from settings model
class FlexColorSchemeBuilder {
  /// Build a FlexColorScheme.light from settings
  static FlexColorScheme buildLight({
    required final FlexThemeSettingsModel settings,
    final ColorScheme? dynamicColorScheme,
    final FlexSubThemesData? subThemesData,
    final FlexKeyColors? keyColors,
    final VisualDensity? visualDensity,
    final CupertinoThemeData? cupertinoOverrideTheme,
  }) {
    final FlexSubThemesData subThemes =
        subThemesData ?? const FlexSubThemesData();
    final FlexKeyColors keyColorsFinal = keyColors ?? const FlexKeyColors();
    final VisualDensity density =
        visualDensity ?? FlexColorScheme.comfortablePlatformDensity;
    final CupertinoThemeData cupertino = cupertinoOverrideTheme ??
        const CupertinoThemeData(applyThemeToAll: true);

    // Use dynamic color scheme if provided (takes precedence)
    if (dynamicColorScheme != null) {
      return FlexColorScheme.light(
        colorScheme: dynamicColorScheme,
        scheme: settings.scheme,
        variant: settings.variant,
        blendLevel: settings.blendLevel ?? 25,
        usedColors: settings.usedColors ?? 3,
        swapColors: settings.swapColors ?? false,
        surfaceMode: settings.surfaceMode,
        fontFamily: settings.fontFamily,
        subThemesData: subThemes,
        keyColors: keyColorsFinal,
        visualDensity: density,
        cupertinoOverrideTheme: cupertino,
        primary: settings.primary,
        onPrimary: settings.onPrimary,
        primaryContainer: settings.primaryContainer,
        onPrimaryContainer: settings.onPrimaryContainer,
        secondary: settings.secondary,
        onSecondary: settings.onSecondary,
        secondaryContainer: settings.secondaryContainer,
        onSecondaryContainer: settings.onSecondaryContainer,
        tertiary: settings.tertiary,
        onTertiary: settings.onTertiary,
        tertiaryContainer: settings.tertiaryContainer,
        onTertiaryContainer: settings.onTertiaryContainer,
        error: settings.error,
        onError: settings.onError,
        errorContainer: settings.errorContainer,
        onErrorContainer: settings.onErrorContainer,
        surface: settings.surface,
        onSurface: settings.onSurface,
      );
    }

    // Build with custom ColorScheme if provided
    if (settings.colorScheme != null) {
      return FlexColorScheme.light(
        colorScheme: settings.colorScheme,
        scheme: settings.scheme,
        variant: settings.variant,
        blendLevel: settings.blendLevel ?? 25,
        usedColors: settings.usedColors ?? 3,
        swapColors: settings.swapColors ?? false,
        surfaceMode: settings.surfaceMode,
        fontFamily: settings.fontFamily,
        subThemesData: subThemes,
        keyColors: keyColorsFinal,
        visualDensity: density,
        cupertinoOverrideTheme: cupertino,
        primary: settings.primary,
        onPrimary: settings.onPrimary,
        primaryContainer: settings.primaryContainer,
        onPrimaryContainer: settings.onPrimaryContainer,
        secondary: settings.secondary,
        onSecondary: settings.onSecondary,
        secondaryContainer: settings.secondaryContainer,
        onSecondaryContainer: settings.onSecondaryContainer,
        tertiary: settings.tertiary,
        onTertiary: settings.onTertiary,
        tertiaryContainer: settings.tertiaryContainer,
        onTertiaryContainer: settings.onTertiaryContainer,
        error: settings.error,
        onError: settings.onError,
        errorContainer: settings.errorContainer,
        onErrorContainer: settings.onErrorContainer,
        surface: settings.surface,
        onSurface: settings.onSurface,
      );
    }

    // Build with individual color parameters
    return FlexColorScheme.light(
      scheme: settings.scheme,
      variant: settings.variant,
      blendLevel: settings.blendLevel ?? 0,
      usedColors: settings.usedColors ?? 3,
      swapColors: settings.swapColors ?? false,
      surfaceMode: settings.surfaceMode,
      fontFamily: settings.fontFamily,
      subThemesData: subThemes,
      keyColors: keyColorsFinal,
      visualDensity: density,
      cupertinoOverrideTheme: cupertino,
      primary: settings.primary,
      onPrimary: settings.onPrimary,
      primaryContainer: settings.primaryContainer,
      onPrimaryContainer: settings.onPrimaryContainer,
      secondary: settings.secondary,
      onSecondary: settings.onSecondary,
      secondaryContainer: settings.secondaryContainer,
      onSecondaryContainer: settings.onSecondaryContainer,
      tertiary: settings.tertiary,
      onTertiary: settings.onTertiary,
      tertiaryContainer: settings.tertiaryContainer,
      onTertiaryContainer: settings.onTertiaryContainer,
      error: settings.error,
      onError: settings.onError,
      errorContainer: settings.errorContainer,
      onErrorContainer: settings.onErrorContainer,
      surface: settings.surface,
      onSurface: settings.onSurface,
    );
  }

  /// Build a FlexColorScheme.dark from settings
  static FlexColorScheme buildDark({
    required final FlexThemeSettingsModel settings,
    final ColorScheme? dynamicColorScheme,
    final FlexSubThemesData? subThemesData,
    final FlexKeyColors? keyColors,
    final VisualDensity? visualDensity,
    final CupertinoThemeData? cupertinoOverrideTheme,
  }) {
    final FlexSubThemesData subThemes =
        subThemesData ?? const FlexSubThemesData();
    final FlexKeyColors keyColorsFinal = keyColors ?? const FlexKeyColors();
    final VisualDensity density =
        visualDensity ?? FlexColorScheme.comfortablePlatformDensity;
    final CupertinoThemeData cupertino = cupertinoOverrideTheme ??
        const CupertinoThemeData(applyThemeToAll: true);

    // Use dynamic color scheme if provided (takes precedence)
    if (dynamicColorScheme != null) {
      return FlexColorScheme.dark(
        colorScheme: dynamicColorScheme,
        scheme: settings.scheme,
        variant: settings.variant,
        blendLevel: settings.blendLevel ?? 25,
        usedColors: settings.usedColors ?? 3,
        darkIsTrueBlack: settings.darkIsTrueBlack ?? false,
        swapColors: settings.swapColors ?? false,
        surfaceMode: settings.surfaceMode,
        fontFamily: settings.fontFamily,
        subThemesData: subThemes,
        keyColors: keyColorsFinal,
        visualDensity: density,
        cupertinoOverrideTheme: cupertino,
        primary: settings.primary,
        onPrimary: settings.onPrimary,
        primaryContainer: settings.primaryContainer,
        onPrimaryContainer: settings.onPrimaryContainer,
        secondary: settings.secondary,
        onSecondary: settings.onSecondary,
        secondaryContainer: settings.secondaryContainer,
        onSecondaryContainer: settings.onSecondaryContainer,
        tertiary: settings.tertiary,
        onTertiary: settings.onTertiary,
        tertiaryContainer: settings.tertiaryContainer,
        onTertiaryContainer: settings.onTertiaryContainer,
        error: settings.error,
        onError: settings.onError,
        errorContainer: settings.errorContainer,
        onErrorContainer: settings.onErrorContainer,
        surface: settings.surface,
        onSurface: settings.onSurface,
      );
    }

    // Build with custom ColorScheme if provided
    if (settings.colorScheme != null) {
      return FlexColorScheme.dark(
        colorScheme: settings.colorScheme,
        scheme: settings.scheme,
        variant: settings.variant,
        blendLevel: settings.blendLevel ?? 25,
        usedColors: settings.usedColors ?? 3,
        darkIsTrueBlack: settings.darkIsTrueBlack ?? false,
        swapColors: settings.swapColors ?? false,
        surfaceMode: settings.surfaceMode,
        fontFamily: settings.fontFamily,
        subThemesData: subThemes,
        keyColors: keyColorsFinal,
        visualDensity: density,
        cupertinoOverrideTheme: cupertino,
        primary: settings.primary,
        onPrimary: settings.onPrimary,
        primaryContainer: settings.primaryContainer,
        onPrimaryContainer: settings.onPrimaryContainer,
        secondary: settings.secondary,
        onSecondary: settings.onSecondary,
        secondaryContainer: settings.secondaryContainer,
        onSecondaryContainer: settings.onSecondaryContainer,
        tertiary: settings.tertiary,
        onTertiary: settings.onTertiary,
        tertiaryContainer: settings.tertiaryContainer,
        onTertiaryContainer: settings.onTertiaryContainer,
        error: settings.error,
        onError: settings.onError,
        errorContainer: settings.errorContainer,
        onErrorContainer: settings.onErrorContainer,
        surface: settings.surface,
        onSurface: settings.onSurface,
      );
    }

    // Build with individual color parameters
    return FlexColorScheme.dark(
      scheme: settings.scheme,
      variant: settings.variant,
      blendLevel: settings.blendLevel ?? 0,
      usedColors: settings.usedColors ?? 3,
      darkIsTrueBlack: settings.darkIsTrueBlack ?? false,
      swapColors: settings.swapColors ?? false,
      surfaceMode: settings.surfaceMode,
      fontFamily: settings.fontFamily,
      subThemesData: subThemes,
      keyColors: keyColorsFinal,
      visualDensity: density,
      cupertinoOverrideTheme: cupertino,
      primary: settings.primary,
      onPrimary: settings.onPrimary,
      primaryContainer: settings.primaryContainer,
      onPrimaryContainer: settings.onPrimaryContainer,
      secondary: settings.secondary,
      onSecondary: settings.onSecondary,
      secondaryContainer: settings.secondaryContainer,
      onSecondaryContainer: settings.onSecondaryContainer,
      tertiary: settings.tertiary,
      onTertiary: settings.onTertiary,
      tertiaryContainer: settings.tertiaryContainer,
      onTertiaryContainer: settings.onTertiaryContainer,
      error: settings.error,
      onError: settings.onError,
      errorContainer: settings.errorContainer,
      onErrorContainer: settings.onErrorContainer,
      surface: settings.surface,
      onSurface: settings.onSurface,
    );
  }
}
