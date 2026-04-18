import 'package:flutter/material.dart';

/// Opacity scale — semantic names for consistent transparency levels across the app.
///
/// These are perceptual constants that work across light and dark themes because
/// the base colors already adapt. Users typically don't need to customize these.
abstract final class Opacities {
  // ── Surface tints (color used as background fill) ──────────
  /// Shadows, shimmer bases (faintest visible overlay)
  static const double faint = 0.06;

  /// Very faint wash (tab indicator background, subtle overlays)
  static const double tintSubtle = 0.08;

  /// Subtle overlays/borders (barely visible)
  static const double subtle = 0.10;

  /// Standard tinted background (chips, badges, selected rows)
  static const double tint = 0.12;

  /// Medium tint overlays (moderate background emphasis)
  static const double tintMedium = 0.15;

  /// Prominent tinted surface (hover/pressed states, strong emphasis)
  static const double tintStrong = 0.20;

  // ── Borders ────────────────────────────────────────────────
  /// Barely visible structural lines (grid lines, chart axes)
  static const double borderSubtle = 0.12;

  /// Standard border (chip outlines, card borders, dividers)
  static const double border = 0.30;

  /// Prominent border (active outlines, highlighted dividers)
  static const double borderStrong = 0.50;

  // ── Text/Icon emphasis ─────────────────────────────────────
  /// Disabled / inactive text and icons (follows Material spec)
  static const double disabled = 0.38;

  /// Placeholder text, hint text, unselected tab labels
  static const double hint = 0.50;

  /// Tertiary labels, medium emphasis (avoids 'tertiary' name conflict)
  static const double muted = 0.60;

  /// Subtitles, metadata, secondary labels
  static const double secondary = 0.70;

  /// High emphasis text on backgrounds
  static const double strong = 0.80;

  /// Near-opaque, active text on tinted backgrounds
  static const double emphasized = 0.90;

  // ── Scrim / overlay ────────────────────────────────────────
  /// Popup/menu barrier overlay
  static const double scrim = 0.30;
}

/// Extension providing semantic opacity methods on Color
extension OpacityTokens on Color {
  // Surface tints
  Color get faint => withValues(alpha: Opacities.faint);
  Color get tintSubtle => withValues(alpha: Opacities.tintSubtle);
  Color get subtle => withValues(alpha: Opacities.subtle);
  Color get tint => withValues(alpha: Opacities.tint);
  Color get tintMedium => withValues(alpha: Opacities.tintMedium);
  Color get tintStrong => withValues(alpha: Opacities.tintStrong);

  // Borders
  Color get borderSubtle => withValues(alpha: Opacities.borderSubtle);
  Color get borderO => withValues(alpha: Opacities.border);
  Color get borderStrong => withValues(alpha: Opacities.borderStrong);

  // Text/Icon emphasis
  Color get disabled => withValues(alpha: Opacities.disabled);
  Color get hinted => withValues(alpha: Opacities.hint);
  Color get muted => withValues(alpha: Opacities.muted);
  Color get secondary => withValues(alpha: Opacities.secondary);
  Color get strong => withValues(alpha: Opacities.strong);
  Color get emphasized => withValues(alpha: Opacities.emphasized);

  // Scrim/overlay
  Color get scrim => withValues(alpha: Opacities.scrim);
}
