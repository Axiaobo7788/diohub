import 'package:diohub/app/settings/code_browser_settings.dart';
import 'package:diohub/providers/settings/code_browser_settings_provider.dart';
import 'package:diohub/view/settings/widgets/theme_config/enum_setting_widget.dart';
import 'package:diohub/view/settings/widgets/theme_config/switch_setting_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Code Browser settings: sort order, show dotfiles, show file metadata.
class CodeBrowserSettingsSection extends ConsumerWidget {
  const CodeBrowserSettingsSection({super.key});

  static String _sortOrderLabel(final CodeSortOrder v) => switch (v) {
    CodeSortOrder.type => 'Type (folders first)',
    CodeSortOrder.nameAsc => 'Name (A–Z)',
    CodeSortOrder.nameDesc => 'Name (Z–A)',
    CodeSortOrder.size => 'Size',
    CodeSortOrder.extension => 'Extension',
  };

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settings = ref.watch(codeBrowserSettingsProvider);
    final notifier = ref.read(codeBrowserSettingsProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EnumSettingWidget<CodeSortOrder>(
          title: 'Sort order',
          description: 'How files and folders are ordered in the tree',
          value: settings.sortOrder,
          options: CodeSortOrder.values,
          onChanged: (final CodeSortOrder v) =>
              notifier.update((final s) => s.copyWith(sortOrder: v)),
          labelBuilder: _sortOrderLabel,
          icon: Icons.sort,
        ),
        SwitchSettingWidget(
          title: 'Show dotfiles',
          description: 'Show files and folders whose names start with a dot',
          value: settings.showDotfiles,
          onChanged: (bool value) =>
              notifier.update((final s) => s.copyWith(showDotfiles: value)),
          icon: Icons.folder_outlined,
        ),
        SwitchSettingWidget(
          title: 'Show file metadata',
          description: 'Show language, line count, size under file names',
          value: settings.showMetadata,
          onChanged: (final bool v) =>
              notifier.update((final s) => s.copyWith(showMetadata: v)),
          icon: Icons.info_outline,
        ),
        SwitchSettingWidget(
          title: 'Load last commit per file',
          description:
              'Uses one additional GitHub request for each visible file or folder',
          value: settings.showLastCommitInfo,
          onChanged: (final bool value) => notifier.update(
            (final CodeBrowserSettings s) =>
                s.copyWith(showLastCommitInfo: value),
          ),
          icon: Icons.history,
        ),
      ],
    );
  }
}
