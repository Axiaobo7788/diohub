import 'package:diohub/common/misc/liquid_glass_wrapper.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// Content widget for the entity info popup shown when tapping the entity
/// in the collapse bar.
///
/// Renders identity header and metadata sections only. Entity actions
/// (Star, Fork, Refresh, etc.) are in the collapse bar kebab menu.
class EntityInfoContent extends StatelessWidget {
  const EntityInfoContent({
    required this.entity,
    this.onDismiss,
    super.key,
  });

  final EntityConfig entity;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.6;
    return LiquidGlassWrapper(
      size: RadiusSize.large,
      child: Padding(
        padding: EdgeInsets.all(spacing.itemSpacing),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EntityIdentityHeader(entity: entity),
                ...entity.metadataSections
                    .where((s) => s.visibleWhen?.call() ?? true)
                    .map((s) => _buildMetadataSection(context, s)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataSection(
    BuildContext context,
    MetadataSectionData section,
  ) {
    final spacing = context.spacing;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(
        top: spacing.sectionSpacing,
        left: spacing.screenPadding.left,
        right: spacing.screenPadding.right,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(section.icon,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              spacing.tightGap,
              Text(
                section.title,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (section.statRail != null) ...[
            SizedBox(height: spacing.tightSpacing),
            section.statRail!,
          ],
          if (section.children.isNotEmpty) ...[
            SizedBox(height: spacing.itemSpacing),
            ...section.children.asMap().entries.expand((entry) => [
                  if (entry.key > 0) SizedBox(height: spacing.itemSpacing),
                  entry.value,
                ]),
          ],
        ],
      ),
    );
  }
}

class _EntityIdentityHeader extends StatelessWidget {
  const _EntityIdentityHeader({required this.entity});

  final EntityConfig entity;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.screenPadding.left,
        spacing.sectionSpacing,
        spacing.screenPadding.right,
        spacing.compactSpacing,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (entity.leading != null) ...[
                entity.leading!,
                SizedBox(width: spacing.itemSpacing),
              ],
              Expanded(child: entity.title),
            ],
          ),
          if (entity.subtitle != null) ...[
            SizedBox(height: spacing.tightSpacing),
            entity.subtitle!,
          ],
          if (entity.statusIndicators != null) ...[
            SizedBox(height: spacing.tightSpacing),
            entity.statusIndicators!,
          ],
        ],
      ),
    );
  }
}
