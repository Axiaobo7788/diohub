import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/inline_container.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/timeline/collapsible_minimal_group.dart';
import 'package:diohub/common/timeline/unified_timeline_item.dart';
import 'package:diohub/common/utils/github_visual_styles.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/common/pagination/anchor_highlight.dart';
import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub/common/pagination/load_earlier_button.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/providers/pagination/patch_providers.dart';
import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/providers/compose/compose_draft_notifier.dart';
import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/providers/issue_pulls/comment_provider.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/compound_grouping.dart';
import 'package:diohub/utils/timeline/timeline_compound_data.dart';
import 'package:diohub/utils/timeline/timeline_display_item.dart';
import 'package:diohub/utils/timeline/timeline_edge.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub/utils/timeline/timeline_grouping_strategy.dart';
import 'package:diohub/utils/timeline/timeline_semantic_interpreter.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/widgets/comment_box.dart';
import 'package:diohub/view/issues_pulls/widgets/timeline_context_content.dart';
import 'package:diohub/view/issues_pulls/widgets/timeline_item.dart';
import 'package:flutter/material.dart' hide DatePickerTheme;
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sliver_tools/sliver_tools.dart';

final DateFormat _discussionCommentsSinceFormat = DateFormat('d MMM yyyy');

/// Timeline for issue or PR discussion. Identified by [repo] + [number] + [isPull].
class IssuePullTimeline extends ConsumerStatefulWidget {
  const IssuePullTimeline({
    required this.repo,
    required this.number,
    required this.isPull,
    this.commentsSince,
    this.nodeID,
    this.isLocked,
    this.createdAt,
    this.scrollToCommentId,
    super.key,
  });

  final RepoRef repo;
  final int number;
  final bool isPull;
  final DateTime? commentsSince;
  final String? nodeID;
  final bool? isLocked;
  final DateTime? createdAt;

  /// When set (e.g. issueRef.fragment), scroll to this comment when it appears (e.g. issuecomment-123).
  final String? scrollToCommentId;

  Uri issueUrlFor(ServerConfig server) => isPull
      ? server.webUrl('/${repo.owner}/${repo.name}/pull/$number')
      : server.webUrl('/${repo.owner}/${repo.name}/issues/$number');

  @override
  IssuePullTimelineState createState() => IssuePullTimelineState();
}

class IssuePullTimelineState extends ConsumerState<IssuePullTimeline> {
  DateTime? commentsSince;

  CompoundGrouper<dynamic, Actor, IssueTimelineSemanticAction>? _grouper;

  CompoundGrouper<dynamic, Actor, IssueTimelineSemanticAction>
      get _grouperOrCreate {
    _grouper ??= CompoundGrouper(
      TimelineGroupingStrategy(
        target:
            widget.issueUrlFor(ref.read(activeServerConfigProvider)).toString(),
      ),
    );
    return _grouper!;
  }

  RepoRef get _repoRef => widget.repo;

  static String _scopeKey(final RepoRef repo, final int number) =>
      '${repo.owner}/${repo.name}/$number';

  late final PaginationController<TimelineEdge, TimelineDisplayItem> _controller;

  DateTime? _getSince() =>
      commentsSince?.toUtc().subtract(const Duration(seconds: 30));

  List<TimelineDisplayItem> _groupItems(final List<TimelineEdge> rawEdges) {
    final List<Object> rawNodes =
        rawEdges.map((edge) => edge.node).whereType<Object>().toList();
    final List<dynamic> validNodes = rawNodes
        .where(
          (final node) =>
              TimelineGroupingStrategy.getActorFromNode(node) != null,
        )
        .toList();
    final sections = _grouperOrCreate.group(events: validNodes).sections;
    final entries = flattenSectionsToEntries(sections);
    return applyCollapsingPass(entries);
  }

