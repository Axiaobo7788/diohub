import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/compose/compose_scaffold.dart';
import 'package:diohub/common/compose/editor/markdown_live_text_field.dart';
import 'package:diohub/common/compose/models/compose_config.dart';
import 'package:diohub/common/compose/models/compose_mode.dart';
import 'package:diohub/common/misc/custom_expand_tile.dart';
import 'package:diohub/providers/log_issue_draft_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/routes/entity_ref_routes.dart';
import 'package:diohub/routes/router.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/issues_pulls/widgets/assignee_select_sheet.dart';
import 'package:diohub/view/issues_pulls/widgets/label_select_sheet.dart';
import 'package:diohub/view/issues_pulls/widgets/milestone_select_sheet.dart';
import 'package:diohub/view/repository/issues/models/selected_issue_metadata.dart';
import 'package:diohub/view/repository/issues/project_ids_select_sheet.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class NewIssueScreen extends ConsumerStatefulWidget {
  const NewIssueScreen({
    required this.repoRef,
    super.key,
    this.template,
    this.initialBody,
    this.initialTitle,
  });

  final RepoRef repoRef;
  final RepoIssueTemplate? template;
  final String? initialBody;
  final String? initialTitle;

  @override
  ConsumerState<NewIssueScreen> createState() => NewIssueScreenState();
}

class NewIssueScreenState extends ConsumerState<NewIssueScreen> {
  bool expanded = false;
  bool _appliedLogDraft = false;
  String? _milestoneId;
  List<SelectedLabel> _selectedLabels = <SelectedLabel>[];
  List<SelectedAssignee> _selectedAssignees = <SelectedAssignee>[];
  List<String> _selectedProjectIds = <String>[];

