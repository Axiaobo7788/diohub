import 'package:diohub/view/repository/md3/repository_md3_layout.dart';
import 'package:diohub/view/repository/md3/repository_md3_theme.dart';
import 'package:flutter/material.dart';

/// Shared responsive shell for the new Repository information architecture.
///
/// The shell owns only layout and global navigation. Repository data remains
/// in the existing Riverpod providers and is supplied by the page widgets.
class RepositoryMd3Shell extends StatelessWidget {
  const RepositoryMd3Shell({
    required this.repositoryLabel,
    required this.header,
    required this.repositoryNavigation,
    required this.body,
    required this.onBack,
    required this.onSearch,
    required this.onRefresh,
    required this.onOpenLegacy,
    this.aside,
    super.key,
  });

  final String repositoryLabel;
  final Widget header;
  final Widget repositoryNavigation;
  final Widget body;
  final Widget? aside;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onRefresh;
  final VoidCallback onOpenLegacy;

  @override
  Widget build(final BuildContext context) {
    return Theme(
      data: repositoryMd3ThemeFor(Theme.of(context)),
      child: LayoutBuilder(
        builder:
            (final BuildContext context, final BoxConstraints constraints) {
              final RepositoryWindowClass windowClass =
                  RepositoryMd3Layout.windowClassFor(constraints.maxWidth);
              return _RepositoryScaffold(
                key: ValueKey<String>('repository-md3-${windowClass.name}'),
                windowClass: windowClass,
                repositoryLabel: repositoryLabel,
                header: header,
                repositoryNavigation: repositoryNavigation,
                body: body,
                aside: aside,
                onBack: onBack,
                onSearch: onSearch,
                onRefresh: onRefresh,
                onOpenLegacy: onOpenLegacy,
              );
            },
      ),
    );
  }
}

class _RepositoryScaffold extends StatelessWidget {
  const _RepositoryScaffold({
    required this.windowClass,
    required this.repositoryLabel,
    required this.header,
    required this.repositoryNavigation,
    required this.body,
    required this.onBack,
    required this.onSearch,
    required this.onRefresh,
    required this.onOpenLegacy,
    this.aside,
    super.key,
  });

  final RepositoryWindowClass windowClass;
  final String repositoryLabel;
  final Widget header;
  final Widget repositoryNavigation;
  final Widget body;
  final Widget? aside;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onRefresh;
  final VoidCallback onOpenLegacy;

  bool get _isCompact => windowClass == RepositoryWindowClass.compact;
  bool get _isExpanded => windowClass == RepositoryWindowClass.expanded;

  void _onDestinationSelected(final BuildContext context, final int index) {
    if (_isCompact) {
      Navigator.of(context).pop();
    }
    switch (index) {
      case 0:
        onBack();
      case 1:
        break;
      case 2:
        onSearch();
      case 3:
        onOpenLegacy();
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      drawer: _isCompact
          ? NavigationDrawer(
              key: const ValueKey<String>('repository-md3-drawer'),
              selectedIndex: 1,
              onDestinationSelected: (final int index) =>
                  _onDestinationSelected(context, index),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    RepositoryMd3Layout.space24,
                    RepositoryMd3Layout.space16,
                    RepositoryMd3Layout.space16,
                    RepositoryMd3Layout.space8,
                  ),
                  child: Text(
                    'DioHub',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ..._destinations.map(
                  (final NavigationRailDestination destination) =>
                      NavigationDrawerDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: destination.label,
                      ),
                ),
              ],
            )
          : null,
      appBar: AppBar(
        leading: _isCompact
            ? Builder(
                builder: (final BuildContext context) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open navigation',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: onBack,
              ),
        title: _isCompact
            ? Text(repositoryLabel, overflow: TextOverflow.ellipsis)
            : Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: RepositoryMd3Layout.appSearchWidth,
                  ),
                  child: SearchBar(
                    hintText: 'Search GitHub',
                    leading: const Icon(Icons.search),
                    onTap: onSearch,
                    onSubmitted: (final String _) => onSearch(),
                  ),
                ),
              ),
        actions: <Widget>[
          if (_isCompact)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: onSearch,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh repository',
            onPressed: onRefresh,
          ),
          PopupMenuButton<_RepositoryMenuAction>(
            tooltip: 'Repository options',
            onSelected: (final _RepositoryMenuAction value) {
              if (value == _RepositoryMenuAction.legacy) {
                onOpenLegacy();
              }
            },
            itemBuilder: (final BuildContext context) =>
                const <PopupMenuEntry<_RepositoryMenuAction>>[
                  PopupMenuItem<_RepositoryMenuAction>(
                    value: _RepositoryMenuAction.legacy,
                    child: Text('Open legacy layout'),
                  ),
                ],
          ),
        ],
      ),
      body: Row(
        children: <Widget>[
          if (!_isCompact) ...<Widget>[
            SizedBox(
              key: const ValueKey<String>('repository-md3-navigation-rail'),
              width: _isExpanded
                  ? RepositoryMd3Layout.expandedNavigationRailWidth
                  : RepositoryMd3Layout.navigationRailWidth,
              child: NavigationRail(
                extended: _isExpanded,
                selectedIndex: 1,
                labelType: _isExpanded
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                onDestinationSelected: (final int index) =>
                    _onDestinationSelected(context, index),
                destinations: _destinations,
              ),
            ),
            const VerticalDivider(),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                repositoryNavigation,
                const Divider(),
                Expanded(
                  child: _isExpanded && aside != null
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(child: body),
                            const VerticalDivider(),
                            SizedBox(
                              key: const ValueKey<String>(
                                'repository-md3-about-panel',
                              ),
                              width: RepositoryMd3Layout.asideWidth,
                              child: aside,
                            ),
                          ],
                        )
                      : body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<NavigationRailDestination> _destinations =
    <NavigationRailDestination>[
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder),
        label: Text('Repository'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.search),
        selectedIcon: Icon(Icons.manage_search),
        label: Text('Search'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.history),
        selectedIcon: Icon(Icons.history_toggle_off),
        label: Text('Legacy view'),
      ),
    ];

enum _RepositoryMenuAction { legacy }
