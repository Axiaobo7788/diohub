import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/events/events.dart';
import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/screen_config.dart';
import 'package:diohub/common/nav_center/shell/nav_center_shell_widgets.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' as gql;
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/profile_card_input.dart';
import 'package:diohub/providers/notifications/notification_count_provider.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/router_provider.dart';
import 'package:diohub/providers/startup_flows/pending_startup_flows_provider.dart';
import 'package:diohub/providers/startup_flows/startup_flow.dart';
import 'package:diohub/providers/watchers/watcher_manager_provider.dart';
import 'package:diohub/services/watchers/background_watcher_service.dart';
import 'package:diohub/utils/fire_and_forget.dart';
import 'package:diohub/view/home/widgets/startup_flow_banners.dart';
import 'package:diohub/common/search_overlay/search_type.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/common/search_overlay/search_bar_with_chips.dart';
import 'package:diohub_models/models/home_filter.dart';
import 'package:diohub/view/home/home_screen_config.dart';
import 'package:diohub/view/home/widgets/home_shimmer_skeleton.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialTabPath, this.filter});

  /// Deeplink path for the initial tab (e.g. 'events', 'issues', 'settings').
  final String? initialTabPath;
  final HomeFilter? filter;

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (!mounted) return;

      // Initialize background watcher service
      fireAndForget(() async {
        await BackgroundWatcherService.instance.initialize((Uri uri) {
          if (mounted) {
            ref.read(pendingDeepLinkProvider.notifier).state = uri;
          }
        });
      }, label: 'Background watcher initialization');

      // Start watcher service
      fireAndForget(
        () async => ref.read(watcherServiceProvider).start(),
        label: 'Watcher startup',
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    final AsyncValue<ViewerInfo?> currentUserAsync = ref.watch(
      currentUserProvider,
    );
    ref.watch(unreadNotificationCountProvider);
    final AsyncValue<PendingFlows> pendingFlowsAsync = ref.watch(
      pendingStartupFlowsProvider,
    );
    if (!currentUserAsync.hasValue || currentUserAsync.requireValue == null) {
      return const HomeShimmerSkeleton();
    }

    final ViewerInfo viewer = currentUserAsync.requireValue!;
    final PendingFlows? pendingFlows = pendingFlowsAsync.hasValue
        ? pendingFlowsAsync.requireValue
        : null;
    final List<StartupFlow> promptedFlows = pendingFlows?.prompted ?? const [];
    final List<StartupFlow> criticalFlows = pendingFlows?.critical ?? const [];
    final Widget? bottomOverlay = promptedFlows.isEmpty
        ? null
        : StartupFlowBanners(promptedFlows: promptedFlows);

    final SearchScope searchScope = SearchScope.typedGlobal(
      searchType: SearchType.repositories,
    );
    final Widget searchBar = Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SearchBarWithChips(
        scope: searchScope,
        hintText: 'Search GitHub',
        onSearchSubmitted: () {
          if (context.mounted) {
            context.router.push(SearchRoute());
          }
        },
      ),
    );
    final List<ExpandedZoneDetail> expandedZoneContent = <ExpandedZoneDetail>[
      ExpandedZoneLeading(searchBar),
    ];

    final ScreenConfig config = buildHomeScreenConfig(
      viewer: viewer,
      ref: ref,
      context: context,
      filter: widget.filter?.value,
      initialTabPath: widget.initialTabPath,
      expandedZoneContent: expandedZoneContent,
      bottomOverlay: bottomOverlay,
      eventsViewBuilder:
          (
            final BuildContext ctx, [
            ValueNotifier<Future<void> Function()?>? refreshRegistrar,
          ]) => Events(refreshRegistrar: refreshRegistrar),
      orgsBody: SliverListBody<ViewerOrgEdge?>(
        getCursor: (final ViewerOrgEdge? item) => item?.cursor,
        fetcher:
            ({
              final String? after,
              final int first = 10,
              final bool refresh = false,
            }) async {
              final List<ViewerOrgEdge?> list = await ref
                  .read(userInfoServiceProvider)
                  .getViewerOrgs(refresh: refresh, after: after);
              final ViewerOrgEdge? last = list.isNotEmpty ? list.last : null;
              return PaginatedResult(
                items: list,
                hasNextPage: list.length >= first,
                endCursor: last?.cursor,
              );
            },
        itemBuilder: (final BuildContext context, final ViewerOrgEdge? item) {
          final ViewerOrgNode? node = item?.node;
          if (node == null) return const SizedBox.shrink();
          final ProfileCardInputOrg input = ProfileCardInputOrg(
            FragmentOrg(node as gql.OrgCardData),
          );
          return BorderedContainer(
            ref: UserRef(login: input.login),
            child: ProfileCard(input),
          );
        },
      ),
    );

    final Widget shell = NavCenterShell(config: config);
    final String viewerLogin =
        ref.read(accountProvider).value?.activeAccount ?? '';
    if (criticalFlows.isNotEmpty) {
      final StartupFlow flow = criticalFlows.first;
      final Widget? modal = flow.buildModal(
        context,
        onComplete: () async {
          await flow.markHandled(ref.container);
          ref.invalidate(pendingStartupFlowsProvider);
        },
      );
      if (modal != null) {
        return Stack(
          children: <Widget>[
            shell,
            Positioned.fill(child: modal),
          ],
        );
      }
    }
    return shell;
  }
}
