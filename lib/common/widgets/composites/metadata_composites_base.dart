import 'package:diohub/common/misc/inline_container.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class MetadataGroupCard extends StatelessWidget {
  const MetadataGroupCard({
    required this.children,
    this.title,
    this.subtitle,
    this.padding,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry? padding;
  final List<Widget> children;

  @override
  Widget build(final BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final AppSpacing spacing = context.spacing;
    final Widget card = InlineContainer(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null && title!.isNotEmpty) ...<Widget>[
            Padding(
              padding: spacing.metadataRowPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.colorScheme.onSurface,
                        ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                    spacing.tightGap,
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                context.colorScheme.onSurfaceVariant.secondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          ...children,
        ],
      ),
    );
    return card;
  }
}

class MetadataSectionSpacer extends StatelessWidget {
  const MetadataSectionSpacer({super.key});

  @override
  Widget build(final BuildContext context) => context.spacing.itemGap;
}

class MetadataBadgeChip {
  const MetadataBadgeChip({
    required this.label,
    required this.color,
    required this.icon,
    this.priority = 100,
  });

  final String label;
  final Color color;
  final IconData icon;
  final int priority;
}

/// Adaptive badge flow for constrained headers.
///
/// If [compact] is true, chips stay on one line with overflow summarized as +N.
class MetadataBadgeFlow extends StatelessWidget {
  const MetadataBadgeFlow({
    required this.badges,
    this.compact = false,
    this.padding,
    super.key,
  });

  final List<MetadataBadgeChip> badges;
  final bool compact;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(final BuildContext context) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<MetadataBadgeChip> sorted = List<MetadataBadgeChip>.from(badges)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final AppSpacing spacing = context.spacing;
    final EdgeInsetsGeometry effectivePadding = padding ?? EdgeInsets.zero;

    if (!compact) {
      return Padding(
        padding: effectivePadding,
        child: Wrap(
          spacing: spacing.tightSpacing,
          runSpacing: spacing.compactSpacing,
          children: sorted
              .map(
                (final MetadataBadgeChip chip) => TintedChip(
                  color: chip.color,
                  icon: chip.icon,
                  label: chip.label,
                  border: true,
                ),
              )
              .toList(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final List<double> widths = sorted
            .map((final MetadataBadgeChip badge) =>
                _estimateCompactChipWidth(context, badge))
            .toList();

        int visible = 0;
        double used = 0;
        for (int i = 0; i < sorted.length; i += 1) {
          final int remainingAfterCurrent = sorted.length - (i + 1);
          final double leadingSpace = visible == 0 ? 0 : spacing.tightSpacing;
          final double nextUsed = used + leadingSpace + widths[i];
          double reservedForOverflow = 0;
          if (remainingAfterCurrent > 0) {
            reservedForOverflow = spacing.tightSpacing +
                _estimateOverflowChipWidth(context, remainingAfterCurrent);
          }
          if (nextUsed + reservedForOverflow <= maxWidth || visible == 0) {
            used = nextUsed;
            visible += 1;
            continue;
          }
          break;
        }

        final int remaining = sorted.length - visible;
        final List<Widget> chips = <Widget>[
          ...sorted.take(visible).map(
                (final MetadataBadgeChip chip) => TintedChip(
                  color: chip.color,
                  icon: chip.icon,
                  label: chip.label,
                  border: true,
                  size: RadiusSize.small,
                  iconSize: 10,
                  padding: spacing.badgePadding,
                ),
              ),
          if (remaining > 0)
            TintedChip(
              color: context.colorScheme.onSurfaceVariant,
              icon: Icons.add_rounded,
              label: '$remaining',
              border: true,
              iconSize: 10,
              padding: spacing.badgePadding,
            ),
        ];

        return Padding(
          padding: effectivePadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < chips.length; i += 1) ...<Widget>[
                chips[i],
                if (i != chips.length - 1)
                  SizedBox(width: spacing.tightSpacing),
              ],
            ],
          ),
        );
      },
    );
  }

  double _estimateCompactChipWidth(
    final BuildContext context,
    final MetadataBadgeChip chip,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: chip.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final AppSpacing spacing = context.spacing;
    return painter.width +
        spacing.badgePadding.horizontal +
        spacing.tightSpacing +
        14;
  }

  double _estimateOverflowChipWidth(
      final BuildContext context, final int count) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final AppSpacing spacing = context.spacing;
    return painter.width +
        spacing.badgePadding.horizontal +
        spacing.tightSpacing +
        14;
  }
}

/// Single check run row: name + conclusion icon + color. Tappable when [detailsUrl] is set.
