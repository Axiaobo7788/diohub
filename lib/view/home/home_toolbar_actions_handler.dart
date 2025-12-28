import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/settings/theme_mode.dart';
import 'package:diohub/app/theme_settings/api/flex_theme_settings_service.dart';
import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/surface_shape_resolver.dart';
import 'package:diohub/common/search_overlay/search_overlay.dart';
import 'package:diohub/common/widgets/theme_mode_selector_widget.dart';
import 'package:diohub/common/wrappers/search_scroll_wrapper.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/utils/string_compare.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

/// Handles all toolbar action button creation and management for HomeScreen
class HomeScreenToolbarActionsHandler {
  HomeScreenToolbarActionsHandler({
    required this.context,
    required this.currentTab,
    required this.tabsController,
    required this.issuesSearchState,
    required this.pullsSearchState,
    required this.setState,
  });

  final BuildContext context;
  final String currentTab;
  final DynamicTabsController tabsController;
  final SearchScrollWrapperState? issuesSearchState;
  final SearchScrollWrapperState? pullsSearchState;
  final void Function(VoidCallback) setState;

  /// Builds all toolbar actions based on the current tab
  /// Always builds ALL possible actions and uses visibilityState to control visibility
  /// This prevents button reinitialization on tab switches for smooth animations
  List<ActionButtonData> buildActions() {
    final List<ActionButtonData> allActions = [];

    // Always build all tab-specific actions, but control visibility via visibilityState
    // This ensures button instances persist across tab switches for smooth animations
    allActions.addAll(_buildEventsTabActions());
    allActions.addAll(_buildIssuesTabActions());
    allActions.addAll(_buildPullsTabActions());
    allActions.addAll(_buildOrganizationsTabActions());
    allActions.addAll(_buildAccountsTabActions());
    allActions.addAll(_buildThemeCarouselTabActions());

    // Shared search actions (works for both Issues and Pulls tabs)
    allActions.add(_buildSharedSearchAction());
    allActions.add(_buildSharedQuickFiltersAction());
    allActions.add(_buildSharedSortAction());
    allActions.addAll(_buildSharedQuickOptionsActions());

    // Common actions (navigation and account management)
    allActions.addAll(_buildCommonActions());

    return allActions;
  }

  /// Builds actions specific to the Events tab
  List<ActionButtonData> _buildEventsTabActions() {
    return [];
  }

  /// Builds a shared search action that works for both Issues and Pulls tabs
  ActionButtonData _buildSharedSearchAction() {
    final isSearchTab = currentTab == 'Issues' || currentTab == 'Pulls';

    // Determine which search state to use based on current tab
    final searchWrapperState = switch (currentTab) {
      'Issues' => issuesSearchState,
      'Pulls' => pullsSearchState,
      _ => null,
    };

    final isVisible = isSearchTab && searchWrapperState != null;

    // Determine the message based on current tab
    final message = switch (currentTab) {
      'Issues' =>
        searchWrapperState?.searchBarMessage ?? 'Search in your issues',
      'Pulls' =>
        searchWrapperState?.searchBarMessage ?? 'Search in your pull requests',
      _ => 'Search',
    };

    return MinorActionButton(
      icon: Icons.search_rounded,
      label: 'Search',
      category: 'Search & Filter',
      onTap: () async {
        if (searchWrapperState != null) {
          await AutoRouter.of(context).push(
            SearchOverlayRoute(
              message: message,
              multiHero: true,
              searchData: searchWrapperState.currentSearchData,
              heroTag: searchWrapperState.searchHeroTag,
              onSubmit: searchWrapperState.updateSearchData,
            ),
          );
        }
      },
      visibilityState: isVisible
          ? ActionButtonVisibilityState.both
          : ActionButtonVisibilityState.none,
    );
  }

