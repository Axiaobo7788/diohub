import 'package:built_collection/built_collection.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

extension ThemeExtension on BuildContext {
  ThemeData get themeData => Theme.of(this);
  ColorScheme get colorScheme => themeData.colorScheme;

  TextTheme get textTheme => themeData.textTheme;
  SurfaceStyle get surface => themeData.surface;
}

extension TextStyles on TextStyle {
  TextStyle asMuted() => copyWith(
        color: color?.withValues(alpha: 0.60),
      );

  TextStyle asBold() => copyWith(
        fontWeight: FontWeight.bold,
      );
  TextStyle asDisabled() => copyWith(
        color: color?.withValues(alpha: 0.38),
      );
}


extension IconSize on TextStyle {
  double getIconSize(final BuildContext context, {final double scale = 0.7}) {
    final textScaler = MediaQuery.textScalerOf(context);
    final double adjustedScaleFactor = textScaler.scale(1.0) * scale;
    final double scaledSize =
        fontSize != null ? fontSize! * adjustedScaleFactor : 25;

    return scaledSize;
  }
}


extension ColorFader on Color {
  Color fadeBrightness(final double factor) {
    assert(
      factor >= -1.0 && factor <= 1.0,
      'Factor value must be between -1.0 and 1.0',
    );

    final HSLColor hslColor = HSLColor.fromColor(this);
    final HSLColor newHslColor = hslColor.withLightness(
      (hslColor.lightness + factor).clamp(0.0, 1.0),
    );
    return newHslColor.toColor();
  }
}

T returnItself<T>(final T data) => data;

extension StringIntp on int {
  String toShortenedStr() {
    if (this >= 1000000) {
      final double millions = this / 1000000;
      // If it's a whole number, show without decimal
      if (millions == millions.truncateToDouble()) {
        return '${millions.toInt()}M';
      }
      // Otherwise show one decimal place
      return '${millions.toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      final double thousands = this / 1000;
      // If it's a whole number, show without decimal
      if (thousands == thousands.truncateToDouble()) {
        return '${thousands.toInt()}k';
      }
      // Otherwise show one decimal place
      return '${thousands.toStringAsFixed(1)}k';
    }
    return toString();
  }
}

