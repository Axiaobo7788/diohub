import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Expandable "Advanced" subsection for settings.
/// Tap to expand/collapse; uses theme text styles (labelSmall for header).
class ExpandableSettingsSection extends StatefulWidget {
  const ExpandableSettingsSection({
    required this.title,
    required this.child,
    super.key,
    this.initialExpanded = false,
  });

  final String title;
  final Widget child;
  final bool initialExpanded;

  @override
  State<ExpandableSettingsSection> createState() =>
      _ExpandableSettingsSectionState();
}

class _ExpandableSettingsSectionState extends State<ExpandableSettingsSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initialExpanded;
  }

  @override
  void didUpdateWidget(final ExpandableSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialExpanded != widget.initialExpanded) {
      _expanded = widget.initialExpanded;
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: spacing.itemSpacing),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.cardContentPadding.left,
                vertical: spacing.tightSpacing * 2,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    widget.title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: kMicroDuration,
                    curve: kMicroCurve,
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: widget.child,
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: kMicroDuration,
        ),
      ],
    );
  }
}
