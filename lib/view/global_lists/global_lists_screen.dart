import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/common/utils/github_visual_styles.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/l10n/relative_time.dart';
import 'package:diohub/models/global_list_destination.dart';
import 'package:diohub/models/global_repository_browse_query.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/models/repository_preview.dart';
import 'package:diohub/models/search/quick_filter.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/dashboard/home_top_repositories_provider.dart';
import 'package:diohub/providers/repository/repository_preview_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/search/global_search_session_provider.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/app_chrome/app_chrome.dart';
import 'package:diohub/view/app_chrome/global_header.dart';
import 'package:diohub/view/app_chrome/global_navigation_drawer.dart';
import 'package:diohub/view/repository/md3/repository_issue_pull_row.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_graphql/queries/users/user_repositories_list.graphql.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/issue_or_pull.dart';
import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub_models/models/search/sort_config.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'global_lists_filters.dart';
part 'global_lists_results.dart';
part 'global_lists_flows.dart';
part 'global_lists_helpers.dart';

@RoutePage()
class GlobalListsScreen extends ConsumerWidget {
  const GlobalListsScreen({required this.destination, super.key});

  final GlobalListDestination destination;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<AccountSession?> accountState = ref.watch(accountProvider);
    final bool accountResolved =
        accountState.hasValue && !accountState.hasError;
    final AccountModel? account = accountResolved
        ? accountState.value?.activeAccountModel
        : null;
    final ViewerInfo? viewerCandidate = account == null
        ? null
        : ref.watch(currentUserProvider).value;
    final ViewerInfo? viewer = viewerCandidate?.id == account?.nodeId
        ? viewerCandidate
        : null;
    final AsyncValue<List<HomeRepositoryItem>> topRepositories = account == null
        ? const AsyncData<List<HomeRepositoryItem>>(<HomeRepositoryItem>[])
        : ref.watch(
            homeTopRepositoriesProvider((
              accountKey: account.accountKey,
              login: account.username,
            )),
          );

    return GlobalListsShell(
      initialDestination: destination,
      account: account,
      accountLoading: !accountResolved,
      topRepositories: topRepositories,
      statusEmoji: viewer?.status?.emoji,
      statusMessage: viewer?.status?.message,
    );
  }
}

/// Stable production shell for the three account-wide work lists.
///
/// Drawer navigation is local to this shell so switching between Issues,
/// Pull requests, and Repositories does not replace the route and dispose the
/// visited query sessions. Each destination is created lazily and remains
/// mounted after its first visit; hidden destinations have ticker-driven
/// pagination disabled.
class GlobalListsShell extends StatefulWidget {
  const GlobalListsShell({
    required this.initialDestination,
    required this.account,
    required this.accountLoading,
    required this.topRepositories,
    this.statusEmoji,
    this.statusMessage,
    super.key,
  });

  final GlobalListDestination initialDestination;
  final AccountModel? account;
  final bool accountLoading;
  final AsyncValue<List<HomeRepositoryItem>> topRepositories;
  final String? statusEmoji;
  final String? statusMessage;

  @override
  State<GlobalListsShell> createState() => _GlobalListsShellState();
}

class _GlobalListsShellState extends State<GlobalListsShell> {
  late GlobalListDestination _destination = widget.initialDestination;

  @override
  void didUpdateWidget(final GlobalListsShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDestination != widget.initialDestination) {
      _destination = widget.initialDestination;
    }
  }

  void _selectDestination(final GlobalListDestination destination) {
    if (destination == _destination) {
      return;
    }
    setState(() => _destination = destination);
  }

  @override
  Widget build(final BuildContext context) {
    final AccountModel? account = widget.account;
    return AppChrome(
      title: GlobalHeaderTitle(title: _title(context, _destination)),
      account: account,
      accountLoading: widget.accountLoading,
      topRepositories: widget.topRepositories,
      selectedNavigation: _navigationDestination(_destination),
      statusEmoji: widget.statusEmoji,
      statusMessage: widget.statusMessage,
      onGlobalListDestination: _selectDestination,
      body: widget.accountLoading
          ? const _GlobalListsResolvingState()
          : account == null
          ? const _GlobalListsSignInState()
          : _RetainedGlobalListsBody(
              key: ValueKey<String>(account.accountKey),
              destination: _destination,
              account: account,
              scope: resourceScopeForAccount(account),
            ),
    );
  }
}

