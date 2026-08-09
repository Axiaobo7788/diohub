import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/settings/notifications.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/l10n/relative_time.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/dashboard/home_top_repositories_provider.dart';
import 'package:diohub/providers/entity_store_notifier.dart';
import 'package:diohub/providers/notifications/notifications_filters_provider.dart';
import 'package:diohub/providers/notifications/notifications_inbox_session_provider.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/settings/notifications_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/app_chrome/app_chrome.dart';
import 'package:diohub/view/app_chrome/global_header.dart';
import 'package:diohub/view/notifications/notification_navigation.dart';
import 'package:diohub/view/notifications/notifications_md3_layout.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

part 'widgets/notifications_inbox_rows.dart';
part 'widgets/notifications_inbox_toolbar.dart';
part 'widgets/notifications_account_states.dart';

typedef NotificationSelectionChanged =
    void Function(Thread thread, {required bool selected});

@RoutePage()
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<AccountSession?> accountState = ref.watch(accountProvider);
    final bool accountResolved = accountState.hasValue;
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

    final Widget body;
    if (!accountResolved && accountState.hasError) {
      body = _NotificationsAccountErrorState(
        onRetry: () => ref.invalidate(accountProvider),
      );
    } else if (!accountResolved) {
      body = const _NotificationsAccountLoadingState();
    } else if (account == null) {
      body = const _NotificationsSignInState();
    } else {
      body = NotificationsMd3Page(scope: resourceScopeForAccount(account));
    }

    return AppChrome(
      title: GlobalHeaderTitle(title: context.l10n.homeNotifications),
      account: account,
      accountLoading: !accountResolved,
      topRepositories: topRepositories,
      statusEmoji: viewer?.status?.emoji,
      statusMessage: viewer?.status?.message,
      body: body,
    );
  }
}

class NotificationsMd3Page extends ConsumerStatefulWidget {
  const NotificationsMd3Page({required this.scope, super.key});

  final ResourceScope scope;

  @override
  ConsumerState<NotificationsMd3Page> createState() =>
      _NotificationsMd3PageState();
}

class _NotificationsMd3PageState extends ConsumerState<NotificationsMd3Page> {
  final Map<String, Thread> _selected = <String, Thread>{};
  final Set<String> _pending = <String>{};
  bool _bulkBusy = false;

  void _setUnread(final bool unread) {
    _clearSelection();
    ref.read(notificationsFiltersProvider.notifier).setOnlyUnread(unread);
  }

  void _toggleReason(final String reason) {
    _clearSelection();
    ref
        .read(notificationsFiltersProvider.notifier)
        .toggleShowOnlyReason(reason);
  }

  void _clearReasonFilters() {
    _clearSelection();
    ref
        .read(notificationsFiltersProvider.notifier)
        .setShowOnlyReasons(<String>[]);
  }

  void _setQuery(final String query) {
    _clearSelection();
    ref.read(notificationsProjectionProvider.notifier).setQuery(query);
  }

  void _setRepository(final String? repository) {
    _clearSelection();
    ref
        .read(notificationsProjectionProvider.notifier)
        .setRepository(repository);
  }

  void _setSortOrder(final NotificationSortOrder sortOrder) {
    _clearSelection();
    ref.read(notificationsProjectionProvider.notifier).setSortOrder(sortOrder);
  }

  void _setGroupByRepository(final bool groupByRepository) {
    _clearSelection();
    unawaited(
      ref
          .read(notificationsProvider.notifier)
          .update(
            (final NotificationsSettings settings) =>
                settings.copyWith(groupByRepo: groupByRepository),
          )
          .catchError((final Object _) => _showUpdateError()),
    );
  }

  void _dismissCleanupPrompt() {
    unawaited(
      ref
          .read(notificationsProvider.notifier)
          .update(
            (final NotificationsSettings settings) =>
                settings.copyWith(cleanupPromptDismissed: true),
          )
          .catchError((final Object _) => _showUpdateError()),
    );
  }

  void _selectReadNotifications(final Iterable<Thread> items) {
    setState(() {
      _selected
        ..clear()
        ..addEntries(
          items
              .where((final Thread thread) => !thread.unread)
              .map(
                (final Thread thread) =>
                    MapEntry<String, Thread>(thread.id, thread),
              ),
        );
    });
    _dismissCleanupPrompt();
  }

