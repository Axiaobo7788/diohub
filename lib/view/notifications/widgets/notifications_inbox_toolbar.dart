part of '../notifications_md3_screen.dart';

class _NotificationsToolbar extends StatelessWidget {
  const _NotificationsToolbar({
    required this.filters,
    required this.projection,
    required this.groupByRepository,
    required this.selectedCount,
    required this.allSelected,
    required this.bulkBusy,
    required this.compact,
    required this.showFilterAction,
    required this.refreshing,
    required this.onSetUnread,
    required this.onSetQuery,
    required this.onSetSortOrder,
    required this.onSetGroupByRepository,
    required this.onOpenFilters,
    required this.onRefresh,
    required this.onMarkAllRead,
    required this.onMarkSelectedDone,
    required this.onClearSelection,
    required this.onToggleAll,
  });

  final NotificationsFiltersState filters;
  final NotificationsProjectionState projection;
  final bool groupByRepository;
  final int selectedCount;
  final bool allSelected;
  final bool bulkBusy;
  final bool compact;
  final bool showFilterAction;
  final bool refreshing;
  final ValueChanged<bool> onSetUnread;
  final ValueChanged<String> onSetQuery;
  final ValueChanged<NotificationSortOrder> onSetSortOrder;
  final ValueChanged<bool> onSetGroupByRepository;
  final VoidCallback onOpenFilters;
  final Future<void> Function() onRefresh;
  final VoidCallback onMarkAllRead;
  final VoidCallback onMarkSelectedDone;
  final VoidCallback onClearSelection;
  final ValueChanged<bool> onToggleAll;

  @override
  Widget build(final BuildContext context) {
    final bool reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedSwitcher(
      key: const ValueKey<String>('notifications-toolbar-switcher'),
      duration: reducedMotion ? Duration.zero : kContentTransitionDuration,
      switchInCurve: kContentTransitionCurve,
      switchOutCurve: kContentTransitionCurve,
      layoutBuilder:
          (final Widget? currentChild, final List<Widget> previousChildren) =>
              Stack(
                alignment: Alignment.centerLeft,
                children: <Widget>[
                  for (final Widget child in previousChildren)
                    IgnorePointer(child: ExcludeSemantics(child: child)),
                  ?currentChild,
                ],
              ),
      child: selectedCount > 0
          ? _SelectionToolbar(
              key: const ValueKey<String>('notifications-selection-toolbar'),
              selectedCount: selectedCount,
              allSelected: allSelected,
              busy: bulkBusy,
              compact: compact,
              onToggleAll: onToggleAll,
              onMarkDone: onMarkSelectedDone,
              onClear: onClearSelection,
            )
          : _InboxFilterToolbar(
              key: const ValueKey<String>('notifications-filter-toolbar'),
              filters: filters,
              projection: projection,
              groupByRepository: groupByRepository,
              compact: compact,
              showFilterAction: showFilterAction,
              bulkBusy: bulkBusy,
              refreshing: refreshing,
              onSetUnread: onSetUnread,
              onSetQuery: onSetQuery,
              onSetSortOrder: onSetSortOrder,
              onSetGroupByRepository: onSetGroupByRepository,
              onOpenFilters: onOpenFilters,
              onMarkAllRead: onMarkAllRead,
              onRefresh: onRefresh,
            ),
    );
  }
}

class _InboxFilterToolbar extends StatelessWidget {
  const _InboxFilterToolbar({
    required this.filters,
    required this.projection,
    required this.groupByRepository,
    required this.compact,
    required this.showFilterAction,
    required this.bulkBusy,
    required this.refreshing,
    required this.onSetUnread,
    required this.onSetQuery,
    required this.onSetSortOrder,
    required this.onSetGroupByRepository,
    required this.onOpenFilters,
    required this.onMarkAllRead,
    required this.onRefresh,
    super.key,
  });

