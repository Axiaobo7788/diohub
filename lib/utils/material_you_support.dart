import 'package:flutter/material.dart';

/// Utility class for checking Material You (dynamic color) support
///
/// The `dynamic_color` package doesn't provide a direct synchronous method
/// to check Material You support. Instead, support is determined by checking
/// if the ColorScheme values returned by DynamicColorBuilder are non-null.
class MaterialYouSupport {
  MaterialYouSupport._();

  /// Check if the device supports Material You dynamic colors
  ///
  /// This checks if both light and dark dynamic color schemes are available.
  /// Returns true if the device supports Material You (Android 12+ or iOS with
  /// dynamic color support).
  ///
  /// **Usage within DynamicColorBuilder:**
  /// ```dart
  /// DynamicColorBuilder(
  ///   builder: (lightDynamic, darkDynamic) {
  ///     final supportsMaterialYou = MaterialYouSupport.isSupported(
  ///       lightDynamic,
  ///       darkDynamic,
  ///     );
  ///
  ///     if (supportsMaterialYou) {
  ///       // Device supports Material You - use dynamic colors
  ///     } else {
  ///       // Fall back to custom theme
  ///     }
  ///   },
  /// )
  /// ```
  ///
  /// **Why this approach?**
  /// - `DynamicColorBuilder` automatically handles platform detection
  /// - Returns null ColorSchemes when Material You is not supported
  /// - This is the recommended way to check support per the package docs
  static bool isSupported(
    ColorScheme? lightDynamic,
    ColorScheme? darkDynamic,
  ) {
    return lightDynamic != null && darkDynamic != null;
  }

  /// Check if only light dynamic colors are available
  ///
  /// Some edge cases might only have light colors available
  static bool hasLightSupport(ColorScheme? lightDynamic) {
    return lightDynamic != null;
  }

  /// Check if only dark dynamic colors are available
  ///
  /// Some edge cases might only have dark colors available
  static bool hasDarkSupport(ColorScheme? darkDynamic) {
    return darkDynamic != null;
  }
}

