import 'package:freezed_annotation/freezed_annotation.dart';

part 'issue_field.freezed.dart';
part 'issue_field.g.dart';

/// Data type for an issue field.
enum IssueFieldDataType {
  @JsonValue('single_select')
  singleSelect,
  @JsonValue('text')
  text,
  @JsonValue('number')
  number,
  @JsonValue('date')
  date,
}

/// Visibility of an issue field.
enum IssueFieldVisibility {
  @JsonValue('public')
  public,
  @JsonValue('private')
  private,
}

/// Definition of an issue field (schema).
/// 
/// Represents a field that can be applied to issues in an organization,
/// such as Priority, Effort, Start Date, Target Date, or custom fields.
@freezed
abstract class IssueFieldDef with _$IssueFieldDef {
  const factory IssueFieldDef({
    required String id,
    required String name,
    required IssueFieldDataType dataType,
    String? description,
    IssueFieldVisibility? visibility,
    String? color,
    List<IssueFieldOption>? options,
  }) = _IssueFieldDef;

  factory IssueFieldDef.fromJson(Map<String, dynamic> json) =>
      _$IssueFieldDefFromJson(json);
}

/// Option for a single-select issue field.
@freezed
abstract class IssueFieldOption with _$IssueFieldOption {
  const factory IssueFieldOption({
    required String id,
    required String name,
    String? description,
    String? color,
  }) = _IssueFieldOption;

  factory IssueFieldOption.fromJson(Map<String, dynamic> json) =>
      _$IssueFieldOptionFromJson(json);
}

/// Value of an issue field on a specific issue.
/// 
/// For single-select fields, [value] will be null and [selectedOption] will be populated.
/// For text/number/date fields, [value] will be populated and [selectedOption] will be null.
@freezed
abstract class IssueFieldValue with _$IssueFieldValue {
  const factory IssueFieldValue({
    required String fieldId,
    String? value,
    IssueFieldOption? selectedOption,
  }) = _IssueFieldValue;

  factory IssueFieldValue.fromJson(Map<String, dynamic> json) =>
      _$IssueFieldValueFromJson(json);
}
