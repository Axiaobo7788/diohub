import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Reusable widget for color selection
class ColorSettingWidget extends StatelessWidget {
  const ColorSettingWidget({
    super.key,
    required this.title,
    required this.description,
    required this.color,
    required this.onChanged,
    this.icon,
    this.showAlpha = false,
  });

  final String title;
  final String? description;
  final Color color;
  final ValueChanged<Color> onChanged;
  final IconData? icon;
  final bool showAlpha;

  Future<void> _showColorPicker(BuildContext context) async {
    Color currentColor = color;
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                currentColor = color;
              },
              enableAlpha: showAlpha,
              displayThumbColor: true,
              paletteType: PaletteType.hslWithSaturation,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onChanged(currentColor);
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: description != null ? Text(description!) : null,
      trailing: GestureDetector(
        onTap: () => _showColorPicker(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 2,
            ),
          ),
        ),
      ),
      onTap: () => _showColorPicker(context),
    );
  }
}




















