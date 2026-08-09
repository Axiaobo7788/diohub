part of 'global_lists_screen.dart';

class _GlobalListHeader extends ConsumerWidget {
  const _GlobalListHeader({
    required this.destination,
    required this.login,
    required this.resourceScope,
    required this.scope,
    required this.state,
    required this.searchController,
    required this.showCompactFilters,
  });

  final GlobalListDestination destination;
  final String login;
  final ResourceScope resourceScope;
  final SearchScope scope;
  final SearchState state;
  final TextEditingController searchController;
  final bool showCompactFilters;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final SearchStateNotifier notifier = ref.read(
      searchStateNotifierProvider(scope).notifier,
    );
    final bool repositories = destination == GlobalListDestination.repositories;
    final String issueState = state
        .activeQualifierValues('is')
        .firstWhere(
          (final String value) => value == 'open' || value == 'closed',
          orElse: () => '',
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, showCompactFilters ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder:
                (final BuildContext context, final BoxConstraints constraints) {
                  final Widget heading = Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        _title(context, destination),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (repositories)
                        Text(
                          context.l10n.globalListsRepositoriesFor(login),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  );
                  if (repositories) {
                    return heading;
                  }
                  final Widget createButton = FilledButton.icon(
                    onPressed: () => unawaited(
                      _startCreateFlow(
                        context: context,
                        ref: ref,
                        destination: destination,
                        login: login,
                        resourceScope: resourceScope,
                      ),
                    ),
                    icon: Icon(
                      destination == GlobalListDestination.issues
                          ? Icons.add
                          : Icons.call_merge_outlined,
                    ),
                    label: Text(
                      destination == GlobalListDestination.issues
                          ? context.l10n.globalListsNewIssue
                          : context.l10n.globalListsNewPullRequest,
                    ),
                  );
                  if (constraints.maxWidth < 680) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        heading,
                        const SizedBox(height: 12),
                        createButton,
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      Expanded(child: heading),
                      const SizedBox(width: 12),
                      createButton,
                    ],
                  );
                },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder:
                (final BuildContext context, final BoxConstraints constraints) {
                  final bool stack = constraints.maxWidth < 680;
                  final Widget search = TextField(
                    key: ValueKey<String>(
                      'global-lists-search-${destination.name}',
                    ),
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: notifier.updateFreeText,
                    decoration: InputDecoration(
                      hintText: _searchHint(context, destination),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: state.freeText.isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.l10n.globalListsClearFilters,
                              onPressed: () {
                                searchController.clear();
                                notifier.updateFreeText('');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  );
                  final Widget controls = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      if (!repositories)
                        SegmentedButton<bool>(
                          key: ValueKey<String>(
                            'global-lists-state-${destination.name}',
                          ),
                          showSelectedIcon: false,
                          segments: <ButtonSegment<bool>>[
                            ButtonSegment<bool>(
                              value: true,
                              icon: const Icon(Icons.adjust_outlined),
                              label: Text(context.l10n.repoOpen),
                            ),
                            ButtonSegment<bool>(
                              value: false,
                              icon: const Icon(Icons.check),
                              label: Text(context.l10n.repoClosed),
                            ),
                          ],
                          selected: <bool>{issueState != 'closed'},
                          onSelectionChanged: (final Set<bool> selection) {
                            notifier.replaceQualifier(
                              QualifierExpression(
                                selection.single
                                    ? Qualifier.isOpen
                                    : Qualifier.isClosed,
                              ),
                            );
                          },
                        ),
                      _SortMenu(
                        destination: destination,
                        scope: scope,
                        state: state,
                      ),
                    ],
                  );
                  if (stack) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        search,
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: controls,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      Expanded(child: search),
                      const SizedBox(width: 10),
                      controls,
                    ],
                  );
                },
          ),
          if (showCompactFilters) ...<Widget>[
            const SizedBox(height: 12),
            _CompactQuickFilters(
              destination: destination,
              scope: scope,
              state: state,
            ),
          ],
        ],
      ),
    );
  }
}

