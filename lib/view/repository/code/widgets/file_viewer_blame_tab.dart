import 'package:diohub/common/code/app_code_editor.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/file_content.dart';
import 'package:diohub_models/models/repositories/tree_typedefs.dart';
import 'package:diohub/providers/code_browser/blame_provider.dart';
import 'package:diohub/providers/code_browser/file_content_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Blame tab: file content + blame from repo notifier (GQL [BlameRange] for [AppCodeEditor]).
class FileViewerBlameTab extends ConsumerWidget {
  const FileViewerBlameTab({
    required this.repoRef,
    required this.branch,
    required this.filePath,
    this.lineStart,
    this.lineEnd,
    super.key,
  });

  final RepoRef repoRef;
  final String branch;
  final String filePath;
  final int? lineStart;
  final int? lineEnd;

  (int, int)? get _highlightedLineRange {
    final int? start = lineStart;
    if (start == null) return null;
    final int end = lineEnd ?? start;
    return (start, end);
  }

  String? get _languageFromPath {
    final String ext = filePath.contains('.')
        ? filePath.split('.').last.toLowerCase()
        : '';
    if (ext.isEmpty) return 'plaintext';
    return ext;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FileContentKey key = (
      repo: repoRef,
      branch: branch,
      path: filePath,
    );
    final AsyncValue<FileContent> contentAsync =
        ref.watch(fileContentProvider(key));

    return contentAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (Object err, _) => Center(
        child: Padding(
          padding: context.spacing.screenPadding,
          child: Text(
            'Failed to load file: $err',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.error,
            ),
          ),
        ),
      ),
      data: (FileContent content) {
        if (content.isBinary || content.text == null || content.text!.isEmpty) {
          return Center(
            child: Text(
              'Blame not available for this file',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final blameKey = (
          repoRef: repoRef,
          branch: branch,
          filePath: filePath,
        );
        final blameAsync = ref.watch(blameProvider(blameKey));
        return blameAsync.when(
          loading: () => const Center(child: LoadingIndicator()),
          error: (Object err, _) => Center(
            child: Text(
              'Failed to load blame: $err',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ),
          data: (List<BlameRange> ranges) {
            final String code = content.text!;
            return Padding(
              padding: context.spacing.screenPadding,
              child: AppCodeEditor(
                code: code,
                language: _languageFromPath,
                readOnly: true,
                blameRanges: ranges,
                repoRef: repoRef,
                highlightedLineRange: _highlightedLineRange,
              ),
            );
          },
        );
      },
    );
  }
}
