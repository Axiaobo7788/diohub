import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/common/misc/ref_list_item.dart';
import 'package:diohub/common/events/view_commits_expand_row.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub_models/models/repository/compare_result.dart'
    show CompareCommitSummary;
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/events/compound_data.dart';
import 'package:diohub/utils/events/compound_extractors.dart';
import 'package:diohub/utils/pagination/event_grouping_reducer.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One branch with optional push range (before/head) for compare API.
class _BranchPush {
  const _BranchPush({
    required this.branch,
    this.before,
    this.head,
  });

  final String branch;
  final String? before;
  final String? head;
}

List<_BranchPush> _groupByBranch(final EventCluster pushCluster) {
  final Map<String, _BranchPush> byBranch = <String, _BranchPush>{};

  for (final EventsModel event in pushCluster.events) {
    final String? rawRef = event.payload.ref;
    if (rawRef == null) continue;

    final String branch = rawRef.split('/').last;
    final _BranchPush? existing = byBranch[branch];

    if (existing == null) {
      byBranch[branch] = _BranchPush(
        branch: branch,
        before: event.payload.before,
        head: event.payload.head,
      );
    } else {
      byBranch[branch] = _BranchPush(
        branch: branch,
        before: existing.before ?? event.payload.before,
        head: event.payload.head ?? existing.head,
      );
    }
  }

  return byBranch.values.toList();
}

/// One row in the unified branch context: name, status, optional push range.
class _BranchRowData {
  const _BranchRowData({
    required this.name,
    required this.status,
    this.before,
    this.head,
  });

  final String name;
  final BranchStatus status;
  final String? before;
  final String? head;

  bool get hasPush => before != null && head != null;
  String get cacheKey => '$name|$before|$head';
}

/// Unified branch context: one row per branch (created/deleted/pushed).
/// Push rows expand inline to load and show commits; no bottom sheet.
class UnifiedBranchContext extends ConsumerStatefulWidget {
  const UnifiedBranchContext({
    required this.data,
    required this.compound,
    required this.repoUrl,
    super.key,
  });

  final EventCompoundData data;
  final EventCompound compound;
  final String repoUrl;

  @override
  ConsumerState<UnifiedBranchContext> createState() =>
      _UnifiedBranchContextState();
}

class _UnifiedBranchContextState extends ConsumerState<UnifiedBranchContext> {
  String? _expandedKey;
  final Map<String, List<CompareCommitSummary>> _cache =
      <String, List<CompareCommitSummary>>{};
  final Set<String> _loadingKeys = <String>{};

  List<_BranchRowData> _buildRows() {
    final Map<String, BranchStatus> statusByBranch = <String, BranchStatus>{
      for (final BranchHighlight b in widget.data.branches) b.name: b.status,
    };

    final EventCluster? pushCluster =
        widget.compound.partWith(SemanticAction.push);
    final List<_BranchPush> pushList =
        pushCluster != null ? _groupByBranch(pushCluster) : <_BranchPush>[];

    final Set<String> allNames = <String>{
      ...widget.data.branches.map((final BranchHighlight b) => b.name),
      ...pushList.map((final _BranchPush p) => p.branch),
    };

    final Map<String, _BranchPush> pushByBranch = <String, _BranchPush>{
      for (final _BranchPush p in pushList) p.branch: p,
    };

    final List<_BranchRowData> rows = <_BranchRowData>[];
    for (final String name in allNames) {
      final BranchStatus status = statusByBranch[name] ?? BranchStatus.normal;
      final _BranchPush? push = pushByBranch[name];
      rows.add(
        _BranchRowData(
          name: name,
          status: status,
          before: push?.before,
          head: push?.head,
        ),
      );
    }

    return rows;
  }