  @override
  void initState() {
    super.initState();
    commentsSince = widget.commentsSince;
    final issueRef = IssueRef(repo: _repoRef, number: widget.number);
    final service = issueRef.services(ref.read(apiClientProvider));
    
    // Helper to wrap timeline edges based on isPull flag
    List<TimelineEdge> _wrapEdges(List<dynamic> edges) {
      if (widget.isPull) {
        return edges
            .cast<PullTimelineEdge>()
            .map((e) => PullTimelineEdgeWrapper(e))
            .toList();
      } else {
        return edges
            .cast<IssueTimelineEdge>()
            .map((e) => IssueTimelineEdgeWrapper(e))
            .toList();
      }
    }
    
    final source = CursorBidirectionalSource<TimelineEdge>(
      forward: ({required int first, String? after}) async {
        final result = await service.getTimeline(
          refresh: after == null && _getSince() == null,
          after: after,
          since: _getSince(),
        );
        return CursorPage<TimelineEdge>(
          items: _wrapEdges(result.edges.toList()),
          hasNextPage: result.hasNextPage,
          endCursor: result.endCursor,
          startCursor: result.startCursor,
        );
      },
      backward: ({required int last, String? before}) async {
        final result = await service.getTimelineBackward(
          before: before,
          last: last,
        );
        return CursorPage<TimelineEdge>(
          items: _wrapEdges(result.edges.toList()),
          hasNextPage: result.hasPreviousPage,
          endCursor: result.endCursor,
          startCursor: result.startCursor,
        );
      },
      anchor: (String itemId) async {
        final createdAt =
            await ref.read(commentCreatedAtProvider(itemId).future);
        final result = await service.getTimeline(
          refresh: true,
          since: createdAt?.subtract(const Duration(seconds: 30)),
        );
        return AnchorResult<TimelineEdge>(
          items: _wrapEdges(result.edges.toList()),
          hasMoreForward: result.hasNextPage,
          hasMoreBackward: true,
          forwardCursor: result.endCursor,
          backwardCursor: result.startCursor,
        );
      },
    );
    final scopeKey = _scopeKey(_repoRef, widget.number);
    _controller = PaginationController<TimelineEdge, TimelineDisplayItem>(
      source: source,
      idOf: (item) => item.itemId,
      transform: _groupItems,
      boundaryMerger: _tryMergeBoundary,
      containedIdsOf: (item) => item.containedIds,
      pageSize: 20,
      getPatches: () => ref.read(timelinePatchesProvider(scopeKey)),
    );
    if (widget.scrollToCommentId != null) {
      _controller.navigateToAnchor(widget.scrollToCommentId!);
    } else {
      _controller.fetchForward();
    }
  }

