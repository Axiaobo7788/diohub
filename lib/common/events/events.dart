import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/cards/release_card.dart';
import 'package:diohub/common/cards/discussion_card.dart';
import 'package:diohub/common/events/compound_annotation_chips.dart';
import 'package:diohub/common/events/unified_branch_context.dart';
import 'package:diohub/common/misc/floating_glass_pill.dart';
import 'package:diohub/common/misc/glass_pill_constants.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/common/pagination/pagination_phase.dart'
    show
        Failed,
        FetchDirection,
        Idle,
        LoadingForward,
        PaginationPhase,
        Refreshing;
import 'package:diohub/common/timeline/unified_timeline_item.dart';
import 'package:diohub/common/timeline_content/timeline_issue_content.dart';
import 'package:diohub/common/timeline_content/timeline_pull_request_content.dart';
import 'package:diohub/common/utils/github_visual_styles.dart';
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/providers/activity/events_provider.dart';
import 'package:diohub/providers/settings/events_provider.dart'
    as settings_events;
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/compound_grouping.dart';
import 'package:diohub/utils/events/compound_data.dart';
import 'package:diohub/utils/events/compound_extractors.dart';
import 'package:diohub/utils/events/event_action.dart';
import 'package:diohub/utils/events/event_texts.dart';
import 'package:diohub/utils/events/semantic_interpreter.dart';
import 'package:diohub/utils/pagination/event_grouping_reducer.dart';
import 'package:diohub/utils/pagination/infinite_pagination_data_handler.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/src/widgets/sliver_sticky_header.dart';
import 'package:sliver_tools/sliver_tools.dart';

typedef ActivityLoadMoreCallback = Future<bool> Function();

class Events extends ConsumerStatefulWidget {
  const Events({
    this.privateEvents = true,
    this.specificUser,
    this.orgLogin,
    this.mockEvents,
    this.refreshRegistrar,
    this.loadMoreRegistrar,
    super.key,
  });

  /// Render pre-built mock events directly, bypassing the API.
  /// Pass a list of [EventsModel] (e.g. from `mockAllEventTypes()` or
  /// `mockRealisticFeed()` in `test/mocks/mock_events.dart`).
  const Events.mock(
    final List<EventsModel> events, {
    this.refreshRegistrar,
    this.loadMoreRegistrar,
    super.key,
  }) : privateEvents = false,
       specificUser = null,
       orgLogin = null,
       mockEvents = events;

  final bool privateEvents;
  final String? specificUser;
  final String? orgLogin;

  /// When non-null, the widget renders these events directly instead of
  /// fetching from the API. Useful for visual testing / Storybook-style
  /// preview of all event types and compound merging scenarios.
  final List<EventsModel>? mockEvents;

  /// When non-null, the widget registers its refresh callback here so
  /// pull-to-refresh (e.g. [SliverBuilderBody.refreshRegistrar]) can trigger it.
  final ValueNotifier<Future<void> Function()?>? refreshRegistrar;

  /// Registers a callback that fetches the next page and reports whether
  /// another page may still be available. The enclosing scroll view uses this
  /// to prefetch before the user reaches the end of the feed.
  final ValueNotifier<ActivityLoadMoreCallback?>? loadMoreRegistrar;

  /// Whether to apply top padding. Set to false when tab bar is visible.
  // final bool hasTopPadding;

  @override
  ConsumerState<Events> createState() => _EventsState();
}

class _EventsState extends ConsumerState<Events> {
  // Allowed event types for filtering
  static const Set<EventsType> _allowedEventTypes = <EventsType>{
    EventsType.CommitCommentEvent,
    EventsType.CreateEvent,
    EventsType.DeleteEvent,
    EventsType.DiscussionEvent,
    EventsType.ForkEvent,
    EventsType.GollumEvent,
    EventsType.IssueCommentEvent,
    EventsType.IssuesEvent,
    EventsType.MemberEvent,
    EventsType.PublicEvent,
    EventsType.PullRequestEvent,
    EventsType.PullRequestReviewEvent,
    EventsType.PushEvent,
    EventsType.ReleaseEvent,
    EventsType.WatchEvent,
  };

