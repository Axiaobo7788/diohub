import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/notifications/notification_page_resource.dart';
import 'package:diohub/providers/notifications/notifications_inbox_session_provider.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:flutter_test/flutter_test.dart';

const ResourceScope _scope = ResourceScope(
  serverId: 'github.com',
  principal: 'account-1',
);

void main() {
  test(
    'All and Unread retain two bounded sessions and reason filters do not load',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      final _NotificationPageBackend backend = _NotificationPageBackend();
      final NotificationsInboxSessionPool pool = NotificationsInboxSessionPool(
        runtime: runtime,
        specFactory: backend.specFactory,
        scope: _scope,
      );
      addTearDown(() {
        pool.dispose();
        runtime.dispose();
      });

      final PaginationController<Thread, Thread> all = pool.controllerFor(
        showAll: true,
      );
      await _waitForIdle(all);
      expect(backend.calls, <String>['all:1']);
      expect(
        all.state.value.items.map((final Thread item) => item.id),
        <String>['mention', 'author'],
      );

      final PaginationController<Thread, Thread> unread = pool.controllerFor(
        showAll: false,
      );
      await _waitForIdle(unread);
      expect(backend.calls, <String>['all:1', 'unread:1']);
      expect(unread.state.value.items.single.id, 'mention');

      expect(
        pool.controllerFor(showAll: true),
        same(all),
        reason: 'returning to All must retain the exact query controller',
      );
      expect(backend.calls.length, 2);

      pool.updateReasons(<String>['mention']);
      expect(all.state.value.items.single.id, 'mention');
      expect(unread.state.value.items.single.id, 'mention');
      expect(
        backend.calls.length,
        2,
        reason: 'reason filtering is a local projection, not a new query',
      );
    },
  );

  test('a returned route session reuses a fresh Runtime first page', () async {
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final _NotificationPageBackend backend = _NotificationPageBackend();
    final NotificationsInboxSessionPool first = NotificationsInboxSessionPool(
      runtime: runtime,
      specFactory: backend.specFactory,
      scope: _scope,
    );

    final PaginationController<Thread, Thread> firstController = first
        .controllerFor(showAll: true);
    await _waitForIdle(firstController);
    expect(backend.calls.length, 1);
    first.dispose();

    final NotificationsInboxSessionPool returned =
        NotificationsInboxSessionPool(
          runtime: runtime,
          specFactory: backend.specFactory,
          scope: _scope,
        );
    addTearDown(() {
      returned.dispose();
      runtime.dispose();
    });
    final PaginationController<Thread, Thread> returnedController = returned
        .controllerFor(showAll: true);
    await _waitForIdle(returnedController);

    expect(returnedController.state.value.items.length, 2);
    expect(
      backend.calls.length,
      1,
      reason: 'the 30-second fresh page must not repeat its REST request',
    );
  });
}

Future<void> _waitForIdle(
  final PaginationController<Thread, Thread> controller,
) async {
  for (int attempt = 0; attempt < 100; attempt++) {
    final PaginationState<Thread> state = controller.state.value;
    if (state.items.isNotEmpty && state.phase is Idle) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Pagination controller did not settle');
}

final class _NotificationPageBackend {
  final List<String> calls = <String>[];

  ResourceSpec<PaginatedResourcePage<Thread, NotificationPageKey>> specFactory({
    required final ResourceScope scope,
    required final bool showAll,
    required final NotificationPageKey pageKey,
    required final int pageSize,
  }) {
    final String query = showAll ? 'all' : 'unread';
    return ResourceSpec<PaginatedResourcePage<Thread, NotificationPageKey>>(
      id: ResourceId<PaginatedResourcePage<Thread, NotificationPageKey>>(
        kind: 'notifications-inbox-page',
        version: 1,
        scope: scope,
        key: '$query/page:${pageKey.page}/size:$pageSize',
      ),
      policy: notificationPageResourcePolicy,
      tags: <ResourceTag>{
        notificationsInboxTag,
        notificationQueryTag(showAll: showAll),
      },
      contract: 'test-notifications-inbox-page-v1',
      load: (final ResourceLoadContext _) async {
        calls.add('$query:${pageKey.page}');
        final List<Thread> items = showAll
            ? <Thread>[_mention, _author]
            : <Thread>[_mention];
        return ResourceLoadResult<
          PaginatedResourcePage<Thread, NotificationPageKey>
        >(
          data: PaginatedResourcePage<Thread, NotificationPageKey>(
            items: items,
            hasNextPage: false,
          ),
        );
      },
    );
  }
}

const MinimalRepository _repository = MinimalRepository(
  fullName: 'octocat/hello-world',
  owner: MinimalOwner(login: 'octocat'),
);

const Thread _mention = Thread(
  id: 'mention',
  subject: ThreadSubject(
    title: 'Please review the notification runtime',
    type: NotificationSubjectType.pullRequest,
  ),
  reason: 'mention',
  repository: _repository,
  unread: true,
);

const Thread _author = Thread(
  id: 'author',
  subject: ThreadSubject(
    title: 'A closed issue',
    type: NotificationSubjectType.issue,
  ),
  reason: 'author',
  repository: _repository,
);