  TimelineDisplayItem? _tryMergeBoundary(
    TimelineDisplayItem prev,
    TimelineDisplayItem next,
  ) {
    if (prev is SingleTimelineEntry && next is SingleTimelineEntry) {
      if (prev.actor.login != next.actor.login) return null;
      final combined = [...prev.compound.allEvents, ...next.compound.allEvents];
      final result = _grouperOrCreate.group(events: combined);
      if (result.sections.length == 1 &&
          result.sections.single.compounds.length == 1) {
        final section = result.sections.single;
        return SingleTimelineEntry(
          actor: section.actor,
          compound: section.compounds.single,
        );
      }
      return null;
    }
    if (prev is CollapsedMinimalGroup && next is SingleTimelineEntry) {
      if (next.tier != TimelineTier.minimal) return null;
      return CollapsedMinimalGroup(
        entries: [...prev.entries, next],
      );
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// True when the compound renders as a single line (action text inline with content).
  bool _isSingleLineContext(final TimelineCompoundData data) {
    switch (data.action) {
      case IssueTimelineSemanticAction.assigned:
      case IssueTimelineSemanticAction.unassigned:
        return data.assigneeLogins.length <= 1;
      case IssueTimelineSemanticAction.stateChange:
        return data.closer == null;
      case IssueTimelineSemanticAction.milestoneChange:
        return data.addedMilestoneTitles.length +
                data.removedMilestoneTitles.length <=
            1;
      case IssueTimelineSemanticAction.other:
        return data.previousTitle == null &&
            data.lockReason == null &&
            (data.isPinned ||
                data.isUnpinned ||
                data.isConvertedToDraft ||
                data.isReadyForReview ||
                data.isHeadRefRestored ||
                data.baseRefDeletedName != null ||
                data.headRefDeletedName != null) &&
            data.duplicateCanonicalIssue == null &&
            data.duplicateCanonicalPullRequest == null &&
            (data.unmarkedDuplicateCanonicalIssue == null &&
                data.unmarkedDuplicateCanonicalPullRequest == null) &&
            data.baseRefPreviousName == null &&
            data.forcePushRefName == null;
      case IssueTimelineSemanticAction.labelChange:
      case IssueTimelineSemanticAction.review:
      case IssueTimelineSemanticAction.commitPush:
      case IssueTimelineSemanticAction.crossReference:
      case IssueTimelineSemanticAction.comment:
        return false;
    }
  }

  DraftKey get _commentDraftKey {
    final entityRef = widget.isPull
        ? PullRequestRef(repo: _repoRef, number: widget.number)
        : IssueRef(repo: _repoRef, number: widget.number);
    return DraftKey(
      entityPath: entityRef.apiPath,
      scope: 'comment',
      entityType: entityRef.dbType,
      parentPath: entityRef.parentPath,
    );
  }

  /// Action text with actor prefix for timeline rail (e.g. "naman closed this").
  String _buildActionTextWithActor(final Actor actor, final String verb) =>
      '${actor.login} $verb';

  /// Builds one timeline entry (single compound) with tier-based layout.
  Widget _buildSingleEntry(
    final BuildContext context,
    final SingleTimelineEntry entry,
    final int index,
    final int totalCount,
  ) {
    final TimelineCompound compound = entry.compound;
    final Actor actor = entry.actor;
    final IssueTimelineSemanticAction action = entry.action;
    final TimelineTier tier = entry.tier;
    final bool isFirst = index == 0;
    final bool isLast = index == totalCount - 1;

    final spacing = context.spacing;
    if (tier == TimelineTier.primary &&
        action == IssueTimelineSemanticAction.comment &&
        compound.firstPart.events.length == 1) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.tightSpacing,
          0,
          spacing.tightSpacing,
          0,
        ),
        child: TimelineItem(
          compound.firstPart.events.first,
          pullNodeID: widget.nodeID,
          pullRef: widget.isPull
              ? PullRequestRef(repo: widget.repo, number: widget.number)
              : null,
          issueRef: widget.isPull
              ? null
              : IssueRef(repo: widget.repo, number: widget.number),
          commentDraftKey: _commentDraftKey,
          onQuote: openCommentSheet,
          repoRef: _repoRef,
          scrollToCommentId: widget.scrollToCommentId,
          timelineKey:
              '${widget.repo.owner}/${widget.repo.name}/${widget.number}',
        ),
      );
    }

