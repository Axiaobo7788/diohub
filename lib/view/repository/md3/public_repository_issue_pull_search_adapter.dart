import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub/models/repositories/public_repository.dart';
import 'package:diohub/providers/repository/public_repository_providers.dart';
import 'package:diohub/view/repository/md3/repository_issue_pull_row.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:flutter/material.dart';

/// Page-number adapter for GitHub's unsigned REST issue search.
///
/// The Repository page always supplies its own row builder; [buildItem] is a
/// defensive fallback so this adapter cannot accidentally create a second list
/// presentation.
final class PublicRepositoryIssuePullSearchAdapter
    extends SearchTypeAdapter<Object> {
  PublicRepositoryIssuePullSearchAdapter(super.ref, {required this.repo});

  final RepoRef repo;

  int _page = 1;
  bool _hasNextPage = true;

  @override
  Future<PageSlice<Object>> fetchSlice({
    required final String query,
    required final int count,
    final void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    if (!_hasNextPage) {
      return const PageSlice<Object>(items: <Object>[], hasNextPage: false);
    }
    final PageSlice<PublicRepositoryIssuePullSummary> result = await ref
        .read(publicRepositoryServiceProvider)
        .searchIssuesPulls(
          repo: repo,
          query: query,
          page: _page,
          perPage: count,
        );
    _hasNextPage = result.hasNextPage;
    if (_hasNextPage) {
      _page += 1;
    }
    return PageSlice<Object>(
      items: result.items,
      hasNextPage: result.hasNextPage,
      totalCount: result.totalCount,
    );
  }

  @override
  void resetState() {
    _page = 1;
    _hasNextPage = true;
  }

  @override
  Widget buildItem(
    final BuildContext context,
    final Object item,
    final int index,
  ) {
    final PublicRepositoryIssuePullSummary result =
        item as PublicRepositoryIssuePullSummary;
    return RepositoryIssuePullRow(
      data: RepositoryIssuePullRowData.fromPublicResult(result),
      onTap: () {},
    );
  }

  @override
  Widget buildLoadingShimmer(final BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  String itemId(final Object item) {
    return (item as PublicRepositoryIssuePullSummary).nodeId;
  }
}
