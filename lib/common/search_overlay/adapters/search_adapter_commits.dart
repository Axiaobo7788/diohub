import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/global_services.dart';
import 'package:flutter/material.dart';

final class CommitSearchAdapter extends SearchTypeAdapter<CommitListItemModel> {
  CommitSearchAdapter(super.ref);

  int _page = 1;
  bool _hasNextPage = true;

  @override
  Future<PageSlice<CommitListItemModel>> fetchSlice({
    required String query,
    required int count,
    void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    if (!_hasNextPage) {
      return const PageSlice<CommitListItemModel>(
          items: <CommitListItemModel>[], hasNextPage: false);
    }
    final page = await ref.read(globalServicesProvider).search
        .searchCommits(query, first: count, page: _page);
    _page++;
    _hasNextPage = page.hasNextPage;
    return PageSlice<CommitListItemModel>(
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
  Widget buildItem(BuildContext context, CommitListItemModel item, int index) {
    final RepoRef? repoRef = item.repoFullName != null
        ? RepoRef.fromFullName(item.repoFullName!)
        : null;
    final RepoRef repo = repoRef ?? RepoRef(owner: 'search', name: 'result');
    return BorderedContainer(
      ref: CommitRef(repo: repo, oid: item.sha),
      child: CommitCard(
        data: item,
        repoRef: repoRef,
        showRepoName: repoRef != null,
      ),
    );
  }

  @override
  Widget buildLoadingShimmer(BuildContext context) =>
      ListLoadingShimmers.commitList(context);

  @override
  String itemId(CommitListItemModel item) => item.sha;
}
