import 'package:diohub/common/animations/animated_counter_text.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A reusable stat card widget for displaying metrics.
///
/// This widget can be used to display any metric with an icon, value, and label.
/// It's tappable and can navigate to detailed views.
///
/// Example usage:
/// ```dart
/// StatCardWidget(
///   icon: Octicons.git_commit,
///   value: '1,234',
///   label: 'Commits',
///   color: Colors.green,
///   onTap: () => navigateToCommits(),
/// )
/// ```
class StatCardWidget extends ConsumerWidget {
  const StatCardWidget({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.onTap,
    this.iconSize = 14.0,
    this.valueStyle,
    this.labelStyle,
    this.padding,
    this.borderRadius = 8.0,
    super.key,
  });

  /// Icon to display
  final IconData icon;

  /// The value to display (e.g., "1,234" or "45%")
  final String value;

  /// Label text below the value
  final String label;

  /// Color for the icon and value
  final Color? color;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Size of the icon
  final double iconSize;

  /// Style for the value text
  final TextStyle? valueStyle;

  /// Style for the label text
  final TextStyle? labelStyle;

  /// Padding around the content
  final EdgeInsets? padding;

  /// Border radius for the card
  final double borderRadius;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final Color defaultColor = color ?? colorScheme.primary;
    final TextStyle? defaultValueStyle = valueStyle ??
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: defaultColor,
        );
    final TextStyle? defaultLabelStyle = labelStyle ??
        theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
        );
    final EdgeInsets defaultPadding =
        padding ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 6);

    final Column content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: iconSize,
                color: defaultColor,
              ),
              context.spacing.tightGap,
              Flexible(
                child: _valueWidget(
                  value: value,
                  style: defaultValueStyle,
                  ref: ref,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Flexible(
          child: Text(
            label,
            style: defaultLabelStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    if (onTap == null) {
      // Non-tappable stat card
      return Padding(
        padding: defaultPadding,
        child: content,
      );
    }

    // Tappable stat card with visual feedback
    return Material(
      color: colorScheme.surfaceContainerHighest.tintStrong,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: defaultPadding,
          child: content,
        ),
      ),
    );
  }

  static Widget _valueWidget({
    required final String value,
    required final TextStyle? style,
    required final WidgetRef ref,
  }) {
    final int? parsed = int.tryParse(
      value.replaceAll(',', '').replaceAll('%', '').trim(),
    );
    if (parsed != null) {
      final bool withPercent = value.contains('%');
      return AnimatedCounterText(
        value: parsed,
        style: style,
        formatter: (final int v) => withPercent ? '$v%' : v.toString(),
      );
    }
    return Text(
      value,
      style: style,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
    );
  }
}

/// A grid of stat cards for displaying multiple metrics.
///
/// Example usage:
/// ```dart
/// StatCardGrid(
///   stats: [
///     StatCardData(
///       icon: Octicons.git_commit,
///       value: '1,234',
///       label: 'Commits',
///       color: Colors.green,
///     ),
///     StatCardData(
///       icon: Octicons.git_pull_request,
///       value: '456',
///       label: 'Pull Requests',
///       color: Colors.blue,
///     ),
///   ],
/// )
/// ```
class StatCardGrid extends StatelessWidget {
  const StatCardGrid({
    required this.stats,
    this.crossAxisCount = 4,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.padding,
    super.key,
  });

  /// List of stat data to display
  final List<StatCardData> stats;

  /// Number of columns in the grid
  final int crossAxisCount;

  /// Spacing between cards horizontally
  final double spacing;

  /// Spacing between cards vertically
  final double runSpacing;

  /// Padding around the grid
  final EdgeInsets? padding;

  @override
  Widget build(final BuildContext context) => Padding(
        padding: padding ?? EdgeInsets.zero,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
          ),
          itemCount: stats.length,
          itemBuilder: (final BuildContext context, final int index) {
            final StatCardData stat = stats[index];
            return StatCardWidget(
              icon: stat.icon,
              value: stat.value,
              label: stat.label,
              color: stat.color,
              onTap: stat.onTap,
            );
          },
        ),
      );
}

/// Data class for stat card information
class StatCardData {
  const StatCardData({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
}
