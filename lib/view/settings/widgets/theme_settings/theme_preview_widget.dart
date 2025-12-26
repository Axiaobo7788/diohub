import 'package:diohub/app/theme_settings/models/flex_theme_settings_model.dart';
import 'package:diohub/app/theme_settings/utils/flex_color_scheme_builder.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Preview widget that shows how the theme looks with current settings
class ThemePreviewWidget extends StatefulWidget {
  const ThemePreviewWidget({
    super.key,
    required this.settings,
    required this.brightness,
  });

  final FlexThemeSettingsModel settings;
  final Brightness brightness;

  @override
  State<ThemePreviewWidget> createState() => _ThemePreviewWidgetState();
}

class _ThemePreviewWidgetState extends State<ThemePreviewWidget> {
  late Brightness _previewBrightness;

  @override
  void initState() {
    super.initState();
    _previewBrightness = widget.brightness;
  }

  @override
  void didUpdateWidget(ThemePreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update preview brightness if the widget's brightness changed
    // but keep user's manual selection if they've changed it
    if (oldWidget.brightness != widget.brightness &&
        _previewBrightness == oldWidget.brightness) {
      _previewBrightness = widget.brightness;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the theme from settings
    final FlexColorScheme flexScheme = _previewBrightness == Brightness.light
        ? FlexColorSchemeBuilder.buildLight(settings: widget.settings)
        : FlexColorSchemeBuilder.buildDark(settings: widget.settings);

    final ThemeData previewTheme = flexScheme.toTheme;

    // Wrap in Theme to apply the preview theme
    return Theme(
      data: previewTheme,
      child: Builder(
        builder: (BuildContext previewContext) {
          return Container(
            decoration: BoxDecoration(
              color: previewTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: previewTheme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Header
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.preview,
                      color: previewTheme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Theme Preview',
                      style: previewTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: previewTheme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    // Toggle between light and dark preview
                    SegmentedButton<Brightness>(
                      segments: const <ButtonSegment<Brightness>>[
                        ButtonSegment<Brightness>(
                          value: Brightness.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode, size: 16),
                        ),
                        ButtonSegment<Brightness>(
                          value: Brightness.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode, size: 16),
                        ),
                      ],
                      selected: <Brightness>{_previewBrightness},
                      onSelectionChanged: (Set<Brightness> newSelection) {
                        setState(() {
                          _previewBrightness = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Buttons section
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Elevated'),
                    ),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Filled'),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Outlined'),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Text'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card preview
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.info_outline,
                              color: previewTheme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sample Card',
                              style:
                                  previewTheme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This is a preview card showing how your theme looks.',
                          style: previewTheme.textTheme.bodySmall?.copyWith(
                            color: previewTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Color chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _ColorChip(
                      label: 'Primary',
                      color: previewTheme.colorScheme.primary,
                      textColor: previewTheme.colorScheme.onPrimary,
                    ),
                    _ColorChip(
                      label: 'Secondary',
                      color: previewTheme.colorScheme.secondary,
                      textColor: previewTheme.colorScheme.onSecondary,
                    ),
                    _ColorChip(
                      label: 'Tertiary',
                      color: previewTheme.colorScheme.tertiary,
                      textColor: previewTheme.colorScheme.onTertiary,
                    ),
                    _ColorChip(
                      label: 'Error',
                      color: previewTheme.colorScheme.error,
                      textColor: previewTheme.colorScheme.onError,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Text styles
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Headline',
                      style: previewTheme.textTheme.headlineSmall,
                    ),
                    Text(
                      'Title',
                      style: previewTheme.textTheme.titleMedium,
                    ),
                    Text(
                      'Body text',
                      style: previewTheme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Label',
                      style: previewTheme.textTheme.labelSmall?.copyWith(
                        color: previewTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Input field
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Sample Input',
                    hintText: 'Type something...',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Helper widget for color chips
class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
