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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedSwitcher(
          key: const ValueKey<String>('notifications-toolbar-switcher'),
          duration: reducedMotion ? Duration.zero : kContentTransitionDuration,
          switchInCurve: kContentTransitionCurve,
          switchOutCurve: kContentTransitionCurve,
          layoutBuilder:
              (
                final Widget? currentChild,
                final List<Widget> previousChildren,
              ) => Stack(
                alignment: Alignment.centerLeft,
                children: <Widget>[
                  for (final Widget child in previousChildren)
                    IgnorePointer(child: ExcludeSemantics(child: child)),
                  ?currentChild,
                ],
              ),
          child: selectedCount > 0
              ? _SelectionToolbar(
                  key: const ValueKey<String>(
                    'notifications-selection-toolbar',
                  ),
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
        ),
        SizedBox(
          height: 2,
          child: refreshing
              ? Semantics(
                  label: context.l10n.notificationsSyncing,
                  child: LinearProgressIndicator(
                    key: const ValueKey<String>(
                      'notifications-refresh-progress',
                    ),
                    value: reducedMotion ? 0.5 : null,
                  ),
                )
              : const SizedBox.expand(),
        ),
      ],
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
