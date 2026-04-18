import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/gist_mutation_models.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet to create a new gist (description, one file, public/secret).
Future<void> showCreateGistSheet(
  BuildContext context, {
  required UserRef userRef,
  required VoidCallback onCreated,
}) async {
  await AppSheet.form<void>(
    context,
    header: AppSheetHeader.text('New gist'),
    bodyBuilder: (BuildContext ctx, StateSetter setState) =>
        _CreateGistSheetBody(onCreated: onCreated),
  );
}

class _CreateGistSheetBody extends ConsumerStatefulWidget {
  const _CreateGistSheetBody({required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateGistSheetBody> createState() =>
      _CreateGistSheetBodyState();
}

class _CreateGistSheetBodyState extends ConsumerState<_CreateGistSheetBody> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _filenameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _public = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    _filenameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final filename = _filenameController.text.trim();
    final content = _contentController.text.trim();
    if (filename.isEmpty) {
      setState(() => _error = 'Enter a filename');
      return;
    }
    if (content.isEmpty) {
      setState(() => _error = 'Enter file content');
      return;
    }
    setState(() => _error = null);
    await ref.read(viewerSettingsServiceProvider).createGist(
          description: _descriptionController.text.trim(),
          files: [GistFileInput(filename: filename, content: content)],
          public: _public,
        );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        SizedBox(height: spacing.itemSpacing),
        TextField(
          controller: _filenameController,
          decoration: const InputDecoration(
            labelText: 'Filename',
            hintText: 'hello.dart',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        SizedBox(height: spacing.itemSpacing),
        TextField(
          controller: _contentController,
          decoration: const InputDecoration(
            labelText: 'Content',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
          maxLines: 8,
          onChanged: (_) => setState(() => _error = null),
        ),
        SizedBox(height: spacing.itemSpacing),
        SwitchListTile(
          title: const Text('Public'),
          subtitle: Text(
            _public ? 'Anyone can see this gist' : 'Secret (only you can see)',
            style: theme.textTheme.bodySmall,
          ),
          value: _public,
          onChanged: (bool value) => setState(() => _public = value),
        ),
        if (_error != null) ...[
          SizedBox(height: spacing.tightSpacing),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        SizedBox(height: spacing.sectionSpacing),
        SubmitButton(
          onSubmit: _submit,
          onSuccess: () {
            widget.onCreated();
            Navigator.of(context).pop();
          },
          onError: (e) {
            AppLogger.warning(
              'Create gist failed',
              error: e,
              stackTrace: StackTrace.current,
              tag: 'CreateGistSheet',
            );
            setState(() => _error = e.toString());
          },
          label: (isSubmitting) =>
              Text(isSubmitting ? 'Creating...' : 'Create gist'),
        ),
      ],
    );
  }
}
