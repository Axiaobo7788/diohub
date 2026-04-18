import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart'
    show RepoCardData;
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/search_overlay/filters.dart' show SearchQueries;
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/global_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _trendingQuery = () => SearchQueries().pushed.toQueryString(
  '>${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 7)))}',
);

/// Source for "Trending Repositories" (repos pushed in the last 7 days).
/// Use with [PaginationController] so the view layer does not import [SearchService].
final trendingReposSourceProvider = Provider<CursorForwardSource<RepoCardData>>(
  (ref) {
    return CursorForwardSource<RepoCardData>(
      fetch: ({required int first, String? after}) async {
        final PaginatedResult<RepoCardData> r = await ref
            .read(globalServicesProvider)
            .search
            .searchRepos(_trendingQuery(), first: first, after: after);
        return CursorPage<RepoCardData>(
          items: r.items,
          hasNextPage: r.hasNextPage,
          endCursor: r.endCursor,
        );
      },
    );
  },
);
