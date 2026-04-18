import 'package:diohub/app/settings/settings_descriptor.dart';

/// Links handling: open GitHub in app, confirm before opening in browser.
class LinksSettings {
  const LinksSettings({
    this.openGitHubInApp = true,
    this.confirmBeforeBrowser = true,
  });

  factory LinksSettings.fromJson(final Map<String, dynamic> json) =>
      LinksSettings(
        openGitHubInApp: json['openGitHubInApp'] as bool? ?? true,
        confirmBeforeBrowser: json['confirmBeforeBrowser'] as bool? ?? true,
      );

  final bool openGitHubInApp;
  final bool confirmBeforeBrowser;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'openGitHubInApp': openGitHubInApp,
        'confirmBeforeBrowser': confirmBeforeBrowser,
      };

  LinksSettings copyWith({
    final bool? openGitHubInApp,
    final bool? confirmBeforeBrowser,
  }) =>
      LinksSettings(
        openGitHubInApp: openGitHubInApp ?? this.openGitHubInApp,
        confirmBeforeBrowser: confirmBeforeBrowser ?? this.confirmBeforeBrowser,
      );
}

Map<String, dynamic> _linksToJson(final LinksSettings v) => v.toJson();

const SettingsDescriptor<LinksSettings> linksDescriptor =
    SettingsDescriptor<LinksSettings>(
  key: 'app_links',
  defaultValue: LinksSettings(),
  fromJson: LinksSettings.fromJson,
  toJson: _linksToJson,
);