  /// Builds a shared Quick Filters action that works for both Issues and Pulls tabs
  ActionButtonData _buildSharedQuickFiltersAction() {
    final isSearchTab = currentTab == 'Issues' || currentTab == 'Pulls';

    // Determine which search state to use based on current tab
    final searchWrapperState = switch (currentTab) {
      'Issues' => issuesSearchState,
      'Pulls' => pullsSearchState,
      _ => null,
    };

    final isVisible = isSearchTab && searchWrapperState != null;
    final filters = searchWrapperState?.quickFilters;
    final activeFilter = searchWrapperState != null &&
            searchWrapperState.currentSearchData.activeQuickFilter != null &&
            filters != null
        ? filters[searchWrapperState.currentSearchData.activeQuickFilter]
        : null;

    return ExpandableActionButton(
      icon: Icons.filter_list_rounded,
      label: 'Quick Filters',
      subtitle: activeFilter,
      category: 'Search & Filter',
      expandableWidgetBuilder: (onCollapse) {
        if (searchWrapperState == null || filters == null || filters.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildQuickFiltersWidget(
          context,
          searchWrapperState,
          filters,
          onCollapse,
          setState,
        );
      },
      visibilityState: (isVisible && filters != null && filters.isNotEmpty)
          ? ActionButtonVisibilityState.both
          : ActionButtonVisibilityState.none,
    );
  }

  /// Builds a shared Sort action that works for both Issues and Pulls tabs
  ActionButtonData _buildSharedSortAction() {
    final isSearchTab = currentTab == 'Issues' || currentTab == 'Pulls';

    // Determine which search state to use based on current tab
    final searchWrapperState = switch (currentTab) {
      'Issues' => issuesSearchState,
      'Pulls' => pullsSearchState,
      _ => null,
    };

    final isVisible = isSearchTab && searchWrapperState != null;
    final sortOptions = searchWrapperState?.sortOptions;
    final currentSort = searchWrapperState?.currentSearchData.sort;
    final sortSubtitle = (sortOptions != null &&
            currentSort != null &&
            sortOptions.containsKey(currentSort))
        ? sortOptions[currentSort]!
        : null;

    return ExpandableActionButton(
      icon: Icons.sort_rounded,
      label: 'Sort',
      subtitle: sortSubtitle,
      category: 'Search & Filter',
      expandableWidgetBuilder: (onCollapse) {
        if (searchWrapperState == null) {
          return const SizedBox.shrink();
        }
        return _buildSortWidget(
          context,
          searchWrapperState,
          onCollapse,
          setState,
        );
      },
      visibilityState: isVisible
          ? ActionButtonVisibilityState.both
          : ActionButtonVisibilityState.none,
    );
  }

  /// Builds shared Quick Options checkbox actions that work for both Issues and Pulls tabs
  List<ActionButtonData> _buildSharedQuickOptionsActions() {
    final List<ActionButtonData> actions = [];
    final isSearchTab = currentTab == 'Issues' || currentTab == 'Pulls';

    // Determine which search state to use based on current tab
    final searchWrapperState = switch (currentTab) {
      'Issues' => issuesSearchState,
      'Pulls' => pullsSearchState,
      _ => null,
    };

    final isVisible = isSearchTab && searchWrapperState != null;
    final options = searchWrapperState?.quickOptions;
    final optionsToAdd = options?.entries.toList() ?? [];

    for (final entry in optionsToAdd) {
      final filterKey = entry.key;
      final currentSearchData = searchWrapperState?.currentSearchData;
      final isSelected =
          currentSearchData?.filterStrings.contains(filterKey) ?? false;

      actions.add(
        CheckboxActionButton(
          label: entry.value,
          value: isSelected,
          category: 'Search & Filter',
          onChanged: (bool value) {
            if (searchWrapperState == null) return;
            final currentData = searchWrapperState.currentSearchData;
            final filters = currentData.filterStrings.toList();
            if (value) {
              if (!filters.contains(filterKey)) {
                filters.add(filterKey);
              }
            } else {
              filters.remove(filterKey);
            }
            final newSearchData = currentData.copyWith(
              filterStrings: filters,
            );
            searchWrapperState.updateSearchData(newSearchData);
            setState(() {});
          },
          visibilityState: (isVisible && options != null && options.isNotEmpty)
              ? ActionButtonVisibilityState.both
              : ActionButtonVisibilityState.none,
        ),
      );
    }

    return actions;
  }

  /// Builds actions specific to the Issues tab
  /// Always builds these actions, but uses visibilityState to control visibility
  List<ActionButtonData> _buildIssuesTabActions() {
    final List<ActionButtonData> actions = [];
    final isIssuesTab = currentTab == 'Issues';

    // Search, Quick Filters, Sort, and Quick Options are now shared - see _buildShared* methods

    // New Issue button - only visible on Issues tab
    actions.add(
      MajorActionButton(
        icon: Octicons.plus,
        label: 'New Issue',
        isPositive: true,
        category: 'Actions',
        visibilityState: isIssuesTab
            ? ActionButtonVisibilityState.both
            : ActionButtonVisibilityState.none,
        onTap: () {
          // TODO: Navigate to repository selection or issue creation
        },
      ),
    );

    return actions;
  }

  /// Builds actions specific to the Pulls tab
  /// Always builds these actions, but uses visibilityState to control visibility
  List<ActionButtonData> _buildPullsTabActions() {
    final List<ActionButtonData> actions = [];

    // Search, Quick Filters, Sort, and Quick Options are now shared - see _buildShared* methods

    return actions;
  }

  /// Builds actions specific to the Organizations tab
  List<ActionButtonData> _buildOrganizationsTabActions() {
    return [];
  }

  /// Builds actions specific to the Accounts tab
  /// Always builds these actions, but uses visibilityState to control visibility
  List<ActionButtonData> _buildAccountsTabActions() {
    final List<ActionButtonData> actions = [];
    final isAccountsTab = currentTab == 'Accounts';

    // Add Account button - only visible on Accounts tab
    actions.add(
      MajorActionButton(
        icon: Icons.add_rounded,
        label: 'Add Account',
        isPositive: true,
        category: 'Actions',
        visibilityState: isAccountsTab
            ? ActionButtonVisibilityState.both
            : ActionButtonVisibilityState.none,
        onTap: () {
          AutoRouter.of(context).push(
            AuthRoute(
              onAuthenticated: () {},
            ),
          );
        },
      ),
    );

    // Log Out of All Accounts - visible only on Accounts tab when accounts exist
    final accountState = context.read<AccountBloc>().state;
    final hasAccounts =
        accountState is AccountReady && accountState.accounts.isNotEmpty;
    actions.add(
      MajorActionButton(
        icon: Icons.logout_rounded,
        label: 'Log Out of All',
        category: 'Account',
        seedColor: Colors.red,
        visibilityState: (isAccountsTab && hasAccounts)
            ? ActionButtonVisibilityState.both
            : ActionButtonVisibilityState.none,
        onTap: () {
          _showLogOutAllDialog(context);
        },
      ),
    );

    return actions;
  }

  /// Builds actions specific to the Theme Carousel tab
  List<ActionButtonData> _buildThemeCarouselTabActions() {
    final List<ActionButtonData> actions = [];
    final isThemeCarouselTab = currentTab == 'ThemeCarousel';

    // Helper function to get theme mode label
    String _getThemeModeLabel(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return 'Light';
        case ThemeMode.dark:
          return 'Dark';
        case ThemeMode.system:
          return 'Auto';
      }
    }

    // Theme Mode dropdown
    final themeModeSettings =
        Provider.of<ThemeModeSettings>(context, listen: false);
    actions.add(
      ExpandableActionButton(
        icon: Icons.brightness_auto_rounded,
        label: 'Theme Mode',
        subtitle: _getThemeModeLabel(themeModeSettings.themeMode),
        visibilityState: isThemeCarouselTab
            ? ActionButtonVisibilityState.both
            : ActionButtonVisibilityState.none,
        category: 'Theme',
        expandableWidgetBuilder: (onCollapse) {
          return ThemeModeSelectorWidget(onCollapse: onCollapse);
        },
      ),
    );

    // Reset themes button
    actions.add(
      MajorActionButton(
        icon: Icons.refresh_rounded,
        label: 'Reset Theme',
        visibilityState: isThemeCarouselTab
            ? ActionButtonVisibilityState.both
            : ActionButtonVisibilityState.none,
        category: 'Theme',
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: SurfaceShapeResolver.large(context),
              title: const Text('Reset Theme?'),
              content: const Text(
                'This will reset all theme settings to their default values.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Reset'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            final settingsService =
                Provider.of<FlexThemeSettingsService>(context, listen: false);
            await settingsService.reset();
          }
        },
      ),
    );

