import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/nav_center/models/selection_state.dart';
import 'package:diohub/common/pagination/pagination.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub/providers/notifications/notification_count_provider.dart';
import 'package:diohub/providers/notifications/notifications_filters_provider.dart';
import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:diohub/providers/settings/notifications_provider.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/open_in_app_browser.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/basic_notification_card.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/check_suite_notification_card.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/commit_notification_card.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/discussion_notification_card.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/issue_notification_card.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/pull_request_notification_card.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/release_notification_card.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub_models/models/notifications/notification_card_data.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Parsed owner, repo name, and run ID from a GitHub Actions run URL
/// (HTML: /owner/repo/actions/runs/ID or API: /repos/owner/repo/actions/runs/ID).
class _ParsedActionsRun {
  const _ParsedActionsRun({
    required this.owner,
    required this.repoName,
    required this.runId,
  });
  final String owner;
  final String repoName;
  final int runId;
}

_ParsedActionsRun? _parseActionsRunIdFromUrl(String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || uri.pathSegments.isEmpty) return null;
  final List<String> seg = uri.pathSegments;
  // HTML: [owner, repo, actions, runs, runId]
  if (seg.length >= 5 &&
      seg[2] == 'actions' &&
      seg[3] == 'runs' &&
      seg[4].isNotEmpty) {
    final runId = int.tryParse(seg[4]);
    if (runId != null) {
      return _ParsedActionsRun(owner: seg[0], repoName: seg[1], runId: runId);
    }
  }
  // API: [repos, owner, repo, actions, runs, runId]
  if (seg.length >= 6 &&
      seg[0] == 'repos' &&
      seg[3] == 'actions' &&
      seg[4] == 'runs' &&
      seg[5].isNotEmpty) {
    final runId = int.tryParse(seg[5]);
    if (runId != null) {
      return _ParsedActionsRun(owner: seg[1], repoName: seg[2], runId: runId);
    }
  }
  return null;
}

/// Creates the pagination controller for the notifications list.
/// The caller owns the controller and must dispose it.
PaginationController<Thread, Thread> createNotificationsController(
  WidgetRef ref,
) {
  return PaginationController<Thread, Thread>(
    source: PageNumberForwardSource<Thread>(
      fetch: ({required int page, required int perPage}) async {
        final filtersState = ref.read(notificationsFiltersProvider);
        return ref.read(notificationsServiceProvider).getNotifications(
          page: page,
          perPage: perPage,
          filters: <String, dynamic>{'all': filtersState.showAll},
        );
      },
    ),
    idOf: (Thread t) => t.id,
    filter: (List<Thread> items) {
      final showOnlyReasons =
          ref.read(notificationsFiltersProvider).showOnlyReasons;
      if (showOnlyReasons.isEmpty) return items;
      return items
          .where((Thread n) => showOnlyReasons.contains(n.reason))
          .toList();
    },
    pageSize: 20,
  );
}

/// Inbox list content. [controller] is owned by the parent (body or screen).
/// Registers the controller in [notificationsListControllerProvider] so actions (e.g. "Mark all as read") can refresh. When [onRefreshReady] is set, calls it with a callback that refreshes the list so the shell can wire pull-to-refresh.
class NotificationsInboxContent extends ConsumerStatefulWidget {
  const NotificationsInboxContent({
    super.key,
    required this.controller,
    this.onRefreshReady,
  });

  final PaginationController<Thread, Thread> controller;

  /// When set, called with a callback that performs refresh once the controller is ready. Used by the body/shell for pull-to-refresh.
  final void Function(Future<void> Function())? onRefreshReady;

  @override
  ConsumerState<NotificationsInboxContent> createState() =>
      _NotificationsInboxContentState();
}