  final NotificationsFiltersState filters;
  final NotificationsProjectionState projection;
  final bool groupByRepository;
  final bool compact;
  final bool showFilterAction;
  final bool bulkBusy;
  final bool refreshing;
  final ValueChanged<bool> onSetUnread;
  final ValueChanged<String> onSetQuery;
  final ValueChanged<NotificationSortOrder> onSetSortOrder;
  final ValueChanged<bool> onSetGroupByRepository;
  final VoidCallback onOpenFilters;
  final VoidCallback onMarkAllRead;
  final Future<void> Function() onRefresh;

  @override
  Widget build(final BuildContext context) {
    final Widget scopeControl = _AllUnreadControl(
      onlyUnread: filters.onlyUnread,
      onChanged: onSetUnread,
    );
    final Widget queryField = _NotificationQueryField(
      value: projection.query,
      compact: compact,
      onChanged: onSetQuery,
    );
    final Widget sortControl = _NotificationPopupControl<NotificationSortOrder>(
      key: const ValueKey<String>('notifications-sort-menu'),
      icon: Icons.swap_vert,
      compact: compact,
      label: context.l10n.notificationsSortLabel(
        projection.sortOrder == NotificationSortOrder.newest
            ? context.l10n.notificationsNewestToOldest
            : context.l10n.notificationsOldestToNewest,
      ),
      initialValue: projection.sortOrder,
      onSelected: onSetSortOrder,
      entries: <PopupMenuEntry<NotificationSortOrder>>[
        _checkedMenuItem<NotificationSortOrder>(
          context: context,
          value: NotificationSortOrder.newest,
          selected: projection.sortOrder == NotificationSortOrder.newest,
          label: context.l10n.notificationsNewestToOldest,
        ),
        _checkedMenuItem<NotificationSortOrder>(
          context: context,
          value: NotificationSortOrder.oldest,
          selected: projection.sortOrder == NotificationSortOrder.oldest,
          label: context.l10n.notificationsOldestToNewest,
        ),
      ],
    );
    final Widget groupControl = _NotificationPopupControl<bool>(
      key: const ValueKey<String>('notifications-group-menu'),
      icon: Icons.view_agenda_outlined,
      compact: compact,
      label: context.l10n.notificationsGroupLabel(
        groupByRepository
            ? context.l10n.notificationsRepository
            : context.l10n.notificationsDate,
      ),
      initialValue: groupByRepository,
      onSelected: onSetGroupByRepository,
      entries: <PopupMenuEntry<bool>>[
        _checkedMenuItem<bool>(
          context: context,
          value: true,
          selected: groupByRepository,
          label: context.l10n.notificationsRepository,
        ),
        _checkedMenuItem<bool>(
          context: context,
          value: false,
          selected: !groupByRepository,
          label: context.l10n.notificationsDate,
        ),
      ],
    );
    final Widget? navigationControl = showFilterAction
        ? _NotificationsNavigationButton(
            compact: compact,
            onPressed: onOpenFilters,
          )
        : null;
    final Widget moreControl = _NotificationsMoreMenu(
      compact: compact,
      showFilterAction: false,
      hasReasonFilters: filters.showOnlyReasons.isNotEmpty,
      busy: bulkBusy,
      refreshing: refreshing,
      onOpenFilters: onOpenFilters,
      onMarkAllRead: onMarkAllRead,
      onRefresh: onRefresh,
    );

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final double textScale = MediaQuery.textScalerOf(context).scale(1);
        final bool singleLine =
            constraints.maxWidth >= 980 && textScale <= 1.15;
        if (singleLine) {
          return Row(
            children: <Widget>[
              if (navigationControl != null) ...<Widget>[
                navigationControl,
                const SizedBox(width: NotificationsMd3Layout.space8),
              ],
              scopeControl,
              const SizedBox(width: NotificationsMd3Layout.space8),
              Expanded(child: queryField),
              const SizedBox(width: NotificationsMd3Layout.space8),
              sortControl,
              const SizedBox(width: NotificationsMd3Layout.space8),
              groupControl,
              const SizedBox(width: NotificationsMd3Layout.space4),
              moreControl,
            ],
          );
        }
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(alignment: Alignment.centerLeft, child: scopeControl),
              const SizedBox(height: NotificationsMd3Layout.space8),
              queryField,
              const SizedBox(height: NotificationsMd3Layout.space8),
              Wrap(
                spacing: NotificationsMd3Layout.space8,
                runSpacing: NotificationsMd3Layout.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  ?navigationControl,
                  sortControl,
                  groupControl,
                  moreControl,
                ],
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                scopeControl,
                const SizedBox(width: NotificationsMd3Layout.space8),
                Expanded(child: queryField),
              ],
            ),
            const SizedBox(height: NotificationsMd3Layout.space8),
            Row(
              children: <Widget>[
                if (navigationControl != null) ...<Widget>[
                  navigationControl,
                  const SizedBox(width: NotificationsMd3Layout.space8),
                ],
                Expanded(child: sortControl),
                const SizedBox(width: NotificationsMd3Layout.space8),
                Expanded(child: groupControl),
                const SizedBox(width: NotificationsMd3Layout.space4),
                moreControl,
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AllUnreadControl extends StatelessWidget {
  const _AllUnreadControl({required this.onlyUnread, required this.onChanged});

  final bool onlyUnread;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey<String>('notifications-all-unread-control'),
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ScopeOption(
            label: context.l10n.notificationsAll,
            selected: !onlyUnread,
            onTap: () => onChanged(false),
          ),
          _ScopeOption(
            label: context.l10n.notificationsUnread,
            selected: onlyUnread,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 54),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? colors.surface : null,
              border: Border(
                right: BorderSide(
                  color: selected ? colors.outlineVariant : Colors.transparent,
                ),
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationQueryField extends StatefulWidget {
  const _NotificationQueryField({
    required this.value,
    required this.compact,
    required this.onChanged,
  });

  final String value;
  final bool compact;
  final ValueChanged<String> onChanged;

  @override
  State<_NotificationQueryField> createState() =>
      _NotificationQueryFieldState();
}

class _NotificationQueryFieldState extends State<_NotificationQueryField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant final _NotificationQueryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final bool expandedHitTarget = _usesExpandedHitTarget(
      context,
      compact: widget.compact,
    );
    final bool canClear = _controller.text.isNotEmpty;
    final double targetExtent = expandedHitTarget ? 48 : 40;
    return SizedBox(
      key: const ValueKey<String>('notifications-query-target'),
      height: targetExtent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Align(
            child: SizedBox(
              height: 40,
              child: TextField(
                key: const ValueKey<String>('notifications-query-field'),
                controller: _controller,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.l10n.notificationsSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: canClear ? const SizedBox(width: 48) : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    maxWidth: 48,
                    minHeight: 0,
                    maxHeight: 40,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          if (canClear)
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox.square(
                key: const ValueKey<String>('notifications-query-clear'),
                dimension: targetExtent,
                child: IconButton(
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  tooltip: context.l10n.notificationsClearSearch,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

PopupMenuItem<T> _checkedMenuItem<T>({
  required final BuildContext context,
  required final T value,
  required final bool selected,
  required final String label,
}) => PopupMenuItem<T>(
  value: value,
  child: Row(
    children: <Widget>[
      SizedBox(
        width: 24,
        child: selected ? const Icon(Icons.check, size: 18) : null,
      ),
      Expanded(child: Text(label)),
    ],
  ),
);

class _NotificationPopupControl<T> extends StatelessWidget {
  const _NotificationPopupControl({
    required this.icon,
    required this.compact,
    required this.label,
    required this.initialValue,
    required this.onSelected,
    required this.entries,
    super.key,
  });

  final IconData icon;
  final bool compact;
  final String label;
  final T initialValue;
  final ValueChanged<T> onSelected;
  final List<PopupMenuEntry<T>> entries;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool expandedHitTarget = _usesExpandedHitTarget(
      context,
      compact: compact,
    );
    final double targetExtent = expandedHitTarget ? 48 : 40;
    return PopupMenuButton<T>(
      initialValue: initialValue,
      onSelected: onSelected,
      itemBuilder: (final BuildContext context) => entries,
      tooltip: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: targetExtent,
          minHeight: targetExtent,
        ),
        child: Center(
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 18),
                if (!compact) ...<Widget>[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _NotificationsMoreAction { filters, markAllRead, refresh }

class _NotificationsNavigationButton extends StatelessWidget {
  const _NotificationsNavigationButton({
    required this.compact,
    required this.onPressed,
  });

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final double targetExtent =
        _usesExpandedHitTarget(context, compact: compact) ? 48 : 40;
    return SizedBox.square(
      dimension: targetExtent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: IgnorePointer(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey<String>(
              'notifications-compact-navigation-button',
            ),
            onPressed: onPressed,
            tooltip: context.l10n.homeNotifications,
            visualDensity: VisualDensity.standard,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.menu_open, size: 20),
          ),
        ],
      ),
    );
  }
}

class _NotificationsMoreMenu extends StatelessWidget {
  const _NotificationsMoreMenu({
    required this.compact,
    required this.showFilterAction,
    required this.hasReasonFilters,
    required this.busy,
    required this.refreshing,
    required this.onOpenFilters,
    required this.onMarkAllRead,
    required this.onRefresh,
  });

  final bool compact;
  final bool showFilterAction;
  final bool hasReasonFilters;
  final bool busy;
  final bool refreshing;
  final VoidCallback onOpenFilters;
  final VoidCallback onMarkAllRead;
  final Future<void> Function() onRefresh;

  @override
  Widget build(final BuildContext context) {
    final double targetExtent =
        _usesExpandedHitTarget(context, compact: compact) ? 48 : 40;
    return PopupMenuButton<_NotificationsMoreAction>(
      key: const ValueKey<String>('notifications-more-menu'),
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      enabled: !busy && !refreshing,
      onSelected: (final _NotificationsMoreAction action) {
        switch (action) {
          case _NotificationsMoreAction.filters:
            onOpenFilters();
          case _NotificationsMoreAction.markAllRead:
            onMarkAllRead();
          case _NotificationsMoreAction.refresh:
            unawaited(onRefresh());
        }
      },
      itemBuilder: (final BuildContext context) =>
          <PopupMenuEntry<_NotificationsMoreAction>>[
            if (showFilterAction)
              PopupMenuItem<_NotificationsMoreAction>(
                value: _NotificationsMoreAction.filters,
                child: Row(
                  children: <Widget>[
                    Badge(
                      isLabelVisible: hasReasonFilters,
                      child: const Icon(Icons.filter_list, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(context.l10n.notificationsFilters),
                  ],
                ),
              ),
            PopupMenuItem<_NotificationsMoreAction>(
              value: _NotificationsMoreAction.markAllRead,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.done_all_outlined, size: 18),
                  const SizedBox(width: 12),
                  Text(context.l10n.notificationsMarkAllRead),
                ],
              ),
            ),
            PopupMenuItem<_NotificationsMoreAction>(
              value: _NotificationsMoreAction.refresh,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.refresh, size: 18),
                  const SizedBox(width: 12),
                  Text(context.l10n.notificationsRefresh),
                ],
              ),
            ),
          ],
      child: SizedBox.square(
        dimension: targetExtent,
        child: Center(
          child: Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: refreshing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.more_horiz, size: 20),
          ),
        ),
      ),
    );
  }
}

bool _usesExpandedHitTarget(
  final BuildContext context, {
  required final bool compact,
}) =>
    compact ||
    switch (Theme.of(context).platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => true,
      _ => false,
    };

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.selectedCount,
    required this.allSelected,
    required this.busy,
    required this.compact,
    required this.onToggleAll,
    required this.onMarkDone,
    required this.onClear,
    super.key,
  });

  final int selectedCount;
  final bool allSelected;
  final bool busy;
  final bool compact;
  final ValueChanged<bool> onToggleAll;
  final VoidCallback onMarkDone;
  final VoidCallback onClear;

  @override
  Widget build(final BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NotificationsMd3Layout.space8,
        vertical: NotificationsMd3Layout.space4,
      ),
      child: Row(
        children: <Widget>[
          Checkbox(
            value: allSelected,
            onChanged: busy
                ? null
                : (final bool? value) => onToggleAll(value ?? false),
            semanticLabel: context.l10n.notificationsSelectAll,
          ),
          Expanded(
            child: Text(
              context.l10n.notificationsSelectedCount(selectedCount),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (compact)
            IconButton(
              onPressed: busy ? null : onMarkDone,
              tooltip: context.l10n.notificationsMarkDone,
              icon: const Icon(Icons.done),
            )
          else
            TextButton.icon(
              onPressed: busy ? null : onMarkDone,
              icon: const Icon(Icons.done),
              label: Text(context.l10n.notificationsMarkDone),
            ),
          IconButton(
            onPressed: busy ? null : onClear,
            tooltip: context.l10n.notificationsClearSelection,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    ),
  );
}

class _NotificationsSidebar extends StatelessWidget {
  const _NotificationsSidebar({
    required this.filters,
    required this.projection,
    required this.savedFilters,
    required this.repositories,
    required this.onSelectInbox,
    required this.onToggleReason,
    required this.onClearReasons,
    required this.onSetQuery,
    required this.onSetRepository,
    required this.onAddFilter,
    required this.onUnavailableSection,
    super.key,
  });

  final NotificationsFiltersState filters;
  final NotificationsProjectionState projection;
  final AsyncValue<List<NotificationSavedFilter>> savedFilters;
  final List<String> repositories;
  final VoidCallback onSelectInbox;
  final ValueChanged<String> onToggleReason;
  final VoidCallback onClearReasons;
  final ValueChanged<String> onSetQuery;
  final ValueChanged<String?> onSetRepository;
  final VoidCallback onAddFilter;
  final ValueChanged<String> onUnavailableSection;

  @override
  Widget build(final BuildContext context) => ListView(
    key: const ValueKey<String>('notifications-sidebar'),
    padding: const EdgeInsets.all(NotificationsMd3Layout.space16),
    children: <Widget>[
      _SidebarItem(
        selected: true,
        icon: Icons.inbox_outlined,
        label: context.l10n.notificationsInbox,
        onTap: onSelectInbox,
      ),
      _SidebarItem(
        key: const ValueKey<String>('notifications-saved-unavailable'),
        icon: Icons.bookmark_border,
        label: context.l10n.notificationsSaved,
        unavailableMessage: context.l10n.notificationsSectionUnavailable(
          context.l10n.notificationsSaved,
        ),
        onTap: () => onUnavailableSection(context.l10n.notificationsSaved),
      ),
      _SidebarItem(
        key: const ValueKey<String>('notifications-done-unavailable'),
        icon: Icons.done,
        label: context.l10n.notificationsDone,
        unavailableMessage: context.l10n.notificationsSectionUnavailable(
          context.l10n.notificationsDone,
        ),
        onTap: () => onUnavailableSection(context.l10n.notificationsDone),
      ),
      const Divider(height: NotificationsMd3Layout.space32),
      _SidebarHeading(
        label: context.l10n.notificationsFilters,
        trailing:
            filters.showOnlyReasons.isNotEmpty || projection.query.isNotEmpty
            ? SizedBox.square(
                key: const ValueKey<String>(
                  'notifications-sidebar-clear-filters',
                ),
                dimension: kMinInteractiveDimension,
                child: IconButton(
                  onPressed: () {
                    onClearReasons();
                    onSetQuery('');
                  },
                  tooltip: context.l10n.notificationsClearFilters,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                ),
              )
            : null,
      ),
      _ReasonFilterList(
        selected: filters.showOnlyReasons.toSet(),
        onToggle: onToggleReason,
      ),
      ...savedFilters.maybeWhen(
        data: (final List<NotificationSavedFilter> values) => values
            .map(
              (final NotificationSavedFilter filter) => _SidebarItem(
                icon: Icons.filter_alt_outlined,
                label: filter.label,
                selected: projection.query == filter.query,
                onTap: () => onSetQuery(filter.query),
              ),
            )
            .toList(growable: false),
        orElse: () => const <Widget>[],
      ),
      _SidebarItem(
        icon: Icons.add,
        label: context.l10n.notificationsAddFilter,
        onTap: onAddFilter,
      ),
      const Divider(height: NotificationsMd3Layout.space32),
      _SidebarHeading(label: context.l10n.notificationsRepositories),
      if (projection.repository != null)
        _SidebarItem(
          icon: Icons.close,
          label: context.l10n.notificationsAllRepositories,
          onTap: () => onSetRepository(null),
        ),
      for (final String repository in repositories)
        _SidebarItem(
          icon: Icons.book_outlined,
          label: repository,
          selected: projection.repository == repository,
          onTap: () => onSetRepository(repository),
        ),
    ],
  );
}

class _SidebarHeading extends StatelessWidget {
  const _SidebarHeading({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) => SizedBox(
    height: kMinInteractiveDimension,
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.unavailableMessage,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final String? unavailableMessage;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool unavailable = unavailableMessage != null;
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: label,
      hint: unavailableMessage,
      button: true,
      selected: selected,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? colors.surfaceContainerHighest : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                key: ValueKey<String>('notifications-sidebar-indicator-$label'),
                duration: reducedMotion
                    ? Duration.zero
                    : kContentTransitionDuration,
                width: 3,
                height: 28,
                color: selected ? colors.primary : Colors.transparent,
              ),
              Expanded(
                child: ListTile(
                  dense: true,
                  minTileHeight: 48,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                  iconColor: unavailable ? colors.onSurfaceVariant : null,
                  textColor: unavailable ? colors.onSurfaceVariant : null,
                  leading: Icon(icon, size: 18),
                  title: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : null,
                    ),
                  ),
                  trailing: unavailable
                      ? Tooltip(
                          message: unavailableMessage,
                          child: const Icon(Icons.lock_outline, size: 16),
                        )
                      : null,
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonFilterList extends StatelessWidget {
  const _ReasonFilterList({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(final BuildContext context) => Column(
    children: <Widget>[
      for (final NotificationFilterReasonItem item
          in notificationFilterReasonItems)
        _SidebarItem(
          icon: item.icon,
          label: _reasonLabel(context, item.id),
          selected: selected.contains(item.id),
          onTap: () => onToggle(item.id),
        ),
    ],
  );
}

class _NotificationsCleanupPrompt extends StatelessWidget {
  const _NotificationsCleanupPrompt({
    required this.onDismiss,
    required this.onGetStarted,
  });

  final VoidCallback onDismiss;
  final VoidCallback onGetStarted;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Widget message = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.notifications_active_outlined,
          size: 42,
          color: colors.primary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.notificationsCleanupTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(context.l10n.notificationsCleanupBody),
            ],
          ),
        ),
      ],
    );
    final Widget actions = Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        OutlinedButton(
          onPressed: onDismiss,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(context.l10n.notificationsDismiss),
        ),
        FilledButton(
          onPressed: onGetStarted,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(context.l10n.notificationsGetStarted),
        ),
      ],
    );
    return Container(
      key: const ValueKey<String>('notifications-cleanup-prompt'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: LayoutBuilder(
        builder:
            (final BuildContext context, final BoxConstraints constraints) {
              final bool stacked =
                  constraints.maxWidth < 640 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    message,
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: message),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
      ),
    );
  }
}

class _NotificationsListHeader extends StatelessWidget {
  const _NotificationsListHeader({
    required this.hasItems,
    required this.selectedCount,
    required this.allSelected,
    required this.onToggleAll,
  });

  final bool hasItems;
  final int selectedCount;
  final bool allSelected;
  final ValueChanged<bool> onToggleAll;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool? value = selectedCount == 0
        ? false
        : allSelected
        ? true
        : null;
    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(NotificationsMd3Layout.sectionRadius),
        ),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: <Widget>[
            Checkbox(
              key: const ValueKey<String>('notifications-select-all-checkbox'),
              value: value,
              tristate: true,
              semanticLabel: context.l10n.notificationsSelectAll,
              onChanged: !hasItems
                  ? null
                  : (final bool? selected) =>
                        onToggleAll(selected ?? !allSelected),
            ),
            Expanded(
              child: Text(
                context.l10n.notificationsSelectAll,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: NotificationsMd3Layout.space12),
          ],
        ),
      ),
    );
  }
}
