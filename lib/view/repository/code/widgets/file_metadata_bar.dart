import 'package:diohub_models/models/repositories/code/directory_last_commit.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/format_bytes.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:flutter/material.dart';

/// Compact metadata row: language, line count, byte size, optional "Updated {relative}".
class FileMetadataBar extends StatelessWidget {
  const FileMetadataBar({
    this.languageName,
    this.lineCount,
    this.byteSize,
    this.lastCommit,
    super.key,
  });

  final String? languageName;
  final int? lineCount;
  final int? byteSize;
  final DirectoryLastCommit? lastCommit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> parts = <String>[];
    if (languageName != null && languageName!.isNotEmpty) {
      parts.add(languageName!);
    }
    if (lineCount != null && lineCount! > 0) {
      parts.add('$lineCount ${lineCount == 1 ? 'line' : 'lines'}');
    }
    if (byteSize != null && byteSize! > 0) {
      parts.add(formatBytes(byteSize!));
    }
    if (lastCommit != null) {
      parts.add('Updated ${lastCommit!.committedDate.toRelativeDate()}');
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: context.spacing.screenPadding,
      child: Text(
        parts.join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
