import 'package:diohub/app/settings/repository.dart';
import 'package:diohub/common/misc/settings_dropdown.dart';
import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/providers/settings/repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Defaults section: repository default tab.
class DefaultsSection extends ConsumerWidget {
  const DefaultsSection({super.key});

  static List<SettingsDropdownOption<RepositoryDefaultTab>>
      get _defaultTabOptions =>
          <SettingsDropdownOption<RepositoryDefaultTab>>[
            const SettingsDropdownOption<RepositoryDefaultTab>(
              value: RepositoryDefaultTab.readme,
              label: 'Readme',
            ),
            const SettingsDropdownOption<RepositoryDefaultTab>(
              value: RepositoryDefaultTab.code,
              label: 'Code',
            ),
            const SettingsDropdownOption<RepositoryDefaultTab>(
              value: RepositoryDefaultTab.issues,
              label: 'Issues',
            ),
            const SettingsDropdownOption<RepositoryDefaultTab>(
              value: RepositoryDefaultTab.pulls,
              label: 'Pull requests',
            ),
            const SettingsDropdownOption<RepositoryDefaultTab>(
              value: RepositoryDefaultTab.commits,
              label: 'Commits',
            ),
          ];

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final repoSettings = ref.watch(repositoryProvider);

    return SettingsGroup(
      children: <Widget>[
        SettingsDropdown<RepositoryDefaultTab>(
          title: 'Repository default tab',
          value: repoSettings.defaultTab,
          options: _defaultTabOptions,
          onChanged: (final RepositoryDefaultTab v) => ref
              .read(repositoryProvider.notifier)
              .update((final s) => s.copyWith(defaultTab: v)),
          icon: Octicons.repo,
          subtitle: 'Which tab opens first when viewing a repository',
        ),
      ],
    );
  }
}
