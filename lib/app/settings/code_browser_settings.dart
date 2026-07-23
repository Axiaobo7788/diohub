import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'code_browser_settings.freezed.dart';
part 'code_browser_settings.g.dart';

/// Sort order for the code browser file tree.
enum CodeSortOrder { type, nameAsc, nameDesc, size, extension }

CodeSortOrder _sortOrderFromJson(String? v) => switch (v) {
  'nameAsc' => CodeSortOrder.nameAsc,
  'nameDesc' => CodeSortOrder.nameDesc,
  'size' => CodeSortOrder.size,
  'extension' => CodeSortOrder.extension,
  _ => CodeSortOrder.type,
};
String _sortOrderToJson(CodeSortOrder v) => switch (v) {
  CodeSortOrder.type => 'type',
  CodeSortOrder.nameAsc => 'nameAsc',
  CodeSortOrder.nameDesc => 'nameDesc',
  CodeSortOrder.size => 'size',
  CodeSortOrder.extension => 'extension',
};

@freezed
abstract class CodeBrowserSettings with _$CodeBrowserSettings {
  const CodeBrowserSettings._();

  const factory CodeBrowserSettings({
    @JsonKey(fromJson: _sortOrderFromJson, toJson: _sortOrderToJson)
    @Default(CodeSortOrder.type)
    CodeSortOrder sortOrder,
    @Default(true) bool showDotfiles,
    @Default(true) bool showMetadata,
    @Default(true) bool showGeneratedFiles,
    // GitHub's API has no batch field for this. Enabling it performs one
    // history query per visible path, so keep it opt-in.
    @Default(false) bool showLastCommitInfo,
  }) = _CodeBrowserSettings;

  factory CodeBrowserSettings.fromJson(Map<String, dynamic> json) =>
      _$CodeBrowserSettingsFromJson(json);
}

Map<String, dynamic> _codeBrowserToJson(CodeBrowserSettings v) => v.toJson();

const SettingsDescriptor<CodeBrowserSettings> codeBrowserSettingsDescriptor =
    SettingsDescriptor<CodeBrowserSettings>(
      key: 'code_browser',
      defaultValue: CodeBrowserSettings(),
      fromJson: CodeBrowserSettings.fromJson,
      toJson: _codeBrowserToJson,
    );
