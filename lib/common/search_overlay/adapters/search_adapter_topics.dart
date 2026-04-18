import 'package:diohub/common/cards/topic_card.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/topic_search_result.dart';
import 'package:diohub/services/global_services.dart';
import 'package:flutter/material.dart';

final class TopicSearchAdapter extends SearchTypeAdapter<TopicSearchResult> {
  TopicSearchAdapter(super.ref);

  int _page = 1;
  bool _hasNextPage = true;

  @override
  Future<PageSlice<TopicSearchResult>> fetchSlice({
    required String query,
    required int count,
    void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    if (!_hasNextPage) {
      return const PageSlice<TopicSearchResult>(
          items: <TopicSearchResult>[], hasNextPage: false);
    }
    final page = await ref.read(globalServicesProvider).search
        .searchTopics(query, first: count, page: _page);
    _page++;
    _hasNextPage = page.hasNextPage;
    return PageSlice<TopicSearchResult>(
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
  Widget buildItem(BuildContext context, TopicSearchResult item, int index) {
    return BorderedContainer(
      ref: TopicRef(name: item.name),
      child: TopicCard(item),
    );
  }

  @override
  Widget buildLoadingShimmer(BuildContext context) =>
      ListLoadingShimmers.topicList(context);

  @override
  String itemId(TopicSearchResult item) => item.name;
}
