part of '../notifications_md3_screen.dart';

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
        unavailableMessage: context.l10n.notificationsSavedHistoryUnavailable,
        onTap: () => onUnavailableSection(
          context.l10n.notificationsSavedHistoryUnavailable,
        ),
      ),
      _SidebarItem(
        key: const ValueKey<String>('notifications-done-history-unavailable'),
        icon: Icons.done,
        label: context.l10n.notificationsDone,
        unavailableMessage: context.l10n.notificationsDoneHistoryUnavailable,
        onTap: () => onUnavailableSection(
          context.l10n.notificationsDoneHistoryUnavailable,
        ),
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
                          child: const Icon(Icons.info_outline, size: 16),
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
