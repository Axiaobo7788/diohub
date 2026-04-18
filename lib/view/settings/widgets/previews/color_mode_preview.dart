import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/style/app_spacing.dart';

/// Compact preview of the current color scheme: swatches + mock card.
class ColorModePreview extends ConsumerWidget {
  const ColorModePreview({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppSpacing spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _ColorSwatch(color: colorScheme.primary, label: 'Primary'),
            _ColorSwatch(color: colorScheme.secondary, label: 'Secondary'),
            _ColorSwatch(color: colorScheme.tertiary, label: 'Tertiary'),
            _ColorSwatch(
                color: colorScheme.primaryContainer, label: 'Primary container'),
            _ColorSwatch(
                color: colorScheme.secondaryContainer,
                label: 'Secondary container'),
            _ColorSwatch(color: colorScheme.surface, label: 'Surface'),
          ],
        ),
        SizedBox(height: spacing.tightSpacing),
        Container(
          padding: spacing.cardContentPadding,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Preview Title',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                'Sample body text that inherits the current theme.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(final BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            backgroundColor: color,
          ),
          context.spacing.tightGap,
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
}
