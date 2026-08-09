import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/services/activity/notifications_service.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:flutter/foundation.dart';

typedef NotificationPageResourceSpecFactory =
    ResourceSpec<PaginatedResourcePage<Thread, NotificationPageKey>> Function({
      required ResourceScope scope,
      required bool showAll,
      required NotificationPageKey pageKey,
      required int pageSize,
    });

/// Explicit REST page identity for one notifications inbox query.
@immutable
final class NotificationPageKey {
  const NotificationPageKey(this.page)
    : assert(page > 0, 'Notification page numbers start at one.');

  final int page;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is NotificationPageKey && other.page == page;

  @override
  int get hashCode => page.hashCode;
}

const ResourcePolicy notificationPageResourcePolicy = ResourcePolicy(
  freshFor: Duration(seconds: 30),
  retainFor: Duration(minutes: 5),
  estimatedWeight: 20,
);

const ResourceTag notificationsInboxTag = ResourceTag(
  'notifications-inbox',
  'active',
);

ResourceTag notificationQueryTag({required final bool showAll}) =>
    ResourceTag('notifications-inbox-query', showAll ? 'all' : 'unread');

ResourceSpec<PaginatedResourcePage<Thread, NotificationPageKey>>
notificationPageResourceSpec({
  required final NotificationsService service,
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
    contract: 'github-rest-notifications-inbox-page-v1',
    load: (final ResourceLoadContext _) async {
      final List<Thread> loaded = await service.getNotifications(
        page: pageKey.page,
        perPage: pageSize,
        filters: <String, dynamic>{'all': showAll},
      );
      final List<Thread> items = List<Thread>.unmodifiable(loaded);
      final bool hasNextPage = items.length == pageSize;
      return ResourceLoadResult<
        PaginatedResourcePage<Thread, NotificationPageKey>
      >(
        data: PaginatedResourcePage<Thread, NotificationPageKey>(
          items: items,
          hasNextPage: hasNextPage,
          nextPageKey: hasNextPage
              ? NotificationPageKey(pageKey.page + 1)
              : null,
        ),
        estimatedWeight: items.isEmpty ? 1 : items.length * 2,
      );
    },
  );
}

ResourceSelector notificationQuerySelector({
  required final ResourceScope scope,
  required final bool showAll,
}) => ResourceSelector.forTags(<ResourceTag>{
  notificationQueryTag(showAll: showAll),
}, scope: scope);

ResourceSelector notificationsInboxSelector(final ResourceScope scope) =>
    ResourceSelector.forTags(<ResourceTag>{
      notificationsInboxTag,
    }, scope: scope);
