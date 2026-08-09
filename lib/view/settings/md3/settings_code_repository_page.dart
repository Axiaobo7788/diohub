import 'dart:async';

import 'package:diohub/app/settings/code_browser_settings.dart';
import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/app/settings/repository.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/providers/settings/code_browser_settings_provider.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:diohub/providers/settings/repository_provider.dart';
import 'package:diohub/view/settings/md3/settings_md3_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsCodeRepositoryPage extends ConsumerWidget {
  const SettingsCodeRepositoryPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final RepositorySettings repository = ref.watch(repositoryProvider);
    final CodeBrowserSettings browser = ref.watch(codeBrowserSettingsProvider);
    final DiffSettings diff = ref.watch(diffSettingsProvider);

    return Column(
      key: const ValueKey<String>('settings-code-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.settingsCodeAndRepositories,
          description: context.l10n.settingsCodeAndRepositoriesDescription,
        ),
        Md3SettingsSection(
          title: context.l10n.settingsRepositoryDefaults,
          children: <Widget>[
            SettingsChoiceRow<RepositoryDefaultTab>(
              title: context.l10n.settingsDefaultRepositoryTab,
              subtitle: context.l10n.settingsDefaultRepositoryTabDescription,
              value: repository.defaultTab,
              values: RepositoryDefaultTab.values,
              labelBuilder: (final RepositoryDefaultTab value) =>
                  _repositoryTabLabel(context, value),
              onSelected: (final RepositoryDefaultTab value) => unawaited(
                runSettingsUpdate(
                  context,
                  ref
                      .read(repositoryProvider.notifier)
                      .update(
                        (final RepositorySettings current) =>
                            current.copyWith(defaultTab: value),
                      ),
                ),
              ),
            ),
          ],
        ),
        Md3SettingsSection(
          title: context.l10n.settingsCodeBrowser,
          children: <Widget>[
            SettingsChoiceRow<CodeSortOrder>(
              title: context.l10n.settingsFileSort,
              subtitle: context.l10n.settingsFileSortDescription,
              value: browser.sortOrder,
              values: CodeSortOrder.values,
              labelBuilder: (final CodeSortOrder value) =>
                  _sortOrderLabel(context, value),
              onSelected: (final CodeSortOrder value) => _updateBrowser(
                context,
                ref,
                browser.copyWith(sortOrder: value),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsShowDotfiles,
              subtitle: context.l10n.settingsShowDotfilesDescription,
              value: browser.showDotfiles,
              onChanged: (final bool value) => _updateBrowser(
                context,
                ref,
                browser.copyWith(showDotfiles: value),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsShowFileMetadata,
              subtitle: context.l10n.settingsShowFileMetadataDescription,
              value: browser.showMetadata,
              onChanged: (final bool value) => _updateBrowser(
                context,
                ref,
                browser.copyWith(showMetadata: value),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsShowGeneratedFiles,
              subtitle: context.l10n.settingsShowGeneratedFilesDescription,
              value: browser.showGeneratedFiles,
              onChanged: (final bool value) => _updateBrowser(
                context,
                ref,
                browser.copyWith(showGeneratedFiles: value),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsShowLastCommit,
              subtitle: context.l10n.settingsShowLastCommitDescription,
              value: browser.showLastCommitInfo,
              onChanged: (final bool value) => _updateBrowser(
                context,
                ref,
                browser.copyWith(showLastCommitInfo: value),
              ),
            ),
          ],
        ),
        Md3SettingsSection(
          title: context.l10n.settingsDiffViewer,
          children: <Widget>[
            SettingsChoiceRow<DiffDisplayMode>(
              title: context.l10n.settingsDiffLayout,
              subtitle: context.l10n.settingsDiffLayoutDescription,
              value: diff.defaultDiffDisplayMode,
              values: DiffDisplayMode.values,
              labelBuilder: (final DiffDisplayMode value) => switch (value) {
                DiffDisplayMode.unified => context.l10n.settingsDiffUnified,
                DiffDisplayMode.split => context.l10n.settingsDiffSplit,
              },
              onSelected: (final DiffDisplayMode value) => _updateDiff(
                context,
                ref,
                diff.copyWith(defaultDiffDisplayMode: value),
              ),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsWrapCode,
              subtitle: context.l10n.settingsWrapCodeDescription,
              value: diff.wrapLines,
              onChanged: (final bool value) =>
                  _updateDiff(context, ref, diff.copyWith(wrapLines: value)),
            ),
            SettingsSwitchRow(
              title: context.l10n.settingsLineNumbers,
              subtitle: context.l10n.settingsLineNumbersDescription,
              value: diff.showLineNumbers,
              onChanged: (final bool value) => _updateDiff(
                context,
                ref,
                diff.copyWith(showLineNumbers: value),
              ),
            ),
            SettingsChoiceRow<DiffHighlightIntensity>(
              title: context.l10n.settingsDiffHighlight,
              subtitle: context.l10n.settingsDiffHighlightDescription,
              value: diff.highlightIntensity,
              values: DiffHighlightIntensity.values,
              labelBuilder: (final DiffHighlightIntensity value) =>
                  _highlightLabel(context, value),
              onSelected: (final DiffHighlightIntensity value) => _updateDiff(
                context,
                ref,
                diff.copyWith(highlightIntensity: value),
              ),
            ),
            SettingsSliderRow(
              title: context.l10n.settingsCodeFontScale,
              subtitle: context.l10n.settingsCodeFontScaleDescription,
              value: diff.codeFontScale,
              min: 0.75,
              max: 1.5,
              divisions: 6,
              valueLabelBuilder: (final double value) =>
                  '${(value * 100).round()}%',
              onChanged: (final double value) => _updateDiff(
                context,
                ref,
                diff.copyWith(codeFontScale: value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateBrowser(
    final BuildContext context,
    final WidgetRef ref,
    final CodeBrowserSettings value,
  ) {
    unawaited(
      runSettingsUpdate(
        context,
        ref
            .read(codeBrowserSettingsProvider.notifier)
            .update((final CodeBrowserSettings _) => value),
      ),
    );
  }

  void _updateDiff(
    final BuildContext context,
    final WidgetRef ref,
    final DiffSettings value,
  ) {
    unawaited(
      runSettingsUpdate(
        context,
        ref
            .read(diffSettingsProvider.notifier)
            .update((final DiffSettings _) => value),
      ),
    );
  }

  String _repositoryTabLabel(
    final BuildContext context,
    final RepositoryDefaultTab value,
  ) => switch (value) {
    RepositoryDefaultTab.readme => context.l10n.repoReadme,
    RepositoryDefaultTab.code => context.l10n.repoCode,
    RepositoryDefaultTab.issues => context.l10n.repoIssues,
    RepositoryDefaultTab.pulls => context.l10n.repoPullRequests,
    RepositoryDefaultTab.commits => context.l10n.settingsCommits,
  };

  String _sortOrderLabel(
    final BuildContext context,
    final CodeSortOrder value,
  ) => switch (value) {
    CodeSortOrder.type => context.l10n.settingsSortType,
    CodeSortOrder.nameAsc => context.l10n.settingsSortNameAscending,
    CodeSortOrder.nameDesc => context.l10n.settingsSortNameDescending,
    CodeSortOrder.size => context.l10n.settingsSortSize,
    CodeSortOrder.extension => context.l10n.settingsSortExtension,
  };

  String _highlightLabel(
    final BuildContext context,
    final DiffHighlightIntensity value,
  ) => switch (value) {
    DiffHighlightIntensity.subtle => context.l10n.settingsHighlightSubtle,
    DiffHighlightIntensity.default_ => context.l10n.settingsHighlightDefault,
    DiffHighlightIntensity.high => context.l10n.settingsHighlightHigh,
  };
}
