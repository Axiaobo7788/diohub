import 'dart:async';

import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:test/test.dart';

void main() {
  test(
    'interactive work can use reserved capacity ahead of queued refresh',
    () async {
      final ResourceScheduler scheduler = ResourceScheduler(
        config: const ResourceSchedulerConfig(
          maxConcurrent: 2,
          reservedInteractive: 1,
        ),
      );
      addTearDown(scheduler.dispose);
      final Completer<void> firstRefreshStarted = Completer<void>();
      final Completer<void> firstRefreshDone = Completer<void>();
      final Completer<void> secondRefreshStarted = Completer<void>();
      final Completer<void> secondRefreshDone = Completer<void>();
      final Completer<void> interactiveStarted = Completer<void>();
      final Completer<void> interactiveDone = Completer<void>();

      final ScheduledResourceTask<void> firstRefresh = scheduler.schedule<void>(
        priority: ResourcePriority.refresh,
        operation: () {
          firstRefreshStarted.complete();
          return firstRefreshDone.future;
        },
      );
      final ScheduledResourceTask<void> secondRefresh = scheduler
          .schedule<void>(
            priority: ResourcePriority.refresh,
            operation: () {
              secondRefreshStarted.complete();
              return secondRefreshDone.future;
            },
          );
      await firstRefreshStarted.future;
      expect(secondRefreshStarted.isCompleted, isFalse);

      final ScheduledResourceTask<void> interactive = scheduler.schedule<void>(
        priority: ResourcePriority.interactive,
        operation: () {
          interactiveStarted.complete();
          return interactiveDone.future;
        },
      );
      await interactiveStarted.future;
      expect(secondRefreshStarted.isCompleted, isFalse);

      interactiveDone.complete();
      await interactive.result;
      expect(secondRefreshStarted.isCompleted, isFalse);

      firstRefreshDone.complete();
      await firstRefresh.result;
      await secondRefreshStarted.future;
      secondRefreshDone.complete();
      await secondRefresh.result;
    },
  );
}
