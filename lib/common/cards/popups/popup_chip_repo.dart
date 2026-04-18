import 'package:diohub/common/cards/popups/popup_chip_template.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/misc/license_overview_card.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

Widget buildLicensePopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final String spdxId,
  final String? fullName,
  final String? description,
  final List<LicenseRuleDisplay>? permissions,
  final List<LicenseRuleDisplay>? conditions,
  final List<LicenseRuleDisplay>? limitations,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final List<Widget> children = <Widget>[
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Octicons.law, size: 16, color: cs.primary),
        spacing.compactGap,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                fullName ?? spdxId,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.strong,
                ),
              ),
              spacing.compactGap,
              Text(
                'SPDX: $spdxId',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ];
  final bool hasOverview =
      (description != null && description.trim().isNotEmpty) ||
          (permissions != null && permissions.isNotEmpty) ||
          (conditions != null && conditions.isNotEmpty) ||
          (limitations != null && limitations.isNotEmpty);
  if (hasOverview) {
    children.add(spacing.sectionGap);
    children.add(
      LicenseOverviewCard(
        description: description,
        permissions: permissions,
        conditions: conditions,
        limitations: limitations,
      ),
    );
  }
  return PopupContentTemplate(
    context,
    children: children,
    onDismiss: onDismiss,
  );
}

/// Builds popup content for sub-issue progress: 24px ring + "X of Y sub-issues completed" + percentage.

class LanguageBarItem {
  const LanguageBarItem({
    required this.name,
    this.colorHex,
    required this.size,
  });
  final String name;
  final String? colorHex;
  final int size;
}

/// Builds popup content for repo language chip: horizontal multi-color distribution bar + per-language rows (color dot, name, percentage).
Widget buildLanguagePopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final List<LanguageBarItem> languages,
}) {
  if (languages.isEmpty) {
    return PopupContentTemplate(
      context,
      children: <Widget>[
        Text(
          'No language data',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant.secondary,
              ),
        ),
      ],
      onDismiss: onDismiss,
    );
  }
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final int total = languages.fold<int>(
      0, (final int sum, final LanguageBarItem e) => sum + e.size);
  final List<Widget> children = <Widget>[];
  if (total > 0) {
    children.add(
      Padding(
        padding: EdgeInsets.only(bottom: spacing.tightSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Language distribution',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.secondary,
              ),
            ),
            spacing.tightGap,
            ClipRRect(
              borderRadius: context.radius(RadiusSize.small),
              child: SizedBox(
                height: 8,
                width: double.infinity,
                child: Row(
                  children: languages
                      .map(
                        (final LanguageBarItem e) => Expanded(
                          flex: e.size.clamp(1, 0x7fffffff),
                          child: Container(
                            color: e.colorHex != null && e.colorHex!.isNotEmpty
                                ? tryParseHexColor(e.colorHex!, fallback: const Color(0xFF6B7280))!
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  for (final LanguageBarItem e in languages) {
    final double pct = total > 0 ? (e.size / total * 100) : 0.0;
    final Color color = e.colorHex != null && e.colorHex!.isNotEmpty
        ? tryParseHexColor(e.colorHex!, fallback: const Color(0xFF6B7280))!
        : cs.onSurfaceVariant;
    children.add(
      Padding(
        padding: EdgeInsets.only(bottom: spacing.tightSpacing),
        child: Row(
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            spacing.tightGap,
            Expanded(
              child: Text(
                e.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.strong,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${pct.toStringAsFixed(1)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  return PopupContentTemplate(
    context,
    children: children,
    onDismiss: onDismiss,
  );
}

/// Builds popup content for diff chip: distribution bar, commit count, file count, "View Changes" action.

Widget buildForkSourcePopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final String repoName,
  required final String ownerLogin,
  final VoidCallback? onViewRepository,
  final String? description,
  final int? starCount,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final List<Widget> content = <Widget>[
    Text(
      '$ownerLogin / $repoName',
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: cs.onSurface.strong,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  ];
  if (starCount != null) {
    content.addAll(<Widget>[
      spacing.compactGap,
      Row(
        children: <Widget>[
          Icon(Octicons.star, size: 14, color: cs.onSurfaceVariant.emphasized),
          spacing.tightGap,
          Text(
            _formatCount(starCount),
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.secondary,
            ),
          ),
        ],
      ),
    ]);
  }
  if (description != null && description.isNotEmpty) {
    content.addAll(<Widget>[
      spacing.compactGap,
      Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant.secondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ]);
  }
  return PopupContentTemplate(
    context,
    children: content,
    actionLabel: 'View Repository',
    onAction: onViewRepository,
    onDismiss: onDismiss,
  );
}

String _formatCount(final int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}
