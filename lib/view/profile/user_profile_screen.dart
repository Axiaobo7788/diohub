import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/common/events/events.dart';
import 'package:diohub/common/misc/animated_tab_bar.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/common/misc/floating_action_toolbar.dart';
import 'package:diohub/common/misc/floating_toolbar_wrapper.dart';
import 'package:diohub/common/misc/scaffold_body.dart';
import 'package:diohub/common/widgets/expandable_scroll_wrapper.dart';
import 'package:diohub/common/wrappers/provider_loading_progress_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/users/user_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/utils/contribution_query_utils.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/profile/about/user_about_screen.dart';
import 'package:diohub/view/profile/repositories/user_repositories.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart' as provider;

@RoutePage()
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen(this.login, {super.key});

  final String login;

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  GuserInfoData_user? data;

  // Date range state for Activity tab (contribution graph)
  // Store ContributionQueryKey as single source of truth
  late ContributionQueryKey _contributionQueryKey;

  @override
  void initState() {
    super.initState();
    // Initialize to default last year range
    _contributionQueryKey = ContributionQueryKey.lastYear(widget.login);
    if (kDebugMode) {
      final (from, to) = _contributionQueryKey.dateRange.dates;    }
  }

  /// Gets the current query key
  ContributionQueryKey _getCurrentQueryKey() {
    return _contributionQueryKey;
  }

  /// Gets the display label for the current date range selection
  String _getDateRangeLabel() {
    final key = _getCurrentQueryKey();
    final dateRange = key.dateRange;

    // Check for "Last Year" first (it's a CustomRange with isLastYear flag)
    if (dateRange.isLastYear) {
      return 'Last Year';
    }

    if (dateRange.isCustomRange) {
      final from = dateRange.displayFromDate;
      final DateTime? createdAt = data?.createdAt;
      if (from != null && createdAt != null) {
        final bool isSinceJoining = from.year == createdAt.year &&
            from.month == createdAt.month &&
            from.day == createdAt.day;
        return isSinceJoining ? 'Since joining' : 'Custom';
      }
      return 'Custom';
    }

    final year = dateRange.displayYear;
    return year?.toString() ?? 'Last Year';
  }

  /// Handles year selection change
  void _onYearChanged(final int year) {    setState(() {
      _contributionQueryKey = ContributionQueryKey.year(widget.login, year);    });
  }

  /// Handles custom date range change
  void _onCustomRangeChanged(final DateTime? from, final DateTime? to) {    setState(() {
      if (from == null && to == null) {
        // Reset to last year
        _contributionQueryKey = ContributionQueryKey.lastYear(widget.login);
      } else if (from != null && to != null) {
        _contributionQueryKey = ContributionQueryKey.customRange(
          userName: widget.login,
          from: from,
          to: to,
        );
      }    });
  }

  /// Builds the expanded content for the date range selector
  Widget _buildDateRangeExpandedContent(
    final BuildContext context,
    final GuserInfoData_user userData,
    final VoidCallback onCollapse,
  ) {
    final currentKey = _getCurrentQueryKey();
    return _DateRangeExpandedContent(
      userName: userData.login,
      currentQueryKey: currentKey,
      createdAt: userData.createdAt,
      onYearChanged: _onYearChanged,
      onCustomRangeChanged: _onCustomRangeChanged,
      onCollapse: onCollapse,
    );
  }

  Widget _buildCollapsedHeader(
    final BuildContext context,
    final GuserInfoData_user userData,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: userData.avatarUrl.toString(),
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                placeholder: (final _, final __) => Container(
                  width: 24,
                  height: 24,
                  color: context.colorScheme.surfaceVariant,
                ),
                errorWidget: (final _, final __, final ___) => Container(
                  width: 24,
                  height: 24,
                  color: context.colorScheme.surfaceVariant,
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      userData.name ?? userData.login,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (userData.name != null) ...<Widget>[
                    const SizedBox(width: 6),
                    Text(
                      '•',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant
                            .withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        userData.login,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildExpandedHeader(
    final BuildContext context,
    final GuserInfoData_user userData,
    final DynamicTabsController? tabController,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // User info row with avatar and name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Larger avatar in expanded state
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: userData.avatarUrl.toString(),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  placeholder: (final _, final __) => Container(
                    width: 44,
                    height: 44,
                    color: context.colorScheme.surfaceVariant,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (final _, final __, final ___) => Container(
                    width: 44,
                    height: 44,
                    color: context.colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.person,
                      size: 24,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      userData.name ?? userData.login,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                height: 1.2,
                              ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userData.login,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    final BuildContext context,
    final GuserInfoData_user userData,
    final DynamicTabsController? tabController,
  ) {
    final bool isViewer = userData.isViewer;

    final List<ActionButtonData> primaryActions = <ActionButtonData>[];

    // Follow/Unfollow button (only for other users)
    if (!isViewer && userData.viewerCanFollow) {
      primaryActions.add(
        MinorActionButton(
          icon: Octicons.person_add,
          label: userData.viewerIsFollowing ? 'Unfollow' : 'Follow',
          trailing: buildActionButtonTrailingCount(
            context,
            userData.followers.totalCount,
          ),
          onTap: () async {
            // TODO: Implement follow/unfollow logic
            // Use UserInfoService.changeFollowStatus
          },
        ),
      );
    }

    // Repositories count
    primaryActions.add(
      MinorActionButton(
        icon: Octicons.repo,
        label: 'Repositories',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.repositories.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        onTap: () => tabController?.openTab('Repositories'),
      ),
    );

    // Followers count
    primaryActions.add(
      MinorActionButton(
        icon: Octicons.people,
        label: 'Followers',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.followers.totalCount,
        ),
        onTap: () {
          // TODO: Navigate to followers list
        },
      ),
    );

    // Following count (only for users, not organizations)
    userData.when(
      user: (final GuserInfoData_user__asUser user) {
        primaryActions.add(
          MinorActionButton(
            icon: Octicons.person,
            label: 'Following',
            trailing: buildActionButtonTrailingCount(
              context,
              user.following.totalCount,
            ),
            onTap: () {
              // TODO: Navigate to following list
            },
          ),
        );
      },
      orElse: () {
        // Organizations don't have following
      },
    );

    final List<ActionButtonData> secondaryActions = <ActionButtonData>[];

    // More actions can go here
    // Note: publicGists is not available in GraphQL user query
    // If needed, it can be added to the query

    if (primaryActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return CollapsibleActionButtons(
      primaryActions: primaryActions,
      secondaryActions: secondaryActions,
      actionCardBuilder:
          (final BuildContext context, final ActionButtonData action) =>
              buildStandardActionCard(
        context,
        action,
        iconSize: 16,
        padding: const EdgeInsets.all(10),
      ),
      visibilityConfig: const ActionButtonsVisibilityConfig(
        minPerRow: 2,
        maxPerRow: 4,
      ),
      onExpandChanged: (final bool isExpanded) {},
    );
  }

  List<ActionButtonData> _buildToolbarActions(
    final BuildContext context,
    final GuserInfoData_user userData,
    final DynamicTabsController? tabController,
  ) {
    final String currentTab = tabController?.activeIdentifier ?? 'Activity';

    // Get pinned repositories
    final List<GuserInfoData_user_pinnedItems_edges?> pinnedItems =
        userData.pinnedItems.edges?.toList() ??
            <GuserInfoData_user_pinnedItems_edges?>[];
    final List<GrepositoryFields> pinnedRepos = pinnedItems
        .map((final GuserInfoData_user_pinnedItems_edges? edge) => edge?.node)
        .whereType<GuserInfoData_user_pinnedItems_edges_node>()
        .where(
          (final GuserInfoData_user_pinnedItems_edges_node node) =>
              node.G__typename == 'Repository',
        )
        .map(
          (final GuserInfoData_user_pinnedItems_edges_node node) =>
              node as GrepositoryFields,
        )
        .toList();
    final int pinnedReposCount = pinnedRepos.length;

    return <ActionButtonData>[
      // Pinned Repos - visible on all tabs
      if (pinnedReposCount > 0)
        ExpandableActionButton(
          icon: Octicons.pin,
          label: 'Pinned Repos',
          trailing: pinnedReposCount > 0
              ? buildModernCountBadge(context, pinnedReposCount)
              : null,
          enabled: pinnedReposCount > 0,
          category: 'Primary',
          visibilityState: ActionButtonVisibilityState.both,
          expandableWidgetBuilder: (final onCollapse) => Builder(
            builder: (final BuildContext context) {
              if (pinnedRepos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Text(
                    'No pinned repositories available',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: pinnedRepos
                      .asMap()
                      .entries
                      .map((final MapEntry<int, GrepositoryFields> entry) {
                    final int index = entry.key;
                    final GrepositoryFields repo = entry.value;
                    final bool isLast = index == pinnedRepos.length - 1;

                    final String ownerLogin = repo.owner.login;
                    final String repoName = repo.name;

                    // Construct repository URL for navigation: owner/repo
                    final String navigationUrl = '$ownerLogin/$repoName';

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await AutoRouter.of(context).push(
                            RepositoryRoute(
                              repositoryURL: navigationUrl,
                            ),
                          );
                          onCollapse();
                        },
                        borderRadius: BorderRadius.only(
                          bottomLeft:
                              isLast ? const Radius.circular(14) : Radius.zero,
                          bottomRight:
                              isLast ? const Radius.circular(14) : Radius.zero,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: context.colorScheme.outline
                                          .withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      repoName,
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (repo.description != null &&
                                        repo.description!
                                            .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 4),
                                      Text(
                                        repo.description!,
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                          color: context
                                              .colorScheme.onSurfaceVariant
                                              .withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (repo.stargazerCount > 0) ...<Widget>[
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Octicons.star,
                                      size: 14,
                                      color: context
                                          .colorScheme.onSurfaceVariant
                                          .withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      repo.stargazerCount.toString(),
                                      style:
                                          context.textTheme.bodySmall?.copyWith(
                                        color: context
                                            .colorScheme.onSurfaceVariant
                                            .withOpacity(0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      // Time range selector - only visible on Activity tab

      ExpandableActionButton(
        icon: Icons.date_range,
        label: _getDateRangeLabel(),
        subtitle: 'Time Range',
        category: 'Primary',
        visibilityState: currentTab == 'Activity'
            ? ActionButtonVisibilityState.both
            : ActionButtonVisibilityState.none,
        expandableWidgetBuilder: (final onCollapse) =>
            _buildDateRangeExpandedContent(
          context,
          userData,
          onCollapse,
        ),
      ),
      // Primary - always visible in collapsed state
      MinorActionButton(
        icon: Octicons.pulse,
        label: 'Activity',
        category: 'Primary',
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Activity'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController?.openTab('Activity'),
      ),
      MinorActionButton(
        icon: Octicons.repo,
        label: 'Repositories',
        category: 'Primary',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.repositories.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Repositories'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController?.openTab('Repositories'),
      ),
      MinorActionButton(
        icon: Octicons.star,
        label: 'Stars',
        category: 'Primary',
        iconColor:
            const Color(0xFFFFC107).withOpacity(0.65), // Amber/Yellow for stars
        trailing: buildActionButtonTrailingCount(
          context,
          userData.starredRepositories.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Stars'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController?.openTab('Stars'),
      ),

      MinorActionButton(
        icon: Octicons.code_square,
        label: 'Gists',
        category: 'Primary',
        trailing: userData.when(
          user: (final GuserInfoData_user__asUser user) =>
              buildActionButtonTrailingCount(
            context,
            user.gists.totalCount,
          ),
          orElse: () => null,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Gists'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController?.openTab('Gists'),
      ),
      // Content - visible in expanded state only
      MinorActionButton(
        icon: Octicons.git_pull_request,
        label: 'Pull Requests',
        category: 'Content',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.pullRequests.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Pull Requests'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Pull Requests'),
      ),
      MinorActionButton(
        icon: Octicons.issue_opened,
        label: 'Issues',
        category: 'Content',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.issues.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Issues'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Issues'),
      ),
      MinorActionButton(
        icon: Octicons.organization,
        label: 'Organizations',
        category: 'Content',
        trailing: userData.when(
          user: (final GuserInfoData_user__asUser user) =>
              buildActionButtonTrailingCount(
            context,
            user.organizations.totalCount,
          ),
          orElse: () => null,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Organizations'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Organizations'),
      ),
      // Social - visible in expanded state only
      MinorActionButton(
        icon: Octicons.people,
        label: 'Followers',
        category: 'Social',
        trailing: buildActionButtonTrailingCount(
          context,
          userData.followers.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Followers'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Followers'),
      ),
      MinorActionButton(
        icon: Octicons.person,
        label: 'Following',
        category: 'Social',
        trailing: userData.when(
          user: (final GuserInfoData_user__asUser user) =>
              buildActionButtonTrailingCount(
            context,
            user.following.totalCount,
          ),
          orElse: () => null,
        ),
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Following'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Following'),
      ),
      // Other - visible in expanded state only
      MinorActionButton(
        icon: Octicons.package,
        label: 'Packages',
        category: 'Other',
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Packages'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Packages'),
      ),
      MinorActionButton(
        icon: Octicons.project,
        label: 'Projects',
        category: 'Other',
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Projects'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Projects'),
      ),
      MinorActionButton(
        icon: Octicons.heart,
        label: 'Sponsors',
        category: 'Other',
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Sponsors'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabController?.openTab('Sponsors'),
      ),
      MinorActionButton(
        icon: Octicons.history,
        label: 'Feed',
        category: 'Primary',
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Activity Feed'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabController?.openTab('Activity Feed'),
      ),
    ];
  }

  @override
  Widget build(final BuildContext context) {    return provider.ChangeNotifierProvider<UserProvider>(
      create: (final _) {        return UserProvider(widget.login);
      },
      builder: (final BuildContext context, final _) => Scaffold(
        appBar:
            provider.Provider.of<UserProvider>(context).status != Status.loaded
                ? AppBar(elevation: 0)
                : null,
        body: ScaffoldBody(
          child: ProviderLoadingProgressWrapper<UserProvider>(
            childBuilder:
                (final BuildContext context, final UserProvider value) {
              data = value.data;

              return _UserProfileTabsContent(
                userData: value.data,
                parentState: this,
                buildCollapsedHeader: _buildCollapsedHeader,
                buildExpandedHeader: _buildExpandedHeader,
                buildToolbarActions: _buildToolbarActions,
                buildActionButtons: _buildActionButtons,
                contributionQueryKey: _getCurrentQueryKey(),
                onYearChanged: _onYearChanged,
                onCustomRangeChanged: _onCustomRangeChanged,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Widget for date range expanded content
class _DateRangeExpandedContent extends StatelessWidget {
  const _DateRangeExpandedContent({
    required this.userName,
    required this.currentQueryKey,
    required this.createdAt,
    required this.onYearChanged,
    required this.onCustomRangeChanged,
    required this.onCollapse,
  });

  final String userName;
  final ContributionQueryKey currentQueryKey;
  final DateTime? createdAt;
  final void Function(int) onYearChanged;
  final void Function(DateTime?, DateTime?) onCustomRangeChanged;
  final VoidCallback onCollapse;

  /// Extract display values from query key
  int? get _selectedYear => currentQueryKey.dateRange.displayYear;
  DateTime? get _customFromDate => currentQueryKey.dateRange.displayFromDate;
  DateTime? get _customToDate => currentQueryKey.dateRange.displayToDate;
  bool get _useCustomRange => currentQueryKey.dateRange.isCustomRange;

  Future<void> _showCustomDateRangePicker(
    final BuildContext context,
    final DateTime? earliestDate,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime initialFrom =
        _customFromDate ?? now.subtract(const Duration(days: 365));
    final DateTime initialTo = _customToDate ?? now;

    // Use createdAt as earliest date, or default to year 2000 if not available
    final DateTime earliest = earliestDate ?? DateTime(2000);

    final DateTime? pickedFrom = await showDatePicker(
      context: context,
      initialDate: initialFrom,
      firstDate: earliest,
      lastDate: now,
      helpText: 'Select start date',
    );

    if (pickedFrom == null) return;

    final DateTime? pickedTo = await showDatePicker(
      context: context,
      initialDate: pickedFrom.isAfter(initialTo) ? pickedFrom : initialTo,
      firstDate: pickedFrom,
      lastDate: now,
      helpText: 'Select end date',
    );

    if (pickedTo != null) {
      onCustomRangeChanged(pickedFrom, pickedTo);
      onCollapse();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Generate available years from joined date to current year
    final List<int> availableYears = generateAvailableYears(createdAt);

    // Determine which option is currently selected
    final dateRange = currentQueryKey.dateRange;
    final bool isLastYearSelected = dateRange.isLastYear;
    final bool isSinceJoiningSelected = _useCustomRange &&
        !isLastYearSelected &&
        isSinceJoining(
          useCustomRange: _useCustomRange,
          customFromDate: _customFromDate,
          createdAt: createdAt,
        );
    final bool isCustomSelected =
        _useCustomRange && !isLastYearSelected && !isSinceJoiningSelected;

    // Build all options into a list
    final List<Widget> optionTiles = <Widget>[];

    // Last Year option
    optionTiles.add(
      _buildOptionTile(
        context: context,
        theme: theme,
        colorScheme: colorScheme,
        icon: Icons.calendar_today,
        title: 'Last Year',
        isSelected: isLastYearSelected,
        onTap: () {
          onCustomRangeChanged(null, null);
          onCollapse();
        },
      ),
    );

    // Year options (sorted in descending order - newest first)
    if (availableYears.isNotEmpty) {
      final List<int> sortedYears = List<int>.from(availableYears)
        ..sort((final int a, final int b) => b.compareTo(a));
      for (final int year in sortedYears) {
        optionTiles.add(
          _buildOptionTile(
            context: context,
            theme: theme,
            colorScheme: colorScheme,
            icon: Icons.calendar_month,
            title: year.toString(),
            isSelected: !_useCustomRange && _selectedYear == year,
            onTap: () {
              onYearChanged(year);
              onCollapse();
            },
          ),
        );
      }
    }

    // Since joining GitHub option
    if (createdAt != null) {
      optionTiles.add(
        _buildOptionTile(
          context: context,
          theme: theme,
          colorScheme: colorScheme,
          icon: Icons.cake,
          title: 'Since joining GitHub',
          isSelected: isSinceJoiningSelected,
          onTap: () {
            final DateTime now = DateTime.now();
            onCustomRangeChanged(createdAt, now);
            onCollapse();
          },
        ),
      );
    }

    // Custom Range option
    optionTiles.add(
      _buildOptionTile(
        context: context,
        theme: theme,
        colorScheme: colorScheme,
        icon: Icons.date_range,
        title: 'Custom Range',
        isSelected: isCustomSelected,
        onTap: () {
          _showCustomDateRangePicker(context, createdAt);
        },
      ),
    );

    return Container(
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(maxWidth: 300),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: optionTiles
              .asMap()
              .entries
              .map((final MapEntry<int, Widget> entry) {
            final int index = entry.key;
            final Widget tile = entry.value;
            final bool isLast = index == optionTiles.length - 1;

            return Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
              ),
              child: tile,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required final BuildContext context,
    required final ThemeData theme,
    required final ColorScheme colorScheme,
    required final IconData icon,
    required final String title,
    required final bool isSelected,
    required final VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: Theme.of(context).surfaceStyle.borderRadiusMedium(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: Theme.of(context).surfaceStyle.borderRadiusMedium(),
              border: isSelected
                  ? Border.all(
                      color: colorScheme.primary.withOpacity(0.5),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      );
}

class _UserProfileTabsContent extends StatefulWidget {
  const _UserProfileTabsContent({
    required this.userData,
    required this.parentState,
    required this.buildCollapsedHeader,
    required this.buildExpandedHeader,
    required this.buildToolbarActions,
    required this.buildActionButtons,
    required this.contributionQueryKey,
    required this.onYearChanged,
    required this.onCustomRangeChanged,
  });

  final GuserInfoData_user userData;
  final TickerProvider parentState;
  final Widget Function(BuildContext, GuserInfoData_user) buildCollapsedHeader;
  final Widget Function(
    BuildContext,
    GuserInfoData_user,
    DynamicTabsController?,
  ) buildExpandedHeader;
  final List<ActionButtonData> Function(
    BuildContext,
    GuserInfoData_user,
    DynamicTabsController?,
  ) buildToolbarActions;
  final Widget Function(
    BuildContext,
    GuserInfoData_user,
    DynamicTabsController?,
  ) buildActionButtons;
  final ContributionQueryKey contributionQueryKey;
  final void Function(int) onYearChanged;
  final void Function(DateTime?, DateTime?) onCustomRangeChanged;

  @override
  State<_UserProfileTabsContent> createState() =>
      _UserProfileTabsContentState();
}

class _UserProfileTabsContentState extends State<_UserProfileTabsContent>
    with TickerProviderStateMixin {
  DynamicTabsController? tabController;

  @override
  void initState() {
    super.initState();
    _initializeTabs();
  }

  void _initializeTabs() {
    final GuserInfoData_user userData = widget.userData;

    if (kDebugMode) {      if (userData.login != widget.contributionQueryKey.userName) {      }
    }

    final List<DynamicTab> tabs = <DynamicTab>[
      DynamicTab(
        identifier: 'Activity',
        isDismissible: false,
        isFocusedOnInit: true,
        tabViewBuilder: (final BuildContext context) {          return UserAboutScreen(
            userData,
            contributionQueryKey: widget.contributionQueryKey,
            onYearChanged: widget.onYearChanged,
            onCustomRangeChanged: widget.onCustomRangeChanged,
          );
        },
      ),
      DynamicTab(
        identifier: 'Activity Feed',
        tab: TabBarItem(label: 'Feed'),
        tabViewBuilder: (final BuildContext context) => Events(
          privateEvents: false,
          specificUser: userData.login,
        ),
      ),
      DynamicTab(
        identifier: 'Repositories',
        // isDismissible: false,
        tabViewBuilder: (final BuildContext context) => UserRepositories(
          userData.login,
          currentUser: userData.isViewer,
        ),
      ),
      DynamicTab(
        identifier: 'Gists',
        tabViewBuilder: (final BuildContext context) =>
            const SizedBox.shrink(), // TODO: Implement Gists tab
      ),
      DynamicTab(
        identifier: 'Organizations',
        tabViewBuilder: (final BuildContext context) =>
            const SizedBox.shrink(), // TODO: Implement Organizations tab
      ),
      DynamicTab(
        identifier: 'Followers',
        tabViewBuilder: (final BuildContext context) =>
            const SizedBox.shrink(), // TODO: Implement Followers tab
      ),
      DynamicTab(
        identifier: 'Following',
        tabViewBuilder: (final BuildContext context) =>
            const SizedBox.shrink(), // TODO: Implement Following tab
      ),
      DynamicTab(
        identifier: 'Stars',
        tabViewBuilder: (final BuildContext context) =>
            const SizedBox.shrink(), // TODO: Implement Stars tab
      ),
      DynamicTab(
        identifier: 'Packages',
        tabViewBuilder: (final BuildContext context) =>
            const SizedBox.shrink(), // TODO: Implement Packages tab
      ),
      DynamicTab(
        identifier: 'Pull Requests',
        tabViewBuilder: (final BuildContext context) =>
            const SizedBox.shrink(), // TODO: Implement Pull Requests tab
      ),
      DynamicTab(
        identifier: 'Issues',
        tabViewBuilder: (final BuildContext context) =>
            const SizedBox.shrink(), // TODO: Implement Issues tab
      ),
      DynamicTab(
        identifier: 'Projects',
        tabViewBuilder: (final BuildContext context) =>
            const SizedBox.shrink(), // TODO: Implement Projects tab
      ),
      DynamicTab(
        identifier: 'Sponsors',
        tabViewBuilder: (final BuildContext context) =>
            const SizedBox.shrink(), // TODO: Implement Sponsors tab
      ),
    ];
    tabController = DynamicTabsController(vsync: this, tabs: tabs);
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => FloatingToolbarWrapper(
        toolbarBuilder: (
          final ValueNotifier<ScrollNotification?> scrollNotificationNotifier,
        ) {
          return ListenableBuilder(
            listenable: tabController ?? ValueNotifier(''),
            builder: (final BuildContext context, final _) {
              return FloatingActionToolbar(
                key: const ValueKey('user_profile_toolbar'),
                actions: widget.buildToolbarActions(
                  context,
                  widget.userData,
                  tabController,
                ),
                actionCardBuilder: (
                  final BuildContext context,
                  final ActionButtonData action,
                ) =>
                    buildStandardActionCard(context, action),
                position: FloatingPosition.bottom,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                bottomPadding: 0.0,
                title: widget.userData.name ?? widget.userData.login,
                subtitle:
                    widget.userData.name != null ? widget.userData.login : null,
                scrollNotificationNotifier: scrollNotificationNotifier,
                onExpandChanged: (final bool isExpanded) {},
              );
            },
          );
        },
        child: tabController != null
            ? SafeArea(
              bottom: false,
                child: ExpandOnScrollWrapper(
                  collapsedWidget: (final BuildContext context,
                          final double pullProgress,
                          final bool isReadyToExpand) =>
                      PullToExpandIndicator(
                    pullProgress: pullProgress,
                    isReadyToExpand: isReadyToExpand,
                  ),
                  expandedWidget: (
                    final BuildContext context,
                    final VoidCallback onCollapse,
                  ) =>
                      ExpandableMetadataContent(
                    onCollapse: onCollapse,
                    // title: widget.userData.login,
                    children: _buildUserMetadataTiles(),
                  ),
                  builder: (
                    final BuildContext context,
                    final Widget expandOnScrollWidget,
                  ) =>
                      DynamicTabsParent(
                    controller: tabController!,
                    builder: (
                      final BuildContext context,
                      final PreferredSizeWidget tabBar,
                      final tabView,
                    ) =>
                        DynamicScroll(
                      collapsedWidget: widget.buildCollapsedHeader(
                        context,
                        widget.userData,
                      ),
                      expandedWidget: widget.buildExpandedHeader(
                        context,
                        widget.userData,
                        tabController,
                      ),
                      actions: <Widget>[
                        // Share button can go here
                      ],
                      headerSlivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: expandOnScrollWidget,
                          ),
                        ),
                        AnimatedTabBar(
                          showTabBar: tabController!.activeLength > 1,
                          tabBar: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: tabBar,
                          ),
                        ),
                      ],
                      bodyBuilder: tabView,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      );

  /// Builds metadata tiles for the user
  List<Widget> _buildUserMetadataTiles() {
    final List<Widget> tiles = <Widget>[];

    return widget.userData.when(
      user: (final GuserInfoData_user__asUser user) {
        // Bio
        if (user.bio != null && user.bio!.isNotEmpty) {
          tiles.add(
            DetailTile(
              title: 'Bio',
              actionType: DetailTileActionType.none,
              child: DetailTileText(user.bio!),
            ),
          );
        }

        // Pronouns
        if (user.pronouns != null && user.pronouns!.isNotEmpty) {
          tiles.add(
            DetailTile(
              title: 'Pronouns',
              actionType: DetailTileActionType.none,
              child: DetailTileText(user.pronouns!),
            ),
          );
        }

        // Location
        if (user.location != null) {
          tiles.add(
            DetailTile(
              title: 'Location',
              actionType: DetailTileActionType.none,
              child: DetailTileText(user.location!),
            ),
          );
        }

        // Company
        if (user.company != null) {
          tiles.add(
            DetailTile(
              title: 'Company',
              actionType: DetailTileActionType.none,
              child: DetailTileText(user.company!),
            ),
          );
        }

        // Status
        if (user.status != null && user.status!.message != null) {
          final String statusText = user.status!.emoji != null
              ? '${user.status!.emoji} ${user.status!.message}'
              : user.status!.message!;
          tiles.add(
            DetailTile(
              title: 'Status',
              actionType: DetailTileActionType.none,
              child: DetailTileText(statusText),
            ),
          );
        }

        // Available for hire
        if (user.isHireable == true) {
          tiles.add(
            DetailTile(
              title: 'Available for hire',
              actionType: DetailTileActionType.none,
              child: DetailTileText('Yes'),
            ),
          );
        }

        // Email
        if (user.email.isNotEmpty) {
          tiles.add(
            DetailTile(
              title: 'Email',
              actionType: DetailTileActionType.navigation,
              onTap: () {
                // Handle email tap
              },
              child: DetailTileText(user.email),
            ),
          );
        }

        // Twitter
        if (user.twitterUsername != null) {
          tiles.add(
            DetailTile(
              title: 'Twitter',
              actionType: DetailTileActionType.navigation,
              onTap: () {
                // Handle Twitter tap
              },
              child: DetailTileText('@${user.twitterUsername}'),
            ),
          );
        }

        // Website
        if (user.websiteUrl != null) {
          tiles.add(
            DetailTile(
              title: 'Website',
              actionType: DetailTileActionType.navigation,
              onTap: () {
                // Handle website tap
              },
              child: DetailTileText(user.websiteUrl!.toString()),
            ),
          );
        }

        // Joined date
        tiles.add(
          DetailTile(
            title: 'Joined',
            actionType: DetailTileActionType.none,
            child: DetailTileText(
              getDate(user.createdAt.toString(), shorten: false),
            ),
          ),
        );

        return tiles;
      },
      orElse: () {
        // Organization metadata
        // Bio
        if (widget.userData.bio != null) {
          tiles.add(
            DetailTile(
              title: 'Bio',
              actionType: DetailTileActionType.none,
              child: DetailTileText(widget.userData.bio!),
            ),
          );
        }

        // Location
        if (widget.userData.location != null) {
          tiles.add(
            DetailTile(
              title: 'Location',
              actionType: DetailTileActionType.none,
              child: DetailTileText(widget.userData.location!),
            ),
          );
        }

        // Website
        if (widget.userData.websiteUrl != null) {
          tiles.add(
            DetailTile(
              title: 'Website',
              actionType: DetailTileActionType.navigation,
              onTap: () {
                // Handle website tap
              },
              child: DetailTileText(widget.userData.websiteUrl!.toString()),
            ),
          );
        }

        // Created date
        tiles.add(
          DetailTile(
            title: 'Created',
            actionType: DetailTileActionType.none,
            child: DetailTileText(
              getDate(widget.userData.createdAt.toString(), shorten: false),
            ),
          ),
        );

        return tiles;
      },
    );
  }
}
