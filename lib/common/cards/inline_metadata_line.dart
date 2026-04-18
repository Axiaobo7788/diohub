import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A single-line metadata widget displaying multiple items separated by dots.
///
/// Uses `Text.rich` with dot separators (` . `) between items. Each item
/// can have a tap handler via [InlineMetadataItem.onTap].
///
/// Style: `bodySmall` at `onSurfaceVariant.secondary`, with dots in `.hinted`.
///
/// Example:
/// ```dart
/// InlineMetadataLine(
///   items: [
///     InlineMetadataItem(
///       text: '@octocat',
///       onTap: () => navigateToProfile(),
///     ),
///     InlineMetadataItem(text: 'facebook/react'),
///     InlineMetadataItem(text: 'OWNER'),
///   ],
/// )
/// ```
class InlineMetadataLine extends StatelessWidget {
  const InlineMetadataLine({
    required this.items,
    super.key,
  });

  final List<InlineMetadataItem> items;

  @override
  Widget build(final BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    final TextStyle baseStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant.secondary,
            ) ??
            const TextStyle();
    final Color dotColor = context.colorScheme.onSurfaceVariant.hinted;
    
    final List<InlineSpan> spans = <InlineSpan>[];
    for (int i = 0; i < items.length; i++) {
      final InlineMetadataItem item = items[i];
      
      // Add separator dot before all items except the first
      if (i > 0) {
        spans.add(
          TextSpan(
            text: ' \u2022 ', // bullet character
            style: baseStyle.copyWith(color: dotColor),
          ),
        );
      }
      
      // Apply custom color if provided
      final TextStyle itemStyle = item.color != null
          ? baseStyle.copyWith(color: item.color)
          : baseStyle;
      
      // Add the item span
      if (item.onTap != null) {
        spans.add(
          TextSpan(
            text: item.text,
            style: itemStyle,
            recognizer: TapGestureRecognizer()..onTap = item.onTap,
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: item.text,
            style: itemStyle,
          ),
        );
      }
    }
    
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A single metadata item for [InlineMetadataLine].
class InlineMetadataItem {
  const InlineMetadataItem({
    required this.text,
    this.onTap,
    this.color,
  });

  final String text;
  final VoidCallback? onTap;
  final Color? color;
}
