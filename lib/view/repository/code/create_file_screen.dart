import 'package:diohub/common/code/app_code_editor.dart';
import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/git/file_change.dart';
import 'package:diohub/providers/code_browser/directory_provider.dart';
import 'package:diohub/providers/repository/commit_file_mutation_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';

/// Screen to create a new file in a directory. Pushed via [Navigator].
class CreateFileScreen extends ConsumerStatefulWidget {
  const CreateFileScreen({
    required this.repoRef,
    required this.branchRef,
    required this.parentPath,
    super.key,
  });

  final RepoRef repoRef;
  final String branchRef;

  /// Directory path (e.g. "lib" or "lib/foo"). New file will be parentPath/fileName.
  final String parentPath;

  @override
  ConsumerState<CreateFileScreen> createState() => _CreateFileScreenState();
}

class _CreateFileScreenState extends ConsumerState<CreateFileScreen> {
  final TextEditingController _fileNameController = TextEditingController();
  late final CodeLineEditingController _codeController;
  final TextEditingController _commitMessageController =
      TextEditingController(text: 'Add ');

  @override
  void initState() {
    super.initState();
    _codeController = CodeLineEditingController.fromText('');
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _codeController.dispose();
    _commitMessageController.dispose();
    super.dispose();
  }

  String? _expectedHeadOid() {
    final repo = ref.read(repositoryProvider(widget.repoRef)).value?.repository;
    final refName = widget.branchRef.startsWith('refs/')
        ? widget.branchRef
        : 'refs/heads/${widget.branchRef}';
    final initialRef = repo?.initialRef;
    if (initialRef?.name != refName) return null;
    return initialRef?.target?.maybeWhen(
      commit: (final c) => c.oid,
      orElse: () => null,
    );
  }

  Future<void> _create() async {
    final String name = _fileNameController.text.trim();
    if (name.isEmpty) {
      ref.read(notificationServiceProvider).error('Enter a file name');
      return;
    }
    final String fullPath =
        widget.parentPath.isEmpty ? name : '${widget.parentPath}/$name';
    final String message = _commitMessageController.text.trim();
    if (message.isEmpty) {
      ref.read(notificationServiceProvider).error('Enter a commit message');
      return;
    }
    final String? expectedHeadOid = _expectedHeadOid();
    if (expectedHeadOid == null) {
      ref.read(notificationServiceProvider).error(
            'Open this branch from the repository to create files',
          );
      return;
    }
    if (widget.branchRef.length == 40) {
      ref.read(notificationServiceProvider).error(
            'Cannot create file when viewing a specific commit',
          );
      return;
    }
    await ref.read(commitFileMutationProvider(widget.repoRef).notifier).commit(
          CommitFileParams(
            branchRef: widget.branchRef,
            expectedHeadOid: expectedHeadOid,
            message: message,
            additions: <FileChange>[
            FileChange(path: fullPath, content: _codeController.text),
            ],  
          ),
        );
  }

  @override
  Widget build(final BuildContext context) {
    final spacing = context.spacing.screenPadding;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New File'),
        actions: <Widget>[
          SubmitButton(
            onSubmit: _create,
            onSuccess: () {
              ref.read(notificationServiceProvider).success('File created');
              ref.invalidate(directoryProvider(
                (
                  repo: widget.repoRef,
                  branch: widget.branchRef,
                  path: widget.parentPath
                ),
              ));
              if (context.mounted) Navigator.of(context).pop();
            },
            onError: (e) => ref
                .read(notificationServiceProvider)
                .error('Create failed: $e'),
            label: (isSubmitting) =>
                Text(isSubmitting ? 'Creating…' : 'Create'),
          ),
        ],
      ),
      body: Padding(
        padding: spacing,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _fileNameController,
              decoration: InputDecoration(
                labelText: 'File name',
                hintText: widget.parentPath.isEmpty
                    ? 'e.g. foo.dart'
                    : 'e.g. bar.dart',
                border: const OutlineInputBorder(),
              ),
              onChanged: (final String value) {
                if (_commitMessageController.text == 'Add ' ||
                    _commitMessageController.text.startsWith('Add ')) {
                  _commitMessageController.text =
                      'Add ${widget.parentPath.isEmpty ? value : '${widget.parentPath}/$value'}';
                }
              },
            ),
            SizedBox(height: spacing.top),
            Expanded(
              child: AppCodeEditor(
                code: '',
                language: 'plaintext',
                readOnly: false,
                controller: _codeController,
                showLineNumbers: true,
                enableFolding: true,
              ),
            ),
            SizedBox(height: spacing.top),
            TextField(
              controller: _commitMessageController,
              decoration: const InputDecoration(
                labelText: 'Commit message',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
