import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// A compact or full pill showing user status (emoji + message), optionally
/// with a "Busy" prefix when [indicatesLimitedAvailability] is true.
class UserStatusPill extends StatelessWidget {
  const UserStatusPill({
    this.emoji,
    this.message,
    this.indicatesLimitedAvailability = false,
    this.compact = true,
    super.key,
  });

  final String? emoji;
  final String? message;
  final bool indicatesLimitedAvailability;
  final bool compact;

  @override
  Widget build(final BuildContext context) {
    if (message == null) {
      return const SizedBox.shrink();
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppSpacing spacing = context.spacing;

    final EdgeInsets padding =
        compact ? spacing.badgePadding : spacing.chipPadding;
    final int maxLines = compact ? 1 : 2;
    final TextStyle textStyle = (compact
            ? textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 10,
              )
            : textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              )) ??
        const TextStyle(fontSize: 10, fontWeight: FontWeight.w500);

    final String displayText =
        (emoji != null && emoji!.isNotEmpty) ? '$emoji $message' : message!;

    final Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.borderO,
        borderRadius: context.radius(RadiusSize.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (indicatesLimitedAvailability) ...<Widget>[
            TintedChip(
              color: Colors.amber,
              icon: Icons.do_not_disturb,
              label: 'Busy',
              iconSize: 10,
              padding: spacing.badgePadding,
              labelStyle: textStyle,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              displayText,
              style: textStyle,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return content;
  }
}
