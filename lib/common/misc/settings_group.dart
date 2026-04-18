import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Card/group container for a list of setting rows.
///
/// Uses theme surface and radius so settings and onboarding share the same look.
/// Children are stacked vertically with optional dividers between them.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    required this.children,
    super.key,
    this.showDividers = true,
  });

  final List<Widget> children;
  final bool showDividers;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final BorderRadius borderRadius = context.radius(RadiusSize.medium);

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: borderRadius,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildChildrenWithDividers(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final List<Widget> out = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0 && showDividers) {
        out.add(
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        );
      }
      out.add(children[i]);
    }
    return out;
  }
}
