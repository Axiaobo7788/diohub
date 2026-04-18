import 'package:diohub/app/theme_config/models/flex_theme_settings_model.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/search/client_text_matcher.dart';
import 'package:diohub/providers/settings/flex_theme_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class _FontPreset {
  const _FontPreset(this.label, this.fontFamily);
  final String label;
  final String fontFamily;
}

/// Preset font options: system default and monospace; rest from Google Fonts.
const List<_FontPreset> _presets = <_FontPreset>[
  _FontPreset('Default', ''),
  _FontPreset('Monospace', 'monospace'),
];

/// Lazy-loaded sorted list of Google Font family names for the picker.
List<String> _getGoogleFontNames() => GoogleFonts.asMap().keys.toList()
  ..sort((final String a, final String b) => a.compareTo(b));

/// Card that shows the current app font and opens a searchable font picker on tap.
class FontFamilySettingCard extends ConsumerWidget {
  const FontFamilySettingCard({super.key});

  static String _displayLabel(final String fontFamily) {
    for (final _FontPreset preset in _presets) {
      if (preset.fontFamily == fontFamily) return preset.label;
    }
    return fontFamily.isNotEmpty ? fontFamily : 'Default';
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final String currentFont = ref.watch(flexThemeProvider).fontFamily ?? '';

    final theme = Theme.of(context);
    final spacing = context.spacing;
    return BorderedContainer(
      onTap: () async {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (final BuildContext context) => _FontPickerScreen(
              currentFontFamily: currentFont,
              onSelected: (final String fontFamily) {
                ref.read(flexThemeProvider.notifier).update(
                    (final FlexThemeSettingsModel m) => fontFamily.isEmpty
                        ? m.copyWith(clearFontFamily: true)
                        : m.copyWith(fontFamily: fontFamily));
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
      padding: spacing.cardContentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'App Font',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Icon(Icons.edit_rounded),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _displayLabel(currentFont),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: currentFont.isNotEmpty ? currentFont : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FontPickerScreen extends StatefulWidget {
  const _FontPickerScreen({
    required this.currentFontFamily,
    required this.onSelected,
  });

  final String currentFontFamily;
  final ValueChanged<String> onSelected;

  @override
  State<_FontPickerScreen> createState() => _FontPickerScreenState();
}

class _FontPickerScreenState extends State<_FontPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _googleFontNames = <String>[];
  String _query = '';

  static final _presetMatcher = ClientTextMatcher<_FontPreset>(
      fields: [(_FontPreset p) => p.label],
  );

  @override
  void initState() {
    super.initState();
    _googleFontNames = _getGoogleFontNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<_FontPreset> get _filteredOptions {
    final List<_FontPreset> all = <_FontPreset>[
      ..._presets,
      ..._googleFontNames.map((String name) => _FontPreset(name, name)),
    ];
    return _presetMatcher.filter(all, _query);
  }

  @override
  Widget build(final BuildContext context) {
    final List<_FontPreset> options = _filteredOptions;
    final AppSpacing spacing = context.spacing;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose font'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.screenPadding.left,
              0,
              spacing.screenPadding.right,
              8,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search fonts...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: spacing.inputPadding,
              ),
              onChanged: (final String value) => setState(() => _query = value),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemExtent: 56,
        padding: EdgeInsets.symmetric(horizontal: spacing.screenPadding.left),
        itemCount: options.length,
        itemBuilder: (final BuildContext context, final int index) {
          final _FontPreset option = options[index];
          final bool isSelected = option.fontFamily == widget.currentFontFamily;
          final bool isPreset = _presets
              .any((final _FontPreset e) => e.fontFamily == option.fontFamily);

          return ListTile(
            contentPadding: spacing.cardContentPadding,
            title: Text(
              option.label,
              style: (isPreset
                      ? Theme.of(context).textTheme.bodyMedium
                      : Theme.of(context).textTheme.bodyLarge)
                  ?.copyWith(
                fontFamily:
                    option.fontFamily.isNotEmpty ? option.fontFamily : null,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check, color: colorScheme.primary)
                : null,
            onTap: () => widget.onSelected(option.fontFamily),
          );
        },
      ),
    );
  }
}
