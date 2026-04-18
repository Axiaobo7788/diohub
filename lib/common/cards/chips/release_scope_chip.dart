import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Chip showing release asset summary: "📦 5 assets · 2.3k↓" or "📦 5 assets".
///
/// Returns [SizedBox.shrink] when [assetCount] is 0.
class ReleaseScopeChip extends StatelessWidget {
  const ReleaseScopeChip({
    required this.assetCount,
    this.totalDownloads,
    super.key,
  });

  final int assetCount;
  final int? totalDownloads;

  @override
  Widget build(final BuildContext context) {
    if (assetCount <= 0) {
      return const SizedBox.shrink();
    }
    final String label = totalDownloads != null && totalDownloads! > 0
        ? '$assetCount assets · ${totalDownloads!.toShortenedStr()}↓'
        : '$assetCount assets';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Octicons.package,
          size: 12,
          color: context.colorScheme.onSurfaceVariant.muted,
        ),
        SizedBox(width: context.spacing.tightSpacing),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant.muted,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
