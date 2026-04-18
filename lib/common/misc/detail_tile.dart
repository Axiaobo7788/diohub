import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Type of action that will be performed when a DetailTile is tapped
enum DetailTileActionType {
  /// Opens a tab within the current screen
  tab,

  /// Opens a bottom sheet
  bottomSheet,

  /// Navigates to a new screen
  navigation,

  /// No action (just displays information)
  none,
}

class DetailTile extends StatelessWidget {
  const DetailTile({
    required this.title,
    required this.child,
    this.trailing,
    this.onTap,
    this.actionType,
    super.key,
  });

  /// Title text to display
  final String title;

  /// Subtitle widget to display below the title
  final Widget child;

  /// Optional widget to display on the trailing side (overrides default icon based on actionType)
  final Widget? trailing;

  /// Callback when tile is tapped
  final VoidCallback? onTap;

  /// Type of action this tile performs (determines trailing icon)
  final DetailTileActionType? actionType;

  @override
  Widget build(final BuildContext context) => InkWell(
        onTap: onTap,
        child: ColoredBox(
          // Subtle background to prevent empty look
          color: context.colorScheme.surfaceContainerHighest.borderO,
          child: Padding(
            padding: context.spacing.inputPadding,
            child: Row(
              children: <Widget>[
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Title
                      Text(
                        title,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant.strong,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Subtitle (child)
                      child,
                    ],
                  ),
                ),
                // Trailing widget
                if (trailing != null) ...<Widget>[
                  context.spacing.itemGap,
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      );
}
