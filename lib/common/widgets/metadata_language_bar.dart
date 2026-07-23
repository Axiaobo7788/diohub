import 'package:diohub/common/animations/animated_gradient_bar.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data for a single language in the repo language bar.
class LanguageBarEntry {
  const LanguageBarEntry({
    required this.name,
    required this.color,
    required this.size,
  });

  final String name;
  final String color;
  final int size;
}

/// Horizontal stacked bar + legend for repository languages (top 4–5, rest as "Other").
class MetadataLanguageBar extends StatelessWidget {
  const MetadataLanguageBar({
    required this.entries,
    this.maxVisible = 5,
    super.key,
  });

  final List<LanguageBarEntry> entries;
  final int maxVisible;

  @override
  Widget build(final BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final int total = entries.fold<int>(
      0,
      (final int sum, final LanguageBarEntry e) => sum + e.size,
    );
    if (total == 0) {
      return const SizedBox.shrink();
    }

    final List<LanguageBarEntry> visible = entries.take(maxVisible).toList();
    final int otherSize = entries.length > maxVisible
        ? entries
              .skip(maxVisible)
              .fold<int>(
                0,
                (final int s, final LanguageBarEntry e) => s + e.size,
              )
        : 0;

    final List<LanguageBarEntry> forBar = List<LanguageBarEntry>.from(visible);
    if (otherSize > 0) {
      forBar.add(
        LanguageBarEntry(
          name: context.l10n.repoOtherLanguages,
          color: '#6e7681',
          size: otherSize,
        ),
      );
    }
    final int barTotal = forBar.fold<int>(
      0,
      (final int sum, final LanguageBarEntry e) => sum + e.size,
    );
    if (barTotal == 0) {
      return const SizedBox.shrink();
    }

    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Widget barRow = Row(
      children: forBar.map((final LanguageBarEntry e) {
        final Color color = _parseColor(e.color, colorScheme);
        return Expanded(
          flex: e.size,
          child: ClipRRect(
            borderRadius: context.radius(RadiusSize.small),
            child: Container(height: 6, color: color),
          ),
        );
      }).toList(),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Consumer(
            builder:
                (final BuildContext context, final WidgetRef ref, final _) =>
                    AnimatedGradientBar(child: barRow),
          ),
          context.spacing.itemGap,
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              ...visible.map((final LanguageBarEntry e) {
                final Color color = _parseColor(e.color, colorScheme);
                final int pct = (e.size * 100 / total).round();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    context.spacing.tightGap,
                    Text(
                      '${e.name} $pct%',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.secondary,
                      ),
                    ),
                  ],
                );
              }),
              if (otherSize > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _parseColor('#6e7681', colorScheme),
                        shape: BoxShape.circle,
                      ),
                    ),
                    context.spacing.tightGap,
                    Text(
                      '${context.l10n.repoOtherLanguages} '
                      '${(otherSize * 100 / total).round()}%',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.secondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _parseColor(final String hex, final ColorScheme colorScheme) {
    return tryParseHexColor(hex, fallback: colorScheme.primary) ??
        colorScheme.primary;
  }
}