  Future<void> _loadCommits(
      final String key, final String? before, final String head) async {
    if (before == null || before.isEmpty) {
      if (mounted) setState(() => _cache[key] = <CompareCommitSummary>[]);
      return;
    } 
    if (_cache.containsKey(key)) return;

    setState(() => _loadingKeys.add(key));
    try {
      final RepoRef repo = RepoRef.fromApiUrl(widget.repoUrl);
      final List<CompareCommitSummary> commits =
          await repo.services(ref.read(apiClientProvider)).getCompareCommits(
        base: before,
        head: head,
      );

      if (mounted) {
        setState(() {
          _loadingKeys.remove(key);
          _cache[key] = commits;
        });
      }
    } catch (e, st) {
      AppLogger.warning(
        'Failed to load compare commits',
        error: e,
        stackTrace: st,
        tag: 'UnifiedBranchContext',
      );
      if (mounted) {
        setState(() => _loadingKeys.remove(key));
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final List<_BranchRowData> rows = _buildRows();
    if (rows.isEmpty) return const SizedBox.shrink();

    final AppSpacing spacing = context.spacing;
    final RepoRef repo = RepoRef.fromApiUrl(widget.repoUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < rows.length; i++) ...<Widget>[
          _UnifiedBranchRow(
            rowData: rows[i],
            repo: repo,
            isExpanded: _expandedKey == rows[i].cacheKey,
            commits: rows[i].hasPush ? _cache[rows[i].cacheKey] : null,
            isLoading:
                rows[i].hasPush && _loadingKeys.contains(rows[i].cacheKey),
            onTap: () {
              if (!rows[i].hasPush) return;
              setState(() {
                if (_expandedKey == rows[i].cacheKey) {
                  _expandedKey = null;
                } else {
                  _expandedKey = rows[i].cacheKey;
                  _loadCommits(
                    rows[i].cacheKey,
                    rows[i].before,
                    rows[i].head!,
                  );
                }
              });
            },
          ),
          if (i < rows.length - 1) SizedBox(height: spacing.itemSpacing),
        ],
      ],
    );
  }
}

class _UnifiedBranchRow extends StatelessWidget {
  const _UnifiedBranchRow({
    required this.rowData,
    required this.repo,
    required this.isExpanded,
    required this.commits,
    required this.isLoading,
    required this.onTap,
  });

  final _BranchRowData rowData;
  final RepoRef repo;
  final bool isExpanded;
  final List<CompareCommitSummary>? commits;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final bool hasPush = rowData.hasPush;

    if (hasPush) {
      return ViewCommitsExpandRow(
        leading: RefListItem(
          variant: RefListItemVariant.branch,
          branchData: RefListItemBranchData(
            name: rowData.name,
            isDeleted: rowData.status == BranchStatus.deleted,
          ),
          isHighlighted: rowData.status == BranchStatus.created,
        ),
        isExpanded: isExpanded,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (isLoading)
              Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.itemSpacing),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (commits != null) ...<Widget>[
              if (commits!.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing.itemSpacing),
                  child: Text(
                    'No commits found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                ...commits!.map(
                  (final CompareCommitSummary c) {
                    final CommitListItemModel model =
                        CommitListItemModel.fromCompareCommitSummary(
                      c.sha,
                      c.message,
                      repo,
                      authorName: c.authorName,
                      authorAvatarUrl: c.authorAvatarUrl,
                      date: c.date,
                    );
                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                      child: BorderedContainer(
                        ref: CommitRef(repo: repo, oid: c.sha),
                        child: CommitCard(data: model),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      );
    }

    return TapFeedback(
      borderRadius: context.radius(RadiusSize.small),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: spacing.itemSpacing,
          horizontal: spacing.itemSpacing,
        ),
        child: RefListItem(
          variant: RefListItemVariant.branch,
          branchData: RefListItemBranchData(
            name: rowData.name,
            isDeleted: rowData.status == BranchStatus.deleted,
          ),
          isHighlighted: rowData.status == BranchStatus.created,
        ),
      ),
    );
  }
}
