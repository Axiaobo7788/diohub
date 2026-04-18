import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// A settings section container with header, optional danger zone styling,
/// and optional visibility predicate.
///
/// Used inside [SettingsBody.sections] to group related rows.
/// The [NavCenterShell] renders sections in a [ListView] separated
/// by [sectionGap] (16dp).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
    this.icon,
    this.description,
    this.visibleWhen,
    this.isDangerZone = false,
  });

  /// Section header title.
  final String title;

  /// Row widgets inside the section (typically [SettingsToggleRow],
  /// [SettingsEnumRow], etc.). Separated by dividers.
  final List<Widget> children;

  /// Icon displayed before the title. Overridden by danger icon when
  /// [isDangerZone] is true.
  final IconData? icon;

  /// Short description displayed after the title.
  final String? description;

  /// When non-null, the entire section is hidden when this returns false.
  /// Evaluated at build time.
  final bool Function()? visibleWhen;

  /// When true, the section has a red/error-tinted border and a warning
  /// icon in the header. Used for irreversible actions (delete, transfer).
  final bool isDangerZone;

  @override
  Widget build(BuildContext context) {
    if (visibleWhen != null && !visibleWhen!()) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final AppSpacing spacing = context.spacing;
    final double radiusValue =
        Theme.of(context).surface.radius(RadiusSize.medium);

    final IconData? headerIcon =
        isDangerZone ? Icons.warning_amber_rounded : icon;
    final Color? headerIconColor =
        isDangerZone ? colorScheme.error : colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radiusValue),
        border: isDangerZone
            ? Border.all(
                color: colorScheme.error.borderO,
                width: 1,
              )
            : Border.all(
                color: colorScheme.outline.withValues(alpha: 0.08),
                width: 0.5,
              ),
        color: colorScheme.surfaceContainerLow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: spacing.sectionTitlePaddingLarge,
            child: Row(
              children: <Widget>[
                if (headerIcon != null) ...<Widget>[
                  Icon(headerIcon, size: 18, color: headerIconColor),
                  spacing.itemGap,
                ],
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...<Widget>[
                  spacing.tightGap,
                  Flexible(
                    child: Text(
                      description!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.secondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
