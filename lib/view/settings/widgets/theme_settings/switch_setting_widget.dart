import 'package:flutter/material.dart';

/// Reusable widget for boolean switch settings
class SwitchSettingWidget extends StatelessWidget {
  const SwitchSettingWidget({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: description != null ? Text(description!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}















