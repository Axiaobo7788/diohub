import 'package:lens_annotations/lens_annotations.dart';

/// Represents a file to add or modify in a commit.
///
/// Used as a structured parameter for commit operations, implementing [ToolParam]
/// to ensure type-safe serialization across the tool boundary.
class FileChange implements ToolParam {
  const FileChange({required this.path, required this.content});

  /// Path to the file in the repository
  final String path;

  /// Content of the file
  final String content;

  factory FileChange.fromJson(Map<String, dynamic> json) {
    return FileChange(
      path: json['path'] as String,
      content: json['content'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'content': content,
    };
  }
}
