import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/action_card_style.dart';
import 'package:diohub/common/misc/action_content_row.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:flutter/material.dart';

/// Styled container for action buttons with interaction.
///
/// Uses `Ink(decoration:)` so the decoration paints on the `Material` ink
/// layer and the `InkWell` splash renders **on top** of the background.
class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.action,
    this.style = const ActionCardStyle(),
    this.onTap,
    this.borderRadiusOverride,
    this.seedColor,
    this.child,
    super.key,
  });

  final ActionButtonData action;
  final ActionCardStyle style;
  final VoidCallback? onTap;
  final double? borderRadiusOverride;
  final Color? seedColor;
  final Widget? child; // Custom content (overrides ActionContentRow)

  @override
  Widget build(final BuildContext context) {
    final ActionButtonColors colors = action.getColors(
      context,
      forProminentButton: true,
      seedColor: seedColor,
    );

    final Color effectiveBackgroundColor =
        style.backgroundColor ?? colors.backgroundColor;

    final BorderRadius borderRadius = borderRadiusOverride != null
        ? BorderRadius.circular(borderRadiusOverride!)
        : context.radius(style.borderRadiusSize);

    final Widget content = child ?? ActionContentRow(action: action);

    final BoxDecoration decoration = BoxDecoration(
      color: effectiveBackgroundColor,
      borderRadius: borderRadius,
      border: Border.all(
        color: Theme.of(context)
            .colorScheme
            .outline
            .withValues(alpha: style.borderOpacity),
        width: style.borderWidth,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Theme.of(context)
              .colorScheme
              .shadow
              .withValues(alpha: style.shadowOpacity),
          blurRadius: style.shadowBlurRadius,
          offset: style.shadowOffset,
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: AbsorbPointer(
        absorbing: !action.enabled,
        child: InkWell(
          onTap: action.enabled ? onTap : null,
          borderRadius: borderRadius,
          child: Ink(
            decoration: decoration,
            child: AnimatedSize(
              duration: kMicroDuration,
              curve: kMicroCurve,
              child: Padding(
                key: action.getCheckboxKey(),
                padding: style.padding,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
