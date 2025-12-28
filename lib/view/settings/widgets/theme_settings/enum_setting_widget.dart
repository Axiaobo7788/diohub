import 'package:flutter/material.dart';

/// Reusable widget for selecting enum values
class EnumSettingWidget<T extends Enum> extends StatelessWidget {
  const EnumSettingWidget({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.labelBuilder,
    this.icon,
  });

  final String title;
  final String? description;
  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: description != null ? Text(description!) : null,
      trailing: DropdownButton<T>(
        value: value,
        items: options.map((T option) {
          return DropdownMenuItem<T>(
            value: option,
            child: Text(labelBuilder(option)),
          );
        }).toList(),
        onChanged: (T? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
}





