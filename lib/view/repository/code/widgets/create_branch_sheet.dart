import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/bottom_sheet/paginated_select_sheet.dart';
import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub_models/models/repositories/create_ref_name.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet to create a new branch or tag from a source ref.
///
/// [onCreated] is called after successful create (sheet pops).
class CreateBranchSheet extends ConsumerStatefulWidget {
  const CreateBranchSheet({
    required this.repoRef,
    required this.repositoryId,
    required this.onCreated,
    super.key,
  });

  final RepoRef repoRef;
  final String repositoryId;
  final VoidCallback onCreated;

  static Future<void> show(
    BuildContext context, {
    required RepoRef repoRef,
    required String repositoryId,
    required VoidCallback onCreated,
  }) async {
    return AppSheet.form<void>(
      context,
      header: AppSheetHeader.text('Create Branch'),
      bodyBuilder: (BuildContext context, StateSetter setState) =>
          CreateBranchSheet(
            repoRef: repoRef,
            repositoryId: repositoryId,
            onCreated: onCreated,
          ),
    );
  }

  @override
  ConsumerState<CreateBranchSheet> createState() => _CreateBranchSheetState();
}

class _CreateBranchSheetState extends ConsumerState<CreateBranchSheet> {
  final TextEditingController _nameController = TextEditingController();
  BranchEdge? _selectedSource;
  String? _error;

  CreateRefName _refKind = CreateRefName.branch('');

  Future<void> _pickSourceBranch() async {
    final BranchEdge? selected = await AppSheet.scrollable<BranchEdge?>(
      context,
      header: AppSheetHeader.text('Source branch'),
      bodyBuilder:
          (
            BuildContext ctx,
            StateSetter setState,
            ScrollController scrollController,
          ) {
            return PaginatedSelectSheet<BranchEdge>(
              mode: SelectMode.single,
              searchable: true,
              searchHint: 'Search branches…',
              scrollController: scrollController,
              sourceBuilder: (String? query) => CursorForwardSource<BranchEdge>(
                fetch: ({required int first, String? after}) async {
                  final r = await widget.repoRef
                      .branches(ref.read(apiClientProvider))
                      .fetchBranchesPaginated(
                        first: first,
                        after: after,
                        query: query,
                      );
                  return CursorPage<BranchEdge>(
                    items: r.items,
                    hasNextPage: r.hasNextPage,
                    endCursor: r.endCursor,
                  );
                },
              ),
              idOf: (e) => e.node?.name ?? '',
              titleOf: (e) => e.node?.name ?? '',
              onSelectSingle: (BranchEdge item) {
                if (ctx.mounted) Navigator.of(ctx).pop(item);
              },
            );
          },
    );
    if (selected != null && mounted) {
      setState(() => _selectedSource = selected);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _sourceOid() {
    final target = _selectedSource?.node?.target;
    if (target == null) return null;
    return target.maybeWhen(commit: (c) => c.oid, orElse: () => null);
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    final oid = _sourceOid();
    if (oid == null) {
      setState(() => _error = 'Select a source ref');
      return;
    }
    final refName = _refKind.withName(name);
    await widget.repoRef
        .branches(ref.read(apiClientProvider))
        .createRef(
          repositoryId: widget.repositoryId,
          refType: refName.isTag ? 'tag' : 'branch',
          refName: refName.name,
          oid: oid,
        );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final theme = Theme.of(context);
    return Padding(
      padding: spacing.screenPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create ${_refKind.displayLabel.toLowerCase()}',
            style: theme.textTheme.titleLarge,
          ),
          spacing.itemGap,
          SwitchListTile(
            title: Text('Create as ${CreateRefName.tag('').displayLabel}'),
            value: _refKind.isTag,
            onChanged: (v) => setState(
              () => _refKind = v
                  ? CreateRefName.tag('')
                  : CreateRefName.branch(''),
            ),
          ),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '${_refKind.displayLabel} name',
              hintText: _refKind.isTag ? 'e.g. v1.0.0' : 'e.g. feature/foo',
              errorText: _error,
            ),
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
          ),
          spacing.itemGap,
          ListTile(
            title: Text(_selectedSource?.node?.name ?? 'Select source branch'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickSourceBranch,
          ),
          spacing.sectionGap,
          SubmitButton(
            onSubmit: _create,
            onSuccess: () {
              Navigator.of(context).pop();
              widget.onCreated();
            },
            onError: (e) {
              AppLogger.warning(
                'Create ref failed',
                error: e,
                stackTrace: StackTrace.current,
                tag: 'CreateBranchSheet',
              );
              setState(() => _error = e.toString());
            },
            icon: Icon(_refKind.icon),
            label: (isSubmitting) =>
                Text(isSubmitting ? 'Creating…' : 'Create'),
            enabled: _selectedSource != null,
          ),
        ],
      ),
    );
  }
}
