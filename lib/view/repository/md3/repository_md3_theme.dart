import 'package:flutter/material.dart';

/// A deliberately small MD3 layer for newly migrated repository pages.
///
/// It keeps the app's active [ColorScheme] and extensions so existing leaf
/// widgets continue to work, while resetting the page's core Material widgets
/// to SDK defaults. Future visual customization can remain centralized here.
ThemeData repositoryMd3ThemeFor(final ThemeData base) {
  final ThemeData material3 = ThemeData.from(
    colorScheme: base.colorScheme,
    textTheme: base.textTheme,
    useMaterial3: true,
  );
  return material3.copyWith(
    extensions: base.extensions.values,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      backgroundColor: base.colorScheme.surface,
      foregroundColor: base.colorScheme.onSurface,
      surfaceTintColor: base.colorScheme.surfaceTint,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    cardTheme: const CardThemeData(),
    dividerTheme: DividerThemeData(
      color: base.colorScheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
  );
}
