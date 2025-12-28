import 'package:flutter/material.dart';

/// Reusable widget for numeric slider settings
class SliderSettingWidget extends StatelessWidget {
  const SliderSettingWidget({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
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
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (description != null) Text(description!),
          const SizedBox(height: 8),
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
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}



