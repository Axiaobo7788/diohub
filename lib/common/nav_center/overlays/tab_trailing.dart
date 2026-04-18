import 'package:flutter/material.dart';
import 'package:diohub/common/nav_center/models/trailing_indicator.dart';

/// Widget displayed in the trailing area of a tab.
class TabTrailing extends StatelessWidget {
  const TabTrailing({
    required this.indicator,
    super.key,
  });

  final TrailingIndicator indicator;

  @override
  Widget build(BuildContext context) {
    return switch (indicator) {
      CountTrailing(count: final getCount) => () {
          final count = getCount();
          return count != null && count > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const SizedBox.shrink();
        }(),
      LoadingTrailing() => SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      IconTrailing(icon: final icon) => Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
      CompoundTrailing(children: final children) => Row(
          mainAxisSize: MainAxisSize.min,
          children: children.map((child) => TabTrailing(indicator: child)).toList(),
        ),
    };
  }
}