  List<EventsModel> _filterEvents(final List<EventsModel> items) => items
      .where((final EventsModel item) => _allowedEventTypes.contains(item.type))
      .toList();

  late final PaginationController<EventsModel, ActorEventSection>
  _paginationController;

  Future<bool> _loadMore() async {
    final PaginationState<ActorEventSection> before =
        _paginationController.state.value;
    if (!before.hasMoreForward ||
        before.phase is LoadingForward ||
        before.phase is Refreshing ||
        before.phase is Failed) {
      return false;
    }
    await _paginationController.fetchForward();
    final PaginationState<ActorEventSection> after =
        _paginationController.state.value;
    return after.hasMoreForward && after.phase is! Failed;
  }

  @override
  void initState() {
    super.initState();
    final EventsQueryKey key = EventsQueryKey(
      specificUser: widget.specificUser,
      orgLogin: widget.orgLogin,
      privateEvents: widget.privateEvents,
    );
    _paginationController =
        PaginationController<EventsModel, ActorEventSection>(
          source: PageNumberForwardSource<EventsModel>(
            fetch: ({required int page, required int perPage}) async {
              if (widget.mockEvents != null) {
                return page == 1 ? widget.mockEvents! : <EventsModel>[];
              }
              return fetchEventsPage(
                ref,
                key,
                PageRequest<EventsModel>(
                  page: page,
                  pageSize: perPage,
                  refresh: false,
                ),
              );
            },
          ),
          idOf: (final ActorEventSection s) => s.itemId,
          transform: (final List<EventsModel> rawItems) {
            final bool compoundActions = ref
                .read(settings_events.eventsProvider)
                .compoundActions;
            final GroupingStrategy<EventsModel, Actor, SemanticAction>
            strategy = compoundActions
                ? EventGroupingStrategy()
                : StandaloneEventGroupingStrategy(EventGroupingStrategy());
            final CompoundGrouper<EventsModel, Actor, SemanticAction> grouper =
                CompoundGrouper(strategy);
            final List<EventsModel> filteredItems = _filterEvents(rawItems);
            return grouper.group(events: filteredItems).sections;
          },
          boundaryMerger:
              (final ActorEventSection prev, final ActorEventSection next) {
                final bool compoundActions = ref
                    .read(settings_events.eventsProvider)
                    .compoundActions;
                final GroupingStrategy<EventsModel, Actor, SemanticAction>
                strategy = compoundActions
                    ? EventGroupingStrategy()
                    : StandaloneEventGroupingStrategy(EventGroupingStrategy());
                final CompoundGrouper<EventsModel, Actor, SemanticAction>
                grouper = CompoundGrouper(strategy);
                return grouper.tryMergeBoundary(prev, next);
              },
          pageSize: 10,
        );
    widget.refreshRegistrar?.value = () => _paginationController.refresh();
    widget.loadMoreRegistrar?.value = _loadMore;
  }

