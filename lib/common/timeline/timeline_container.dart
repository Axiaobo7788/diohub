import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';

/// Reusable container widget for timeline content items
/// Provides consistent styling across all timeline content widgets
class TimelineContainer extends StatelessWidget {
  const TimelineContainer({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: Theme.of(context).surfaceStyle.borderRadius(
          size: BorderRadiusSize.small,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

