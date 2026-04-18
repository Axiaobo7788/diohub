import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_content.freezed.dart';
part 'file_content.g.dart';

/// Domain model for file blob content. Isolates UI from GQL blob types.
@freezed
abstract class FileContent with _$FileContent {
  const factory FileContent({
    required String oid,
    required int byteSize,
    required bool isBinary,
    required bool isTruncated,
    String? text,
  }) = _FileContent;

  factory FileContent.fromJson(Map<String, dynamic> json) =>
      _$FileContentFromJson(json);
}
