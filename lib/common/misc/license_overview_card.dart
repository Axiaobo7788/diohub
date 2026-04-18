import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A display-only rule entry for license overview (key + label).
typedef LicenseRuleDisplay = ({String key, String label});

/// Reusable card that shows license description and the three rule groups
/// (permissions, conditions, limitations). Used in popups, file viewer banner,
/// and license tab.
///
/// If [description] and all three rule lists are null or empty (e.g. pseudo-license),
/// returns [SizedBox.shrink] so callers don't show empty boxes.
class LicenseOverviewCard extends StatelessWidget {
  const LicenseOverviewCard({
    super.key,
    this.description,
    this.permissions,
    this.conditions,
    this.limitations,
  });

  final String? description;
  final List<LicenseRuleDisplay>? permissions;
  final List<LicenseRuleDisplay>? conditions;
  final List<LicenseRuleDisplay>? limitations;

  bool get _hasContent =>
      (description != null && description!.trim().isNotEmpty) ||
      (permissions != null && permissions!.isNotEmpty) ||
      (conditions != null && conditions!.isNotEmpty) ||
      (limitations != null && limitations!.isNotEmpty);

  @override
  Widget build(final BuildContext context) {
    if (!_hasContent) return const SizedBox.shrink();

    final AppSpacing spacing = context.spacing;
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = context.colorScheme;

    final List<Widget> children = <Widget>[];

    if (description != null && description!.trim().isNotEmpty) {
      children.add(
        Text(
          description!.trim(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface,
          ),
        ),
      );
      children.add(spacing.sectionGap);
    }

    children.add(
      _RuleSection(
        title: 'Permissions',
        icon: Octicons.check_circle,
        color: Colors.green.shade700,
        rules: permissions ?? const <LicenseRuleDisplay>[],
      ),
    );
    children.add(spacing.compactGap);
    children.add(
      _RuleSection(
        title: 'Conditions',
        icon: Octicons.info,
        color: cs.primary,
        rules: conditions ?? const <LicenseRuleDisplay>[],
      ),
    );
    children.add(spacing.compactGap);
    children.add(
      _RuleSection(
        title: 'Limitations',
        icon: Octicons.alert,
        color: cs.error,
        rules: limitations ?? const <LicenseRuleDisplay>[],
      ),
    );

    return Padding(
      padding: spacing.contentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.rules,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<LicenseRuleDisplay> rules;

  @override
  Widget build(final BuildContext context) {
    if (rules.isEmpty) return const SizedBox.shrink();

    final AppSpacing spacing = context.spacing;
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = context.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: color),
            spacing.tightGap,
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.strong,
              ),
            ),
          ],
        ),
        spacing.tightGap,
        Wrap(
          spacing: spacing.tightSpacing,
          runSpacing: spacing.tightSpacing,
          children: rules
              .map(
                (final LicenseRuleDisplay r) => Text(
                  r.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.secondary,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
