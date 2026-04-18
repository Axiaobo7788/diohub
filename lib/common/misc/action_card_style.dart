import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Configurable styling for ActionCard
///
/// Defines visual appearance: background, border, shadow, padding, etc.
/// All styling is always applied - no conditional rendering.
class ActionCardStyle {
  const ActionCardStyle({
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadiusSize = RadiusSize.medium,
    this.borderOpacity = 0.1,
    this.borderWidth = 0.5,
    this.shadowOpacity = 0.0,
    this.shadowBlurRadius = 6.0,
    this.shadowOffset = const Offset(0, 2),
    this.backgroundColor,
  });

  final EdgeInsets padding;
  final RadiusSize borderRadiusSize;
  final double borderOpacity;
  final double borderWidth;
  final double shadowOpacity;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final Color? backgroundColor; // Override background color

  /// Preset for popup menu actions
  static const ActionCardStyle popup = ActionCardStyle();

  /// Preset for primary popup actions (Star, Fork, Watch, Follow, etc.)
  static const ActionCardStyle primaryPopup = ActionCardStyle(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  /// Preset for utility popup actions (Copy URL, Share, Open in Browser).
  /// Takes [context] so padding uses [AppSpacing.screenPadding].
  static ActionCardStyle utilityPopup(final BuildContext context) =>
      ActionCardStyle(
        padding: context.spacing.screenPadding,
        shadowBlurRadius: 0,
        shadowOffset: Offset.zero,
      );

  /// Preset for toolbar prominent actions (collapsed state)
  static const ActionCardStyle toolbar = ActionCardStyle();

  /// Preset for expanded toolbar actions (horizontal scrollable row)
  /// Matches legacy prominent action button padding
  static const ActionCardStyle toolbarExpanded = ActionCardStyle(
    shadowOpacity: 0.06,
    borderOpacity: 0.16,
    borderWidth: 0.6,
  );

  /// Preset for compact icon-only buttons
  static const ActionCardStyle compact = ActionCardStyle(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  );

  /// Preset for settings and onboarding rows (cards, toggles, dropdowns)
  static const ActionCardStyle settings = ActionCardStyle(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    borderRadiusSize: RadiusSize.medium,
    shadowOpacity: 0,
    shadowBlurRadius: 0,
    borderOpacity: 0.08,
    borderWidth: 0.5,
  );

  ActionCardStyle copyWith({
    final EdgeInsets? padding,
    final RadiusSize? borderRadiusSize,
    final double? borderOpacity,
    final double? borderWidth,
    final double? shadowOpacity,
    final double? shadowBlurRadius,
    final Offset? shadowOffset,
    final Color? backgroundColor,
  }) =>
      ActionCardStyle(
        padding: padding ?? this.padding,
        borderRadiusSize: borderRadiusSize ?? this.borderRadiusSize,
        borderOpacity: borderOpacity ?? this.borderOpacity,
        borderWidth: borderWidth ?? this.borderWidth,
        shadowOpacity: shadowOpacity ?? this.shadowOpacity,
        shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
        shadowOffset: shadowOffset ?? this.shadowOffset,
        backgroundColor: backgroundColor ?? this.backgroundColor,
      );
}
