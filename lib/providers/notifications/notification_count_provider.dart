import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub/common/pagination/pagination.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier for unread notification count. Exposes [decrement] for
/// client-side patch when marking a single thread as done (avoids full refetch).
final class UnreadNotificationCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async =>
      ref.watch(notificationsServiceProvider).getUnreadCount();

  /// Decrements the count by one. Call after "Mark as done" on a single thread.
  void decrement() {
    state.whenData((final int value) {
      if (value > 0) {
        state = AsyncData(value - 1);
      }
    });
  }
}

/// Unread notification count for the toolbar badge.
/// Use [UnreadNotificationCountNotifier.decrement] after "Mark as done" on one thread
/// instead of invalidating, to avoid a full refetch.
final AsyncNotifierProvider<UnreadNotificationCountNotifier, int>
    unreadNotificationCountProvider =
    AsyncNotifierProvider<UnreadNotificationCountNotifier, int>(
  UnreadNotificationCountNotifier.new,
  isAutoDispose: true,
);

/// The active notifications list controller, if the Inbox is mounted.
/// Set by [NotificationsInboxContent]; use to refresh directly (e.g. after "Mark as done").
final notificationsListControllerProvider = NotifierProvider.autoDispose<
    NotificationsListControllerNotifier, PaginationController<Thread, Thread>?>(
  NotificationsListControllerNotifier.new,
);

/// Notifier that owns the notifications list [PaginationController] lifecycle.
class NotificationsListControllerNotifier
    extends Notifier<PaginationController<Thread, Thread>?> {
  @override
  PaginationController<Thread, Thread>? build() => null;

  void register(PaginationController<Thread, Thread> controller) {
    state?.dispose();
    state = controller;
    ref.onDispose(controller.dispose);
  }

  void unregister() {
    state?.dispose();
    state = null;
  }
}

/// Marks a thread as read and patches it in the list. Use from UI via this provider instead of calling the service directly.
final Provider<void Function(String threadId)> markThreadAsReadProvider =
    Provider<void Function(String threadId)>((final Ref ref) {
  return (final String threadId) async {
    await ref.read(notificationsServiceProvider).markThreadAsRead(threadId);
    final controller = ref.read(notificationsListControllerProvider);
    controller?.applyPatch(
      PatchTransformed<Thread>(
          threadId, (Thread t) => t.copyWith(unread: false)),
    );
  };
});