class _NotificationsInboxContentState
    extends ConsumerState<NotificationsInboxContent>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    ref
        .read(notificationsListControllerProvider.notifier)
        .register(widget.controller);
    widget.onRefreshReady?.call(() => widget.controller.refresh());
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ColorScheme colorScheme = context.colorScheme;

    ref.listen<NotificationsFiltersState>(
      notificationsFiltersProvider,
      (NotificationsFiltersState? prev, NotificationsFiltersState next) {
        if (prev != null && prev != next && mounted) {
          widget.controller.refilter();
        }
      },
    );

    final controller = widget.controller;
    final groupByRepo = ref.watch(notificationsProvider).groupByRepo;

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        left: context.spacing.listInset.left,
        right: context.spacing.listInset.right,
        bottom: 16,
      ),
      child: AppCustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Builder(
              builder: (BuildContext context) {
                final items = controller.state.value.items;
                if (items.isEmpty) return const SizedBox.shrink();
                final unread = items.where((Thread t) => t.unread).toList();
                final list = unread.isNotEmpty ? unread : items;
                final content = list
                    .take(50)
                    .map((Thread t) => '${t.subject.title}: ${t.reason}')
                    .join('\n');
                if (content.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(
                    left: context.spacing.listInset.left,
                    right: context.spacing.listInset.right,
                    bottom: context.spacing.itemSpacing,
                  ),
                  child: ref
                          .read(premiumAiProvider)
                          .buildAiSummaryChip(
                            context,
                            ref,
                            content: content,
                            label: 'Summarise unread',
                          ) ??
                      const SizedBox.shrink(),
                );
              },
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: groupByRepo
                ? _GroupedNotificationsSliver(
                    controller: controller,
                    colorScheme: colorScheme,
                    buildItem: _buildNotificationItem,
                    loadingBuilder: ListLoadingShimmers.issuePullList,
                  )
                : PaginatedSliverList<Thread>(
                    controller: controller,
                    loadingBuilder: ListLoadingShimmers.issuePullList,
                    itemBuilder: (
                      BuildContext context,
                      Thread notification,
                      int index,
                    ) =>
                        _buildNotificationItem(
                      context,
                      notification,
                      index,
                      index < controller.state.value.items.length - 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(Thread notification) {
    final String? subjectUrl = notification.subject.url;
    final NotificationSubjectType? type = notification.subject.type;

    if (type == NotificationSubjectType.issue) {
      if (subjectUrl != null && subjectUrl.isNotEmpty) {
        try {
          IssueRef.fromApiUrl(subjectUrl).navigate(context, ref);
          return;
        } catch (e, st) {
          AppLogger.warning(
            'Failed to open notification thread',
            error: e,
            stackTrace: st,
            tag: 'Notifications',
          );
        }
      }
      _openThreadUrl(notification);
      return;
    }
    if (type == NotificationSubjectType.pullRequest) {
      if (subjectUrl != null && subjectUrl.isNotEmpty) {
        try {
          PullRequestRef.fromApiUrl(subjectUrl).navigate(context, ref);
          return;
        } catch (e, st) {
          AppLogger.warning(
            'Failed to open notification thread',
            error: e,
            stackTrace: st,
            tag: 'Notifications',
          );
        }
      }
      _openThreadUrl(notification);
      return;
    }
    if (type == NotificationSubjectType.commit) {
      if (subjectUrl != null && subjectUrl.isNotEmpty) {
        try {
          CommitRef.fromApiUrl(subjectUrl).navigate(context, ref);
          return;
        } catch (e, st) {
          AppLogger.warning(
            'Failed to open notification thread',
            error: e,
            stackTrace: st,
            tag: 'Notifications',
          );
        }
      }
      _openThreadUrl(notification);
      return;
    }
    // E.1: Release → repo with Releases tab
    if (type == NotificationSubjectType.release) {
      final parts = notification.repository.fullName.split('/');
      if (parts.length >= 2) {
        RepoRef(
          owner: parts[0],
          name: parts[1],
          location: const RepoLocationReleases(),
        ).navigate(context, ref);
        return;
      }
      _openThreadUrl(notification);
      return;
    }
    // E.2: CheckSuite → parse run_id from URL, push WorkflowRunDetailRoute
    if (type == NotificationSubjectType.checkSuite) {
      final _ParsedActionsRun? parsed =
          _parseActionsRunIdFromUrl(notification.url ?? subjectUrl ?? '');
      if (parsed != null) {
        final workflowRunRef = WorkflowRunRef(
          repo: RepoRef(owner: parsed.owner, name: parsed.repoName),
          runId: parsed.runId,
        );
        final route = ref.read(premiumRoutingProvider).resolveEntityRoute(workflowRunRef);
        if (route != null) {
          context.router.push(route);
        } else {
          // Fallback to repo route if premium not available
          context.router.push(RepositoryRoute(repo: workflowRunRef.repo));
        }
        return;
      }
      _openThreadUrl(notification);
      return;
    }
    // E.3: Discussion → in-app browser
    if (type == NotificationSubjectType.discussion) {
      final String? threadUrl = notification.url;
      if (threadUrl != null && threadUrl.isNotEmpty) {
        openInAppBrowser(Uri.parse(threadUrl));
        return;
      }
      _openThreadUrl(notification);
      return;
    }
    _openThreadUrl(notification);
  }

  void _openThreadUrl(Thread notification) {
    final String? threadUrl = notification.url;
    if (threadUrl != null && threadUrl.isNotEmpty) {
      launchUrl(Uri.parse(threadUrl));
    }
  }

  Widget _buildNotificationItem(
    BuildContext context,
    Thread notification,
    int index,
    bool showDividerBelow,
  ) {
    final NotificationCardData cardData =
        NotificationCardData.fromThread(notification);
    void Function() onTap() => () async => _onNotificationTap(notification);
    final VoidCallback onMarkDone =
        () => widget.controller.applyPatch(PatchDeleted(notification.id));

    final Widget card = switch (cardData.subjectType) {
      NotificationSubjectType.issue => IssueNotificationCard(
          thread: notification,
          onTap: onTap,
        ),
      NotificationSubjectType.pullRequest => PullRequestNotificationCard(
          thread: notification,
          onTap: onTap,
        ),
      NotificationSubjectType.release => ReleaseNotificationCard(
          thread: notification,
          onTap: onTap,
        ),
      NotificationSubjectType.discussion => DiscussionNotificationCard(
          thread: notification,
          onTap: onTap,
        ),
      NotificationSubjectType.commit => CommitNotificationCard(
          thread: notification,
          onTap: onTap,
        ),
      NotificationSubjectType.checkSuite => CheckSuiteNotificationCard(
          thread: notification,
          onTap: onTap,
        ),
      null => BorderedContainer(
          child: BasicNotificationCard(
            data: cardData,
            onTap: onTap,
            onMarkDone: onMarkDone,
          ),
        ),
    };
    final bool autoMarkRead = ref.watch(notificationsProvider).autoMarkRead;
    final Widget wrappedCard = autoMarkRead && notification.unread
        ? _AutoMarkReadOnVisible(
            threadId: notification.id,
            onMarkAsRead: ref.read(markThreadAsReadProvider),
            child: card,
          )
        : card;

    const String _notificationsPositionKey = 'notifications';
    final selection =
        ref.watch(selectionModeProvider(_notificationsPositionKey));
    final selected = selection.selectedIds.contains(notification.id);
    void toggleSelection() => ref
        .read(selectionModeProvider(_notificationsPositionKey).notifier)
        .toggle(notification.id, notification);

    Widget content = Padding(
      padding: EdgeInsets.only(bottom: context.spacing.itemSpacing),
      child: wrappedCard,
    );
    if (selection.isActive) {
      content = InkWell(
        onTap: toggleSelection,
        onLongPress: toggleSelection,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(
                top: 12,
                right: context.spacing.tightSpacing,
              ),
              child: Checkbox(
                value: selected,
                onChanged: (_) => toggleSelection(),
              ),
            ),
            Expanded(child: content),
          ],
        ),
      );
    } else {
      content = GestureDetector(
        onLongPress: toggleSelection,
        child: content,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        content,
        if (showDividerBelow)
          Divider(
            height: 0,
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}

/// When mounted, waits 1.5s then invokes [onMarkAsRead] (for autoMarkRead setting).
/// The callback is provided by the parent from [markThreadAsReadProvider] so the write goes through app state.
class _AutoMarkReadOnVisible extends StatefulWidget {
  const _AutoMarkReadOnVisible({
    required this.threadId,
    required this.child,
    required this.onMarkAsRead,
  });

  final String threadId;
  final Widget child;
  final void Function(String threadId) onMarkAsRead;

  @override
  State<_AutoMarkReadOnVisible> createState() => _AutoMarkReadOnVisibleState();
}

class _AutoMarkReadOnVisibleState extends State<_AutoMarkReadOnVisible> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      widget.onMarkAsRead(widget.threadId);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// When groupByRepo is true, shows notifications grouped by repository with sticky section headers.
class _GroupedNotificationsSliver extends StatelessWidget {
  const _GroupedNotificationsSliver({
    required this.controller,
    required this.colorScheme,
    required this.buildItem,
    required this.loadingBuilder,
  });

  final PaginationController<Thread, Thread> controller;
  final ColorScheme colorScheme;
  final Widget Function(BuildContext, Thread, int, bool) buildItem;
  final Widget Function(BuildContext)? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PaginationState<Thread>>(
      valueListenable: controller.state,
      builder: (BuildContext context, PaginationState<Thread> state, _) {
        final List<Thread> items = state.items;
        if (items.isEmpty) {
          if (state.phase is LoadingForward) {
            return SliverToBoxAdapter(
              child: loadingBuilder?.call(context) ??
                  const Center(child: LoadingIndicator()),
            );
          }
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final List<String> order = <String>[];
        final Map<String, List<Thread>> grouped = <String, List<Thread>>{};
        for (final Thread t in items) {
          final String repo = t.repository.fullName;
          if (!grouped.containsKey(repo)) order.add(repo);
          grouped.putIfAbsent(repo, () => <Thread>[]).add(t);
        }
        return MultiSliver(
          children: <Widget>[
            for (final String repoName in order) ...[
              StickyGlassSection.withTitle(
                title: repoName,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int i) {
                      final List<Thread> threads = grouped[repoName]!;
                      final Thread thread = threads[i];
                      final bool showDivider = i < threads.length - 1;
                      return buildItem(context, thread, i, showDivider);
                    },
                    childCount: grouped[repoName]!.length,
                  ),
                ),
              ),
            ],
            if (state.hasMoreForward)
              switch (state.phase) {
                LoadingForward() || Refreshing() => SliverToBoxAdapter(
                    child: loadingBuilder?.call(context) ??
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: LoadingIndicator()),
                        ),
                  ),
                _ => SliverToBoxAdapter(
                    child: loadingBuilder?.call(context) ??
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: LoadingIndicator()),
                        ),
                  ),
              },
          ],
        );
      },
    );
  }
}

