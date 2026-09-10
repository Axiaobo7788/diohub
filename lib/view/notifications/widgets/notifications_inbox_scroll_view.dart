part of '../notifications_md3_screen.dart';

class _NotificationsInboxScrollView extends StatelessWidget {
  const _NotificationsInboxScrollView({
    required this.controller,
    required this.state,
    required this.filters,
    required this.projection,
    required this.selected,
    required this.pending,
    required this.allSelected,
    required this.groupByRepository,
    required this.autoMarkRead,
    required this.showCleanupPrompt,
    required this.bulkBusy,
    required this.windowClass,
    required this.onSetUnread,
    required this.onSetQuery,
    required this.onSetSortOrder,
    required this.onSetGroupByRepository,
    required this.onOpenFilters,
    required this.onRefresh,
    required this.onMarkAllRead,
    required this.onDismissCleanupPrompt,
    required this.onStartCleanup,
    required this.onMarkSelectedDone,
    required this.onClearSelection,
    required this.onToggleAll,
    required this.onToggleSelected,
    required this.onOpen,
    required this.onMarkRead,
    required this.onMarkDone,
  });

  final PaginationController<Thread, Thread> controller;
  final PaginationState<Thread> state;
  final NotificationsFiltersState filters;
  final NotificationsProjectionState projection;
  final Map<String, Thread> selected;
  final Set<String> pending;
  final bool allSelected;
  final bool groupByRepository;
  final bool autoMarkRead;
  final bool showCleanupPrompt;
  final bool bulkBusy;
  final NotificationsWindowClass windowClass;
  final ValueChanged<bool> onSetUnread;
  final ValueChanged<String> onSetQuery;
  final ValueChanged<NotificationSortOrder> onSetSortOrder;
  final ValueChanged<bool> onSetGroupByRepository;
  final VoidCallback onOpenFilters;
  final Future<void> Function() onRefresh;
  final VoidCallback onMarkAllRead;
  final VoidCallback onDismissCleanupPrompt;
  final VoidCallback onStartCleanup;
  final VoidCallback onMarkSelectedDone;
  final VoidCallback onClearSelection;
  final ValueChanged<bool> onToggleAll;
  final NotificationSelectionChanged onToggleSelected;
  final ValueChanged<Thread> onOpen;
  final ValueChanged<Thread> onMarkRead;
  final ValueChanged<Thread> onMarkDone;

  @override
  Widget build(final BuildContext context) {
    final bool compact = windowClass == NotificationsWindowClass.compact;
    final EdgeInsets pagePadding = NotificationsMd3Layout.pagePaddingFor(
      windowClass,
    );
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        key: ValueKey<String>(
          filters.showAll
              ? 'notifications-scroll-all'
              : 'notifications-scroll-unread',
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: pagePadding.copyWith(bottom: 12),
            sliver: SliverToBoxAdapter(
              child: _NotificationsToolbar(
                filters: filters,
                projection: projection,
                groupByRepository: groupByRepository,
                selectedCount: selected.length,
                allSelected: allSelected,
                bulkBusy: bulkBusy,
                compact: compact,
                showFilterAction:
                    windowClass != NotificationsWindowClass.expanded,
                refreshing: state.phase is Refreshing,
                onSetUnread: onSetUnread,
                onSetQuery: onSetQuery,
                onSetSortOrder: onSetSortOrder,
                onSetGroupByRepository: onSetGroupByRepository,
                onOpenFilters: onOpenFilters,
                onRefresh: onRefresh,
                onMarkAllRead: onMarkAllRead,
                onMarkSelectedDone: onMarkSelectedDone,
                onClearSelection: onClearSelection,
                onToggleAll: onToggleAll,
              ),
            ),
          ),
          if (showCleanupPrompt)
            SliverPadding(
              padding: pagePadding.copyWith(top: 0, bottom: 16),
              sliver: SliverToBoxAdapter(
                child: _NotificationsCleanupPrompt(
                  onDismiss: onDismissCleanupPrompt,
                  onGetStarted: onStartCleanup,
                ),
              ),
            ),
          SliverPadding(
            padding: pagePadding.copyWith(top: 0),
            sliver: SingleTreeSliverFadeTransition(
              transitionKey: _notificationsVisualStateKey(state),
              sliver: MultiSliver(
                key: const ValueKey<String>('notifications-inbox-list'),
                children: <Widget>[
                  SliverToBoxAdapter(
                    child: _NotificationsListHeader(
                      hasItems: state.items.isNotEmpty,
                      selectedCount: selected.length,
                      allSelected: allSelected,
                      onToggleAll: onToggleAll,
                    ),
                  ),
                  PaginatedSliverList<Thread>(
                    controller: controller,
                    loadingBuilder: (final BuildContext context) {
                      if (state.items.isEmpty) {
                        return const _NotificationsLoading();
                      }
                      return state.phase is LoadingForward
                          ? const _NotificationsLoadingMore()
                          : const SizedBox.shrink();
                    },
                    errorBuilder:
                        (
                          final BuildContext context,
                          final Object error,
                          final VoidCallback retry,
                        ) => state.items.isEmpty
                        ? _NotificationsError(onRetry: retry)
                        : _NotificationsRefreshError(onRetry: retry),
                    emptyBuilder: (final BuildContext context) =>
                        _NotificationsEmpty(filters: filters),
                    itemBuilder:
                        (
                          final BuildContext context,
                          final Thread thread,
                          final int index,
                        ) {
                          final String groupKey = groupByRepository
                              ? thread.repository.fullName
                              : _notificationDateGroupKey(thread.updatedAt);
                          final String? previousGroupKey = index == 0
                              ? null
                              : groupByRepository
                              ? state.items[index - 1].repository.fullName
                              : _notificationDateGroupKey(
                                  state.items[index - 1].updatedAt,
                                );
                          final bool showGroup = groupKey != previousGroupKey;
                          final Widget row = _NotificationInboxRow(
                            thread: thread,
                            selected: selected.containsKey(thread.id),
                            pending: pending.contains(thread.id),
                            compact: compact,
                            showRepository: !groupByRepository,
                            onSelected: (final bool value) =>
                                onToggleSelected(thread, selected: value),
                            onOpen: () => onOpen(thread),
                            onMarkRead: thread.unread
                                ? () => onMarkRead(thread)
                                : null,
                            onMarkDone: () => onMarkDone(thread),
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              if (showGroup)
                                _NotificationGroupHeader(
                                  groupKey: groupKey,
                                  label: groupByRepository
                                      ? groupKey
                                      : _notificationDateGroupLabel(
                                          context,
                                          thread.updatedAt,
                                        ),
                                ),
                              if (autoMarkRead && thread.unread)
                                _AutoMarkNotificationRead(
                                  threadId: thread.id,
                                  onMarkRead: () => onMarkRead(thread),
                                  child: row,
                                )
                              else
                                row,
                            ],
                          );
                        },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _notificationsVisualStateKey(final PaginationState<Thread> state) {
  if (state.items.isNotEmpty) {
    return 'content';
  }
  if (state.phase is Failed) {
    return 'error';
  }
  if (state.phase is Idle && !state.hasMoreForward) {
    return 'empty';
  }
  return 'loading';
}
