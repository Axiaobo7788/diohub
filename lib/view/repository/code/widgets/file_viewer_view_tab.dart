import 'package:diohub/common/code/app_code_editor.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/file_content.dart';
import 'package:diohub/providers/code_browser/file_content_provider.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

/// View tab: file content from [fileContentProvider]; binary/image/markdown/code.
class FileViewerViewTab extends ConsumerWidget {
  const FileViewerViewTab({
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
    if (lineStart == null) return null;
    final int end = lineEnd ?? lineStart!;
    return (lineStart!, end);
  }

  String? get _languageFromPath {
    final String ext =
        filePath.contains('.') ? filePath.split('.').last.toLowerCase() : '';
    if (ext.isEmpty) return 'plaintext';
    return ext;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FileContentKey key = (repo: repoRef, branch: branch, path: filePath);
    final AsyncValue<FileContent> asyncContent =
        ref.watch(fileContentProvider(key));

    return asyncContent.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (Object err, StackTrace _) =>
          CenteredError('Failed to load file: $err'),
      data: (FileContent content) {
        if (content.isBinary) {
          return _buildBinaryBody(context, content.byteSize);
        }
        final String? text = content.text;
        if (text == null || text.isEmpty) {
          return Center(
            child: Text(
              'Empty file',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final String? mime = lookupMimeType(filePath);
        if (mime != null && mime.startsWith('image/')) {
          return _buildImageBody(context, ref);
        }
        if (_isMarkdown(filePath, mime)) {
          return _buildMarkdownBody(context, text);
        }
        return _buildCodeBody(context, text);
      },
    );
  }

  bool _isMarkdown(String path, String? mime) {
    final String lower = path.toLowerCase();
    return lower.endsWith('.md') ||
        lower.endsWith('.markdown') ||
        mime == 'text/markdown';
  }

  Widget _buildBinaryBody(BuildContext context, int byteSize) {
    return Center(
      child: Text(
        'Binary file — $byteSize bytes',
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildImageBody(BuildContext context, WidgetRef ref) {
    final server = ref.read(activeServerConfigProvider);
    final String rawUrl =
        server.rawUrl(repoRef.owner, repoRef.name, branch, filePath).toString();
    return Center(
      child: SingleChildScrollView(
        padding: context.spacing.screenPadding,
        child: Image.network(
          rawUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: context.colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownBody(BuildContext context, String text) {
    return SingleChildScrollView(
      padding: context.spacing.screenPadding,
      child: MarkdownBody(text),
    );
  }

  Widget _buildCodeBody(BuildContext context, String text) {
    return Padding(
      padding: context.spacing.screenPadding,
      child: AppCodeEditor(
        code: text,
        language: _languageFromPath,
        readOnly: true,
        showLineNumbers: true,
        highlightedLineRange: _highlightedLineRange,
        repoRef: repoRef,
      ),
    );
  }
}
