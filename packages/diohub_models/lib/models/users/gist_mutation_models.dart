import 'package:freezed_annotation/freezed_annotation.dart';

part 'gist_mutation_models.freezed.dart';
part 'gist_mutation_models.g.dart';

/// Input for creating or updating a gist.
@freezed
abstract class GistFileInput with _$GistFileInput {
  const factory GistFileInput({
    required String filename,
    required String content,
  }) = _GistFileInput;

  factory GistFileInput.fromJson(Map<String, dynamic> json) =>
      _$GistFileInputFromJson(json);
}

/// Minimal response from gist create/update (REST).
@freezed
abstract class GistResponse with _$GistResponse {
  const factory GistResponse({
    required String id,
    @JsonKey(name: 'html_url') required String htmlUrl,
  }) = _GistResponse;

  factory GistResponse.fromJson(Map<String, dynamic> json) =>
      _$GistResponseFromJson(json);
}
