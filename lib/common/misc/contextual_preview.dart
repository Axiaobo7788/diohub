import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Standardized preview container used by [SettingsSection] and [OnboardingSection].
///
/// Renders a compact, live-updating preview above the settings it illustrates.
/// Uses theme surface and spacing; supports optional gradient overlay for
/// surface-style previews.
class ContextualPreview extends StatelessWidget {
  const ContextualPreview({
    required this.child,
    super.key,
    this.gradient,
  });

  final Widget child;

  /// Optional gradient overlay (e.g. for surface preview with primaryContainer × secondaryContainer).
  final Gradient? gradient;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;
    final BorderRadius borderRadius = context.radius(RadiusSize.medium);

    return AnimatedSize(
      duration: kMicroDuration,
      curve: kMicroCurve,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: <Widget>[
              if (gradient != null)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: gradient),
                  ),
                ),
              Padding(
                padding: spacing.cardContentPadding,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
