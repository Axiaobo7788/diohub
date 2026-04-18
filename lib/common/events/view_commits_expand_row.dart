import 'package:diohub/common/cards/commit_card.dart' show CommitCard;
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Reusable row for "View commits" / "View commit" with trailing chevron.
/// Expands to show [child] (e.g. loading, empty text, or list of [CommitCard]).
///
/// Used by timeline force-push, activity feed branch row, and timeline single commit.
class ViewCommitsExpandRow extends StatelessWidget {
  const ViewCommitsExpandRow({
    required this.isExpanded,
    required this.onTap,
    required this.child,
    this.leading,
    this.label = 'View commits',
    super.key,
  });

  final bool isExpanded;
  final VoidCallback? onTap;
  final Widget child;
  final Widget? leading;
  final String label;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TapFeedback(
          onTap: onTap,
          borderRadius: context.radius(RadiusSize.small),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: spacing.itemSpacing,
              horizontal: spacing.itemSpacing,
            ),
            child: Row(
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  Flexible(child: leading!),
                  SizedBox(width: spacing.itemSpacing),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Icon(
                  isExpanded ? Octicons.chevron_down : Octicons.chevron_right,
                  size: 14,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Padding(
              padding: EdgeInsets.only(
                left: spacing.itemSpacing,
                top: spacing.itemSpacing,
                bottom: spacing.itemSpacing,
              ),
              child: child,
            ),
          ),
      ],
    );
  }
}