    return actions;
  }

  /// Builds common actions that appear across all tabs (navigation and account management)
  List<ActionButtonData> _buildCommonActions() {
    final List<ActionButtonData> actions = [];
    final currentUserLogin = context.provider<CurrentUserProvider>().data.login;
    final isAccountsTab = currentTab == 'Accounts';

    // Navigation actions
    actions.addAll([
      MinorActionButton(
        icon: Octicons.pulse,
        label: 'Events',
        actionType: ActionButtonActionType.tab,
        visibilityState: currentTab == 'Events'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        category: 'Navigation',
        onTap: () => tabsController.openTab('Events'),
      ),
      MinorActionButton(
        icon: Octicons.issue_opened,
        label: 'Issues',
        trailing: buildActionButtonTrailingCount(
          context,
          context.viewer.issues.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        category: 'Navigation',
        visibilityState: currentTab == 'Issues'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabsController.openTab('Issues'),
      ),
      MinorActionButton(
        icon: Octicons.git_pull_request,
        label: 'Pull Requests',
        trailing: buildActionButtonTrailingCount(
          context,
          context.viewer.pullRequests.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        category: 'Navigation',
        visibilityState: currentTab == 'Pulls'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.both,
        onTap: () => tabsController.openTab('Pulls'),
      ),
      MinorActionButton(
        icon: Octicons.organization,
        label: 'Organizations',
        trailing: buildActionButtonTrailingCount(
          context,
          context.viewer.organizations.totalCount,
        ),
        actionType: ActionButtonActionType.tab,
        category: 'Navigation',
        visibilityState: currentTab == 'orgs'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabsController.openTab('orgs'),
      ),
      MinorActionButton(
        icon: Octicons.repo,
        label: 'Repositories',
        trailing: buildActionButtonTrailingCount(
          context,
          context.viewer.repositories.totalCount,
        ),
        category: 'Navigation',
        visibilityState: currentTab == 'repos'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () {
          // tabsController.openTab('repos');
        },
      ),
      // MinorActionButton(
      //   icon: Icons.palette_rounded,
      //   label: 'Theme',
      //   actionType: ActionButtonActionType.tab,
      //   category: 'Navigation',
      //   visibilityState: currentTab == 'Theme'
      //       ? ActionButtonVisibilityState.none
      //       : ActionButtonVisibilityState.both,
      //   onTap: () => tabsController.openTab('Theme'),
      // ),
      MinorActionButton(
        icon: Icons.swipe_rounded,
        label: 'Themes',
        actionType: ActionButtonActionType.tab,
        category: 'Navigation',
        visibilityState: currentTab == 'ThemeCarousel'
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () => tabsController.openTab('ThemeCarousel'),
      ),
    ]);

    // Account management actions
    actions.addAll([
      MinorActionButton(
        icon: Icons.person_rounded,
        label: 'Profile',
        category: 'Account',
        actionType: ActionButtonActionType.navigation,
        visibilityState: ActionButtonVisibilityState.expandedOnly,
        onTap: () {
          AutoRouter.of(context)
              .push(UserProfileRoute(login: currentUserLogin));
        },
      ),
      MinorActionButton(
        icon: Icons.swap_horiz_rounded,
        label: 'Manage Accounts',
        category: 'Account',
        actionType: ActionButtonActionType.tab,
        visibilityState: isAccountsTab
            ? ActionButtonVisibilityState.none
            : ActionButtonVisibilityState.expandedOnly,
        onTap: () {
          tabsController.openTab('Accounts');
        },
      ),
      MinorActionButton(
        icon: Icons.settings_rounded,
        label: 'App Settings',
        category: 'Account',
        visibilityState: ActionButtonVisibilityState.expandedOnly,
        onTap: () {
          // Navigate to settings
        },
      ),
      MinorActionButton(
        icon: Icons.notifications_rounded,
        label: 'Notifications',
        category: 'Account',
        visibilityState: ActionButtonVisibilityState.expandedOnly,
        onTap: () {
          // Navigate to notifications
        },
      ),
    ]);

    return actions;
  }

  /// Shows the log out all accounts dialog
  void _showLogOutAllDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out of All Accounts'),
          content: const Text(
            'Are you sure you want to log out of all accounts? This will remove all accounts and clear all local data. You will need to sign in again.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<AccountBloc>().add(LogOutAll());
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.error,
              ),
              child: const Text('Log Out of All'),
            ),
          ],
        );
      },
    );
  }

  /// Builds the quick filters widget
  Widget _buildQuickFiltersWidget(
    BuildContext context,
    SearchScrollWrapperState searchWrapperState,
    Map<String, String> quickFilters,
    VoidCallback onCollapse,
    void Function(VoidCallback) setState,
  ) {
    final currentSearchData = searchWrapperState.currentSearchData;
    final activeQuickFilter = currentSearchData.activeQuickFilter;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: quickFilters.entries.map((entry) {
        final isSelected = activeQuickFilter != null &&
            StringFunctions(activeQuickFilter).isStringEqual(entry.key);
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          shape: SurfaceShapeResolver.shape(
            context,
            size: BorderRadiusSize.small,
          ),
          selected: isSelected,
          selectedTileColor: isSelected ? context.colorScheme.primary : null,
          title: Text(
            entry.value,
            style: context.textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? context.colorScheme.onPrimary
                  : context.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: context.colorScheme.onPrimary,
                )
              : null,
          onTap: () {
            SearchData newSearchData;
            if (isSelected) {
              final filters = currentSearchData.filterStrings.toList();
              final activeFilter = currentSearchData.activeQuickFilter;
              if (activeFilter != null) {
                filters.removeWhere((filter) {
                  for (final quickFilter in quickFilters.keys) {
                    if (StringFunctions(quickFilter).isStringEqual(filter)) {
                      return true;
                    }
                  }
                  return false;
                });
              }
              final quickFiltersList = quickFilters.keys.toList();
              newSearchData = currentSearchData.copyWith(
                filterStrings: filters,
                quickFilters: quickFiltersList,
              );
            } else {
              final quickFiltersList = quickFilters.keys.toList();
              newSearchData = currentSearchData.copyWith(
                quickFilter: entry.key,
                quickFilters: quickFiltersList,
              );
            }
            searchWrapperState.updateSearchData(newSearchData);
            setState(() {});
            onCollapse();
          },
        );
      }).toList(),
    );
  }

  /// Builds the sort widget
  Widget _buildSortWidget(
    BuildContext context,
    SearchScrollWrapperState searchWrapperState,
    VoidCallback onCollapse,
    void Function(VoidCallback) setState,
  ) {
    final currentSearchData = searchWrapperState.currentSearchData;
    final sortOptions = searchWrapperState.sortOptions;
    if (sortOptions == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: sortOptions.entries.map((entry) {
          final isSelected = currentSearchData.sort == entry.key;
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            shape: SurfaceShapeResolver.shape(
              context,
              size: BorderRadiusSize.small,
            ),
            selected: isSelected,
            selectedTileColor: isSelected ? context.colorScheme.primary : null,
            title: Text(
              entry.value,
              style: context.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? context.colorScheme.onPrimary
                    : context.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: context.colorScheme.onPrimary,
                  )
                : null,
            onTap: () {
              final newSearchData = currentSearchData.copyWith(sort: entry.key);
              searchWrapperState.updateSearchData(newSearchData);
              setState(() {});
              onCollapse();
            },
          );
        }).toList(),
      ),
    );
  }
}