/// Wraps [NotificationsInboxContent] and owns the controller. Registers
/// refresh with [refreshRegistrar] so [SliverBuilderBody] can expose pull-to-refresh.
class NotificationsInboxWithRefreshRegistrar extends ConsumerStatefulWidget {
  const NotificationsInboxWithRefreshRegistrar({
    required this.refreshRegistrar,
    super.key,
  });

  final ValueNotifier<Future<void> Function()?> refreshRegistrar;

  @override
  ConsumerState<NotificationsInboxWithRefreshRegistrar> createState() =>
      _NotificationsInboxWithRefreshRegistrarState();
}

class _NotificationsInboxWithRefreshRegistrarState
    extends ConsumerState<NotificationsInboxWithRefreshRegistrar> {
  late final PaginationController<Thread, Thread> _controller;

  @override
  void initState() {
    super.initState();
    _controller = createNotificationsController(ref);
    widget.refreshRegistrar.value = () => _controller.refresh();
  }

  @override
  void dispose() {
    widget.refreshRegistrar.value = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      NotificationsInboxContent(controller: _controller);
}

/// Notifications tab content: list only. Toolbar actions (Mark all as read,
/// Filter Inbox) are provided by the Inbox position config when focused.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late final PaginationController<Thread, Thread> _controller;

  @override
  void initState() {
    super.initState();
    _controller = createNotificationsController(ref);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationsInboxContent(controller: _controller);
  }
}
