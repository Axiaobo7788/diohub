import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef PullFilePatchPageSpecFactory =
    ResourceSpec<PaginatedResourcePage<DiffEntry, int>> Function({
      required PullRequestRef pullRequest,
      required int page,
      required int pageSize,
      required ResourceScope scope,
    });

const ResourcePolicy pullFilePatchPagePolicy = ResourcePolicy(
  freshFor: Duration(minutes: 2),
  retainFor: Duration(minutes: 10),
  estimatedWeight: 48,
);

String _pullRequestIdentity(final PullRequestRef pullRequest) =>
    '${pullRequest.repo.fullName}#${pullRequest.number}';

ResourceTag pullFilePatchQueryTag(final PullRequestRef pullRequest) =>
    ResourceTag('pull-file-patches', _pullRequestIdentity(pullRequest));

ResourceSelector pullFilePatchQuerySelector({
  required final PullRequestRef pullRequest,
  required final ResourceScope scope,
}) => ResourceSelector.forTags(<ResourceTag>{
  pullFilePatchQueryTag(pullRequest),
}, scope: scope);

ResourceSpec<PaginatedResourcePage<DiffEntry, int>> pullFilePatchPageSpec({
  required final PullRequestRef pullRequest,
  required final int page,
  required final int pageSize,
  required final ResourceScope scope,
  required final Future<List<DiffEntry>> Function({
    required int page,
    required int pageSize,
  })
  loadPage,
}) => ResourceSpec<PaginatedResourcePage<DiffEntry, int>>(
  id: ResourceId<PaginatedResourcePage<DiffEntry, int>>(
    kind: 'pull-file-patch-page',
    version: 1,
    scope: scope,
    key: '${_pullRequestIdentity(pullRequest)}/page:$page/size:$pageSize',
  ),
  policy: pullFilePatchPagePolicy,
  tags: <ResourceTag>{
    ResourceTag('repository', pullRequest.repo.fullName),
    pullFilePatchQueryTag(pullRequest),
  },
  contract: 'github-rest-pull-files-with-patch-v1',
  load: (final ResourceLoadContext _) async {
    final List<DiffEntry> items = List<DiffEntry>.unmodifiable(
      await loadPage(page: page, pageSize: pageSize),
    );
    final bool hasNextPage = items.length >= pageSize;
    return ResourceLoadResult<PaginatedResourcePage<DiffEntry, int>>(
      data: PaginatedResourcePage<DiffEntry, int>(
        items: items,
        hasNextPage: hasNextPage,
        nextPageKey: hasNextPage ? page + 1 : null,
      ),
      estimatedWeight: items.isEmpty ? 1 : items.length * 4,
    );
  },
);

final pullFilePatchPageSpecFactoryProvider =
    Provider<PullFilePatchPageSpecFactory>((final Ref ref) {
      return ({
        required final PullRequestRef pullRequest,
        required final int page,
        required final int pageSize,
        required final ResourceScope scope,
      }) {
        final service = pullRequest.services(ref.read(apiClientProvider));
        return pullFilePatchPageSpec(
          pullRequest: pullRequest,
          page: page,
          pageSize: pageSize,
          scope: scope,
          loadPage: ({required final int page, required final int pageSize}) =>
              service.getPullFilePatchesPage(
                page: page,
                perPage: pageSize,
                refresh: false,
              ),
        );
      };
    });
