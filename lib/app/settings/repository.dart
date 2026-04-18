import 'package:diohub/app/settings/settings_descriptor.dart';

/// Repository screen default tab.
enum RepositoryDefaultTab {
  readme,
  code,
  issues,
  pulls,
  commits;

  String get name => switch (this) {
        RepositoryDefaultTab.readme => 'readme',
        RepositoryDefaultTab.code => 'code',
        RepositoryDefaultTab.issues => 'issues',
        RepositoryDefaultTab.pulls => 'pulls',
        RepositoryDefaultTab.commits => 'commits',
      };

  static RepositoryDefaultTab fromName(final String name) =>
      RepositoryDefaultTab.values.firstWhere(
        (final RepositoryDefaultTab e) => e.name == name,
        orElse: () => RepositoryDefaultTab.readme,
      );
}

class RepositorySettings {
  const RepositorySettings({
    this.defaultTab = RepositoryDefaultTab.readme,
  });

  factory RepositorySettings.fromJson(final Map<String, dynamic> json) =>
      RepositorySettings(
        defaultTab: json['defaultTab'] is String
            ? RepositoryDefaultTab.fromName(json['defaultTab'] as String)
            : RepositoryDefaultTab.readme,
      );

  final RepositoryDefaultTab defaultTab;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'defaultTab': defaultTab.name};

  RepositorySettings copyWith({final RepositoryDefaultTab? defaultTab}) =>
      RepositorySettings(
        defaultTab: defaultTab ?? this.defaultTab,
      );
}

Map<String, dynamic> _repositoryToJson(final RepositorySettings v) =>
    v.toJson();

const SettingsDescriptor<RepositorySettings> repositoryDescriptor =
    SettingsDescriptor<RepositorySettings>(
  key: 'app_repository',
  defaultValue: RepositorySettings(),
  fromJson: RepositorySettings.fromJson,
  toJson: _repositoryToJson,
);
