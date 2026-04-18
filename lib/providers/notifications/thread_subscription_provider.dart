import 'package:diohub/common/riverpod/optimistic_notifier.dart';
import 'package:diohub_models/models/notifications/thread_subscription.dart';
import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:diohub/services/activity/notifications_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Family provider for per-thread subscription state.
///
/// Keyed by thread ID. Lazy: only built when first read (e.g. when user opens
/// peek menu or uses swipe). Optimistic toggles with auto-revert on error.
final AsyncNotifierProviderFamily<ThreadSubscriptionNotifier,
        ThreadSubscription, String> threadSubscriptionProvider =
    AsyncNotifierProvider.family<ThreadSubscriptionNotifier, ThreadSubscription,
        String>(
  ThreadSubscriptionNotifier.new,
);

class ThreadSubscriptionNotifier extends AsyncNotifier<ThreadSubscription>
    with OptimisticFamilyAsyncNotifier<ThreadSubscription> {
  ThreadSubscriptionNotifier(this.threadId);
  final String threadId;

  @override
  Future<ThreadSubscription> build() async {
    return ref
        .watch(notificationsServiceProvider)
        .getThreadSubscription(threadId);
  }

  /// Mute (ignore) or unmute the thread. Optimistic; reverts on error.
  Future<void> toggleMute() async {
    final ThreadSubscription current = state.requireValue;
    if (current.ignored) {
      await optimistic(
        transform: (final ThreadSubscription s) => s.copyWith(ignored: false),
        mutation: () => ref
            .read(notificationsServiceProvider)
            .deleteThreadSubscription(threadId),
      );
    } else {
      await optimistic(
        transform: (final ThreadSubscription s) => s.copyWith(ignored: true),
        mutation: () =>
            ref.read(notificationsServiceProvider).muteThread(threadId),
      );
    }
  }

  /// Subscribe or unsubscribe. Optimistic; reverts on error.
  Future<void> toggleSubscribe() async {
    final ThreadSubscription current = state.requireValue;
    if (current.subscribed) {
      await optimistic(
        transform: (final ThreadSubscription s) =>
            s.copyWith(subscribed: false),
        mutation: () => ref
            .read(notificationsServiceProvider)
            .deleteThreadSubscription(threadId),
      );
    } else {
      await optimistic(
        transform: (final ThreadSubscription s) => s.copyWith(subscribed: true),
        mutation: () =>
            ref.read(notificationsServiceProvider).subscribeToThread(threadId),
        applyResponse: (final _, final ThreadSubscription res) => res,
      );
    }
  }
}
