import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:flutter/foundation.dart';

/// Explicit REST page identity for authenticated Settings collections.
@immutable
final class ViewerSettingsRestPageKey {
  const ViewerSettingsRestPageKey(this.page)
    : assert(page > 0, 'REST page numbers start at one.');

  final int page;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ViewerSettingsRestPageKey && other.page == page;

  @override
  int get hashCode => page.hashCode;
}

/// Explicit GraphQL cursor identity for authenticated Settings collections.
@immutable
final class ViewerSettingsCursorPageKey {
  const ViewerSettingsCursorPageKey(this.cursor);

  final String? cursor;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ViewerSettingsCursorPageKey && other.cursor == cursor;

  @override
  int get hashCode => cursor.hashCode;
}

typedef ViewerSettingsRestPageLoader<T> =
    Future<PaginatedResult<T>> Function({
      required int page,
      required int perPage,
    });

typedef ViewerSettingsCursorPageLoader<T> =
    Future<PaginatedResult<T>> Function({
      required String? after,
      required int first,
    });

/// Account administration data changes infrequently, but mutations must become
/// visible immediately. Thirty seconds avoids repeated tab churn while the
/// session-owned controller and exact invalidation preserve write consistency.
const ResourcePolicy viewerSettingsPagePolicy = ResourcePolicy(
  freshFor: Duration(seconds: 30),
  retainFor: Duration(minutes: 5),
  estimatedWeight: 10,
  allowPrefetch: false,
);

ResourceTag viewerSettingsCollectionTag(final String collection) =>
    ResourceTag('viewer-settings-collection', collection);

ResourceSelector viewerSettingsCollectionSelector({
  required final ResourceScope scope,
  required final String collection,
}) => ResourceSelector.forTags(<ResourceTag>{
  viewerSettingsCollectionTag(collection),
}, scope: scope);

ResourceSpec<PaginatedResourcePage<T, ViewerSettingsRestPageKey>>
viewerSettingsRestPageSpec<T>({
  required final ResourceScope scope,
  required final String collection,
  required final ViewerSettingsRestPageKey pageKey,
  required final int pageSize,
  required final ViewerSettingsRestPageLoader<T> loadPage,
}) => ResourceSpec<PaginatedResourcePage<T, ViewerSettingsRestPageKey>>(
  id: ResourceId<PaginatedResourcePage<T, ViewerSettingsRestPageKey>>(
    kind: 'viewer-settings-$collection-page',
    version: 1,
    scope: scope,
    key: 'page:${pageKey.page}/size:$pageSize',
  ),
  policy: viewerSettingsPagePolicy,
  tags: <ResourceTag>{viewerSettingsCollectionTag(collection)},
  contract: 'github-rest-viewer-settings-$collection-page-v1',
  load: (final ResourceLoadContext _) async {
    final PaginatedResult<T> result = await loadPage(
      page: pageKey.page,
      perPage: pageSize,
    );
    final List<T> items = List<T>.unmodifiable(result.items);
    return ResourceLoadResult<
      PaginatedResourcePage<T, ViewerSettingsRestPageKey>
    >(
      data: PaginatedResourcePage<T, ViewerSettingsRestPageKey>(
        items: items,
        hasNextPage: result.hasNextPage,
        nextPageKey: result.hasNextPage
            ? ViewerSettingsRestPageKey(pageKey.page + 1)
            : null,
        totalCount: result.totalCount,
      ),
      estimatedWeight: items.isEmpty ? 1 : items.length * 2,
    );
  },
);

ResourceSpec<PaginatedResourcePage<T, ViewerSettingsCursorPageKey>>
viewerSettingsCursorPageSpec<T>({
  required final ResourceScope scope,
  required final String collection,
  required final ViewerSettingsCursorPageKey pageKey,
  required final int pageSize,
  required final ViewerSettingsCursorPageLoader<T> loadPage,
}) => ResourceSpec<PaginatedResourcePage<T, ViewerSettingsCursorPageKey>>(
  id: ResourceId<PaginatedResourcePage<T, ViewerSettingsCursorPageKey>>(
    kind: 'viewer-settings-$collection-page',
    version: 1,
    scope: scope,
    key: 'cursor:${pageKey.cursor ?? "start"}/size:$pageSize',
  ),
  policy: viewerSettingsPagePolicy,
  tags: <ResourceTag>{viewerSettingsCollectionTag(collection)},
  contract: 'github-graphql-viewer-settings-$collection-page-v1',
  load: (final ResourceLoadContext _) async {
    final PaginatedResult<T> result = await loadPage(
      after: pageKey.cursor,
      first: pageSize,
    );
    final List<T> items = List<T>.unmodifiable(result.items);
    final bool hasNextPage = result.hasNextPage && result.endCursor != null;
    return ResourceLoadResult<
      PaginatedResourcePage<T, ViewerSettingsCursorPageKey>
    >(
      data: PaginatedResourcePage<T, ViewerSettingsCursorPageKey>(
        items: items,
        hasNextPage: hasNextPage,
        nextPageKey: hasNextPage
            ? ViewerSettingsCursorPageKey(result.endCursor)
            : null,
        totalCount: result.totalCount,
      ),
      estimatedWeight: items.isEmpty ? 1 : items.length * 2,
    );
  },
);
