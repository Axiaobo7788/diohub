import 'package:diohub/common/bottom_sheet/paginated_select_sheet.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';

import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around [PaginatedSelectSheet] for label multi-select.
/// Used in issue/PR edit flows; syncs selection with issue/PR detail or calls [newLabels] in new-issue mode.
///
/// When [issueRef] or [pullRef] is set (edit mode), [onApplyChanges] is called
/// with the sets to add and remove instead of calling notifier methods directly.
/// This keeps premium mutation logic out of this OSS widget.
class LabelSelectSheet extends ConsumerStatefulWidget {
  const LabelSelectSheet({
    super.key,
    this.labels,
    this.repoRef,
    this.issueRef,
    this.pullRef,
    this.controller,
    this.newLabels,
    this.initialSelectedIds,
    this.onApplyChanges,
  });
  final RepoRef? repoRef;
  final IssueRef? issueRef;
  final PullRequestRef? pullRef;
  final List<LabelNode>? labels;
  final ScrollController? controller;
  final ValueChanged<List<LabelNode>?>? newLabels;

  /// Called in edit mode with the diff to apply: (toAdd, toRemove).
  /// If null and in edit mode, no mutations are performed.
  final Future<void> Function(List<String> toAdd, List<String> toRemove)?
  onApplyChanges;

  /// Pre-fill selected IDs (e.g. from template) when [issueRef] is null (new-issue mode).
  final Set<String>? initialSelectedIds;

  @override
  ConsumerState<LabelSelectSheet> createState() => _LabelSelectSheetState();
}

class _LabelSelectSheetState extends ConsumerState<LabelSelectSheet> {
  Set<String> _initialLabelIds = {};
  bool _initializedFromProvider = false;

  Set<String> get _initialSelectedIds {
    if (widget.issueRef != null || widget.pullRef != null) {
      return _initialLabelIds;
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
              issue.labels?.nodes
                  ?.map((final IssueLabelNode? n) => n?.id)
                  .whereType<String>()
                  .toList() ??
              <String>[];
          setState(() {
            _initialLabelIds = ids.toSet();
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
              pr.labels?.nodes
                  ?.whereType<PullLabelNode>()
                  .map((final PullLabelNode n) => n.id)
                  .toList() ??
              <String>[];
          setState(() {
            _initialLabelIds = ids.toSet();
            _initializedFromProvider = true;
          });
        }
      });
    }

    if (repoRef == null) {
      return const EmptyState(message: 'No repository');
    }

    return PaginatedSelectSheet<LabelEdge>(
      key: ValueKey<Set<String>>(_initialSelectedIds),
      mode: SelectMode.multi,
      searchable: true,
      searchHint: 'Search labels…',
      initialSelectedIds: _initialSelectedIds,
      scrollController: widget.controller,
      sourceBuilder: (String? query) => CursorForwardSource<LabelEdge>(
        fetch: ({required int first, String? after}) async {
          final r = await repoRef!
              .labelsAndMilestones(ref.read(apiClientProvider))
              .listAvailableLabelsGQL(first: first, after: after, query: query);
          final List<LabelEdge> items = r.items.whereType<LabelEdge>().toList();
          return CursorPage<LabelEdge>(
            items: items,
            hasNextPage: r.hasNextPage,
            endCursor: r.endCursor,
          );
        },
      ),
      idOf: (e) => e.node?.id ?? '',
      titleOf: (e) => e.node?.name ?? '',
      leadingOf: (BuildContext context, LabelEdge e) =>
          IssueLabel.fromNameColor(e.node?.name ?? '', e.node?.color ?? ''),
      onApplyMulti: (List<LabelEdge> selected) async {
        final bool isNewIssueMode = issueRef == null && pullRef == null;
        if (isNewIssueMode) {
          final List<LabelNode> nodes = selected
              .map((LabelEdge e) => e.node)
              .whereType<LabelNode>()
              .toList();
          widget.newLabels?.call(nodes);
          return;
        }
        final Set<String> selectedIds = selected
            .map((LabelEdge e) => e.node?.id)
            .whereType<String>()
            .toSet();
        final List<String> toAdd = selectedIds
            .difference(_initialLabelIds)
            .toList();
        final List<String> toRemove = _initialLabelIds
            .difference(selectedIds)
            .toList();
        if (widget.onApplyChanges != null) {
          await widget.onApplyChanges!(toAdd, toRemove);
        }
        widget.newLabels?.call(null);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
