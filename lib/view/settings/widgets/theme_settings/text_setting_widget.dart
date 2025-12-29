import 'package:flutter/material.dart';

/// Reusable widget for text input settings
class TextSettingWidget extends StatelessWidget {
  const TextSettingWidget({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.icon,
    this.hintText,
    this.keyboardType,
  });

  final String title;
  final String? description;
  final String value;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final String? hintText;
  final TextInputType? keyboardType;

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
          TextField(
            controller: TextEditingController(text: value)
              ..selection = TextSelection.collapsed(offset: value.length),
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            keyboardType: keyboardType,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}













