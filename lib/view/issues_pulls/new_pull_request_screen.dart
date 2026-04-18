import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/compose/compose_scaffold.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/common/compose/editor/markdown_live_text_field.dart';
import 'package:diohub/common/compose/models/compose_config.dart';
import 'package:diohub/common/compose/models/compose_mode.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/entity_ref_routes.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/routes/router.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/repository/widgets/branch_select_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

@RoutePage()
class NewPullRequestScreen extends ConsumerStatefulWidget {
  const NewPullRequestScreen({
    required this.repoRef,
    super.key,
    this.initialBaseRef,
    this.initialHeadRef,
  });

  final RepoRef repoRef;
  final String? initialBaseRef;
  final String? initialHeadRef;

  @override
  ConsumerState<NewPullRequestScreen> createState() =>
      _NewPullRequestScreenState();
}

class _NewPullRequestScreenState extends ConsumerState<NewPullRequestScreen> {
  late String _baseRefName;
  late String _headRefName;
  bool _draft = false;
  bool _baseRefNameSet = false;

  @override
  void initState() {
    super.initState();
    _baseRefName = widget.initialBaseRef ?? '';
    _headRefName = widget.initialHeadRef ?? '';
  }

  void _showBranchSheet({required final bool isBase}) {
    AppSheet.scrollable<void>(
      context,
      header: AppSheetHeader.text('Select branch'),
      bodyBuilder: (final BuildContext context, StateSetter setState,
              ScrollController scrollController) =>
          BranchSelectSheet(
        widget.repoRef,
        defaultBranch: ref
            .read(repositoryProvider(widget.repoRef))
            .value
            ?.repository
            ?.defaultBranchRef
            ?.name,
        currentBranch: isBase ? _baseRefName : _headRefName,
        onSelected: (final String name) {
          setState(() {
            if (isBase) {
              _baseRefName = name;
            } else {
              _headRefName = name;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    ref.listen(repositoryProvider(widget.repoRef), (final _, final next) {
      if (next case AsyncData(value: final value)) {
        if (!_baseRefNameSet && _baseRefName.isEmpty) {
          _baseRefNameSet = true;
          setState(() => _baseRefName =
              value.repository?.defaultBranchRef?.name ?? 'main');
        }
      }
    });

    final config = ComposeConfig(
      mode: NewPullRequestMode(
        initialBaseRef: widget.initialBaseRef,
        initialHeadRef: widget.initialHeadRef,
      ),
      repoRef: widget.repoRef,
      title: 'New Pull Request',
      subtitle: widget.repoRef.fullName,
      showTitle: true,
      submitIcon: Icons.check,
      submitLabel: 'Create',
      loadingVerb: 'Creating…',
      titleValidator: (final String? v) =>
          (v == null || v.trim().isEmpty) ? 'Title cannot be empty' : null,
      draftSubject: widget.repoRef,
      draftScope: DraftScope.prBody,
      onSubmit: (final String title, final String body) async {
        if (_baseRefName.isEmpty || _headRefName.isEmpty) {
          throw Exception('Please select base and head branches');
        }
        final int? number = await ref
            .read(repositoryProvider(widget.repoRef).notifier)
            .createPullRequest(
              title: title.trim(),
              body: body.trim().isEmpty ? null : body.trim(),
              baseRefName: _baseRefName,
              headRefName: _headRefName,
              draft: _draft,
            );
        if (number == null) {
          throw Exception('Failed to create pull request');
        }
        final PullRequestRef pullRef =
            PullRequestRef(repo: widget.repoRef, number: number);
        if (mounted) {
          await autoRoute(context).replace(pullRef.toRoute());
        }
      },
    );
    return ComposeScaffold(
      config: config,
      metadataBuilder: (final BuildContext context) {
        final spacing = context.spacing;
        return Padding(
          padding: spacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _BranchChip(
                    label: 'Base',
                    value: _baseRefName.isEmpty
                        ? 'Select base branch'
                        : _baseRefName,
                    onTap: () => _showBranchSheet(isBase: true),
                  ),
                  _BranchChip(
                    label: 'Head',
                    value: _headRefName.isEmpty
                        ? 'Select head branch'
                        : _headRefName,
                    onTap: () => _showBranchSheet(isBase: false),
                  ),
                ],
              ),
              context.spacing.sectionGap,
              CheckboxListTile(
                value: _draft,
                onChanged: (final bool? v) =>
                    setState(() => _draft = v ?? false),
                title: const Text('Create as draft'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              context.spacing.sectionGap,
            ],
          ),
        );
      },
      bodyBuilder: (
        final BuildContext context,
        final TextEditingController titleController,
        final TextEditingController bodyController,
        final FocusNode bodyFocusNode,
      ) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            context.spacing.sectionGap,
            MarkdownLiveTextField(
              controller: bodyController,
              focusNode: bodyFocusNode,
              placeholder: 'Add a description…',
              maxLines: 12,
            ),
          ],
        );
      },
    );
  }
}

class _BranchChip extends StatelessWidget {
  const _BranchChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Chip(
          avatar: const Icon(Octicons.git_branch, size: 18),
          label: Text('$label: $value'),
        ),
      );
}
