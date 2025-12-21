import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/timeline/timeline_container.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

/// Unified timeline item that works for both Events and Activity timelines
/// Uses icon-only indicator for timeline visualization
class UnifiedTimelineItem extends StatelessWidget {
  UnifiedTimelineItem({
    required Widget child,
    required this.actionText,
    required this.date,
    required this.eventIcon,
    required this.eventIconColor,
    // Timeline positioning
    this.isFirst = false,
    this.isLast = false,
    // Highlighting
    this.highlighted = false,
    // Action header padding
    this.actionHeaderTopPadding = 16.0,
    super.key,
  }) : children = [child];

  const UnifiedTimelineItem.children({
    required this.children,
    required this.actionText,
    required this.date,
    required this.eventIcon,
    required this.eventIconColor,
    // Timeline positioning
    this.isFirst = false,
    this.isLast = false,
    // Highlighting
    this.highlighted = false,
    // Action header padding
    this.actionHeaderTopPadding = 16.0,
    super.key,
  });

  final List<Widget> children;
  final String actionText;
  final DateTime? date;
  final IconData eventIcon;
  final Color eventIconColor;
  final bool isFirst;
  final bool isLast;
  final bool highlighted;
  final double actionHeaderTopPadding;

  @override
  Widget build(BuildContext context) {
    final indicatorSize = 24.0;
    final indicator = _buildIconIndicator(context);

    final LineStyle lineStyle = LineStyle(
      thickness: 1,
      color: context.colorScheme.outlineVariant.withOpacity(0.5),
    );
    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: indicatorSize,
        height: indicatorSize,
        indicatorXY: 0.5,
        drawGap: true,
        indicator: indicator,
      ),
      beforeLineStyle: lineStyle,
      afterLineStyle: lineStyle,
      endChild: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action header
            Padding(
              padding: EdgeInsets.only(
                top: actionHeaderTopPadding,
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildActionText(context),
                  ),
                  if (date != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      date!.toRelativeDate(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                            fontSize: 10,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Content (each child wrapped in its own container)
            ...children.map((child) {
              if (highlighted) {
                return BorderedContainer(
                  borderColor: eventIconColor,
                  // borderSide: BorderSideType.bottom,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: child,
                  ),
                );
              } else {
                return TimelineContainer(
                  // borderColor: eventIconColor,
                  // borderRadius: 8.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: child,
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildIconIndicator(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colorScheme.surface,
        border: Border.all(
          color: eventIconColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        eventIcon,
        size: 12,
        color: eventIconColor,
      ),
    );
  }

  Widget _buildActionText(BuildContext context) {
    return _buildFormattedActionText(context, actionText);
  }

  /// Build action text as plain text without formatting
  Widget _buildFormattedActionText(BuildContext context, String? actionText) {
    if (actionText == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    return Text(
      actionText,
      style: theme.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurface.withOpacity(0.6),
        fontSize: 12,
      ),
    );
  }
}
