import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/events/events.dart';
import 'package:diohub/common/misc/animated_tab_bar.dart';
import 'package:diohub/common/misc/collapsible_app_bar.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/floating_action_toolbar.dart';
import 'package:diohub/common/misc/floating_toolbar_wrapper.dart';
import 'package:diohub/common/misc/ink_pot.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
import 'package:diohub/common/misc/sliver_pinned_overlap_injector.dart';
import 'package:diohub/common/search_overlay/search_bar.dart';
import 'package:diohub/common/search_overlay/search_overlay.dart';
import 'package:diohub/common/wrappers/dynamic_tabs_parent.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub/graphql/queries/viewer/__generated__/viewer.query.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/search_data_provider.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/users/user_info_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/common/misc/overlay_menu_widget.dart';
import 'package:diohub/view/account/account_switcher.dart';
import 'package:diohub/view/home/home_toolbar_actions_handler.dart';
import 'package:diohub/view/home/widgets/accounts_tab.dart';
import 'package:diohub/view/home/widgets/issues_tab.dart';
import 'package:diohub/view/home/widgets/pulls_tab.dart';
import 'package:diohub/view/home/widgets/theme_tab.dart';
import 'package:diohub/view/home/widgets/theme_carousel_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.deepLinkData, this.buildThemePZero});

  final dynamic buildThemePZero;
  final PathData? deepLinkData;

  // final TabController parentTabController;
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final OverlayController _accountSwitcherController = OverlayController();

  late final DynamicTabsController tabsController = DynamicTabsController(
    vsync: this,
    tabs: _buildTabs(),
  );

  // GlobalKeys for accessing SearchScrollWrapperState
  final GlobalKey<SearchScrollWrapperState> _issuesSearchKey =
      GlobalKey<SearchScrollWrapperState>();
  final GlobalKey<SearchScrollWrapperState> _pullsSearchKey =
      GlobalKey<SearchScrollWrapperState>();

  List<DynamicTab> _buildTabs() => <DynamicTab>[
        DynamicTab(
          identifier: 'Events',
          tab: TabBarItem(label: 'Feed'),
          isDismissible: false,
          tabViewBuilder: (final BuildContext context) => CustomScrollView(
            slivers: [
              SliverPinnedOverlapInjector(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
              Events(),
            ],
          ),
        ),
        DynamicTab(
          identifier: 'Issues',
          tabViewBuilder: (final BuildContext context) => IssuesTab(
            deepLinkData: widget.deepLinkData?.components.first == 'issues'
                ? widget.deepLinkData
                : null,
            searchWrapperKey: _issuesSearchKey,
          ),
        ),
        DynamicTab(
          identifier: 'Pulls',
          tab: TabBarItem(label: 'Pull Requests'),
          tabViewBuilder: (final BuildContext context) => PullsTab(
            deepLinkData: widget.deepLinkData?.components.first == 'pulls'
                ? widget.deepLinkData
                : null,
            searchWrapperKey: _pullsSearchKey,
          ),
        ),
        DynamicTab(
          identifier: 'orgs',
          tab: TabBarItem(label: 'Organizations'),
          tabViewBuilder: (final BuildContext context) => InfiniteScrollWrapper<
              GgetViewerOrgsData_viewer_organizations_edges?>(
            future: (
              final ScrollWrapperFutureArguments<
                      GgetViewerOrgsData_viewer_organizations_edges?>
                  data,
            ) async =>
                UserInfoService.getViewerOrgs(
              refresh: data.refresh,
              after: data.lastItem?.cursor,
            ),
            separatorBuilder: (final BuildContext context, final int index) =>
                const Divider(height: 8),
            listEndIndicator: false,
            // divider: false,
            builder: (
              final BuildContext context,
              final ScrollWrapperBuilderData<
                      GgetViewerOrgsData_viewer_organizations_edges?>
                  data,
            ) =>
                Row(
              children: <Widget>[
                Expanded(
                  child: ProfileTile.login(
                    avatarUrl: data.item?.node?.avatarUrl.toString(),
                    userLogin: data.item?.node?.login,
                    padding: const EdgeInsets.all(16),
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
        DynamicTab(
          identifier: 'Accounts',
          tab: TabBarItem(label: 'Accounts'),
          tabViewBuilder: (final BuildContext context) => const AccountsTab(),
        ),
        DynamicTab(
          identifier: 'Theme',
          tab: TabBarItem(label: 'Theme'),
          tabViewBuilder: (final BuildContext context) => const ThemeTab(),
        ),
        DynamicTab(
          identifier: 'ThemeCarousel',
          tab: TabBarItem(label: 'Themes'),
          keepViewAlive: true,
          tabViewBuilder: (final BuildContext context) =>
              const ThemeCarouselTab(),
        ),
      ];

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    return SizedBox.expand(
      child: FloatingToolbarWrapper(
        toolbarBuilder: (scrollNotificationNotifier) =>
            ValueListenableBuilder<String>(
          valueListenable: tabsController.activeIdentifierNotifier,
          builder: (context, currentTab, _) {
            // Prominent actions (will appear above the row)
            // Always include these buttons so they can animate out smoothly when switching tabs
            // Use visibilityState to control visibility instead of conditionally adding
            final issuesSearchState = _issuesSearchKey.currentState;
            final pullsSearchState = _pullsSearchKey.currentState;

            // Use StatefulBuilder to rebuild when search data changes
            return StatefulBuilder(
              builder: (context, setState) {
                final handler = HomeScreenToolbarActionsHandler(
                  context: context,
                  currentTab: currentTab,
                  tabsController: tabsController,
                  issuesSearchState: issuesSearchState,
                  pullsSearchState: pullsSearchState,
                  setState: setState,
                );

                final allActions = handler.buildActions();

                return FloatingActionToolbar(
                  key: const ValueKey('home_toolbar'),
                  actions: allActions,
                  actionCardBuilder: (context, action) =>
                      buildStandardActionCard(context, action),
                  position: FloatingPosition.bottom,
                  title: context.provider<CurrentUserProvider>().data.login,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  scrollNotificationNotifier: scrollNotificationNotifier,
                  onExpandChanged: (isExpanded) {},
                );
              },
            );
          },
        ),
        child: SafeArea(
            bottom: false,
          child: DynamicTabsParent(
            controller: tabsController,
            builder: (
              final BuildContext context,
              final PreferredSizeWidget tabBar,
              final WidgetBuilder tabView,
            ) =>
                DynamicScroll(
              collapsedWidget: buildCollapsedAppBar(context),
              headerSlivers: [
                AnimatedTabBar(
                  showTabBar: tabsController.activeLength > 1,
                  tabBar: tabBar,
                  // defaultPadding: const EdgeInsets.only(bottom: 8),
                ),
              ],
              expandedWidget: buildProfileCard(context),
              bodyBuilder: (BuildContext context) {
                // Note: Tab views that have pinned headers should use
                // OverlapAwarePinnedHeader to ensure they appear below the
                // header pinned tab bar instead of behind it.
                // Example: OverlapAwarePinnedHeader(child: YourPinnedContent())
                return tabView(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProfileCard(final BuildContext context) {
    final user = context.provider<CurrentUserProvider>().data;
    final searchProvider = context.provider<SearchDataProvider>();
    final name = user.name?.trim().isNotEmpty == true ? user.name! : user.login;
    final subtitle = user.name?.trim().isNotEmpty == true ? user.login : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileTile.avatar(
                avatarUrl: user.avatarUrl.toString(),
                userLogin: user.login,
                padding: EdgeInsets.zero,
                size: 56,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: context.textTheme.titleLarge?.asBold(),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@$subtitle',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              OverlayMenuWidget(
                controller: _accountSwitcherController,
                heightMultiplier: 0.6,
                childAnchor: Alignment.bottomRight,
                portalAnchor: Alignment.topRight,
                overlay: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 500,
                  ),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AccountSwitcher(
                      onClose: () {
                        _accountSwitcherController.close();
                      },
                    ),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded),
                  tooltip: 'Switch Account',
                  onPressed: () {
                    print('[Home] Switching account');
                    _accountSwitcherController.open();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSearchBar(
            heroTag: 'homeSearchBar',
            prompt: 'Search GitHub',
            searchData: searchProvider.searchData,
            onSubmit: (final SearchData data) {
              searchProvider.updateSearchData(data);
              if (data.isActive) {
                AutoRouter.of(context).push(const SearchRoute());
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Row buildCollapsedAppBar(final BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          OverlayMenuWidget(
            controller: _accountSwitcherController,
            heightMultiplier: 0.6,
            childAnchor: Alignment.bottomCenter,
            portalAnchor: Alignment.topCenter,
            overlay: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
                maxHeight: 500,
              ),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AccountSwitcher(
                  onClose: () {
                    _accountSwitcherController.close();
                  },
                ),
              ),
            ),
            child: ClipOval(
              child: InkPot(
                onTap: () {
                  _accountSwitcherController.tapped();
                },
                child: CachedNetworkImage(
                  height: 32,
                  imageUrl: context.viewer.avatarUrl.toString(),
                  placeholder: (final BuildContext context, final _) =>
                      ShimmerWidget(
                    child: Container(color: context.colorScheme.surface),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            context.provider<CurrentUserProvider>().data.login,
            style: context.textTheme.bodyMedium?.asBold(),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ],
      );
}
