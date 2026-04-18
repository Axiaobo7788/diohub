import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_annotation.freezed.dart';
part 'check_annotation.g.dart';

/// Annotation level from GitHub Check API.
enum CheckAnnotationLevel {
  @JsonValue('FAILURE')
  failure,
  @JsonValue('WARNING')
  warning,
  @JsonValue('NOTICE')
  notice,
}

/// Position in a file (line and optional column).
@freezed
abstract class CheckAnnotationPosition with _$CheckAnnotationPosition {
  const factory CheckAnnotationPosition({
    required final int line,
    final int? column,
  }) = _CheckAnnotationPosition;

  factory CheckAnnotationPosition.fromJson(final Map<String, dynamic> json) =>
      _$CheckAnnotationPositionFromJson(json);
}

/// Span of lines for a check annotation.
@freezed
abstract class CheckAnnotationSpan with _$CheckAnnotationSpan {
  const factory CheckAnnotationSpan({
    required final CheckAnnotationPosition start,
    required final CheckAnnotationPosition end,
  }) = _CheckAnnotationSpan;

  factory CheckAnnotationSpan.fromJson(final Map<String, dynamic> json) =>
      _$CheckAnnotationSpanFromJson(json);
}

/// Single annotation (error/warning/notice) from a GitHub check run.
/// Fetched via GraphQL CheckRun.annotations.
@freezed
abstract class CheckAnnotation with _$CheckAnnotation {
  const factory CheckAnnotation({
    required final String path,
    required final CheckAnnotationSpan location,
    @JsonKey(name: 'annotation_level') required final CheckAnnotationLevel annotationLevel,
    required final String message,
    final String? title,
    @JsonKey(name: 'raw_details') final String? rawDetails,
  }) = _CheckAnnotation;

  factory CheckAnnotation.fromJson(final Map<String, dynamic> json) =>
      _$CheckAnnotationFromJson(json);
}

/// Check run containing annotations.
@freezed
abstract class CheckRun with _$CheckRun {
  const factory CheckRun({
    required final String name,
    final String? conclusion,
    @Default([]) final List<CheckAnnotation> annotations,
  }) = _CheckRun;

  factory CheckRun.fromJson(final Map<String, dynamic> json) =>
      _$CheckRunFromJson(json);
}

/// Check suite containing check runs.
@freezed
abstract class CheckSuite with _$CheckSuite {
  const factory CheckSuite({
    @JsonKey(name: 'check_runs') @Default([]) final List<CheckRun> checkRuns,
  }) = _CheckSuite;

  factory CheckSuite.fromJson(final Map<String, dynamic> json) =>
      _$CheckSuiteFromJson(json);
}
