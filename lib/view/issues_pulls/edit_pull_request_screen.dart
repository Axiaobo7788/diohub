import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/compose/models/compose_config.dart';
import 'package:diohub/common/compose/models/compose_mode.dart';
import 'package:diohub/view/issues_pulls/edit_entity_screen.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class EditPullRequestScreen extends ConsumerStatefulWidget {
  const EditPullRequestScreen({
    required this.pullRef,
    super.key,
  });

  final PullRequestRef pullRef;

  RepoRef get repoRef => pullRef.repo;

  @override
  ConsumerState<EditPullRequestScreen> createState() =>
      _EditPullRequestScreenState();
}

class _EditPullRequestScreenState
    extends EditEntityScreenState<EditPullRequestScreen> {
  late String _baseRefName;
  late PullRequestUpdateState _state;

  @override
  RepoRef get repoRef => widget.pullRef.repo;

  @override
  String get entityTitle => 'Pull Request';

  void _initFromPullRequest(PullInfo? pullRequest) {
    if (pullRequest == null || initialized) return;
    initialized = true;
    title = pullRequest.title;
    body = pullRequest.body ?? '';
    _state = pullRequest.pullRequestState == PullRequestState.OPEN
        ? PullRequestUpdateState.OPEN
        : PullRequestUpdateState.CLOSED;
    _baseRefName = pullRequest.baseRef?.name ?? '';
    labelIds = pullRequest.labels?.nodes
            ?.whereType<PullLabelNode>()
            .map((n) => n.id)
            .toList() ??
        [];
    assigneeIds =
        pullRequest.assignees.nodes?.whereType<PullAssigneeNode>().map((n) => n.id).toList() ??
            [];
    milestoneId = pullRequest.milestone?.id;
  }

  @override
  Widget buildAsync(BuildContext context) {
    final pullAsync = ref.watch(pullDetailProvider(widget.pullRef));
    return pullAsync.maybeWhen(
      data: (pr) {
        _initFromPullRequest(pr);
        return buildContent();
      },
      loading: buildLoadingScaffold,
      error: (e, _) => buildErrorScaffold(e),
      orElse: buildLoadingScaffold,
    );
  }

  @override
  ComposeConfig buildConfig() => ComposeConfig(
        mode: EditPullRequestMode(pullRef: widget.pullRef),
        repoRef: repoRef,
        title: 'Edit Pull Request',
        subtitle: repoRef.fullName,
        showTitle: true,
        submitIcon: Icons.check,
        submitLabel: 'Save',
        loadingVerb: 'Saving…',
        initialTitle: title,
        initialBody: body,
        draftSubject: widget.pullRef,
        draftScope: DraftScope.prBody,
        titleValidator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Title cannot be empty' : null,
        onSubmit: (title, body) async {
          await ref
              .read(pullDetailProvider(widget.pullRef).notifier)
              .updatePullRequest(
                title: title.trim(),
                body: body.trim(),
                state: _state,
                assigneeIds: assigneeIds,
                labelIds: labelIds,
                milestoneId: milestoneId,
                baseRefName: _baseRefName.isNotEmpty ? _baseRefName : null,
              );
        },
      );

  @override
  List<Widget> buildMetadataWidgets(BuildContext context) => [
        SwitchListTile(
          value: _state == PullRequestUpdateState.OPEN,
          onChanged: (v) {
            setState(
              () => _state =
                  v ? PullRequestUpdateState.OPEN : PullRequestUpdateState.CLOSED,
            );
          },
          title: Text(
            _state == PullRequestUpdateState.OPEN ? 'Open' : 'Closed',
          ),
          contentPadding: EdgeInsets.zero,
        ),
        if (_baseRefName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Base branch: $_baseRefName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ];
}
