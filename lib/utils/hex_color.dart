import 'package:flutter/material.dart';

/// Safely parses a hex color string to a Flutter Color.
///
/// Accepts hex strings with or without the '#' prefix.
/// Returns the parsed color with full opacity (alpha = 0xFF).
/// If parsing fails or the hex string is invalid, returns the [fallback] color.
///
/// Examples:
/// ```dart
/// tryParseHexColor('#40C463') // Color(0xFF40C463)
/// tryParseHexColor('40C463')  // Color(0xFF40C463)
/// tryParseHexColor('invalid', fallback: Colors.grey) // Colors.grey
/// ```
Color? tryParseHexColor(String hex, {Color? fallback}) {
  final s = hex.startsWith('#') ? hex.substring(1) : hex;
  if (s.length != 6) return fallback;
  final v = int.tryParse(s, radix: 16);
  if (v == null) return fallback;
  return Color(0xFF000000 | v);
}

/// Converts a hex string with dashes to an integer string.
///
/// Used for converting UUID-style hex strings to numeric representations.
/// Removes dashes and converts each 8-character chunk to a decimal number.
///
/// Example:
/// ```dart
/// hexToInt('a1b2c3d4-e5f6-7890-abcd-ef1234567890')
/// // Returns concatenated decimal representations
/// ```
String hexToInt(final String fullString) {
  final String string = fullString.replaceAll('-', '');
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i <= string.length - 8; i += 8) {
    final String hex = string.substring(i, i + 8);
    final int number = int.parse(hex, radix: 16);
    buffer.write(number);
  }
  return buffer.toString();
}
