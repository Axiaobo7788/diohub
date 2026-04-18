import 'package:diohub/common/bottom_sheet/paginated_select_sheet.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';

import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When [issueRef] or [pullRef] is set (edit mode), [onApplyChanges] is called
/// with the sets to add and remove instead of calling notifier methods directly.
/// This keeps premium mutation logic out of this OSS widget.
class AssigneeSelectSheet extends ConsumerStatefulWidget {
  const AssigneeSelectSheet({
    super.key,
    this.assignees,
    this.repoRef,
    this.issueRef,
    this.pullRef,
    this.controller,
    this.newAssignees,
    this.initialSelectedIds,
    this.onApplyChanges,
  });
  final RepoRef? repoRef;
  final IssueRef? issueRef;
  final PullRequestRef? pullRef;
  final List<UserInfoModel>? assignees;
  final ScrollController? controller;
  final ValueChanged<List<UserInfoModel>?>? newAssignees;

  /// Called in edit mode with the diff to apply: (toAdd, toRemove).
  /// If null and in edit mode, no mutations are performed.
  final Future<void> Function(List<String> toAdd, List<String> toRemove)?
  onApplyChanges;

  /// Pre-fill selected IDs (e.g. from template) when [issueRef] is null (new-issue mode).
  final Set<String>? initialSelectedIds;

  @override
  ConsumerState<AssigneeSelectSheet> createState() =>
      _AssigneeSelectSheetState();
}

class _AssigneeSelectSheetState extends ConsumerState<AssigneeSelectSheet> {
  Set<String> _initialAssigneeNodeIds = {};
  bool _initializedFromProvider = false;

  Set<String> get _initialSelectedIds {
    if (widget.issueRef != null || widget.pullRef != null) {
      return _initialAssigneeNodeIds;
    }
    return widget.initialSelectedIds ?? {};
  }

  @override
  Widget build(final BuildContext context) {
    final IssueRef? issueRef = widget.issueRef;
    final PullRequestRef? pullRef = widget.pullRef;
    final RepoRef? repoRef = widget.repoRef;

    if (issueRef != null) {
      ref.listen(issueDetailProvider(issueRef), (
        final AsyncValue<IssueInfo>? prev,
        final AsyncValue<IssueInfo> next,
      ) {
        if (next.value != null && !_initializedFromProvider) {
          final IssueInfo issue = next.value!;
          final List<String> ids =
              issue.assignees.nodes
                  ?.whereType<IssueAssigneeNode>()
                  .map((final IssueAssigneeNode n) => n.id)
                  .toList() ??
              <String>[];
          setState(() {
            _initialAssigneeNodeIds = ids.toSet();
            _initializedFromProvider = true;
          });
        }
      });
    } else if (pullRef != null) {
      ref.listen(pullDetailProvider(pullRef), (
        final AsyncValue<PullInfo>? prev,
        final AsyncValue<PullInfo> next,
      ) {
        if (next.value != null && !_initializedFromProvider) {
          final PullInfo pr = next.value!;
          final List<String> ids =
              pr.assignees.nodes
                  ?.whereType<PullAssigneeNode>()
                  .map((final PullAssigneeNode n) => n.id)
                  .toList() ??
              <String>[];
          setState(() {
            _initialAssigneeNodeIds = ids.toSet();
            _initializedFromProvider = true;
          });
        }
      });
    }

    if (repoRef == null) {
      return const EmptyState(message: 'No repository');
    }

    return PaginatedSelectSheet<AssignableUserEdge>(
      key: ValueKey<Set<String>>(_initialSelectedIds),
      mode: SelectMode.multi,
      searchable: true,
      searchHint: 'Search assignees…',
      initialSelectedIds: _initialSelectedIds,
      scrollController: widget.controller,
      headerWidget: ExpansionTile(
        title: const Text('Note'),
        children: <Widget>[
          Padding(
            padding: context.spacing.screenPadding,
            child: const Text(
              'Organizations on the free plan can only have one active assignee on an issue at a time.',
            ),
          ),
          context.spacing.itemGap,
        ],
      ),
      sourceBuilder: (String? query) => CursorForwardSource<AssignableUserEdge>(
        fetch: ({required int first, String? after}) async {
          final r = await repoRef!
              .collaborators(ref.read(apiClientProvider))
              .listAssignableUsersGQL(first: first, after: after, query: query);
          final List<AssignableUserEdge> items = r.items
              .whereType<AssignableUserEdge>()
              .toList();
          return CursorPage<AssignableUserEdge>(
            items: items,
            hasNextPage: r.hasNextPage,
            endCursor: r.endCursor,
          );
        },
      ),
      idOf: (e) => e.node?.id ?? '',
      titleOf: (e) => e.node?.login ?? '',
      subtitleOf: (e) {
        final n = e.node;
        return (n?.name?.isNotEmpty == true) ? n!.name! : null;
      },
      leadingOf: (BuildContext context, AssignableUserEdge e) =>
          ProfileTile.login(
            avatarUrl: e.node?.avatarUrl.toString() ?? '',
            userLogin: e.node?.login ?? '',
            padding: EdgeInsets.zero,
          ),
      onApplyMulti: (List<AssignableUserEdge> selected) async {
        final bool isNewIssueMode = issueRef == null && pullRef == null;
        if (isNewIssueMode) {
          final List<UserInfoModel> users = selected
              .map(
                (AssignableUserEdge e) => SimpleUser(
                  login: e.node?.login ?? '',
                  avatarUrl: e.node?.avatarUrl.toString() ?? '',
                  id: e.node?.id ?? '',
                ),
              )
              .toList();
          widget.newAssignees?.call(users);
          return;
        }
        final Set<String> selectedIds = selected
            .map((e) => e.node?.id)
            .whereType<String>()
            .toSet();
        final List<String> toAdd = selectedIds
            .difference(_initialAssigneeNodeIds)
            .toList();
        final List<String> toRemove = _initialAssigneeNodeIds
            .difference(selectedIds)
            .toList();
        if (widget.onApplyChanges != null) {
          await widget.onApplyChanges!(toAdd, toRemove);
        }
        widget.newAssignees?.call(null);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
