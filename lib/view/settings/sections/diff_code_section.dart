import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/common/misc/contextual_preview.dart';
import 'package:diohub/common/misc/settings_dropdown.dart';
import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/common/misc/settings_slider.dart';
import 'package:diohub/common/misc/settings_toggle.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:diohub/providers/settings/terminal_settings_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/settings/widgets/code_block_themes.dart';
import 'package:diohub/view/settings/widgets/previews/diff_code_context_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Diff & Code section: wrap lines, line numbers, highlight intensity, code block theme.
class DiffCodeSection extends ConsumerWidget {
  const DiffCodeSection({super.key});

  static List<SettingsDropdownOption<DiffHighlightIntensity>>
      get _intensityOptions => <SettingsDropdownOption<DiffHighlightIntensity>>[
            const SettingsDropdownOption<DiffHighlightIntensity>(
              value: DiffHighlightIntensity.subtle,
              label: 'Subtle',
            ),
            const SettingsDropdownOption<DiffHighlightIntensity>(
              value: DiffHighlightIntensity.default_,
              label: 'Default',
            ),
            const SettingsDropdownOption<DiffHighlightIntensity>(
              value: DiffHighlightIntensity.high,
              label: 'High',
            ),
          ];

  static List<SettingsDropdownOption<String>> get _codeBlockThemeOptions =>
      CodeBlockThemes.themeIds
          .map(
            (final String id) => SettingsDropdownOption<String>(
              value: id,
              label: CodeBlockThemes.themeLabel(id),
            ),
          )
          .toList();

  static List<SettingsDropdownOption<DiffDisplayMode>>
      get _diffDisplayModeOptions => <SettingsDropdownOption<DiffDisplayMode>>[
            const SettingsDropdownOption<DiffDisplayMode>(
              value: DiffDisplayMode.unified,
              label: 'Unified',
              subtitle: 'Single column',
            ),
            const SettingsDropdownOption<DiffDisplayMode>(
              value: DiffDisplayMode.split,
              label: 'Split',
              subtitle: 'Old | New',
            ),
          ];

  static List<SettingsDropdownOption<int>> get _contextLinesOptions =>
      <SettingsDropdownOption<int>>[
        const SettingsDropdownOption<int>(value: 5, label: '5'),
        const SettingsDropdownOption<int>(value: 10, label: '10'),
        const SettingsDropdownOption<int>(value: 20, label: '20'),
        const SettingsDropdownOption<int>(value: 50, label: '50'),
        const SettingsDropdownOption<int>(value: 100, label: '100'),
      ];

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final DiffSettings diff = ref.watch(diffSettingsProvider);
    final notifier = ref.read(diffSettingsProvider.notifier);
    final AppSpacing spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ContextualPreview(
          child: Padding(
            padding: spacing.cardContentPadding,
            child: const DiffCodeContextPreview(),
          ),
        ),
        SizedBox(height: spacing.itemSpacing),
        SettingsGroup(
          children: <Widget>[
            SettingsToggle(
              title: 'Wrap lines',
              value: diff.wrapLines,
              onChanged: (final bool v) =>
              notifier.update((final s) => s.copyWith(wrapLines: v)),
              icon: Icons.wrap_text,
            ),
            SettingsToggle(
              title: 'Show line numbers',
              value: diff.showLineNumbers,
              onChanged: (final bool v) =>
              notifier.update((final s) => s.copyWith(showLineNumbers: v)),
              icon: Icons.format_list_numbered,
            ),
            SettingsDropdown<DiffHighlightIntensity>(
              title: 'Highlight intensity',
              value: diff.highlightIntensity,
              options: _intensityOptions,
              onChanged: (final DiffHighlightIntensity v) => notifier.update((final s) => s.copyWith(highlightIntensity: v)),
            ),
            SettingsDropdown<String>(
              title: 'Code block theme',
              value: CodeBlockThemes.themeIds.contains(diff.codeBlockTheme)
                  ? diff.codeBlockTheme
                  : 'auto',
              options: _codeBlockThemeOptions,
              onChanged: (final String v) =>
              notifier.update((final s) => s.copyWith(codeBlockTheme: v)),
            ),
            SettingsDropdown<DiffDisplayMode>(
              title: 'Default diff view',
              value: diff.defaultDiffDisplayMode,
              options: _diffDisplayModeOptions,
              onChanged: (final DiffDisplayMode v) =>
              notifier.update((final s) => s.copyWith(defaultDiffDisplayMode: v)),
              icon: Icons.view_column,
              subtitle: 'Layout when opening a diff',
            ),
            SettingsToggle(
              title: 'Show blame inline',
              value: diff.showBlameInline,
              onChanged: (final bool v) =>
              notifier.update((final s) => s.copyWith(showBlameInline: v)),
              icon: Icons.history_rounded,
              subtitle: 'Show blame info in code view gutter when available',
            ),
            SettingsSlider(
              title: 'Code font scale',
              value: diff.codeFontScale,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (final double v) => notifier.update((final s) => s.copyWith(codeFontScale: v)),
              icon: Icons.text_fields,
              subtitle: 'Scale code and diff text',
              labelBuilder: (final double v) => '${v.toStringAsFixed(1)}×',
            ),
            SettingsDropdown<int>(
              title: 'Context lines to load',
              value: _contextLinesOptions.any(
                      (final SettingsDropdownOption<int> o) =>
                          o.value == diff.contextLinesToLoad)
                  ? diff.contextLinesToLoad
                  : 20,
              options: _contextLinesOptions,
              onChanged: (final int v) => notifier.update((final s) =>
              s.copyWith(contextLinesToLoad: v.clamp(5, 100))),
              icon: Icons.expand_more,
              subtitle: 'Lines to load when expanding between hunks (5–100)',
            ),
            SettingsSlider(
              title: 'Terminal font size',
              value: ref
                  .watch(terminalSettingsProvider)
                  .terminalFontSizeDelta
                  .toDouble(),
              min: -4,
              max: 8,
              divisions: 12,
              onChanged: (final double v) => ref
                  .read(terminalSettingsProvider.notifier)
                  .setTerminalFontSizeDelta(v.toInt()),
              icon: Icons.text_fields,
              subtitle: 'Adjust font size for log viewer and terminal screens',
              labelBuilder: (final double v) =>
                  v >= 0 ? '+${v.toInt()}' : '${v.toInt()}',
            ),
            SettingsSlider(
              title: 'Terminal scrollback lines',
              value: ref
                  .watch(terminalSettingsProvider)
                  .terminalMaxScrollback
                  .toDouble(),
              min: 1000,
              max: 100000,
              divisions: 10,
              onChanged: (final double v) => ref
                  .read(terminalSettingsProvider.notifier)
                  .setTerminalMaxScrollback(v.toInt()),
              icon: Icons.history,
              subtitle: 'Maximum number of lines kept in terminal buffer',
              labelBuilder: (final double v) => '${(v / 1000).toInt()}K',
            ),
          ],
        ),
      ],
    );
  }
}
