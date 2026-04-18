import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/timeline/timeline_rail.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/timeline/timeline_display_item.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Expandable widget for a group of 3+ consecutive minimal-tier timeline entries.
///
/// Collapsed: shows "N actions" and date; tap to expand.
/// Expanded: shows each entry as a compact row (icon + action text).
class CollapsibleMinimalGroupWidget extends StatefulWidget {
  const CollapsibleMinimalGroupWidget({
    required this.group,
    required this.date,
    required this.buildRow,
    this.isFirst = false,
    this.isLast = false,
    super.key,
  });

  final CollapsedMinimalGroup group;
  final DateTime? date;
  final Widget Function(SingleTimelineEntry entry) buildRow;
  final bool isFirst;
  final bool isLast;

  @override
  State<CollapsibleMinimalGroupWidget> createState() =>
      _CollapsibleMinimalGroupWidgetState();
}

class _CollapsibleMinimalGroupWidgetState
    extends State<CollapsibleMinimalGroupWidget> {
  bool _expanded = false;

  /// Matches [UnifiedTimelineItem] indicator size for timeline rail consistency.
  static const double _indicatorSize = 24;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    const double lineThickness = 1;
    final Color lineColor = context.colorScheme.outlineVariant
        .withValues(alpha: Opacities.borderStrong);

    final Widget indicator = Container(
      width: _indicatorSize,
      height: _indicatorSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colorScheme.surface,
        border: Border.all(
          color:
              context.colorScheme.outline.withValues(alpha: Opacities.border),
          width: 2,
        ),
      ),
      child: Icon(
        _expanded ? Icons.expand_less : Icons.expand_more,
        size: spacing.itemSpacing * 2,
        color: context.colorScheme.onSurfaceVariant,
      ),
    );

    final Widget content = TapFeedback(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.contentPadding.left,
          spacing.cardContentPadding.top,
          0,
          0,
        ),
        child: _expanded ? _buildExpanded(context) : _buildCollapsed(context),
      ),
    );

    return TimelineRail(
      isFirst: widget.isFirst,
      isLast: widget.isLast,
      indicatorWidth: _indicatorSize,
      indicatorHeight: _indicatorSize,
      indicator: indicator,
      lineThickness: lineThickness,
      lineColor: lineColor,
      endChild: content,
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    final count = widget.group.entries.length;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            '$count actions',
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurface.hinted,
            ),
          ),
        ),
        if (widget.date != null) ...<Widget>[
          SizedBox(width: context.spacing.itemSpacing),
          Text(
            widget.date!.toRelativeDate(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant
                  .withValues(alpha: Opacities.secondary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final spacing = context.spacing;
    final children = <Widget>[];
    for (var i = 0; i < widget.group.entries.length; i++) {
      children.add(
        Padding(
          padding: EdgeInsets.only(
            top: i == 0 ? 0 : spacing.itemSpacing,
          ),
          child: widget.buildRow(widget.group.entries[i]),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
