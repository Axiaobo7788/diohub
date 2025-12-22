import 'package:diohub/common/misc/surface_shape_resolver.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';

/// A reusable chip widget for displaying contribution information
///
/// Displays: Icon | Count | label (if provided)
class ContributionInfoChip extends StatelessWidget {
  const ContributionInfoChip({
    required this.icon,
    required this.count,
    this.label,
    required this.color,
    super.key,
  });

  /// Icon to display
  final IconData icon;

  /// Count value to display (formatted automatically)
  final int count;

  /// Optional label text to display after count (e.g., "private", "in 5 repos", "reviews")
  final String? label;

  /// Color for the icon and chip styling
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: SurfaceShapeResolver.boxDecoration(
        context,
        size: BorderRadiusSize.large,
        color: color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            _formatNumber(count),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}k';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}
