import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/compose/models/compose_config.dart';
import 'package:diohub/common/compose/models/compose_mode.dart';
import 'package:diohub/view/issues_pulls/edit_entity_screen.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class EditIssueScreen extends ConsumerStatefulWidget {
  const EditIssueScreen({
    required this.issueRef,
    super.key,
  });

  final IssueRef issueRef;

  RepoRef get repoRef => issueRef.repo;

  @override
  ConsumerState<EditIssueScreen> createState() => _EditIssueScreenState();
}

class _EditIssueScreenState extends EditEntityScreenState<EditIssueScreen> {
  late IssueState _state;

  @override
  RepoRef get repoRef => widget.issueRef.repo;

  @override
  String get entityTitle => 'Issue';

  void _initFromIssue(IssueInfo? issue) {
    if (issue == null || initialized) return;
    initialized = true;
    title = issue.title;
    body = issue.body ?? '';
    _state = issue.issueState;
    labelIds = issue.labels?.nodes
            ?.whereType<IssueLabelNode>()
            .map((n) => n.id)
            .toList() ??
        [];
    assigneeIds =
        issue.assignees.nodes?.whereType<IssueAssigneeNode>().map((n) => n.id).toList() ?? [];
    milestoneId = issue.milestone?.id;
  }

  @override
  Widget buildAsync(BuildContext context) {
    final issueAsync = ref.watch(issueDetailProvider(widget.issueRef));
    return issueAsync.maybeWhen(
      data: (issue) {
        _initFromIssue(issue);
        return buildContent();
      },
      loading: buildLoadingScaffold,
      error: (e, _) => buildErrorScaffold(e),
      orElse: buildLoadingScaffold,
    );
  }

  @override
  ComposeConfig buildConfig() => ComposeConfig(
        mode: EditIssueMode(issueRef: widget.issueRef),
        repoRef: repoRef,
        title: 'Edit Issue',
        subtitle: repoRef.fullName,
        showTitle: true,
        submitIcon: Icons.check,
        submitLabel: 'Save',
        loadingVerb: 'Saving…',
        initialTitle: title,
        initialBody: body,
        titleValidator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Title cannot be empty' : null,
        onSubmit: (title, body) async {
          await ref.read(issueDetailProvider(widget.issueRef).notifier).updateIssue(
                title: title.trim(),
                body: body.trim(),
                state: _state,
                assigneeIds: assigneeIds,
                labelIds: labelIds,
                milestoneId: milestoneId,
              );
        },
      );

  @override
  List<Widget> buildMetadataWidgets(BuildContext context) => [
        SwitchListTile(
          value: _state == IssueState.OPEN,
          onChanged: (v) {
            setState(() => _state = v ? IssueState.OPEN : IssueState.CLOSED);
          },
          title: Text(_state == IssueState.OPEN ? 'Open' : 'Closed'),
          contentPadding: EdgeInsets.zero,
        ),
      ];
}
