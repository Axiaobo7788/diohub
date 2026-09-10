part of 'global_lists_screen.dart';

const double _communityHeaderStackBreakpoint = 680;

class GlobalProjectsPage extends StatefulWidget {
  const GlobalProjectsPage({
    required this.account,
    required this.scope,
    super.key,
  });

  final AccountModel account;
  final ResourceScope scope;

  @override
  State<GlobalProjectsPage> createState() => _GlobalProjectsPageState();
}

class _GlobalProjectsPageState extends State<GlobalProjectsPage> {
  final TextEditingController _searchController = TextEditingController();
  late GlobalProjectBrowseQuery _query = GlobalProjectBrowseQuery(
    login: widget.account.username,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final bool hasProjectScope = ScopeGate.fromScopeString(
      widget.account.scope,
    ).hasScope(GitHubScope.project);
    if (!hasProjectScope) {
      return const _GlobalProjectsPermissionState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _CommunityPageHeader(
          title: context.l10n.navProjects,
          description: context.l10n.globalProjectsOwnedBy(
            widget.account.username,
          ),
          searchKey: const ValueKey<String>('global-projects-search'),
          searchController: _searchController,
          searchHint: context.l10n.globalListsSearchProjects,
          onSearch: (final String text) {
            final GlobalProjectBrowseQuery next = _query.copyWith(text: text);
            if (next != _query) {
              setState(() => _query = next);
            }
          },
          primaryAction: FilledButton.icon(
            onPressed: () => unawaited(_openNewProject(context)),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.globalProjectsNew),
          ),
          filter: _ProjectSortMenu(
            sort: _query.sort,
            onSelected: (final GlobalProjectSort sort) {
              if (sort != _query.sort) {
                setState(() => _query = _query.copyWith(sort: sort));
              }
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleTreeContentTransition(
            transitionKey: _query.identity,
            child: _ProjectResults(resourceScope: widget.scope, query: _query),
          ),
        ),
      ],
    );
  }

  Future<void> _openNewProject(final BuildContext context) async {
    try {
      await openInAppBrowser(
        widget.account.serverConfig.webUrl(
          '/users/${widget.account.username}/projects/new',
        ),
        server: widget.account.serverConfig,
      );
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Could not open the ProjectV2 creation URL',
        error: error,
        stackTrace: stackTrace,
        tag: 'GlobalProjects',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.globalProjectsOpenError)),
        );
      }
    }
  }
}

class GlobalDiscussionsPage extends StatefulWidget {
  const GlobalDiscussionsPage({
    required this.account,
    required this.scope,
    super.key,
  });

  final AccountModel account;
  final ResourceScope scope;

  @override
  State<GlobalDiscussionsPage> createState() => _GlobalDiscussionsPageState();
}

class _GlobalDiscussionsPageState extends State<GlobalDiscussionsPage> {
  final TextEditingController _searchController = TextEditingController();
  late GlobalDiscussionBrowseQuery _query = GlobalDiscussionBrowseQuery(
    login: widget.account.username,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _CommunityPageHeader(
        title: context.l10n.navDiscussions,
        description: context.l10n.globalDiscussionsInvolving(
          widget.account.username,
        ),
        searchKey: const ValueKey<String>('global-discussions-search'),
        searchController: _searchController,
        searchHint: context.l10n.globalListsSearchDiscussions,
        onSearch: (final String text) {
          final GlobalDiscussionBrowseQuery next = _query.copyWith(text: text);
          if (next != _query) {
            setState(() => _query = next);
          }
        },
        filter: _DiscussionFilterMenu(
          filter: _query.filter,
          onSelected: (final GlobalDiscussionFilter filter) {
            if (filter != _query.filter) {
              setState(() => _query = _query.copyWith(filter: filter));
            }
          },
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: SingleTreeContentTransition(
          transitionKey: _query.identity,
          child: _DiscussionResults(resourceScope: widget.scope, query: _query),
        ),
      ),
    ],
  );
}

class _CommunityPageHeader extends StatelessWidget {
  const _CommunityPageHeader({
    required this.title,
    required this.description,
    required this.searchKey,
    required this.searchController,
    required this.searchHint,
    required this.onSearch,
    required this.filter,
    this.primaryAction,
  });