class _GlobalListSidebar extends ConsumerWidget {
  const _GlobalListSidebar({
    required this.destination,
    required this.scope,
    required this.state,
  });

  final GlobalListDestination destination;
  final SearchScope scope;
  final SearchState state;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final SearchStateNotifier notifier = ref.read(
      searchStateNotifierProvider(scope).notifier,
    );
    final List<QuickFilter> filters = _quickFilters(destination, scope);
    final String? selected = _selectedQuickFilter(state, filters);

    return ListView(
      key: ValueKey<String>('global-lists-sidebar-${destination.name}'),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
      children: <Widget>[
        _SidebarTile(
          selected: selected == null,
          icon: _destinationIcon(destination),
          label: _title(context, destination),
          onTap: () => notifier.selectExclusiveQuickFilter(null),
        ),
        for (final QuickFilter filter in filters)
          _SidebarTile(
            selected: selected == filter.qualifier.qualifier.toQueryString(),
            icon: _quickFilterIcon(filter),
            label: _quickFilterLabel(context, filter),
            onTap: () => notifier.selectExclusiveQuickFilter(filter),
          ),
      ],
    );
  }
}

class _CompactQuickFilters extends ConsumerWidget {
  const _CompactQuickFilters({
    required this.destination,
    required this.scope,
    required this.state,
  });

  final GlobalListDestination destination;
  final SearchScope scope;
  final SearchState state;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final SearchStateNotifier notifier = ref.read(
      searchStateNotifierProvider(scope).notifier,
    );
    final List<QuickFilter> filters = _quickFilters(destination, scope);
    final String? selected = _selectedQuickFilter(state, filters);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          FilterChip(
            label: Text(context.l10n.globalListsAll),
            selected: selected == null,
            onSelected: (_) => notifier.selectExclusiveQuickFilter(null),
          ),
          for (final QuickFilter filter in filters) ...<Widget>[
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(_quickFilterIcon(filter), size: 16),
              label: Text(_quickFilterLabel(context, filter)),
              selected: selected == filter.qualifier.qualifier.toQueryString(),
              onSelected: (_) => notifier.selectExclusiveQuickFilter(filter),
            ),
          ],
        ],
      ),
    );
  }
}

class _SortMenu extends ConsumerWidget {
  const _SortMenu({
    required this.destination,
    required this.scope,
    required this.state,
  });

  final GlobalListDestination destination;
  final SearchScope scope;
  final SearchState state;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<SortOption> options =
        destination == GlobalListDestination.repositories
        ? const <SortOption>[
            SortOption(key: 'pushed-desc', displayName: 'Recently pushed'),
            SortOption(key: 'updated-desc', displayName: 'Recently updated'),
            SortOption(key: 'stars-desc', displayName: 'Most stars'),
            SortOption(key: 'name-asc', displayName: 'Name'),
          ]
        : scope.sortConfig.options;
    final SortOption selected =
        state.sort ??
        (destination == GlobalListDestination.repositories
            ? options.first
            : scope.sortConfig.defaultSort);
    return MenuAnchor(
      builder:
          (
            final BuildContext context,
            final MenuController controller,
            final Widget? child,
          ) => OutlinedButton.icon(
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            icon: const Icon(Icons.sort, size: 18),
            label: Text(_sortLabel(context, selected.key)),
          ),
      menuChildren: <Widget>[
        for (final SortOption option in options)
          MenuItemButton(
            leadingIcon: option.key == selected.key
                ? const Icon(Icons.check, size: 18)
                : const SizedBox(width: 18),
            onPressed: () => ref
                .read(searchStateNotifierProvider(scope).notifier)
                .updateSort(
                  option.isBestMatch ||
                          (destination == GlobalListDestination.repositories &&
                              option.key == 'pushed-desc')
                      ? null
                      : option,
                ),
            child: Text(_sortLabel(context, option.key)),
          ),
      ],
    );
  }
}
