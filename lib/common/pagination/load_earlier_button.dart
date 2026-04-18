import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Button shown at the top of an anchored paginated list.
/// Tapping loads earlier items via backward pagination.
class LoadEarlierButton extends StatelessWidget {
  const LoadEarlierButton({
    required this.onTap,
    this.label = 'Load earlier activity',
    super.key,
  });

  final Future<void> Function() onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: context.spacing.pagePadding,
        child: SubmitButton(
          variant: SubmitButtonVariant.text,
          onSubmit: onTap,
          icon: Icon(
            Icons.expand_less_rounded,
            size: 16,
            color: context.colorScheme.primary,
          ),
          label: (_) => Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.primary,
            ),
          ),
        ),
      );
}