  @override
  void dispose() {
    widget.refreshRegistrar?.value = null;
    widget.loadMoreRegistrar?.value = null;
    _paginationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant final Events oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshRegistrar != widget.refreshRegistrar) {
      oldWidget.refreshRegistrar?.value = null;
      widget.refreshRegistrar?.value = () => _paginationController.refresh();
    }
    if (oldWidget.loadMoreRegistrar != widget.loadMoreRegistrar) {
      oldWidget.loadMoreRegistrar?.value = null;
      widget.loadMoreRegistrar?.value = _loadMore;
    }
  }

  EdgeInsets _paddingBuilder(final BuildContext context) {
    final AppSpacing sp = context.spacing;
    return EdgeInsets.only(
      top: sp.itemSpacing,
      left: sp.listInset.left,
      right: sp.listInset.right,
    );
  }

  Widget _buildGroupSliver(
    final BuildContext context,
    final ActorEventSection group,
  ) {
    final bool shouldShowUserHeader = widget.specificUser == null;

    if (!shouldShowUserHeader) {
      return SliverList(
        delegate: SliverChildBuilderDelegate((
          final BuildContext context,
          final int index,
        ) {
          final Compound<SemanticAction, EventsModel> compound =
              group.compounds[index];
          final bool isFirstCompound = index == 0;
          final bool isLastCompound = index == group.compounds.length - 1;
          return _buildTimelineEventFromCompound(
            compound,
            context,
            isFirstInUserGroup: isFirstCompound,
            isLastInUserGroup: isLastCompound,
          );
        }, childCount: group.compounds.length),
      );
    }
    return PinnedGlassHeader(
      headerBuilder:
          (final BuildContext context, final SliverStickyHeaderState state) =>
              _buildActorHeader(context, ref, group.actor),
      style: GlassPillStyle(
        context,
        restingPadding: EdgeInsets.zero,
        restingInnerPadding: const EdgeInsets.only(top: 4),
        floatingInnerPadding: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: 8,
        ),
        floatingPadding: context.glassPill.sectionFloatPadding.copyWith(
          left: 0,
          right: 0,
        ),
        restingColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((
          final BuildContext context,
          final int index,
        ) {
          final Compound<SemanticAction, EventsModel> compound =
              group.compounds[index];
          final bool isFirstCompound = index == 0;
          final bool isLastCompound = index == group.compounds.length - 1;
          return _buildTimelineEventFromCompound(
            compound,
            context,
            isFirstInUserGroup: isFirstCompound,
            isLastInUserGroup: isLastCompound,
          );
        }, childCount: group.compounds.length),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    ref.watch(settings_events.eventsProvider);
    final AppSpacing sp = context.spacing;

    return ValueListenableBuilder<PaginationState<ActorEventSection>>(
      valueListenable: _paginationController.state,
      builder:
          (
            final BuildContext context,
            final PaginationState<ActorEventSection> state,
            final _,
          ) {
            final List<ActorEventSection> items = state.items;
            final PaginationPhase phase = state.phase;
            final bool isLoadingFirst =
                (phase is LoadingForward || phase is Refreshing) &&
                items.isEmpty;

            if (isLoadingFirst) {
              return SliverPadding(
                padding: _paddingBuilder(context),
                sliver: SliverToBoxAdapter(
                  child: ListLoadingShimmers.timeline(
                    context,
                    itemCount: 3,
                    showUserHeaders: true,
                    padding: EdgeInsets.only(
                      top: sp.itemSpacing,
                      left: sp.listInset.left,
                      right: sp.listInset.right,
                    ),
                  ),
                ),
              );
            }

            if (items.isEmpty && phase is Idle && !state.hasMoreForward) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: context.spacing.emptyStatePadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.dynamic_feed_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        context.spacing.sectionGap,
                        Text(
                          context.l10n.activityNoRecent,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        context.spacing.itemGap,
                        Text(
                          context.l10n.activityNoRecentBody,
                          textAlign: TextAlign.center,
                        ),
                        context.spacing.sectionGap,
                        OutlinedButton.icon(
                          onPressed: () =>
                              unawaited(_paginationController.refresh()),
                          icon: const Icon(Icons.refresh),
                          label: Text(context.l10n.activityRefresh),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final List<Widget> slivers = <Widget>[];
            for (var i = 0; i < items.length; i++) {
              final EdgeInsets padding = _paddingBuilder(context);
              final bool isFirst = i == 0;
              final bool isLast = i == items.length - 1;
              slivers.add(
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: padding.left,
                    right: padding.right,
                    top: isFirst ? padding.top : 0,
                    bottom: isLast && !state.hasMoreForward
                        ? padding.bottom
                        : 0,
                  ),
                  sliver: _buildGroupSliver(context, items[i]),
                ),
              );
            }

            if (state.hasMoreForward) {
              switch (phase) {
                case LoadingForward() || Refreshing():
                  slivers.add(
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: sp.listInset.left,
                          right: sp.listInset.right,
                          top: sp.itemSpacing,
                          bottom: sp.sectionSpacing,
                        ),
                        child: const Center(
                          child: SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                  );
                  break;
                case Failed(:final error, :final direction):
                  if (direction == FetchDirection.forward) {
                    slivers.add(
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: context.spacing.pagePadding,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                context.l10n.activityLoadMoreError(
                                  error.toString(),
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              context.spacing.itemGap,
                              TextButton(
                                onPressed: () =>
                                    _paginationController.fetchForward(),
                                child: Text(context.l10n.commonRetry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  break;
                default:
                  slivers.add(
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        key: ValueKey<String>('activity-prefetch-sentinel'),
                        height: 48,
                      ),
                    ),
                  );
              }
            } else if (items.isNotEmpty) {
              slivers.add(
                SliverPadding(
                  padding: EdgeInsets.only(bottom: sp.listInset.bottom),
                  sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
              );
            }

            return MultiSliver(children: slivers);
          },
    );
  }

  /// Build actor header content (avatar + login)
  Widget _buildActorHeader(
    final BuildContext context,
    final WidgetRef ref,
    final Actor? actor,
  ) {
    final String? login = actor?.login;
    if (actor == null || login == null) {
      return const SizedBox.shrink();
    }

    return TapFeedback(
      onTap: () {
        UserRef(login: login).navigate(context, ref);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            UserAvatar(avatarUrl: actor.avatarUrl, size: 24),
            SizedBox(width: context.spacing.itemSpacing),
            Expanded(
              child: Text(
                login,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build issue-scoped compound card. All overrides come from [EventCompoundData].
  Widget _buildIssueCompoundCard(final EventCompoundData data) =>
      TimelineIssueContent.fromCompound(data);

  /// Build PR-scoped compound card. All overrides come from [EventCompoundData].
  Widget _buildPrCompoundCard(final EventCompoundData data) =>
      _KeepAlive(child: TimelinePullRequestContent.fromCompound(data));

  /// Build repo-scoped compound card.
  /// Unified layout: repo card(s) first, then conditional annotation chips below.
  /// Handles push, createRef, deleteRef, fork, member, release, discussion,
  /// wiki, and generic repo cards for watch/public/etc.
  /// For cross-target compounds (starred 3 repos, etc.), shows multiple repo cards.
  ///
  /// [compound] provides raw event access for push drill-down popups.
  Widget _buildRepoCompoundCard(
    final EventCompoundData data,
    final EventCompound compound,
  ) {
    // Fork events can outlive their source repository. In that case GitHub
    // returns repo: {}, while payload.forkee still identifies the visible
    // fork. Prefer the fork target for the card and retain the source URL for
    // source-only operations such as branch context.
    final String? sourceRepoUrl = data.repoUrl;

    // Collect unique displayable repo URLs from all events (for cross-target
    // compounds such as "forked 2 repositories").
    final List<String> allRepoUrls = compound.allEvents
        .map(
          (final EventsModel e) => e.type == EventsType.ForkEvent
              ? (e.payload.forkee?.url ?? e.repo.url)
              : e.repo.url,
        )
        .whereType<String>()
        .toSet()
        .toList();

    final String? displayRepoUrl = allRepoUrls.isNotEmpty
        ? allRepoUrls.first
        : (data.forkRepoUrl ?? sourceRepoUrl);
    if (displayRepoUrl == null) {
      return const SizedBox.shrink();
    }

    final bool isMultiTarget = allRepoUrls.length > 1;

    final EventCluster? pushCluster = compound.partWith(SemanticAction.push);

    final AppSpacing spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Multi-target: show all repo cards (starred 3 repos, forked 2 repos, etc.)
        if (isMultiTarget)
          ...allRepoUrls.asMap().entries.map(
            (final MapEntry<int, String> entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: RepoCardLoading(RepoRef.fromApiUrl(entry.value)),
            ),
          )
        else
          RepoCardLoading(RepoRef.fromApiUrl(displayRepoUrl)),

        // Unified branch context (push/create/delete, inline commit expand)
        if ((data.branches.isNotEmpty || pushCluster != null) &&
            sourceRepoUrl != null)
          Padding(
            padding: EdgeInsets.only(top: spacing.itemSpacing),
            child: UnifiedBranchContext(
              data: data,
              compound: compound,
              repoUrl: sourceRepoUrl,
            ),
          ),

        // Release: full card with loading (fetch by repo + tag)
        if (data.release != null)
          Padding(
            padding: EdgeInsets.only(top: spacing.itemSpacing),
            child: _releaseWidget(data),
          ),

        // Discussion: full card with loading (fetch by repo + number)
        if (data.discussion != null)
          Padding(
            padding: EdgeInsets.only(top: spacing.itemSpacing),
            child: _discussionWidget(data),
          ),

        // Wiki pages annotation
        if (data.wikiPages.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: spacing.itemSpacing),
            child: InlineWikiPages(pages: data.wikiPages),
          ),

        // Member profile annotation
        if (data.member != null)
          Padding(
            padding: EdgeInsets.only(top: spacing.itemSpacing),
            child: InlineMember(login: data.member!.login),
          ),
      ],
    );
  }

  RepoRef? _tryRepoRef(final String? repoName) {
    if (repoName == null || !repoName.contains('/')) return null;
    try {
      return RepoRef.fromFullName(repoName);
    } catch (e, st) {
      AppLogger.warning(
        'Invalid repo name for RepoRef',
        error: e,
        stackTrace: st,
        tag: 'events',
      );
      return null;
    }
  }

  Widget _releaseWidget(final EventCompoundData data) {
    final RepoRef? repoRef = _tryRepoRef(data.repoName);
    final String? tagName = data.release!.tagName;
    if (repoRef != null && tagName != null && tagName.isNotEmpty) {
      return ReleaseCardLoading(repoRef: repoRef, tagName: tagName);
    }
    return InlineRelease(release: data.release!);
  }

  Widget _discussionWidget(final EventCompoundData data) {
    final RepoRef? repoRef = _tryRepoRef(data.repoName);
    final int? number = data.discussion!.number;
    if (repoRef != null && number != null) {
      return DiscussionCardLoading(repoRef: repoRef, number: number);
    }
    return InlineDiscussion(discussion: data.discussion!);
  }

  /// Build timeline event from compound - unified rendering path.
  /// Uses EventCompoundData for extract-once pattern and compound-type dispatch.
  /// All visual/content data comes from [EventCompoundData]; no raw model access.
  Widget _buildTimelineEventFromCompound(
    final EventCompound compound,
    final BuildContext context, {
    required final bool isFirstInUserGroup,
    required final bool isLastInUserGroup,
  }) {
    final EventAction action = interpret(compound);
    final String actionText = _localizedActionText(context, action);

    // Extract once, use everywhere
    final EventCompoundData extractedData = compound.toCompoundData();

    final DateTime? date = extractedData.createdAt;

    // Resolve icons from pre-extracted part actions (no raw payload access)
    final List<({Color color, IconData icon})> icons = extractedData.partActions
        .map(_resolvePartVisual)
        .map((final GitHubActionVisual v) => (icon: v.icon, color: v.color))
        .toList();

    // Deduplicate icons by IconData (keep first occurrence)
    final Set<IconData> seen = <IconData>{};
    final List<({Color color, IconData icon})> uniqueIcons = icons
        .where((final ({Color color, IconData icon}) e) => seen.add(e.icon))
        .toList();

    // Border color from the first part's action visual
    final Color? borderColor = icons.isNotEmpty ? icons.first.color : null;

    // Dispatch to compound-specific builder based on scope
    final Widget child = switch (extractedData.scope) {
      CompoundScope.repo => _buildRepoCompoundCard(extractedData, compound),
      CompoundScope.issue => _buildIssueCompoundCard(extractedData),
      CompoundScope.pullRequest => _buildPrCompoundCard(extractedData),
      // Fallback: show repo card for rare unknown-scope compounds
      CompoundScope.unknown => _buildRepoCompoundCard(extractedData, compound),
    };

    final bool useTimelineView = ref
        .read(settings_events.eventsProvider)
        .useTimelineView;
    if (!useTimelineView) {
      return Padding(
        padding: EdgeInsets.only(bottom: context.spacing.itemSpacing),
        child: child,
      );
    }

    return UnifiedTimelineItem(
      eventIcons: uniqueIcons,
      actionText: actionText,
      date: date,
      isFirst: isFirstInUserGroup,
      isLast: isLastInUserGroup,
      actionHeaderTopPadding: isFirstInUserGroup ? 0.0 : 16.0,
      borderColor: borderColor,
      child: child,
    );
  }

  String _localizedActionText(
    final BuildContext context,
    final EventAction action,
  ) => switch (action) {
    StateChangeAction(:final verb, :final noun, :final count) =>
      EventTexts.localizedStateChange(
        l10n: context.l10n,
        verb: verb,
        noun: noun,
        count: count,
      ),
    PushAction(:final commitCount, :final branchCount) =>
      EventTexts.localizedPush(
        l10n: context.l10n,
        commits: commitCount,
        branches: branchCount,
      ),
    LabelAction(:final added, :final removed) =>
      EventTexts.localizedLabelChange(
        l10n: context.l10n,
        added: added,
        removed: removed,
      ),
    CommentAction(:final verb, :final count) => EventTexts.localizedComment(
      l10n: context.l10n,
      verb: verb,
      count: count,
    ),
    RefAction(:final verb, :final refTypeName, :final count) =>
      EventTexts.localizedRefChange(
        l10n: context.l10n,
        verb: verb,
        refType: refTypeName,
        count: count,
      ),
    CountedItemAction(:final verb, :final singularNoun, :final count) =>
      EventTexts.localizedCountedItem(
        l10n: context.l10n,
        verb: verb,
        singular: singularNoun,
        count: count,
      ),
    AssignAction(:final verb, :final count) => EventTexts.localizedAssign(
      l10n: context.l10n,
      verb: verb,
      count: count,
    ),
    ReviewAction(:final reviewState, :final count) =>
      EventTexts.localizedReview(
        l10n: context.l10n,
        state: reviewState,
        count: count,
      ),
    ReleaseAction(:final count) => context.l10n.activityPublishedReleases(
      count,
    ),
    DiscussionAction(:final count) => context.l10n.activityStartedDiscussions(
      count,
    ),
    WikiAction(:final pageCount) => context.l10n.activityUpdatedWikiPages(
      pageCount,
    ),
    SimpleAction(:final count) => context.l10n.activityPerformedActions(count),
    CompoundAction(:final parts) => EventTexts.localizedNaturalJoin(
      context.l10n,
      parts
          .map((final EventAction part) => _localizedActionText(context, part))
          .toList(),
    ),
  };

  /// Resolve a [GitHubActionVisual] from pre-extracted part action data.
  /// This is the sole bridge between extracted compound data and visual styles.
  static GitHubActionVisual _resolvePartVisual(
    final PartActionData partAction,
  ) => GitHubVisualStyles.fromSemanticAction(
    partAction.action,
    payloadAction: partAction.payloadAction,
    stateReason: partAction.stateReason,
  );
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // keep loading cards alive while scrolling

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
