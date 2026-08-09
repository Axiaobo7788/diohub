import 'dart:async';

import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/notifications/notification_count_provider.dart';
import 'package:diohub/providers/notifications/notification_page_resource.dart';
import 'package:diohub/providers/notifications/notifications_filters_provider.dart';
import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/settings/notifications_provider.dart';
import 'package:diohub/services/activity/notifications_service.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

typedef NotificationsInboxControllerKey = ({ResourceScope scope, bool showAll});

/// Provider-owned, route-scoped query session pool.
///
/// It intentionally has exactly two controller slots: All and Unread. Switching
/// filters returns the previous controller rather than constructing a third
/// business or cache layer. Reason filters are local projections over the
/// already loaded pages and therefore never trigger a request.
final class NotificationsInboxSessionPool {
  NotificationsInboxSessionPool({
    required this.runtime,
    required this.specFactory,
    required this.scope,
  });

  final ResourceRuntime runtime;
  final NotificationPageResourceSpecFactory specFactory;
  final ResourceScope scope;

  final Map<bool, PaginationController<Thread, Thread>> _controllers =
      <bool, PaginationController<Thread, Thread>>{};
  final Set<String> _knownRepositories = <String>{};
  Set<String> _reasons = <String>{};
  NotificationsProjectionState _projection =
      const NotificationsProjectionState();
  bool _groupByRepository = false;
  bool _disposed = false;

  Iterable<PaginationController<Thread, Thread>> get controllers =>
      _controllers.values;

  List<String> get repositoryNames =>
      _knownRepositories.toList(growable: false)..sort();

  PaginationController<Thread, Thread> controllerFor({
    required final bool showAll,
  }) {
    if (_disposed) {
      throw StateError('NotificationsInboxSessionPool is disposed');
    }
    return _controllers.putIfAbsent(showAll, () {
      final RuntimeForwardPageSource<Thread, NotificationPageKey> source =
          RuntimeForwardPageSource<Thread, NotificationPageKey>(
            runtime: runtime,
            firstPageKey: const NotificationPageKey(1),
            specFactory:
                ({
                  required final NotificationPageKey pageKey,
                  required final int pageSize,
                }) => specFactory(
                  scope: scope,
                  showAll: showAll,
                  pageKey: pageKey,
                  pageSize: pageSize,
                ),
            refreshSelector: notificationQuerySelector(
              scope: scope,
              showAll: showAll,
            ),
          );
      final PaginationController<Thread, Thread> controller =
          PaginationController<Thread, Thread>(
            source: source,
            idOf: (final Thread thread) => thread.id,
            filter: (final List<Thread> items) => projectNotifications(
              items: items,
              showAll: showAll,
              reasons: _reasons,
              projection: _projection,
              groupByRepository: _groupByRepository,
            ),
          );
      controller.state.addListener(() {
        _knownRepositories.addAll(
          controller.state.value.items.map(
            (final Thread thread) => thread.repository.fullName,
          ),
        );
      });
      return controller;
    });
  }

  void updateReasons(final Iterable<String> reasons) {
    final Set<String> next = reasons.toSet();
    if (_setEquals(_reasons, next)) {
      return;
    }
    _reasons = next;
    for (final PaginationController<Thread, Thread> controller
        in _controllers.values) {
      controller.refilter();
    }
  }

  void updateProjection(final NotificationsProjectionState projection) {
    if (_projection.query == projection.query &&
        _projection.repository == projection.repository &&
        _projection.sortOrder == projection.sortOrder) {
      return;
    }
    _projection = projection;
    _refilter();
  }

  void updateGroupByRepository(final bool groupByRepository) {
    if (_groupByRepository == groupByRepository) {
      return;
    }
    _groupByRepository = groupByRepository;
    _refilter();
  }

  void _refilter() {
    for (final PaginationController<Thread, Thread> controller
        in _controllers.values) {
      controller.refilter();
    }
  }

  void applyPatch(final ItemPatch patch) {
    for (final PaginationController<Thread, Thread> controller
        in _controllers.values) {
      controller.applyPatch(patch);
    }
  }

  void removePatch(final String threadId) {
    for (final PaginationController<Thread, Thread> controller
        in _controllers.values) {
      controller.removePatch(threadId);
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final PaginationController<Thread, Thread> controller
        in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }
}

final Provider<NotificationPageResourceSpecFactory>
notificationPageResourceSpecFactoryProvider =
    Provider<NotificationPageResourceSpecFactory>((final Ref ref) {
      final NotificationsService service = ref.watch(
        notificationsServiceProvider,
      );
      return ({
        required final ResourceScope scope,
        required final bool showAll,
        required final NotificationPageKey pageKey,
        required final int pageSize,
      }) => notificationPageResourceSpec(
        service: service,
        scope: scope,
        showAll: showAll,
        pageKey: pageKey,
        pageSize: pageSize,
      );
    });

final ProviderFamily<NotificationsInboxSessionPool, ResourceScope>
notificationsInboxSessionPoolProvider = Provider.autoDispose
    .family<NotificationsInboxSessionPool, ResourceScope>((
      final Ref ref,
      final ResourceScope scope,
    ) {
      final NotificationsInboxSessionPool pool =
          NotificationsInboxSessionPool(
              runtime: ref.watch(resourceRuntimeProvider),
              specFactory: ref.watch(
                notificationPageResourceSpecFactoryProvider,
              ),
              scope: scope,
            )
            ..updateReasons(
              ref.read(notificationsFiltersProvider).showOnlyReasons,
            )
            ..updateProjection(ref.read(notificationsProjectionProvider))
            ..updateGroupByRepository(
              ref.read(notificationsProvider).groupByRepo,
            );
      ref
        ..listen<List<String>>(
          notificationsFiltersProvider.select(
            (final NotificationsFiltersState state) => state.showOnlyReasons,
          ),
          (final List<String>? _, final List<String> next) =>
              pool.updateReasons(next),
        )
        ..listen<NotificationsProjectionState>(
          notificationsProjectionProvider,
          (
            final NotificationsProjectionState? _,
            final NotificationsProjectionState next,
          ) => pool.updateProjection(next),
        )
        ..listen<bool>(
          notificationsProvider.select(
            (final settings) => settings.groupByRepo,
          ),
          (final bool? _, final bool next) =>
              pool.updateGroupByRepository(next),
        )
        ..onDispose(pool.dispose);
      return pool;
    });

final ProviderFamily<
  PaginationController<Thread, Thread>,
  NotificationsInboxControllerKey
>
notificationsInboxControllerProvider = Provider.autoDispose
    .family<
      PaginationController<Thread, Thread>,
      NotificationsInboxControllerKey
    >(
      (final Ref ref, final NotificationsInboxControllerKey key) => ref
          .watch(notificationsInboxSessionPoolProvider(key.scope))
          .controllerFor(showAll: key.showAll),
    );

final class NotificationsBulkActionResult {
  const NotificationsBulkActionResult({
    required this.succeeded,
    required this.failed,
  });

