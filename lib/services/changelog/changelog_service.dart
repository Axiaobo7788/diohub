import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/models/changelog/changelog_entry.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub_graphql/schema.graphql.dart';

final class ChangelogService extends BaseService {
  const ChangelogService._(ApiClient client) : super(client);

  factory ChangelogService(ApiClient client) => ChangelogService._(client);

  static final RepoRef _appRepo = RepoRef.fromFullName('NamanShergill/diohub');

  Future<CursorPage<ChangelogEntry>> fetchPage({
    required int first,
    String? after,
  }) async {
    final result = await _appRepo.releases(apiClient).fetchReleasesPaginated(
      first: first,
      after: after,
      orderField: Enum$ReleaseOrderField.CREATED_AT,
      orderDirection: Enum$OrderDirection.DESC,
    );

    // Filter out drafts and map to ChangelogEntry
    final entries = result.items
        .map((edge) => edge.node)
        .where((node) => node != null && !node.isDraft)
        .map((node) {
      return ChangelogEntry(
        tagName: node!.tagName,
        publishedAt: node.publishedAt ?? DateTime.now(),
        bodyHtml: node.descriptionHTML ?? '',
        name: node.name,
        isPrerelease: node.isPrerelease,
      );
    }).toList();

    return CursorPage<ChangelogEntry>(
      items: entries,
      hasNextPage: result.hasNextPage,
      endCursor: result.endCursor,
    );
  }
}