class _RetainedGlobalListsBody extends StatefulWidget {
  const _RetainedGlobalListsBody({
    required this.destination,
    required this.account,
    required this.scope,
    super.key,
  });

  final GlobalListDestination destination;
  final AccountModel account;
  final ResourceScope scope;

  @override
  State<_RetainedGlobalListsBody> createState() =>
      _RetainedGlobalListsBodyState();
}

class _RetainedGlobalListsBodyState extends State<_RetainedGlobalListsBody> {
  late final Set<GlobalListDestination> _visited = <GlobalListDestination>{
    widget.destination,
  };

  @override
  void didUpdateWidget(final _RetainedGlobalListsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.destination);
  }

  @override
  Widget build(final BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      for (final GlobalListDestination destination
          in GlobalListDestination.values)
        if (_visited.contains(destination))
          TickerMode(
            enabled: destination == widget.destination,
            child: IgnorePointer(
              ignoring: destination != widget.destination,
              child: Offstage(
                offstage: destination != widget.destination,
                child: AnimatedOpacity(
                  opacity: destination == widget.destination ? 1 : 0.94,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : kContentTransitionDuration,
                  curve: kContentTransitionCurve,
                  child: GlobalListsPage(
                    key: ValueKey<String>(
                      '${widget.account.accountKey}:${destination.name}',
                    ),
                    destination: destination,
                    account: widget.account,
                    scope: widget.scope,
                  ),
                ),
              ),
            ),
          ),
    ],
  );
}

class GlobalListsPage extends ConsumerStatefulWidget {
  const GlobalListsPage({
    required this.destination,
    required this.account,
    required this.scope,
    super.key,
  });

  final GlobalListDestination destination;
  final AccountModel account;
  final ResourceScope scope;

  @override
  ConsumerState<GlobalListsPage> createState() => _GlobalListsPageState();
}

class _GlobalListsPageState extends ConsumerState<GlobalListsPage> {
  final TextEditingController _searchController = TextEditingController();
  SearchScope? _boundScope;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final SearchScope scope = _searchScope(widget.destination, widget.account);
    if (_boundScope != scope) {
      _boundScope = scope;
      _searchController.text = ref.read(
        searchStateNotifierProvider(
          scope,
        ).select((final SearchState state) => state.freeText),
      );
    }
    final SearchState searchState = ref.watch(
      searchStateNotifierProvider(scope),
    );
    final bool repositories =
        widget.destination == GlobalListDestination.repositories;
    final String issuePullQuery = searchState.apiQuery;
    final GlobalRepositoryBrowseQuery repositoryQuery = _repositoryBrowseQuery(
      widget.account.username,
      searchState,
    );

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final bool showSidebar = constraints.maxWidth >= 960;
        final Widget content = repositories
            ? _RepositoryResults(
                resourceScope: widget.scope,
                query: repositoryQuery,
              )
            : _IssuePullResults(
                destination: widget.destination,
                resourceScope: widget.scope,
                query: issuePullQuery,
              );

        return Center(
          child: ConstrainedBox(
            key: ValueKey<String>(
              'global-lists-${widget.destination.name}-${showSidebar ? 'wide' : 'compact'}',
            ),
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (showSidebar) ...<Widget>[
                  SizedBox(
                    width: 260,
                    child: _GlobalListSidebar(
                      destination: widget.destination,
                      scope: scope,
                      state: searchState,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _GlobalListHeader(
                        destination: widget.destination,
                        login: widget.account.username,
                        resourceScope: widget.scope,
                        scope: scope,
                        state: searchState,
                        searchController: _searchController,
                        showCompactFilters: !showSidebar,
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey<String>(
                            '${widget.destination.name}:'
                            '${repositories ? repositoryQuery.identity : issuePullQuery}',
                          ),
                          tween: Tween<double>(begin: 0.94, end: 1),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : kContentTransitionDuration,
                          curve: kContentTransitionCurve,
                          builder:
                              (
                                final BuildContext context,
                                final double opacity,
                                final Widget? child,
                              ) => Opacity(opacity: opacity, child: child),
                          child: content,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
