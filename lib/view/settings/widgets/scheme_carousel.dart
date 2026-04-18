import 'package:diohub/app/theme_config/models/flex_theme_settings_model.dart';
import 'package:diohub/providers/settings/flex_theme_provider.dart';
import 'package:diohub/providers/settings/theme_mode_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns a readable label for a [FlexScheme] (e.g. "Blue M3").
String getFlexSchemeLabel(final FlexScheme scheme) => scheme.name
    .replaceAllMapped(
      RegExp(r'([A-Z])'),
      (final Match match) => ' ${match.group(1)}',
    )
    .trim();

/// Hue family key and display label for grouping schemes in the carousel.
const Map<String, String> _schemeFamilies = <String, String>{
  'blues': 'Blues',
  'purples': 'Purples & Indigo',
  'reds': 'Reds & Pinks',
  'greens': 'Greens & Teals',
  'oranges': 'Oranges & Ambers',
  'neutrals': 'Neutrals & Greys',
};

/// Maps each FlexScheme to a family key (excluding [FlexScheme.custom]).
final Map<FlexScheme, String> _schemeToFamily = _buildSchemeToFamily();

Map<FlexScheme, String> _buildSchemeToFamily() {
  final Map<FlexScheme, String> out = <FlexScheme, String>{};
  final List<FlexScheme> all =
      FlexScheme.values.where((final FlexScheme s) => s != FlexScheme.custom).toList();

  final Map<String, List<String>> familyNames = <String, List<String>>{
    'blues': <String>[
      'material', 'materialHc', 'blue', 'brandBlue', 'deepBlue', 'aquaBlue',
      'hippieBlue', 'bahamaBlue', 'blumineBlue', 'sanJuanBlue', 'bigStone',
      'blueWhale', 'blueM3', 'shadBlue',
    ],
    'purples': <String>[
      'indigo', 'deepPurple', 'purpleBrown', 'purpleM3', 'indigoM3', 'shadViolet',
    ],
    'reds': <String>[
      'red', 'redWine', 'mandyRed', 'sakura', 'rosewood', 'barossa', 'damask',
      'redM3', 'pinkM3', 'shadRed', 'shadRose',
    ],
    'greens': <String>[
      'green', 'money', 'jungle', 'wasabi', 'mallardGreen', 'verdunHemlock',
      'dellGenoa', 'ebonyClay', 'tealM3', 'greenM3', 'limeM3', 'cyanM3', 'shadGreen',
    ],
    'oranges': <String>[
      'gold', 'mango', 'amber', 'vesuviusBurn', 'shark', 'espresso',
      'orangeM3', 'deepOrangeM3', 'yellowM3', 'shadOrange', 'shadYellow',
    ],
    'neutrals': <String>[
      'greyLaw', 'outerSpace', 'flutterDash', 'materialBaseline', 'blackWhite',
      'greys', 'sepia', 'shadGray', 'shadNeutral', 'shadSlate', 'shadStone', 'shadZinc',
    ],
  };

  for (final FlexScheme scheme in all) {
    for (final MapEntry<String, List<String>> entry in familyNames.entries) {
      if (entry.value.contains(scheme.name)) {
        out[scheme] = entry.key;
        break;
      }
    }
    out.putIfAbsent(scheme, () => 'neutrals');
  }
  return out;
}

/// Grouped schemes by family for carousel. Order of families matches [_schemeFamilies].
List<MapEntry<String, List<FlexScheme>>> get _groupedSchemes {
  final Map<String, List<FlexScheme>> groups = <String, List<FlexScheme>>{};
  for (final FlexScheme scheme
      in FlexScheme.values.where((final FlexScheme s) => s != FlexScheme.custom)) {
    final String family = _schemeToFamily[scheme] ?? 'neutrals';
    groups.putIfAbsent(family, () => <FlexScheme>[]).add(scheme);
  }
  return _schemeFamilies.keys
      .map((final String k) => MapEntry<String, List<FlexScheme>>(k, groups[k] ?? <FlexScheme>[]))
      .where((final MapEntry<String, List<FlexScheme>> e) => e.value.isNotEmpty)
      .toList();
}

/// Horizontal carousel of color schemes grouped by hue family.
class SchemeCarousel extends ConsumerWidget {
  const SchemeCarousel({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final FlexThemeSettingsModel flex = ref.watch(flexThemeProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final FlexScheme currentScheme = isDark
        ? (flex.darkScheme ?? flex.scheme ?? FlexScheme.blueM3)
        : (flex.lightScheme ?? flex.scheme ?? FlexScheme.blueM3);
    final int blendLevel = flex.blendLevel ?? 10;
    final bool materialYouEnabled = ref.watch(themeModeProvider).materialYouEnabled;
    final AppSpacing spacing = context.spacing;

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MapEntry<String, List<FlexScheme>> entry in _groupedSchemes) ...<Widget>[
          Padding(
            padding: spacing.sectionTitlePaddingMedium,
            child: Text(
              _schemeFamilies[entry.key] ?? entry.key,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: spacing.listInset.left),
              itemCount: entry.value.length,
              itemBuilder: (final BuildContext context, final int index) {
                final FlexScheme scheme = entry.value[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ThemeSchemeChip(
                    scheme: scheme,
                    isSelected: scheme == currentScheme,
                    blendLevel: blendLevel,
                    onTap: () => _updateScheme(ref, scheme),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: spacing.itemSpacing),
        ],
      ],
    );

    if (materialYouEnabled) {
      child = Opacity(
        opacity: 0.5,
        child: IgnorePointer(child: child),
      );
    }

    return child;
  }

  Future<void> _updateScheme(final WidgetRef ref, final FlexScheme scheme) async {
    await ref.read(flexThemeProvider.notifier).update(
          (final FlexThemeSettingsModel current) => current.copyWith(
                scheme: scheme,
                lightScheme: scheme,
                darkScheme: scheme,
              ),
        );
  }
}

class _ThemeSchemeChip extends StatelessWidget {
  const _ThemeSchemeChip({
    required this.scheme,
    required this.isSelected,
    required this.blendLevel,
    required this.onTap,
  });

  final FlexScheme scheme;
  final bool isSelected;
  final int blendLevel;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FlexColorScheme previewScheme = FlexColorScheme.light(
      scheme: scheme,
      blendLevel: blendLevel,
    );
    final ColorScheme previewColors = previewScheme.toScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 80,
        height: 72,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.08),
                  width: 0.5,
                ),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: <Color>[
                      previewColors.primary,
                      previewColors.primaryContainer,
                      previewColors.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const <double>[0, 0.5, 1],
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: colorScheme.primary,
                        size: 16,
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                getFlexSchemeLabel(scheme),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
