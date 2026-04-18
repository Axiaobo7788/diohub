import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/common/misc/action_card.dart';
import 'package:diohub/common/misc/action_card_style.dart';
import 'package:diohub/common/misc/action_content_row.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Handles expansion behavior for ExpandableActionButton
///
/// Encapsulates all expansion state management and animation logic.
/// Used internally by ActionCard when action is ExpandableActionButton.
///
/// **Important**: The expanded content container provides NO padding.
/// Content from `expandableWidgetBuilder` must handle its own padding.
class ExpandableActionCard extends StatefulWidget {
  const ExpandableActionCard({
    required this.action,
    required this.style,
    this.borderRadiusOverride,
    this.seedColor,
    this.onOptionSelected,
    super.key,
  });

  final ExpandableActionButton action;
  final ActionCardStyle style;
  final double? borderRadiusOverride;
  final Color? seedColor;
  final VoidCallback? onOptionSelected;

  @override
  State<ExpandableActionCard> createState() => _ExpandableActionCardState();
}

class _ExpandableActionCardState extends State<ExpandableActionCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _onCollapse() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final BorderRadius borderRadius = widget.borderRadiusOverride != null
        ? BorderRadius.circular(widget.borderRadiusOverride!)
        : context.radius(widget.style.borderRadiusSize);

    final ActionButtonColors colors =
        widget.action.getColors(context, forProminentButton: true);

    // Derive expanded background from action's own color, elevated
    final Color expandedBackgroundColor = Color.alphaBlend(
      Theme.of(context).colorScheme.surfaceContainerHigh.borderO,
      colors.backgroundColor,
    );

    return AnimatedSize(
      duration: kMicroDuration,
      alignment: Alignment.topLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ActionCard(
            action: widget.action,
            style: _isExpanded
                ? widget.style.copyWith(
                    borderOpacity: 0.35,
                    borderWidth: 1,
                    shadowOpacity: 0.15,
                    shadowBlurRadius: 8,
                    backgroundColor: expandedBackgroundColor,
                  )
                : widget.style,
            borderRadiusOverride: widget.borderRadiusOverride,
            seedColor: widget.seedColor,
            onTap: widget.action.enabled ? _toggleExpanded : null,
            child: _AnimatedActionContent(
              action: widget.action,
              colors: colors,
              isExpanded: _isExpanded,
            ),
          ),
          AnimatedVisibility(
            visible: _isExpanded,
            transition: AnimationTransition.size,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      Theme.of(context)
                          .colorScheme
                          .surfaceContainerLow
                          .secondary,
                      colors.backgroundColor.borderO,
                    ),
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.tint,
                      width: 0.5,
                    ),
                  ),
                  child: widget.action.expandableWidgetBuilder(_onCollapse),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animates the text style and layout of expandable action content
class _AnimatedActionContent extends StatelessWidget {
  const _AnimatedActionContent({
    required this.action,
    required this.colors,
    required this.isExpanded,
  });

  final ExpandableActionButton action;
  final ActionButtonColors colors;
  final bool isExpanded;

  @override
  Widget build(final BuildContext context) => TweenAnimationBuilder<TextStyle>(
        duration: kMicroDuration,
        curve: kMicroCurve,
        tween: TextStyleTween(
          begin: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textColor,
                fontWeight: FontWeight.w400,
                fontSize: 14,
                letterSpacing: 0,
              ),
          end: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textColor,
                fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w400,
                fontSize: isExpanded ? 14.5 : 14.0,
                letterSpacing: isExpanded ? 0.1 : 0.0,
              ),
        ),
        builder: (final BuildContext context, final TextStyle style,
                final Widget? child) =>
            Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: ActionContentRow(
                action: action,
                labelStyle: style,
              ),
            ),
            context.spacing.itemGap,
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0, // 180 degrees when expanded
              duration: kMicroDuration,
              child: Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: colors.iconColor.secondary,
              ),
            ),
          ],
        ),
      );
}