  final int succeeded;
  final int failed;
}

/// Mutation boundary for the new inbox.
///
/// Optimistic patches are applied to both bounded query sessions. The existing
/// REST service remains authoritative; failures roll back their exact patch and
/// successful mutations invalidate only the authenticated inbox resource tag.
abstract interface class NotificationsInboxActionHandler {
  Future<void> markRead(final Thread thread);
  Future<void> markDone(final Thread thread);
  Future<void> markAllRead();
  Future<NotificationsBulkActionResult> markSelectedDone(
    final Iterable<Thread> threads,
  );
}

final class NotificationsInboxActions
    implements NotificationsInboxActionHandler {
  const NotificationsInboxActions({
    required this.service,
    required this.runtime,
    required this.scope,
    required this.pool,
    required this.invalidateUnreadCount,
  });

  final NotificationsService service;
  final ResourceRuntime runtime;
  final ResourceScope scope;
  final NotificationsInboxSessionPool pool;
  final void Function() invalidateUnreadCount;

  @override
  Future<void> markRead(final Thread thread) async {
    if (!thread.unread) {
      return;
    }
    pool.applyPatch(
      PatchTransformed<Thread>(
        thread.id,
        (final Thread current) => current.copyWith(unread: false),
      ),
    );
    try {
      await service.markThreadAsRead(thread.id);
      _invalidate();
    } on Object {
      pool.removePatch(thread.id);
      rethrow;
    }
  }

  @override
  Future<void> markDone(final Thread thread) async {
    pool.applyPatch(PatchDeleted(thread.id));
    try {
      await service.markThreadAsDone(thread.id);
      _invalidate();
    } on Object {
      pool.removePatch(thread.id);
      rethrow;
    }
  }

  @override
  Future<void> markAllRead() async {
    final Set<String> patched = <String>{};
    for (final PaginationController<Thread, Thread> controller
        in pool.controllers) {
      for (final Thread thread in controller.state.value.items) {
        if (thread.unread && patched.add(thread.id)) {
          pool.applyPatch(
            PatchTransformed<Thread>(
              thread.id,
              (final Thread current) => current.copyWith(unread: false),
            ),
          );
        }
      }
    }
    try {
      await service.markAllAsRead();
      _invalidate();
    } on Object {
      patched.forEach(pool.removePatch);
      rethrow;
    }
  }

  @override
  Future<NotificationsBulkActionResult> markSelectedDone(
    final Iterable<Thread> threads,
  ) async {
    final List<Thread> pending = threads.toList(growable: false);
    for (final Thread thread in pending) {
      pool.applyPatch(PatchDeleted(thread.id));
    }

    int succeeded = 0;
    int failed = 0;
    for (int start = 0; start < pending.length; start += 4) {
      final int end = (start + 4).clamp(0, pending.length);
      final List<Thread> batch = pending.sublist(start, end);
      final List<bool> results = await Future.wait<bool>(
        batch.map((final Thread thread) async {
          try {
            await service.markThreadAsDone(thread.id);
            return true;
          } on Object {
            pool.removePatch(thread.id);
            return false;
          }
        }),
      );
      for (final bool result in results) {
        result ? succeeded++ : failed++;
      }
    }
    if (succeeded > 0) {
      _invalidate();
    }
    return NotificationsBulkActionResult(succeeded: succeeded, failed: failed);
  }

  void _invalidate() {
    runtime.invalidate(notificationsInboxSelector(scope));
    invalidateUnreadCount();
  }
}

final ProviderFamily<NotificationsInboxActionHandler, ResourceScope>
notificationsInboxActionsProvider = Provider.autoDispose
    .family<NotificationsInboxActionHandler, ResourceScope>(
      (final Ref ref, final ResourceScope scope) => NotificationsInboxActions(
        service: ref.watch(notificationsServiceProvider),
        runtime: ref.watch(resourceRuntimeProvider),
        scope: scope,
        pool: ref.watch(notificationsInboxSessionPoolProvider(scope)),
        invalidateUnreadCount: () =>
            ref.invalidate(unreadNotificationCountProvider),
      ),
    );

bool _setEquals(final Set<String> left, final Set<String> right) =>
    left.length == right.length && left.containsAll(right);
