import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/code/app_code_editor.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/code_browser/directory_resource.dart';
import 'package:diohub/providers/repository/repository_document_resource.dart';
import 'package:diohub/providers/repository/repository_readme_resource.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/git/file_change.dart';
import 'package:diohub/providers/code_browser/file_content_provider.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

/// Modal sheet to edit a file: editor + commit message. On success invalidates
/// [fileContentProvider] plus the matching Runtime directory, README, and
/// community-document resources, then pops.
class FileEditSheet {
  /// Shows the edit sheet. [expectedHeadOid] must be the current HEAD OID of the branch.
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required RepoRef repoRef,
    required String branchRef,
    required String filePath,
    required String initialText,
    required String expectedHeadOid,
    String? language,
  }) async {
    await AppSheet.scrollable<void>(
      context,
      header: AppSheetHeader.text('Edit file'),
      bodyBuilder:
          (
            BuildContext ctx,
            StateSetter setState,
            ScrollController scrollController,
          ) => _FileEditSheetBody(
            ref: ref,
            repoRef: repoRef,
            branchRef: branchRef,
            filePath: filePath,
            initialText: initialText,
            expectedHeadOid: expectedHeadOid,
            language: language ?? 'plaintext',
            onSuccess: () => Navigator.of(ctx).pop(),
          ),
    );
  }
}

class _FileEditSheetBody extends StatefulWidget {
  const _FileEditSheetBody({
    required this.ref,
    required this.repoRef,
    required this.branchRef,
    required this.filePath,
    required this.initialText,
    required this.expectedHeadOid,
    required this.language,
    required this.onSuccess,
  });

  final WidgetRef ref;
  final RepoRef repoRef;
  final String branchRef;
  final String filePath;
  final String initialText;
  final String expectedHeadOid;
  final String language;
  final VoidCallback onSuccess;

  @override
  State<_FileEditSheetBody> createState() => _FileEditSheetBodyState();
}

class _FileEditSheetBodyState extends State<_FileEditSheetBody> {
  late final CodeLineEditingController _controller;
  late final TextEditingController _commitMessageController;
  bool _committing = false;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.initialText);
    _commitMessageController = TextEditingController(
      text: 'Update ${widget.filePath}',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _commitMessageController.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    if (_committing) return;
    final String message = _commitMessageController.text.trim();
    if (message.isEmpty) {
      widget.ref
          .read(notificationServiceProvider)
          .error('Enter a commit message');
      return;
    }
    setState(() => _committing = true);
    try {
      final apiClient = widget.ref.read(apiClientProvider);
      await widget.repoRef
          .gitDb(apiClient)
          .commitFileChanges(
            branchRef: widget.branchRef,
            expectedHeadOid: widget.expectedHeadOid,
            message: message,
            additions: <FileChange>[
              FileChange(path: widget.filePath, content: _controller.text),
            ],
          );
      if (!mounted) return;
      final String parentPath = widget.filePath.contains('/')
          ? widget.filePath
                .split('/')
                .sublist(0, widget.filePath.split('/').length - 1)
                .join('/')
          : '';
      final scope = widget.ref.read(activeResourceScopeProvider);
      if (scope != null) {
        final runtime = widget.ref.read(resourceRuntimeProvider);
        invalidateRepositoryDirectoryResource(
          runtime: runtime,
          scope: scope,
          repo: widget.repoRef,
          branch: widget.branchRef,
          path: parentPath,
        );
        invalidateRepositoryReadmeForFiles(
          runtime: runtime,
          scope: scope,
          repo: widget.repoRef,
          branch: widget.branchRef,
          filePaths: <String>[widget.filePath],
        );
        invalidateRepositoryDocumentsForFiles(
          runtime: runtime,
          scope: scope,
          repo: widget.repoRef,
          branch: widget.branchRef,
          filePaths: <String>[widget.filePath],
        );
      }
      widget.ref.invalidate(
        fileContentProvider((
          repo: widget.repoRef,
          branch: widget.branchRef,
          path: widget.filePath,
        )),
      );
      widget.ref.read(notificationServiceProvider).success('Changes committed');
      widget.onSuccess();
    } catch (e, st) {
      AppLogger.warning(
        'File edit commit failed',
        error: e,
        stackTrace: st,
        tag: 'FileEditSheet',
      );
      if (!mounted) return;
      widget.ref.read(notificationServiceProvider).error('Commit failed: $e');
    } finally {
      if (mounted) setState(() => _committing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.spacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 200,
            child: AppCodeEditor(
              code: widget.initialText,
              language: widget.language,
              readOnly: false,
              controller: _controller,
              showLineNumbers: true,
              enableFolding: true,
            ),
          ),
          context.spacing.sectionGap,
          TextField(
            controller: _commitMessageController,
            decoration: const InputDecoration(
              labelText: 'Commit message',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          context.spacing.contentGap,
          FilledButton(
            onPressed: _committing ? null : _commit,
            child: Text(_committing ? 'Committing…' : 'Commit changes'),
          ),
        ],
      ),
    );
  }
}
