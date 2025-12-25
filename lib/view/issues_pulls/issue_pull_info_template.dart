import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/misc/animated_tab_bar.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/common/misc/floating_action_toolbar.dart';
import 'package:diohub/common/misc/floating_toolbar_wrapper.dart';
import 'package:diohub/common/widgets/expandable_scroll_wrapper.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/common/misc/theme_from_image.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/common/wrappers/editing_wrapper.dart';
import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/info_card.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/common/wrappers/liquid_pull_to_refresh_wrapper.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_pull_info.data.gql.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/timeline.data.gql.dart';
import 'package:diohub/providers/issue_pulls/comment_provider.dart';
import 'package:diohub/providers/issue_pulls/issue_provider.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/view/issues_pulls/issue_pull_screen.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/models/issue_pull_state.dart';
import 'package:diohub/view/issues_pulls/widgets/about_tab.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

class IssuePullInfoTemplate extends StatefulWidget {
  const IssuePullInfoTemplate({
    required this.number,
    required this.title,
    required this.repoInfo,
    required this.state,
    required this.bodyHTML,
    required this.labels,
    required this.createdAt,
    required this.createdBy,
    required this.body,
    required this.commentCount,
    required this.reactionGroups,
    required this.viewerCanReact,
    required this.assigneesInfo,
    required this.participantsInfo,
    required this.isPinned,
    required this.uri,
    super.key,
    this.dynamicTabs = const <DynamicTab>[],
    required this.onRefresh,
    this.additionalAboutWidgets = const <Widget>[],
    this.additionalDetailTiles = const <Widget>[],
    this.linkedIssues,
    this.linkedIssuesTrackedIn,
    this.linkedPullRequests,
    this.viewerCanUpdate = false,
    this.actionButtons = const <Widget>[],
  });

  final GassigneeInfo assigneesInfo;
  final String body;
  final String bodyHTML;
  final int commentCount;
  final DateTime createdAt;
  final Gactor? createdBy;
  final List<DynamicTab> dynamicTabs;
  final List<Glabel?> labels;
  final List<Widget> additionalAboutWidgets;
  final List<Widget> additionalDetailTiles;
  final int number;
  final List<GreactionGroups> reactionGroups;
  final GrepoInfo repoInfo;
  final IssuePullState state;
  final String title;
  final Uri uri;
  final bool viewerCanReact;
  final UnfinishedList<Gactor> participantsInfo;
  final bool isPinned;
  final Future<void> Function() onRefresh;
  final GissueInfo_trackedIssues? linkedIssues;
  final GissueInfo_trackedInIssues? linkedIssuesTrackedIn;
  final GpullInfo_closingIssuesReferences? linkedPullRequests;
  final bool viewerCanUpdate;
  final List<Widget> actionButtons;

  @override
  State<IssuePullInfoTemplate> createState() => IssuePullInfoTemplateState();
}