  @override
  void initState() {
    super.initState();
    final RepoIssueTemplate? t = widget.template;
    if (t != null && t.labels?.nodes != null) {
      _selectedLabels = t.labels!.nodes!
          .whereType<RepoIssueTemplateLabel>()
          .map((n) => SelectedLabel(id: n.id, name: n.name, color: n.color))
          .toList();
    }
    if (t != null && t.assignees.nodes != null) {
      _selectedAssignees = t.assignees.nodes!
          .whereType<RepoIssueTemplateAssignee>()
          .map((n) => SelectedAssignee(
                id: n.id,
                login: n.login,
                avatarUrl: n.avatarUrl.toString(),
              ))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final logDraft = ref.watch(pendingLogIssueDraftProvider);
    String initialTitle = widget.template?.title ?? widget.initialTitle ?? '';
    String initialBody = widget.template?.body ?? widget.initialBody ?? '';
    if (logDraft != null && !_appliedLogDraft) {
      initialTitle = logDraft.title;
      initialBody = logDraft.body;
      ref.read(pendingLogIssueDraftProvider.notifier).state = null;
      _appliedLogDraft = true;
    }

    final config = ComposeConfig(
      mode: NewIssueMode(template: widget.template),
      repoRef: widget.repoRef,
      title: 'New Issue',
      subtitle: widget.repoRef.fullName,
      showTitle: true,
      submitIcon: Icons.add,
      submitLabel: 'Create',
      loadingVerb: 'Creating…',
      initialTitle: initialTitle,
      initialBody: initialBody,
      titleValidator: (String? v) =>
          (v == null || v.trim().isEmpty) ? 'Title cannot be empty' : null,
      draftSubject: widget.repoRef,
      draftScope: DraftScope.issueBody,
      onSubmit: (String title, String body) async {
        final int? number = await ref
            .read(repositoryProvider(widget.repoRef).notifier)
            .createIssue(
              title.trim(),
              body: body.trim().isEmpty ? null : body.trim(),
              issueTemplate: widget.template?.name,
              milestoneId: _milestoneId,
              labelIds: _selectedLabels.isEmpty
                  ? null
                  : _selectedLabels.map((e) => e.id).toList(),
              assigneeIds: _selectedAssignees.isEmpty
                  ? null
                  : _selectedAssignees.map((e) => e.id).toList(),
              projectIds:
                  _selectedProjectIds.isEmpty ? null : _selectedProjectIds,
            );
        if (number == null) throw Exception('Failed to create issue');
        final IssueRef issueRef =
            IssueRef(repo: widget.repoRef, number: number);
        if (mounted) {
          await autoRoute(context).replace(issueRef.toRoute());
        }
      },
    );
    return ComposeScaffold(
      config: config,
      metadataBuilder: (BuildContext context) => Padding(
            padding: EdgeInsets.all(context.spacing.itemSpacing),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                InkWell(
                  onTap: () async {
                    final List<LabelNode>? result =
                        await AppSheet.scrollable<List<LabelNode>>(
                      context,
                      header: AppSheetHeader.text('Labels'),
                      bodyBuilder: (BuildContext ctx, StateSetter setState,
                              ScrollController scrollController) =>
                          LabelSelectSheet(
                        repoRef: widget.repoRef,
                        issueRef: null,
                        initialSelectedIds:
                            _selectedLabels.map((e) => e.id).toSet(),
                        newLabels: (List<LabelNode>? nodes) {
                          Navigator.pop(ctx, nodes);
                        },
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() => _selectedLabels = result
                          .map(
                            (n) => SelectedLabel(
                              id: n.id,
                              name: n.name,
                              color: n.color,
                            ),
                          )
                          .toList());
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Chip(
                    label: Text(
                      _selectedLabels.isEmpty
                          ? 'Labels'
                          : 'Labels (${_selectedLabels.length})',
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final List<UserInfoModel>? result =
                        await AppSheet.scrollable<List<UserInfoModel>>(
                      context,
                      header: AppSheetHeader.text('Assignees'),
                      bodyBuilder: (BuildContext ctx, StateSetter setState,
                              ScrollController scrollController) =>
                          AssigneeSelectSheet(
                        repoRef: widget.repoRef,
                        issueRef: null,
                        initialSelectedIds:
                            _selectedAssignees.map((e) => e.id).toSet(),
                        newAssignees: (List<UserInfoModel>? list) {
                          Navigator.pop(ctx, list);
                        },
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() => _selectedAssignees = result
                          .map(
                            (u) => SelectedAssignee(
                              id: u.id ?? '',
                              login: u.login,
                              avatarUrl: u.avatarUrl ?? '',
                            ),
                          )
                          .toList());
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Chip(
                    label: Text(
                      _selectedAssignees.isEmpty
                          ? 'Assignees'
                          : 'Assignees (${_selectedAssignees.length})',
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await AppSheet.scrollable<void>(
                      context,
                      header: AppSheetHeader.text('Milestone'),
                      bodyBuilder: (BuildContext ctx, StateSetter setState,
                              ScrollController scrollController) =>
                          MilestoneSelectSheet(
                        scrollController: scrollController,
                        repoRef: widget.repoRef,
                        initialMilestoneId: _milestoneId,
                        onSelected: (String? id) {
                          setState(() => _milestoneId = id);
                        },
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Chip(
                    label: Text(
                      _milestoneId == null ? 'Milestone' : 'Milestone selected',
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final List<String>? result =
                        await AppSheet.scrollable<List<String>>(
                      context,
                      header: AppSheetHeader.text('Projects'),
                      bodyBuilder: (BuildContext ctx, StateSetter setState,
                              ScrollController scrollController) =>
                          ProjectIdsSelectSheet(
                        scrollController: scrollController,
                        repoRef: widget.repoRef,
                        initialSelectedIds: _selectedProjectIds.toSet(),
                        onSelected: (List<String> ids) {
                          Navigator.of(ctx).pop(ids);
                        },
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() => _selectedProjectIds = result);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Chip(
                    label: Text(
                      _selectedProjectIds.isEmpty
                          ? 'Projects'
                          : 'Projects (${_selectedProjectIds.length})',
                    ),
                  ),
                ),
              ],
        ),
      ),
      headerBuilder: widget.template != null
          ? (BuildContext context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CustomExpandTile(
                    expanded: expanded,
                    title: Text(
                      widget.template!.name,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                    ),
                    onTap: () => setState(() => expanded = !expanded),
                    child: Column(
                      children: <Widget>[
                        if (widget.template!.about != null)
                          Padding(
                            padding: context.spacing.pagePadding,
                            child: Text(widget.template!.about!),
                          ),
                      ],
                    ),
                  ),
                  context.spacing.itemGap,
                ],
              )
          : null,
      bodyBuilder: (
        BuildContext context,
        TextEditingController titleController,
        TextEditingController bodyController,
        FocusNode bodyFocusNode,
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
              maxLines: 5,
              minLines: 1,
            ),
            context.spacing.sectionGap,
            MarkdownLiveTextField(
              controller: bodyController,
              focusNode: bodyFocusNode,
              placeholder: 'Add a description…',
              maxLines: 99,
            ),
          ],
        );
      },
    );
  }
}
