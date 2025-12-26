import 'package:diohub/app/settings/theme_mode.dart';
import 'package:diohub/app/theme_settings/api/flex_theme_settings_service.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Grid-based theme selector tab with easy navigation
class ThemeCarouselTab extends StatefulWidget {
  const ThemeCarouselTab({super.key});

  @override
  State<ThemeCarouselTab> createState() => _ThemeCarouselTabState();
}

class _ThemeCarouselTabState extends State<ThemeCarouselTab> {
  // Default values matching main.dart
  static const FlexScheme _defaultScheme = FlexScheme.materialBaseline;
  static const int _defaultBlendLevel = 25;

  String _getFlexSchemeLabel(FlexScheme scheme) {
    return scheme.name
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .trim();
  }

  Future<void> _updateScheme(FlexScheme scheme) async {
    final settingsService = Provider.of<FlexThemeSettingsService>(
      context,
      listen: false,
    );
    final currentSettings = settingsService.value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Update based on current theme mode
    if (isDarkMode) {
      await settingsService.update(
        currentSettings.copyWith(darkScheme: scheme),
      );
    } else {
      await settingsService.update(
        currentSettings.copyWith(lightScheme: scheme),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateBlendLevel(int blendLevel) async {
    final settingsService = Provider.of<FlexThemeSettingsService>(
      context,
      listen: false,
    );
    await settingsService.update(
      settingsService.value.copyWith(blendLevel: blendLevel),
    );
    // The Consumer in build will automatically rebuild when settings change
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _resetTheme() async {
    final settingsService = Provider.of<FlexThemeSettingsService>(
      context,
      listen: false,
    );
    // Reset to defaults and clear storage
    await settingsService.reset();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildThemeCard(
    FlexScheme scheme,
    bool isSelected,
    int blendLevel,
    BuildContext context, {
    bool isEnabled = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Generate preview colors with current blend level
    final previewScheme = FlexColorScheme.light(
      scheme: scheme,
      blendLevel: blendLevel,
    );
    final previewColors = previewScheme.toScheme;

    return Card(
      elevation: isSelected ? 1 : 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(
                color: colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isEnabled ? () => _updateScheme(scheme) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact color preview
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      previewColors.primary,
                      previewColors.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Selected indicator
                    if (isSelected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: previewColors.onPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: previewColors.primary,
                            size: 14,
                          ),
                        ),
                      ),
                    // Color swatches at bottom
                    Positioned(
                      bottom: 6,
                      left: 6,
                      right: 6,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: previewColors.primary,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      previewColors.onPrimary.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: previewColors.secondary,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: previewColors.onSecondary
                                      .withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                color: previewColors.tertiary,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      previewColors.onTertiary.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Scheme name - compact
              Text(
                _getFlexSchemeLabel(scheme),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Active',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModeSettings>(
      builder: (context, themeModeSettings, child) {
        return Consumer<FlexThemeSettingsService>(
          builder: (context, settings, child) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            final isDarkMode = theme.brightness == Brightness.dark;
            final currentScheme = isDarkMode
                ? (settings.value.darkScheme ??
                    settings.value.scheme ??
                    _defaultScheme)
                : (settings.value.lightScheme ??
                    settings.value.scheme ??
                    _defaultScheme);
            final int blendLevel =
                settings.value.blendLevel ?? _defaultBlendLevel;
            final bool isMaterialYouEnabled =
                themeModeSettings.materialYouEnabled;

            return AppCustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Theme Presets',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Reset to defaults',
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Reset Themes?'),
                                    content: const Text(
                                      'This will reset all theme settings to their default values.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Reset'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  _resetTheme();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Material You Toggle
                        Card(
                          child: SwitchListTile(
                            title: Row(
                              children: [
                                Icon(
                                  Icons.palette_rounded,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text('Material You'),
                              ],
                            ),
                            subtitle: Text(
                              isMaterialYouEnabled
                                  ? 'Using system dynamic colors'
                                  : 'Using custom theme presets',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            value: isMaterialYouEnabled,
                            onChanged: (value) {
                              themeModeSettings.updateMaterialYou(value);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // App Theme Mode (Light/Dark/System) - below title
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode, size: 16),
                              label: Text('Light'),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode, size: 16),
                              label: Text('Dark'),
                            ),
                            ButtonSegment<ThemeMode>(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto, size: 16),
                              label: Text('Auto'),
                            ),
                          ],
                          selected: {themeModeSettings.themeMode},
                          onSelectionChanged: (Set<ThemeMode> newSelection) {
                            themeModeSettings
                                .updateThemeMode(newSelection.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                // Blend slider section - pinned header
                SliverPinnedHeader(
                  child: Container(
                    color: colorScheme.surface,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Blend Level',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$blendLevel',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Slider(
                              value: blendLevel.toDouble(),
                              min: 0,
                              max: 40,
                              divisions: 40,
                              label: blendLevel.toString(),
                              onChanged: (value) {
                                _updateBlendLevel(value.toInt());
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                // Theme grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive grid sizing with shorter cards
                      final width = constraints.crossAxisExtent;
                      int crossAxisCount;
                      double spacing;

                      if (width > 800) {
                        crossAxisCount = 4;
                        spacing = 12;
                      } else if (width > 600) {
                        crossAxisCount = 3;
                        spacing = 12;
                      } else if (width > 400) {
                        crossAxisCount = 2;
                        spacing = 12;
                      } else {
                        crossAxisCount = 2;
                        spacing = 10;
                      }

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: 1.5,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final scheme = FlexScheme.values[index];
                            final isSelected = scheme == currentScheme;
                            return Opacity(
                              opacity: isMaterialYouEnabled ? 0.5 : 1.0,
                              child: _buildThemeCard(
                                scheme,
                                isSelected,
                                blendLevel,
                                context,
                                isEnabled: !isMaterialYouEnabled,
                              ),
                            );
                          },
                          childCount: FlexScheme.values.length,
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        );
      },
    );
  }
}