class IssuePullInfoTemplateState extends State<IssuePullInfoTemplate>
    with TickerProviderStateMixin {
  late EditingController<Object> assigneeEditingController;
  late EditingController<String> descEditingController;
  late final DynamicTabsController dynamicTabsController =
      DynamicTabsController(
    vsync: this,
    tabs: _buildTabs(),
  );
  late EditingController<List<Glabel?>> labelsEditingController;

  late EditingController<String> titleEditingController;

  @override
  void initState() {
    titleEditingController = EditingController<String>(widget.title);
    labelsEditingController = EditingController<List<Glabel?>>(
      widget.labels,
      onEditTap: (final BuildContext context) => null,
    );
    descEditingController = EditingController<String>(
      widget.body,
      onEditTap: (final BuildContext context) => null,
    );
    assigneeEditingController = EditingController<Object>(
      widget.assigneesInfo,
      onEditTap: (final BuildContext context) => null,
    );
    super.initState();
  }

  @override
  Widget build(final BuildContext context) => ThemeFromImage(
        builder: (
          final BuildContext context,
        ) {
          return FloatingToolbarWrapper(
            toolbarBuilder: (
              final ValueNotifier<ScrollNotification?>
                  scrollNotificationNotifier,
            ) {
              return ListenableBuilder(
                listenable: dynamicTabsController,
                builder: (final BuildContext context, final _) {
                  return FloatingActionToolbar(
                    key: const ValueKey('issue_pull_toolbar'),
                    actions: _buildToolbarActions(context),
                    actionCardBuilder: (
                      final BuildContext context,
                      final ActionButtonData action,
                    ) =>
                        buildStandardActionCard(context, action),
                    position: FloatingPosition.bottom,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    bottomPadding: 0.0,
                    title: '#${widget.number}',
                    subtitle: widget.repoInfo.name,
                    scrollNotificationNotifier: scrollNotificationNotifier,
                    onExpandChanged: (final bool isExpanded) {},
                  );
                },
              );
            },
            child: SafeArea(
              child: buildDynamicTabsParent(),
            ),
          );
        },
      );

  // Collapsible App Bar Methods

  Widget _buildCollapsedHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // State icon
          widget.state.icon(size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '#${widget.number} • ${widget.repoInfo.name}',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: State badge and number
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // State badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.state.color.withOpacity(0.15),
                  borderRadius:
                      Theme.of(context).surfaceStyle.borderRadiusMedium(),
                  border: Border.all(
                    color: widget.state.color.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.state.icon(size: 16),
                    const SizedBox(width: 8),
                    Text(
                      widget.state.text,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: widget.state.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Issue number
              Text(
                '${widget.number}',
                style: context.textTheme.headlineSmall?.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  height: 1.2,
                ),
              ),
              if (widget.isPinned) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.colorScheme.tertiary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Octicons.pin,
                    size: 16,
                    color: context.colorScheme.tertiary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          // Repository info section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner avatar
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.repoInfo.owner.avatarUrl.toString(),
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  placeholder: (final _, final __) => Container(
                    width: 32,
                    height: 32,
                    color: context.colorScheme.surfaceVariant,
                  ),
                  errorWidget: (final _, final __, final ___) => Container(
                    width: 32,
                    height: 32,
                    color: context.colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Owner and repo info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Owner name
                    Text(
                      widget.repoInfo.owner.login,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Repository name
                    Text(
                      widget.repoInfo.name,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Date
          Text(
            getDate(widget.createdAt.toString(), shorten: true),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant.withOpacity(0.75),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetadataTiles(BuildContext context) {
    final List<Widget> tiles = <Widget>[];

    // Created date
    tiles.add(
      DetailTile(
        title: 'Created',
        actionType: DetailTileActionType.none,
        child: DetailTileText(
          getDate(widget.createdAt.toString(), shorten: false),
        ),
      ),
    );

    // Author
    if (widget.createdBy != null) {
      tiles.add(
        DetailTile(
          title: 'Author',
          actionType: DetailTileActionType.navigation,
          onTap: () {
            navigateToProfile(
              login: widget.createdBy!.login,
              context: context,
            );
          },
          child: DetailTileUser(
            avatarUrl: widget.createdBy!.avatarUrl.toString(),
            login: widget.createdBy!.login,
          ),
        ),
      );
    }

    // Assignees
    if (widget.assigneesInfo.edges?.isNotEmpty ?? false) {
      tiles.add(_buildAssigneeDetailTile(context));
    }

    // Participants
    if (widget.participantsInfo.totalCount > 1) {
      tiles.add(_buildParticipantsDetailTile(context));
    }

    // Linked issues
    tiles.addAll(_buildLinkedIssuesDetailTiles(context));

    // Linked PRs
    tiles.addAll(_buildLinkedPullRequestsDetailTiles(context));

    // Additional detail tiles (PR-specific)
    tiles.addAll(widget.additionalDetailTiles);

    return tiles;
  }

  Widget _buildAssigneeDetailTile(BuildContext context) {
    final List<GassigneeInfo_edges?> assignees =
        widget.assigneesInfo.edges?.toList() ?? <GassigneeInfo_edges?>[];
    final assigneeList = UnfinishedList<NodeWithPaginationInfo<Gactor>>(
      limitedAvailableList: assignees
          .map((e) => NodeWithPaginationInfo<Gactor>.fromEdge(e!))
          .toList(),
    );

    return DetailTile(
      title: assigneeList.totalCount == 1 ? 'Assignee' : 'Assignees',
      actionType: assigneeList.totalCount > 1
          ? DetailTileActionType.bottomSheet
          : assigneeList.totalCount == 1
              ? DetailTileActionType.navigation
              : DetailTileActionType.none,
      onTap: assigneeList.totalCount > 1
          ? () async {
              await BottomSheetPagination<NodeWithPaginationInfo<Gactor>>(
                paginatedListItemBuilder: _paginatedListItemBuilder,
                paginationFuture: (data) async =>
                    (await context.issueProvider(listen: false).getAssignees(
                              after: data.lastItem?.cursor,
                            ))
                        .map<NodeWithPaginationInfo<Gactor>>(
                          (e) => NodeWithPaginationInfo<Gactor>.fromEdge(e!),
                        )
                        .toList(),
                title: 'Assignees',
              ).openSheet(context);
            }
          : assigneeList.totalCount == 1
              ? () {
                  navigateToProfile(
                    login: assigneeList.limitedAvailableList.first.node.login,
                    context: context,
                  );
                }
              : null,
      child: assigneeList.totalCount == 1
          ? DetailTileUser(
              avatarUrl: assigneeList.limitedAvailableList.first.node.avatarUrl
                  .toString(),
              login: assigneeList.limitedAvailableList.first.node.login,
            )
          : DetailTileUserStack(
              avatars: assigneeList.limitedAvailableList
                  .map((e) => e.node.avatarUrl.toString())
                  .toList(),
              totalCount: assigneeList.totalCount,
            ),
    );
  }

  Widget _buildParticipantsDetailTile(BuildContext context) {
    return DetailTile(
      title: 'Participants',
      actionType: DetailTileActionType.bottomSheet,
      onTap: () async {
        await BottomSheetPagination<NodeWithPaginationInfo<Gactor>>(
          paginatedListItemBuilder: _paginatedListItemBuilder,
          paginationFuture: (data) async =>
              context.issueProvider(listen: false).getParticipants(
                    after: data.lastItem?.cursor,
                  ),
          title: 'Participants',
        ).openSheet(context);
      },
      child: DetailTileUserStack(
        avatars: widget.participantsInfo.limitedAvailableList
            .map((e) => e.avatarUrl.toString())
            .toList(),
        totalCount: widget.participantsInfo.totalCount,
      ),
    );
  }

  List<Widget> _buildLinkedIssuesDetailTiles(BuildContext context) {
    final List<Widget> tiles = [];

    // Tracked issues (issues that track this issue)
    if ((widget.linkedIssues?.totalCount ?? 0) > 0) {
      final nodes = widget.linkedIssues!.nodes
              ?.whereType<GissueInfo_trackedIssues_nodes>()
              .toList() ??
          [];

      if (nodes.length == 1) {
        final node = nodes.first;
        tiles.add(
          DetailTile(
            title: 'Linked issue',
            actionType: DetailTileActionType.navigation,
            onTap: () async {
              await context.router.push(
                issuePullScreenRoute(PathData.fromURL(node.url.toString())),
              );
            },
            child: DetailTileLinkedIssue(
              title: node.title,
              number: node.number,
              repositoryName: node.repository.name,
              repositoryOwner: node.repository.owner.login,
            ),
          ),
        );
      } else if (nodes.isNotEmpty) {
        tiles.add(
          DetailTile(
            title: 'Linked issues',
            actionType: DetailTileActionType.bottomSheet,
            onTap: () async {
              await BottomSheetPagination<GissueInfo_trackedIssues_nodes>(
                paginatedListItemBuilder: (context, data) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    color: context.colorScheme.surface,
                    child: InkWell(
                      onTap: () async {
                        await context.router.push(
                          issuePullScreenRoute(
                              PathData.fromURL(data.item.url.toString())),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: DetailTileLinkedIssue(
                          title: data.item.title,
                          number: data.item.number,
                          repositoryName: data.item.repository.name,
                          repositoryOwner: data.item.repository.owner.login,
                        ),
                      ),
                    ),
                  ),
                ),
                paginationFuture: (data) async => nodes,
                title: 'Linked issues',
              ).openSheet(context);
            },
            child: DetailTileLinkedIssuesStack(
              totalCount: nodes.length,
            ),
          ),
        );
      }
    }

    // Tracked in issues (issues this issue tracks)
    if ((widget.linkedIssuesTrackedIn?.totalCount ?? 0) > 0) {
      final nodes = widget.linkedIssuesTrackedIn!.nodes
              ?.whereType<GissueInfo_trackedInIssues_nodes>()
              .toList() ??
          [];

      if (nodes.length == 1) {
        final node = nodes.first;
        tiles.add(
          DetailTile(
            title: 'Tracked in',
            actionType: DetailTileActionType.navigation,
            onTap: () async {
              await context.router.push(
                issuePullScreenRoute(PathData.fromURL(node.url.toString())),
              );
            },
            child: DetailTileLinkedIssue(
              title: node.title,
              number: node.number,
              repositoryName: node.repository.name,
              repositoryOwner: node.repository.owner.login,
            ),
          ),
        );
      } else if (nodes.isNotEmpty) {
        tiles.add(
          DetailTile(
            title: 'Tracked in',
            actionType: DetailTileActionType.bottomSheet,
            onTap: () async {
              await BottomSheetPagination<GissueInfo_trackedInIssues_nodes>(
                paginatedListItemBuilder: (context, data) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    color: context.colorScheme.surface,
                    child: InkWell(
                      onTap: () async {
                        await context.router.push(
                          issuePullScreenRoute(
                              PathData.fromURL(data.item.url.toString())),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: DetailTileLinkedIssue(
                          title: data.item.title,
                          number: data.item.number,
                          repositoryName: data.item.repository.name,
                          repositoryOwner: data.item.repository.owner.login,
                        ),
                      ),
                    ),
                  ),
                ),
                paginationFuture: (data) async => nodes,
                title: 'Tracked in',
              ).openSheet(context);
            },
            child: DetailTileLinkedIssuesStack(
              totalCount: nodes.length,
            ),
          ),
        );
      }
    }

    return tiles;
  }

  List<Widget> _buildLinkedPullRequestsDetailTiles(BuildContext context) {
    if ((widget.linkedPullRequests?.totalCount ?? 0) == 0) {
      return [];
    }

    final nodes = widget.linkedPullRequests!.nodes
            ?.whereType<GpullInfo_closingIssuesReferences_nodes>()
            .toList() ??
        [];
    if (nodes.isEmpty) {
      return [];
    }

    if (nodes.length == 1) {
      final node = nodes.first;
      return [
        DetailTile(
          title: 'Closes',
          actionType: DetailTileActionType.navigation,
          onTap: () async {
            await context.router.push(
              issuePullScreenRoute(PathData.fromURL(node.url.toString())),
            );
          },
          child: DetailTileLinkedIssue(
            title: node.title,
            number: node.number,
            repositoryName: node.repository.name,
            repositoryOwner: node.repository.owner.login,
          ),
        ),
      ];
    } else {
      return [
        DetailTile(
          title: 'Closes',
          actionType: DetailTileActionType.bottomSheet,
          onTap: () async {
            await BottomSheetPagination<
                GpullInfo_closingIssuesReferences_nodes>(
              paginatedListItemBuilder: (context, data) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  color: context.colorScheme.surface,
                  child: InkWell(
                    onTap: () async {
                      await context.router.push(
                        issuePullScreenRoute(
                            PathData.fromURL(data.item.url.toString())),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DetailTileLinkedIssue(
                        title: data.item.title,
                        number: data.item.number,
                        repositoryName: data.item.repository.name,
                        repositoryOwner: data.item.repository.owner.login,
                      ),
                    ),
                  ),
                ),
              ),
              paginationFuture: (data) async => nodes,
              title: 'Closes',
            ).openSheet(context);
          },
          child: DetailTileLinkedIssuesStack(
            totalCount: nodes.length,
          ),
        ),
      ];
    }
  }

  ScrollWrapperBuilder<NodeWithPaginationInfo<Gactor>>
      get _paginatedListItemBuilder => (
            final BuildContext context,
            final ScrollWrapperBuilderData<NodeWithPaginationInfo<Gactor>> data,
          ) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  color: context.colorScheme.surface,
                  child: ProfileTile.login(
                    avatarUrl: data.item.node.avatarUrl.toString(),
                    userLogin: data.item.node.login,
                    wrapperBuilder: (final Widget child) => Row(
                      children: _buildListItemChildren(data, context, child),
                    ),
                  ),
                ),
              );

  List<Widget> _buildListItemChildren(
    final ScrollWrapperBuilderData<NodeWithPaginationInfo<Gactor>> data,
    final BuildContext context,
    final Widget child,
  ) =>
      <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            '${data.index + 1}',
            style: context.textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ];

  List<ActionButtonData> _buildToolbarActions(BuildContext context) {
    final String currentTab = dynamicTabsController.activeIdentifier;

    return <ActionButtonData>[
      MinorActionButton(
        icon: Octicons.info,
        label: 'About',
        category: 'Primary',
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'About'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => dynamicTabsController.openTab('About'),
      ),
      MinorActionButton(
        icon: Octicons.comment_discussion,
        label: 'Conversation',
        category: 'Primary',
        trailing: widget.commentCount > 0
            ? buildActionButtonTrailingCount(context, widget.commentCount)
            : null,
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Conversation'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => dynamicTabsController.openTab('Conversation'),
      ),
    ];
  }

  Widget buildDynamicTabsParent() => EditingWrapper(
        onSave: () {},
        editingControllers: <EditingController<dynamic>>[
          titleEditingController,
          labelsEditingController,
          descEditingController,
          assigneeEditingController,
        ],
        builder: (final BuildContext context) => ExpandOnScrollWrapper(
          collapsedWidget: (
            final BuildContext context,
            final double pullProgress,
            final bool isReadyToExpand,
          ) =>
              PullToExpandIndicator(
            pullProgress: pullProgress,
            isReadyToExpand: isReadyToExpand,
          ),
          expandedWidget: (
            final BuildContext context,
            final VoidCallback onCollapse,
          ) =>
              Column(
            children: [
              ExpandableSection(
                title: 'Details',
                onCollapse: onCollapse,
                children: _buildMetadataTiles(context),
              ),
              if (widget.viewerCanUpdate && widget.actionButtons.isNotEmpty)
                ExpandableSection(
                  title: 'Actions',
                  headerColor: context.colorScheme.error,
                  onCollapse: () {},
                  children: widget.actionButtons,
                ),
            ],
          ),
          builder: (
            final BuildContext context,
            final Widget expandOnScrollWidget,
          ) =>
              DynamicTabsParent(
            controller: dynamicTabsController,
            builder: (
              final BuildContext context,
              final PreferredSizeWidget tabBar,
              final WidgetBuilder tabViewBuilder,
            ) =>
                PullToRefreshWrapper(
              onRefresh: widget.onRefresh,
              child: DynamicScroll(
                collapsedWidget: _buildCollapsedHeader(context),
                expandedWidget: _buildExpandedHeader(context),
                headerSlivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: expandOnScrollWidget,
                    ),
                  ),
                  AnimatedTabBar(
                    showTabBar: dynamicTabsController.activeLength > 1,
                    tabBar: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: buildTabsView(tabBar),
                    ),
                  ),
                ],
                bodyBuilder: tabViewBuilder,
              ),
            ),
          ),
        ),
      );

  List<DynamicTab> _buildTabs() => List<DynamicTab>.from(widget.dynamicTabs)
    ..addAll(
      <DynamicTab>[
        _buildAboutTab(),
        DynamicTab(
          identifier: 'Conversation',
          keepViewAlive: true,
          tabViewBuilder: (final BuildContext context) =>
              ChangeNotifierProvider<CommentProvider>(
            create: (final _) => CommentProvider(),
            builder: (final BuildContext context, final Widget? child) =>
                IssuePullTimeline(
              number: widget.number,
              isLocked: false,
              createdAt: widget.createdAt,
              owner: widget.repoInfo.owner.login,
              repoName: widget.repoInfo.name,
              issueUrl: widget.uri,
              isPull: false,
            ),
          ),
        ),
      ],
    );

  DynamicTab _buildAboutTab() => DynamicTab(
        identifier: 'About',
        isDismissible: false,
        tabViewBuilder: (final BuildContext context) => AboutTab(
          bodyHTML: widget.bodyHTML,
          body: widget.body,
          reactionGroups: widget.reactionGroups,
          viewerCanReact: widget.viewerCanReact,
          title: widget.title,
          titleEditingController: titleEditingController,
          labels: widget.labels,
          labelsEditingController: labelsEditingController,
        ),
      );

  Widget buildTabsView(final PreferredSizeWidget tabBar) => tabBar;
}
