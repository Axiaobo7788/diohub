import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Shared section label for popup menus, toolbar categories, and peek overlays.
///
/// Use for "Manage", "Share & copy", "Quick actions", or category labels.
/// Typography and padding use [AppSpacing] from theme.
class PopupSectionLabel extends StatelessWidget {
  const PopupSectionLabel({
    required this.label,
    this.icon,
    super.key,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = context.colorScheme;
    final AppSpacing spacing = context.spacing;
    final TextStyle? textStyle = theme.textTheme.labelMedium ??
        theme.textTheme.titleSmall?.copyWith(fontSize: 12);
    final TextStyle? effectiveStyle = textStyle?.copyWith(
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
      fontWeight: FontWeight.w600,
    );

    final EdgeInsets padding = EdgeInsets.only(
      left: spacing.tightSpacing,
      top: spacing.sectionTitlePaddingMedium.top,
      bottom: spacing.sectionTitlePaddingMedium.bottom,
    );

    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            SizedBox(width: spacing.tightSpacing),
          ],
          Flexible(
            child: Text(
              label,
              style: effectiveStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
