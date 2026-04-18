import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/cards/discussion_card.dart';
import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/global_services.dart';
import 'package:flutter/material.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub/utils/timeline/timeline_node_id.dart';

final class DiscussionSearchAdapter
    extends SearchTypeAdapter<DiscussionCardData> {
  DiscussionSearchAdapter(super.ref);

  String? _cursor;
  bool _hasNextPage = true;

  @override
  Future<PageSlice<DiscussionCardData>> fetchSlice({
    required String query,
    required int count,
    void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    if (!_hasNextPage) {
      return const PageSlice<DiscussionCardData>(
          items: <DiscussionCardData>[], hasNextPage: false);
    }
    final page = await ref.read(globalServicesProvider).search.searchDiscussions(
      query,
      first: count,
      after: _cursor,
      onRawResponse: onRawResponse,
    );
    _cursor = page.endCursor;
    _hasNextPage = page.hasNextPage;
    return PageSlice<DiscussionCardData>(
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
  Widget buildItem(BuildContext context, DiscussionCardData item, int index) {
    final List<String> parts = item.repository.nameWithOwner.split('/');
    final RepoRef repo = parts.length == 2
        ? RepoRef(owner: parts[0], name: parts[1])
        : RepoRef(owner: item.repository.owner.login, name: 'repo');
    return BorderedContainer(
      ref: DiscussionRef(repo: repo, number: item.number),
      child: DiscussionCard(item),
    );
  }

  @override
  Widget buildLoadingShimmer(BuildContext context) =>
      ListLoadingShimmers.discussionList(context);

  @override
  String itemId(DiscussionCardData item) =>
      timelineNodeIdOf(item) ?? identityHashCode(item).toString();
}
