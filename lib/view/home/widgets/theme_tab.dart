import 'package:diohub/app/theme_settings/api/flex_theme_settings_service.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Basic theme tab widget that allows selecting FlexScheme presets
class ThemeTab extends StatefulWidget {
  const ThemeTab({super.key});

  @override
  State<ThemeTab> createState() => _ThemeTabState();
}

class _ThemeTabState extends State<ThemeTab> {
  late FlexThemeSettingsService _settingsService;

  @override
  void initState() {
    super.initState();
    _settingsService = FlexThemeSettingsService();
  }

  @override
  void dispose() {
    _settingsService.dispose();
    super.dispose();
  }

  String _getFlexSchemeLabel(FlexScheme scheme) {
    return scheme.name
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .trim();
  }

  Future<void> _updateScheme(FlexScheme scheme) async {
    await _settingsService.update(
      _settingsService.value.copyWith(scheme: scheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FlexThemeSettingsService>.value(
      value: _settingsService,
      child: Consumer<FlexThemeSettingsService>(
        builder: (context, settings, child) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final FlexScheme currentScheme =
              settings.value.scheme ?? FlexScheme.blueM3;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Theme Presets',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a color scheme preset',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: FlexScheme.values.length,
                itemBuilder: (context, index) {
                  final scheme = FlexScheme.values[index];
                  final isSelected = scheme == currentScheme;

                  // Generate preview colors for the scheme
                  final lightScheme = FlexColorScheme.light(scheme: scheme);
                  final primaryColor = lightScheme.toScheme.primary;

                  return InkWell(
                    onTap: () => _updateScheme(scheme),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.surface,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getFlexSchemeLabel(scheme),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Selected',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
