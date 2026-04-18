import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/global_services.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub/utils/timeline/timeline_node_id.dart';
import 'package:flutter/material.dart';

final class RepoSearchAdapter extends SearchTypeAdapter<RepoCardData> {
  RepoSearchAdapter(super.ref, {this.showOwner = true});
  final bool showOwner;

  String? _cursor;
  bool _hasNextPage = true;

  @override
  Future<PageSlice<RepoCardData>> fetchSlice({
    required String query,
    required int count,
    void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    if (!_hasNextPage) {
      return const PageSlice<RepoCardData>(
          items: <RepoCardData>[], hasNextPage: false);
    }
    final page = await ref.read(globalServicesProvider).search.searchRepos(
      query,
      first: count,
      after: _cursor,
      onRawResponse: onRawResponse,
    );
    _cursor = page.endCursor;
    _hasNextPage = page.hasNextPage;
    return PageSlice<RepoCardData>(
      items: page.items,
      hasNextPage: page.hasNextPage,
    );
  }

  @override
  void resetState() {
    _cursor = null;
    _hasNextPage = true;
  }

  @override
  Widget buildItem(BuildContext context, RepoCardData item, int index) {
    return BorderedContainer(
      ref: RepoRef.fromRepoCardFields(item),
      child: RepositoryCard(item, showOwner: showOwner),
    );
  }

  @override
  Widget buildLoadingShimmer(BuildContext context) =>
      ListLoadingShimmers.repoList(context);

  @override
  String itemId(RepoCardData item) =>
      timelineNodeIdOf(item) ?? identityHashCode(item).toString();
}
