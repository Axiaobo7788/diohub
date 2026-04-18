import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/repository/create_from_template_mutation_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet to create a new repository from a template.
/// Shows name, description, owner (viewer), visibility, include all branches.
Future<RepoRef?> showUseTemplateSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String templateRepoId,
  String templateName = 'template',
}) async {
  return AppSheet.form<RepoRef?>(
    context,
    header: AppSheetHeader.text('Use template'),
    bodyBuilder: (BuildContext ctx, StateSetter setState) => _UseTemplateSheet(
      templateRepoId: templateRepoId,
      templateName: templateName,
    ),
  );
}

class _UseTemplateSheet extends ConsumerStatefulWidget {
  const _UseTemplateSheet({
    required this.templateRepoId,
    required this.templateName,
  });

  final String templateRepoId;
  final String templateName;

  @override
  ConsumerState<_UseTemplateSheet> createState() => _UseTemplateSheetState();
}

class _UseTemplateSheetState extends ConsumerState<_UseTemplateSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  RepositoryVisibility _visibility = RepositoryVisibility.PRIVATE;
  bool _includeAllBranches = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.templateName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_formKey.currentState?.validate() != true) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final viewer = ref.read(currentUserProvider).value;
    if (viewer?.id == null) return;
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final notifier = ref.read(createFromTemplateMutationProvider.notifier);
    final repository = await notifier.create(
      templateRepoId: widget.templateRepoId,
      name: name,
      ownerId: viewer!.id,
      visibility: _visibility,
      description: description,
      includeAllBranches: _includeAllBranches,
    );
    if (!mounted) return;
    Navigator.of(context).pop(RepoRef(
      owner: repository!.owner.login,
      name: repository.name,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(createFromTemplateMutationProvider);
    final isLoading = mutationState.isLoading;
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final viewer = ref.watch(currentUserProvider).value;

    return Padding(
      padding: spacing.pagePadding,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Use this template',
              style: theme.textTheme.titleLarge,
            ),
            context.spacing.sectionGap,
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Repository name *',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            context.spacing.contentGap,
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              enabled: !isLoading,
            ),
            context.spacing.contentGap,
            DropdownButtonFormField<RepositoryVisibility>(
              value: _visibility,
              decoration: const InputDecoration(
                labelText: 'Visibility',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: RepositoryVisibility.PUBLIC,
                  child: Text('Public'),
                ),
                const DropdownMenuItem(
                  value: RepositoryVisibility.PRIVATE,
                  child: Text('Private'),
                ),
              ],
              onChanged: isLoading
                  ? null
                  : (v) {
                      if (v != null) setState(() => _visibility = v);
                    },
            ),
            context.spacing.contentGap,
            CheckboxListTile(
              value: _includeAllBranches,
              onChanged: isLoading
                  ? null
                  : (v) => setState(() => _includeAllBranches = v ?? false),
              title: const Text('Include all branches'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (viewer != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Owner: ${viewer.login}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            context.spacing.sectionGap,
            FilledButton(
              onPressed: (isLoading || viewer == null) ? null : _create,
              child: isLoading
                  ? const ButtonSpinner(size: 20)
                  : const Text('Create repository'),
            ),
          ],
        ),
      ),
    );
  }
}