    if (action == IssueTimelineSemanticAction.review &&
        compound.firstPart.events.length == 1) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.tightSpacing,
          isFirst ? 0 : spacing.sectionSpacing,
          spacing.tightSpacing,
          0,
        ),
        child: TimelineItem(
          compound.firstPart.events.first,
          pullNodeID: widget.nodeID,
          pullRef: widget.isPull
              ? PullRequestRef(repo: widget.repo, number: widget.number)
              : null,
          issueRef: widget.isPull
              ? null
              : IssueRef(repo: widget.repo, number: widget.number),
          commentDraftKey: _commentDraftKey,
          onQuote: openCommentSheet,
          repoRef: _repoRef,
          scrollToCommentId: widget.scrollToCommentId,
          timelineKey:
              '${widget.repo.owner}/${widget.repo.name}/${widget.number}',
        ),
      );
    }

    final TimelineCompoundData timelineData = compound.toTimelineCompoundData();
    final TimelinePartActionData? partAction =
        timelineData.partActions.isNotEmpty
            ? timelineData.partActions.first
            : null;
    final GitHubActionVisual visual = GitHubVisualStyles.fromTimelineAction(
      timelineData.action,
      stateReason: partAction?.stateReason,
      stateVerb: timelineData.stateVerb,
    );
    final String verb = interpretTimeline(compound).displayText;
    final String actionText = _buildActionTextWithActor(actor, verb);
    final bool showActionInline =
        tier == TimelineTier.minimal || _isSingleLineContext(timelineData);
    final InlineContainer content = InlineContainer(
      child: buildTimelineContextContent(
        context,
        timelineData,
        repoRef: _repoRef,
      ),
    );

    final double actionHeaderTopPadding = tier == TimelineTier.minimal
        ? (isFirst ? 0.0 : spacing.tightSpacing)
        : (isFirst ? 0.0 : spacing.itemSpacing);
    return UnifiedTimelineItem(
      actionText: actionText,
      date: showActionInline ? timelineData.createdAt : null,
      eventIcon: visual.icon,
      eventIconColor: visual.color,
      isFirst: isFirst,
      isLast: isLast,
      actionHeaderTopPadding: actionHeaderTopPadding,
      showActionInline: showActionInline,
      borderColor: visual.color,
      childrenOwnSurface: false,
      child: content,
    );
  }

  /// Builds the collapsed minimal group (expandable widget).
  Widget _buildCollapsedGroup(
    final BuildContext context,
    final CollapsedMinimalGroup group,
    final int index,
    final int totalCount,
  ) {
    final DateTime? date = group.entries.isNotEmpty
        ? group.entries.first.compound.toTimelineCompoundData().createdAt
        : null;
    return CollapsibleMinimalGroupWidget(
      group: group,
      date: date,
      buildRow: _buildMinimalRow,
      isFirst: index == 0,
      isLast: index == totalCount - 1,
    );
  }

  /// Compact row for one minimal-tier entry (icon + action text + date).
  Widget _buildMinimalRow(final SingleTimelineEntry entry) {
    final data = entry.compound.toTimelineCompoundData();
    final visual = GitHubVisualStyles.fromTimelineAction(data.action);
    final verb = interpretTimeline(entry.compound).displayText;
    final actionText = _buildActionTextWithActor(entry.actor, verb);
    final theme = Theme.of(context);
    final spacing = context.spacing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(
          visual.icon,
          size: spacing.compactSpacing * 2,
          color: visual.color,
        ),
        SizedBox(width: spacing.itemSpacing),
        Expanded(
          child: Text(
            actionText,
            style: theme.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurface.hinted,
            ),
          ),
        ),
        if (data.createdAt != null) ...<Widget>[
          SizedBox(width: spacing.itemSpacing),
          Text(
            data.createdAt!.toRelativeDate(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant
                  .withValues(alpha: Opacities.secondary),
            ),
          ),
        ],
      ],
    );
  }

  /// Build a single-comment entry for synthetic append after post-comment.
  SingleTimelineEntry buildSyntheticEntry(final dynamic comment) {
    final GroupingResult<TimelineActorSection> result =
        _grouperOrCreate.group(events: <dynamic>[comment]);
    final section = result.sections.single;
    return SingleTimelineEntry(
      actor: section.actor,
      compound: section.compounds.single,
    );
  }

  Future<void> openCommentSheet() async {
    final draftKey = _commentDraftKey;
    final String body = ref
        .read(composeDraftProvider(draftKey))
        .when(data: (v) => v, loading: () => '', error: (_, __) => '');
    await showCommentSheet(
      context,
      onSubmit: () async {
        await ref.read(hapticServiceProvider).mediumImpact();
        final pullRef =
            PullRequestRef(repo: widget.repo, number: widget.number);
        final issueRef = IssueRef(repo: widget.repo, number: widget.number);
        if (widget.isPull) {
          await ref.read(pullDetailProvider(pullRef).notifier).addComment(body);
        } else {
          await ref
              .read(issueDetailProvider(issueRef).notifier)
              .addComment(body);
        }
        ref.read(composeDraftProvider(draftKey).notifier).clear();
        return;
      },
      initialData: body,
      onChanged: (final String value) {
        ref.read(composeDraftProvider(draftKey).notifier).updateBody(value);
      },
      repo: widget.repo,
    );
  }

  Widget _buildTimelineHeader(final BuildContext context) {
    if (commentsSince != null) {
      final scopeKey = _scopeKey(_repoRef, widget.number);
      return Button(
        onTap: () {
          ref.read(timelinePatchesProvider(scopeKey).notifier).clear();
          setState(() {
            commentsSince = null;
          });
          _controller.refresh();
        },
        child: Column(
          children: <Widget>[
            Text(
              'Showing timeline since ${_discussionCommentsSinceFormat.format(commentsSince!)}.',
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.spacing.tightSpacing),
            Text(
              'Load the whole timeline?',
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall,
            ),
          ],
        ),
      );
    }

    final scopeKey = _scopeKey(_repoRef, widget.number);
    return Button(
      onTap: () async {
        await DatePicker.showDateTimePicker(
          context,
          maxTime: DateTime.now(),
          onConfirm: (final DateTime date) {
            ref.read(timelinePatchesProvider(scopeKey).notifier).clear();
            setState(() {
              commentsSince = date;
            });
            _controller.refresh();
          },
          currentTime: widget.createdAt,
        );
      },
      child: Text(
        'Show timeline from a specific time?',
        textAlign: TextAlign.center,
        style: context.textTheme.labelSmall,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final scopeKey = _scopeKey(_repoRef, widget.number);
    ref.listen<Map<String, ItemPatch>>(
      timelinePatchesProvider(scopeKey),
      (_, __) => _controller.notifyPatchesChanged(),
    );
    return AnimatedBuilder(
      animation: _controller.state,
      builder: (final BuildContext ctx, final Widget? child) {
        final state = _controller.state.value;
        final displayItems = state.items;
        final isLoading = state.phase is LoadingForward ||
            state.phase is LoadingBackward ||
            state.phase is Refreshing;
        final itemCount =
            displayItems.length + (state.hasMoreForward && !isLoading ? 1 : 0);
        return MultiSliver(
          children: <Widget>[
            if (state.hasMoreBackward)
              SliverToBoxAdapter(
                child: LoadEarlierButton(
                  onTap: () async => _controller.fetchBackward(),
                ),
              ),
            SliverToBoxAdapter(child: _buildTimelineHeader(context)),
            SliverList.builder(
              itemCount: itemCount,
              itemBuilder: (final BuildContext context, final int index) {
                if (index >= displayItems.length) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _controller.fetchForward(),
                  );
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.spacing.sectionSpacing,
                    ),
                    child: ListLoadingShimmers.timeline(context),
                  );
                }
                final TimelineDisplayItem item = displayItems[index];
                final bool isHighlighted = item.itemId == state.anchorId ||
                    (widget.scrollToCommentId != null &&
                        item.containsCommentFragment(
                          widget.scrollToCommentId!,
                        ));
                final Widget childWidget = switch (item) {
                  SingleTimelineEntry(actor: _, compound: _) =>
                    _buildSingleEntry(
                      context,
                      item,
                      index,
                      displayItems.length,
                    ),
                  CollapsedMinimalGroup(entries: _) => _buildCollapsedGroup(
                      context,
                      item,
                      index,
                      displayItems.length,
                    ),
                };
                return AnchorHighlight(
                  isHighlighted: isHighlighted,
                  child: childWidget,
                );
              },
            ),
            if (isLoading && displayItems.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: ctx.spacing.sectionSpacing,
                  ),
                  child: ListLoadingShimmers.timeline(context),
                ),
              )
            else if (isLoading && displayItems.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: ctx.spacing.sectionSpacing,
                  ),
                  child: ListLoadingShimmers.timeline(context),
                ),
              ),
          ],
        );
      },
    );
  }
}
