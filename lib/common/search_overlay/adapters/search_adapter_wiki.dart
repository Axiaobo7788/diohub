import 'package:diohub/common/cards/wiki_card.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/wiki_search_result.dart';
import 'package:diohub/services/global_services.dart';
import 'package:flutter/material.dart';

final class WikiSearchAdapter extends SearchTypeAdapter<WikiSearchResult> {
  WikiSearchAdapter(super.ref);

  int _page = 1;
  bool _hasNextPage = true;

  @override
  Future<PageSlice<WikiSearchResult>> fetchSlice({
    required String query,
    required int count,
    void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    if (!_hasNextPage) {
      return const PageSlice<WikiSearchResult>(
          items: <WikiSearchResult>[], hasNextPage: false);
    }
    final page = await ref.read(globalServicesProvider).search
        .searchWiki(query, first: count, page: _page);
    _page++;
    _hasNextPage = page.hasNextPage;
    return PageSlice<WikiSearchResult>(
      items: page.items,
      hasNextPage: page.hasNextPage,
    );
  }

  @override
  void resetState() {
    _page = 1;
    _hasNextPage = true;
  }

  @override
  Widget buildItem(BuildContext context, WikiSearchResult item, int index) {
    return BorderedContainer(
      ref: WikiRef(
        repo: RepoRef.fromFullName(item.repository.fullName),
        path: item.path,
      ),
      child: WikiCard(item),
    );
  }

  @override
  Widget buildLoadingShimmer(BuildContext context) =>
      ListLoadingShimmers.wikiList(context);

  @override
  String itemId(WikiSearchResult item) =>
      '${item.repository.fullName}:${item.path}';
}
