import 'package:diohub/common/misc/bordered_container.dart'
    show BorderedContainer;
import 'package:diohub/common/timeline/timeline_rail.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_style.dart' show BorderSideType;
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Unified timeline item — a pure layout primitive.
///
/// Renders an icon indicator on the timeline rail with content beside it.
/// Children are always passed through raw; the caller is responsible for
/// wrapping them in [BorderedContainer] or any other shell before handing
/// them to this widget.
class UnifiedTimelineItem extends StatelessWidget {
  UnifiedTimelineItem({
    required final Widget child,
    required this.actionText,
    required this.date,
    final IconData? eventIcon,
    final Color? eventIconColor,
    final List<({IconData icon, Color color})>? eventIcons,
    // Timeline positioning
    this.isFirst = false,
    this.isLast = false,
    this.backgroundColor,
    this.borderColor,
    // Action header padding
    this.actionHeaderTopPadding = 16.0,
    this.showActionInline = false,
    this.childrenOwnSurface = true,
    super.key,
  })  : assert(
          (eventIcon != null && eventIconColor != null) || eventIcons != null,
          'Either provide eventIcon + eventIconColor OR eventIcons',
        ),
        children = <Widget>[child],
        eventIcons = eventIcons ??
            <({Color color, IconData icon})>[
              (icon: eventIcon!, color: eventIconColor!)
            ];

  UnifiedTimelineItem.children({
    required this.children,
    required this.actionText,
    required this.date,
    final IconData? eventIcon,
    final Color? eventIconColor,
    final List<({IconData icon, Color color})>? eventIcons,
    // Timeline positioning
    this.isFirst = false,
    this.isLast = false,
    this.backgroundColor,
    this.borderColor,
    // Action header padding
    this.actionHeaderTopPadding = 16.0,
    this.showActionInline = false,
    this.childrenOwnSurface = true,
    super.key,
  })  : assert(
          (eventIcon != null && eventIconColor != null) || eventIcons != null,
          'Either provide eventIcon + eventIconColor OR eventIcons',
        ),
        eventIcons = eventIcons ??
            <({Color color, IconData icon})>[
              (icon: eventIcon!, color: eventIconColor!)
            ];

  final List<Widget> children;
  final String actionText;
  final DateTime? date;
  final List<({IconData icon, Color color})> eventIcons;
  final bool isFirst;
  final bool isLast;
  final Color? backgroundColor;
  final Color? borderColor;
  final double actionHeaderTopPadding;
  final bool showActionInline;

  /// When true, children pass through raw (they own their own card surface).
  /// When false, each child is wrapped in [BorderedContainer] with optional
  /// [borderColor] left accent.
  final bool childrenOwnSurface;

  static const double _iconSize = 24;
  static const double _iconSpacing = 4;

  @override
  Widget build(final BuildContext context) {
    // Calculate indicator height based on number of icons
    final double indicatorHeight = eventIcons.length == 1
        ? _iconSize
        : (eventIcons.length * _iconSize) +
            ((eventIcons.length - 1) * _iconSpacing);

    final Widget indicator = _buildIconIndicator(context);

    final Color lineColor =
        context.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return TimelineRail(
      isFirst: isFirst,
      isLast: isLast,
      indicatorWidth: _iconSize,
      indicatorHeight: indicatorHeight,
      indicator: indicator,
      lineThickness: 1,
      lineColor: lineColor,
      endChild: _buildContent(context),
    );
  }

  Widget _buildContent(final BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Inline layout: action text beside icon, no separate header
    if (showActionInline && actionText.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(12, actionHeaderTopPadding, 0, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _buildActionText(context)),
            if (date != null) ...<Widget>[
              context.spacing.itemGap,
              Text(
                date!.toRelativeDate(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Default layout: header above content
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (actionText.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: actionHeaderTopPadding,
                bottom: context.spacing.itemSpacing,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _buildActionText(context)),
                  if (date != null) ...<Widget>[
                    context.spacing.itemGap,
                    Text(
                      date!.toRelativeDate(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ..._buildChildren(context),
        ],
      ),
    );
  }

  /// Lay out children with uniform spacing. When [childrenOwnSurface] is false,
  /// each child is wrapped in [BorderedContainer] with [borderColor] left accent.
  List<Widget> _buildChildren(final BuildContext context) =>
      children.indexed.map(
        (final (int, Widget) e) {
          final int index = e.$1;
          final Widget child = e.$2;
          final bool isLastChild = index == children.length - 1;
          final Widget wrappedChild = childrenOwnSurface
              ? child
              : BorderedContainer(
                  borderColor: borderColor ?? eventIcons.first.color,
                  borderSide: BorderSideType.left,
                  borderWidth: 2.5,
                  elevation: 0,
                  child: SizedBox(width: double.infinity, child: child),
                );

          return Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 0.0 : context.spacing.itemSpacing,
              bottom:
                  isLast && isLastChild ? context.spacing.sectionSpacing : 0.0,
            ),
            child: wrappedChild,
          );
        },
      ).toList();

  Widget _buildIconIndicator(final BuildContext context) {
    if (eventIcons.length == 1) {
      return _buildSingleIcon(context, eventIcons.first);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: eventIcons.indexed
          .map((final (int, ({Color color, IconData icon})) entry) {
        final int index = entry.$1;
        final ({Color color, IconData icon}) iconData = entry.$2;
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : _iconSpacing),
          child: _buildSingleIcon(context, iconData),
        );
      }).toList(),
    );
  }

  Widget _buildSingleIcon(
    final BuildContext context,
    final ({IconData icon, Color color}) iconData,
  ) =>
      Container(
        width: _iconSize,
        height: _iconSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colorScheme.surface,
          border: Border.all(
            color: iconData.color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Icon(
          iconData.icon,
          size: 12,
          color: iconData.color,
        ),
      );

  Widget _buildActionText(final BuildContext context) => Text(
        actionText,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurface.hinted,
            ),
      );
}