  final String title;
  final String description;
  final Key searchKey;
  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearch;
  final Widget filter;
  final Widget? primaryAction;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
    child: LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final bool stack =
            constraints.maxWidth < _communityHeaderStackBreakpoint;
        final Widget heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
        final Widget search = TextField(
          key: searchKey,
          controller: searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: onSearch,
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: context.l10n.globalListsClearFilters,
                    onPressed: () {
                      searchController.clear();
                      onSearch('');
                    },
                    icon: const Icon(Icons.close),
                  ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (stack) ...<Widget>[
              heading,
              if (primaryAction != null) ...<Widget>[
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: primaryAction,
                ),
              ],
            ] else
              Row(
                children: <Widget>[
                  Expanded(child: heading),
                  if (primaryAction != null) ...<Widget>[
                    const SizedBox(width: 12),
                    primaryAction!,
                  ],
                ],
              ),
            const SizedBox(height: 16),
            if (stack) ...<Widget>[
              search,
              const SizedBox(height: 10),
              Align(alignment: AlignmentDirectional.centerStart, child: filter),
            ] else
              Row(
                children: <Widget>[
                  Expanded(child: search),
                  const SizedBox(width: 10),
                  filter,
                ],
              ),
          ],
        );
      },
    ),
  );
}

class _ProjectSortMenu extends StatelessWidget {
  const _ProjectSortMenu({required this.sort, required this.onSelected});

  final GlobalProjectSort sort;
  final ValueChanged<GlobalProjectSort> onSelected;

  @override
  Widget build(final BuildContext context) => MenuAnchor(
    menuChildren: <Widget>[
      for (final GlobalProjectSort option in GlobalProjectSort.values)
        MenuItemButton(
          leadingIcon: option == sort ? const Icon(Icons.check) : null,
          onPressed: () => onSelected(option),
          child: Text(_projectSortLabel(context, option)),
        ),
    ],
    builder:
        (
          final BuildContext context,
          final MenuController controller,
          final Widget? child,
        ) => OutlinedButton.icon(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.sort),
          label: Text(_projectSortLabel(context, sort)),
        ),
  );
}

class _DiscussionFilterMenu extends StatelessWidget {
  const _DiscussionFilterMenu({required this.filter, required this.onSelected});

  final GlobalDiscussionFilter filter;
  final ValueChanged<GlobalDiscussionFilter> onSelected;

  @override
  Widget build(final BuildContext context) => MenuAnchor(
    menuChildren: <Widget>[
      for (final GlobalDiscussionFilter option in GlobalDiscussionFilter.values)
        MenuItemButton(
          leadingIcon: option == filter ? const Icon(Icons.check) : null,
          onPressed: () => onSelected(option),
          child: Text(_discussionFilterLabel(context, option)),
        ),
    ],
    builder:
        (
          final BuildContext context,
          final MenuController controller,
          final Widget? child,
        ) => OutlinedButton.icon(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.filter_list),
          label: Text(_discussionFilterLabel(context, filter)),
        ),
  );
}

String _projectSortLabel(
  final BuildContext context,
  final GlobalProjectSort sort,
) => switch (sort) {
  GlobalProjectSort.recentlyUpdated => context.l10n.globalListsRecentlyUpdated,
  GlobalProjectSort.name => context.l10n.globalListsName,
};

String _discussionFilterLabel(
  final BuildContext context,
  final GlobalDiscussionFilter filter,
) => switch (filter) {
  GlobalDiscussionFilter.all => context.l10n.globalListsAll,
  GlobalDiscussionFilter.unanswered => context.l10n.globalDiscussionsUnanswered,
  GlobalDiscussionFilter.answered => context.l10n.globalDiscussionsAnswered,
};

class _GlobalProjectsPermissionState extends StatelessWidget {
  const _GlobalProjectsPermissionState();

  @override
  Widget build(final BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.lock_outline, size: 44),
            const SizedBox(height: 16),
            Text(
              context.l10n.globalProjectsPermissionTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.globalProjectsPermissionDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  unawaited(context.router.push<void>(const AuthRoute())),
              icon: const Icon(Icons.login),
              label: Text(context.l10n.globalProjectsReauthorize),
            ),
          ],
        ),
      ),
    ),
  );
}
