import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Reusable widget for numeric slider settings
class SliderSettingWidget extends StatelessWidget {
  const SliderSettingWidget({
    required this.title,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
    this.divisions,
    this.labelBuilder,
    this.icon,
  });

  final String title;
  final String? description;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String Function(double)? labelBuilder;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    return ListTile(
      leading: icon != null
          ? Icon(
              icon,
              size: 22,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
      title: Text(title),
      contentPadding: spacing.cardContentPadding,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (description != null) Text(description!),
          SizedBox(height: spacing.itemSpacing),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: labelBuilder?.call(value) ?? value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
          Text(
            labelBuilder?.call(value) ?? value.toStringAsFixed(0),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
