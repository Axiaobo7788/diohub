import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class ChangelogVersionDivider extends StatelessWidget {
  const ChangelogVersionDivider({
    required this.label,
    super.key,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.spacing.sectionSpacing,
        horizontal: context.spacing.pagePadding.left,
      ),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: cs.outline,
              thickness: 1,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.itemSpacing,
            ),
            child: Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: cs.outline,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
