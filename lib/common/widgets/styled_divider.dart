import 'package:flutter/material.dart';

/// A styled divider with gradient effect for separating sections
/// Provides consistent visual separation across screens
class StyledDivider extends StatelessWidget {
  const StyledDivider({
    this.verticalPadding = 0,
    this.horizontalMargin = 16,
    this.height = 1,
    this.opacity = 0.3,
    super.key,
  });

  /// Vertical padding around the divider
  final double verticalPadding;

  /// Horizontal margin for the divider
  final double horizontalMargin;

  /// Height of the divider line
  final double height;

  /// Opacity of the divider color
  final double opacity;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Container(
        height: height,
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Colors.transparent,
              colorScheme.outlineVariant.withOpacity(opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}


