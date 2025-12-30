import 'package:diohub/app/settings/theme_mode.dart';
import 'package:diohub/app/theme_config/api/flex_theme_settings_service.dart';
import 'package:diohub/common/misc/surface_shape_resolver.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/utils/material_you_support.dart';
import 'package:dynamic_color/dynamic_color.dart';
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
  static const FlexScheme _defaultScheme = FlexScheme.blueM3;
  static const int _defaultBlendLevel = 10;

  // Sorted list of all FlexScheme values alphabetically by name
  static final List<FlexScheme> _sortedSchemes = List.from(FlexScheme.values)
    ..sort((a, b) => a.name.compareTo(b.name));

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

  Widget _buildThemeCard(
    FlexScheme scheme,
    bool isSelected,
    int blendLevel,
    BuildContext context, {
    bool isEnabled = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceStyle = theme.surfaceStyle;

    // Generate preview colors with current blend level
    final previewScheme = FlexColorScheme.light(
      scheme: scheme,
      blendLevel: blendLevel,
    );
    final previewColors = previewScheme.toScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: SurfaceShapeResolver.large(
        context,
        side: isSelected
            ? BorderSide(
                color: colorScheme.primary,
                width: 2.5,
              )
            : BorderSide(
                color: colorScheme.outline.withOpacity(0.12),
                width: 1,
              ),
      ),
      child: InkWell(
        onTap: isEnabled ? () => _updateScheme(scheme) : null,
        borderRadius: surfaceStyle.borderRadius(size: BorderRadiusSize.large),
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                surfaceStyle.borderRadius(size: BorderRadiusSize.large),
            color: isSelected
                ? colorScheme.primaryContainer.withOpacity(0.3)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color preview with gradient
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          previewColors.primary,
                          previewColors.primaryContainer,
                          previewColors.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: surfaceStyle.borderRadius(
                          size: BorderRadiusSize.medium),
                      boxShadow: [
                        BoxShadow(
                          color: previewColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Selected indicator badge
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                                size: 18,
                              ),
                            ),
                          ),
                        // Color palette preview at bottom
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: previewColors.primary,
                                    borderRadius: surfaceStyle.borderRadius(
                                        size: BorderRadiusSize.soft),
                                    border: Border.all(
                                      color: previewColors.onPrimary
                                          .withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: previewColors.secondary,
                                    borderRadius: surfaceStyle.borderRadius(
                                        size: BorderRadiusSize.soft),
                                    border: Border.all(
                                      color: previewColors.onSecondary
                                          .withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: previewColors.tertiary,
                                    borderRadius: surfaceStyle.borderRadius(
                                        size: BorderRadiusSize.soft),
                                    border: Border.all(
                                      color: previewColors.onTertiary
                                          .withOpacity(0.2),
                                      width: 1,
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
                ),
                const SizedBox(height: 12),
                // Scheme name
                Text(
                  _getFlexSchemeLabel(scheme),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
                // Top controls section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        // Material You Toggle
                        DynamicColorBuilder(
                          builder: (lightDynamic, darkDynamic) {
                            final supportsMaterialYou =
                                MaterialYouSupport.isSupported(
                                    lightDynamic, darkDynamic);

                            final surfaceStyle = Theme.of(context).surfaceStyle;

                            return Card(
                              elevation: 0,
                              shape: SurfaceShapeResolver.medium(
                                context,
                                side: BorderSide(
                                  color: colorScheme.outline.withOpacity(0.12),
                                ),
                              ),
                              child: SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 4,
                                ),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer
                                            .withOpacity(0.5),
                                        borderRadius: surfaceStyle.borderRadius(
                                            size: BorderRadiusSize.small),
                                      ),
                                      child: Icon(
                                        Icons.palette_rounded,
                                        size: 18,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Material You',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 38,
                                    top: 4,
                                  ),
                                  child: Text(
                                    !supportsMaterialYou
                                        ? 'Not supported on this device'
                                        : isMaterialYouEnabled
                                            ? 'Using system dynamic colors'
                                            : 'Using custom theme presets',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      color: supportsMaterialYou
                                          ? colorScheme.onSurfaceVariant
                                          : colorScheme.onSurfaceVariant
                                              .withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                value: isMaterialYouEnabled,
                                onChanged: supportsMaterialYou
                                    ? (value) {
                                        themeModeSettings
                                            .updateMaterialYou(value);
                                      }
                                    : null,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                // Blend slider section - pinned header
                SliverPinnedHeader(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: theme.surfaceStyle
                                .borderRadius(size: BorderRadiusSize.small),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Blend Level',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: theme.surfaceStyle
                                          .borderRadius(
                                              size: BorderRadiusSize.small),
                                    ),
                                    child: Text(
                                      '$blendLevel',
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
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
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                // Theme grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive grid sizing
                      final width = constraints.crossAxisExtent;
                      int crossAxisCount;
                      double spacing;

                      if (width > 800) {
                        crossAxisCount = 4;
                        spacing = 16;
                      } else if (width > 600) {
                        crossAxisCount = 3;
                        spacing = 16;
                      } else if (width > 400) {
                        crossAxisCount = 2;
                        spacing = 16;
                      } else {
                        crossAxisCount = 2;
                        spacing = 12;
                      }

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final scheme = _sortedSchemes[index];
                            final isSelected = scheme == currentScheme;
                            return Opacity(
                              opacity: isMaterialYouEnabled ? 0.4 : 1.0,
                              child: _buildThemeCard(
                                scheme,
                                isSelected,
                                blendLevel,
                                context,
                                isEnabled: !isMaterialYouEnabled,
                              ),
                            );
                          },
                          childCount: _sortedSchemes.length,
                        ),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        );
      },
    );
  }
}