  void _showUnavailableSection(final String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.notificationsSectionUnavailable(section)),
      ),
    );
  }

  Future<void> _showAddFilterDialog() async {
    final TextEditingController labelController = TextEditingController();
    final TextEditingController queryController = TextEditingController(
      text: ref.read(notificationsProjectionProvider).query,
    );
    try {
      final bool? save = await showDialog<bool>(
        context: context,
        builder: (final BuildContext context) => AlertDialog(
          title: Text(context.l10n.notificationsAddFilter),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: labelController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.l10n.notificationsFilterName,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: queryController,
                decoration: InputDecoration(
                  labelText: context.l10n.notificationsFilterQuery,
                  hintText: 'repo:owner/name reason:mention',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.notificationsSaveFilter),
            ),
          ],
        ),
      );
      final String query = queryController.text.trim();
      if (save != true || query.isEmpty || !mounted) {
        return;
      }
      final String label = labelController.text.trim();
      await ref
          .read(entityStoreMutatorProvider)
          .saveSearch(
            query: '$notificationSavedSearchPrefix$query',
            label: label.isEmpty ? query : label,
            searchType: notificationSavedSearchType,
          );
      if (mounted) {
        _setQuery(query);
      }
    } on Object {
      _showUpdateError();
    } finally {
      labelController.dispose();
      queryController.dispose();
    }
  }

  void _clearSelection() {
    if (_selected.isEmpty) {
      return;
    }
    setState(_selected.clear);
  }

  void _toggleSelected(final Thread thread, final bool selected) {
    setState(() {
      if (selected) {
        _selected[thread.id] = thread;
      } else {
        _selected.remove(thread.id);
      }
    });
  }

  void _toggleAll(final List<Thread> items, final bool selected) {
    setState(() {
      if (!selected) {
        _selected.clear();
        return;
      }
      _selected
        ..clear()
        ..addEntries(
          items.map(
            (final Thread thread) =>
                MapEntry<String, Thread>(thread.id, thread),
          ),
        );
    });
  }

  Future<void> _refresh(
    final PaginationController<Thread, Thread> controller,
  ) => controller.refresh();

  Future<void> _markRead(
    final NotificationsInboxActionHandler actions,
    final Thread thread,
  ) async {
    if (_pending.contains(thread.id) || !thread.unread) {
      return;
    }
    setState(() => _pending.add(thread.id));
    try {
      await actions.markRead(thread);
    } on Object {
      _showUpdateError();
    } finally {
      if (mounted) {
        setState(() => _pending.remove(thread.id));
      }
    }
  }

  Future<void> _markDone(
    final NotificationsInboxActionHandler actions,
    final Thread thread,
  ) async {
    if (_pending.contains(thread.id)) {
      return;
    }
    setState(() => _pending.add(thread.id));
    try {
      await actions.markDone(thread);
      if (mounted) {
        setState(() => _selected.remove(thread.id));
      }
    } on Object {
      _showUpdateError();
    } finally {
      if (mounted) {
        setState(() => _pending.remove(thread.id));
      }
    }
  }

  Future<void> _markAllRead(
    final NotificationsInboxActionHandler actions,
  ) async {
    if (_bulkBusy) {
      return;
    }
    setState(() => _bulkBusy = true);
    try {
      await actions.markAllRead();
    } on Object {
      _showUpdateError();
    } finally {
      if (mounted) {
        setState(() => _bulkBusy = false);
      }
    }
  }

  Future<void> _markSelectedDone(
    final NotificationsInboxActionHandler actions,
  ) async {
    if (_bulkBusy || _selected.isEmpty) {
      return;
    }
    setState(() => _bulkBusy = true);
    final NotificationsBulkActionResult result = await actions.markSelectedDone(
      _selected.values,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _bulkBusy = false;
      _selected.clear();
    });
    final String message = <String>[
      if (result.succeeded > 0)
        context.l10n.notificationsBulkDone(result.succeeded),
      if (result.failed > 0)
        context.l10n.notificationsBulkFailed(result.failed),
    ].join(' ');
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openThread(
    final NotificationsInboxActionHandler actions,
    final Thread thread,
  ) async {
    if (thread.unread) {
      unawaited(_markRead(actions, thread));
    }
    await openNotificationThread(context, ref, thread);
  }

  void _showUpdateError() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.notificationsUpdateError)),
    );
  }

  Future<void> _showCompactNavigation() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final BuildContext context) => Consumer(
        builder:
            (
              final BuildContext context,
              final WidgetRef ref,
              final Widget? child,
            ) {
              final NotificationsFiltersState filters = ref.watch(
                notificationsFiltersProvider,
              );
              final NotificationsProjectionState projection = ref.watch(
                notificationsProjectionProvider,
              );
              final AsyncValue<List<NotificationSavedFilter>> savedFilters = ref
                  .watch(notificationSavedFiltersProvider);
              final NotificationsInboxSessionPool sessionPool = ref.watch(
                notificationsInboxSessionPoolProvider(widget.scope),
              );
              return SafeArea(
                child: FractionallySizedBox(
                  heightFactor: 0.86,
                  child: Column(
                    key: const ValueKey<String>(
                      'notifications-compact-navigation-sheet',
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                context.l10n.homeNotifications,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 0, endIndent: 0),
                      Expanded(
                        child: _NotificationsSidebar(
                          key: const ValueKey<String>(
                            'notifications-compact-navigation-list',
                          ),
                          filters: filters,
                          projection: projection,
                          savedFilters: savedFilters,
                          repositories: sessionPool.repositoryNames,
                          onSelectInbox: () => Navigator.pop(context),
                          onToggleReason: _toggleReason,
                          onClearReasons: _clearReasonFilters,
                          onSetQuery: _setQuery,
                          onSetRepository: _setRepository,
                          onAddFilter: () {
                            Navigator.pop(context);
                            unawaited(
                              Future<void>.delayed(Duration.zero, () {
                                if (mounted) {
                                  unawaited(_showAddFilterDialog());
                                }
                              }),
                            );
                          },
                          onUnavailableSection: _showUnavailableSection,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    // This independent watch pins the route-owned session pool while All and
    // Unread swap their active controller dependencies.
    final NotificationsInboxSessionPool sessionPool = ref.watch(
      notificationsInboxSessionPoolProvider(widget.scope),
    );
    final NotificationsFiltersState filters = ref.watch(
      notificationsFiltersProvider,
    );
    final NotificationsProjectionState projection = ref.watch(
      notificationsProjectionProvider,
    );
    final AsyncValue<List<NotificationSavedFilter>> savedFilters = ref.watch(
      notificationSavedFiltersProvider,
    );
    final PaginationController<Thread, Thread> controller = ref.watch(
      notificationsInboxControllerProvider((
        scope: widget.scope,
        showAll: filters.showAll,
      )),
    );
    final NotificationsInboxActionHandler actions = ref.watch(
      notificationsInboxActionsProvider(widget.scope),
    );
    final bool groupByRepository = ref.watch(
      notificationsProvider.select(
        (final NotificationsSettings settings) => settings.groupByRepo,
      ),
    );
    final bool autoMarkRead = ref.watch(
      notificationsProvider.select(
        (final NotificationsSettings settings) => settings.autoMarkRead,
      ),
    );
    final bool cleanupPromptDismissed = ref.watch(
      notificationsProvider.select(
        (final NotificationsSettings settings) =>
            settings.cleanupPromptDismissed,
      ),
    );

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final NotificationsWindowClass windowClass =
            NotificationsMd3Layout.windowClassFor(constraints.maxWidth);
        final bool showSidebar =
            windowClass == NotificationsWindowClass.expanded;
        return ValueListenableBuilder<PaginationState<Thread>>(
          valueListenable: controller.state,
          builder:
              (
                final BuildContext context,
                final PaginationState<Thread> state,
                final Widget? child,
              ) {
                final bool allSelected =
                    state.items.isNotEmpty &&
                    state.items.every(
                      (final Thread item) => _selected.containsKey(item.id),
                    );
                final Widget inbox = _NotificationsInboxScrollView(
                  controller: controller,
                  state: state,
                  filters: filters,
                  projection: projection,
                  selected: _selected,
                  pending: _pending,
                  allSelected: allSelected,
                  groupByRepository: groupByRepository,
                  autoMarkRead: autoMarkRead,
                  showCleanupPrompt:
                      filters.showAll &&
                      !cleanupPromptDismissed &&
                      state.items.any((final Thread thread) => !thread.unread),
                  bulkBusy: _bulkBusy,
                  windowClass: windowClass,
                  onSetUnread: _setUnread,
                  onSetQuery: _setQuery,
                  onSetSortOrder: _setSortOrder,
                  onSetGroupByRepository: _setGroupByRepository,
                  onOpenFilters: _showCompactNavigation,
                  onRefresh: () => _refresh(controller),
                  onMarkAllRead: () => _markAllRead(actions),
                  onDismissCleanupPrompt: _dismissCleanupPrompt,
                  onStartCleanup: () => _selectReadNotifications(state.items),
                  onMarkSelectedDone: () => _markSelectedDone(actions),
                  onClearSelection: _clearSelection,
                  onToggleAll: (final bool selected) =>
                      _toggleAll(state.items, selected),
                  onToggleSelected:
                      (final Thread thread, {required final bool selected}) =>
                          _toggleSelected(thread, selected),
                  onOpen: (final Thread thread) => _openThread(actions, thread),
                  onMarkRead: (final Thread thread) =>
                      _markRead(actions, thread),
                  onMarkDone: (final Thread thread) =>
                      _markDone(actions, thread),
                );
                if (!showSidebar) {
                  return inbox;
                }
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: NotificationsMd3Layout.contentMaxWidth,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(
                          width: NotificationsMd3Layout.sidebarWidth,
                          child: _NotificationsSidebar(
                            filters: filters,
                            projection: projection,
                            savedFilters: savedFilters,
                            repositories: sessionPool.repositoryNames,
                            onSelectInbox: () {},
                            onToggleReason: _toggleReason,
                            onClearReasons: _clearReasonFilters,
                            onSetQuery: _setQuery,
                            onSetRepository: _setRepository,
                            onAddFilter: () =>
                                unawaited(_showAddFilterDialog()),
                            onUnavailableSection: _showUnavailableSection,
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          indent: 0,
                          endIndent: 0,
                        ),
                        Expanded(child: inbox),
                      ],
                    ),
                  ),
                );
              },
        );
      },
    );
  }
}

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
                  loadingBuilder: (final BuildContext context) =>
                      const _NotificationsLoading(),
                  errorBuilder:
                      (
                        final BuildContext context,
                        final Object error,
                        final VoidCallback retry,
                      ) => _NotificationsError(onRetry: retry),
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
        ],
      ),
    );
  }
}
