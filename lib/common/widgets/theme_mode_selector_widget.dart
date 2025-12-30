import 'package:diohub/app/settings/theme_mode.dart';
import 'package:diohub/common/widgets/expandable_option_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Reusable widget for theme mode selection using the expandable option list
/// Used in expandable action buttons and other contexts
class ThemeModeSelectorWidget extends StatelessWidget {
  const ThemeModeSelectorWidget({
    required this.onCollapse,
    super.key,
  });

  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final themeModeSettings = Provider.of<ThemeModeSettings>(context, listen: false);
    final currentThemeMode = themeModeSettings.themeMode;

    return ExpandableOptionListWidget(
      options: [
        ExpandableOption(
          icon: Icons.light_mode,
          label: 'Light',
          isSelected: currentThemeMode == ThemeMode.light,
          onTap: () {
            themeModeSettings.updateThemeMode(ThemeMode.light);
          },
        ),
        ExpandableOption(
          icon: Icons.dark_mode,
          label: 'Dark',
          isSelected: currentThemeMode == ThemeMode.dark,
          onTap: () {
            themeModeSettings.updateThemeMode(ThemeMode.dark);
          },
        ),
        ExpandableOption(
          icon: Icons.brightness_auto,
          label: 'Auto',
          isSelected: currentThemeMode == ThemeMode.system,
          onTap: () {
            themeModeSettings.updateThemeMode(ThemeMode.system);
          },
        ),
      ],
      onCollapse: onCollapse,
    );
  }
}
