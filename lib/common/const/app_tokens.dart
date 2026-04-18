import 'package:flutter/material.dart';

/// Centralized app tokens for DioHub.
///
/// Single source of truth for colors, typography, and app-specific constants.
/// All app-related widgets should compose from these tokens.
abstract final class AppTokens {
  const AppTokens._();

  /// The canonical dark background color used in splash screens and dark themes.
  /// Matches the native splash screen background (#17181C).
  static const Color backgroundDark = Color(0xFF17181C);

  /// Canonical app name text span builder.
  ///
  /// Renders "DIO" in regular weight and "HUB" in bold.
  /// Use this anywhere the app name appears to ensure consistency.
  static InlineSpan appNameSpan({TextStyle? style}) => TextSpan(
        children: <InlineSpan>[
          TextSpan(text: 'DIO', style: style),
          TextSpan(
            text: 'HUB',
            style: style?.copyWith(fontWeight: FontWeight.bold) ??
                const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );
}
