import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/issue_or_pull.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class IssuePullSearchAdapter extends SearchTypeAdapter<IssueOrPull> {
  IssuePullSearchAdapter(
    super.ref, {
    this.showRepoNameOnIssues = true,
    this.showDescription = false,
  });
  final bool showRepoNameOnIssues;
  final bool showDescription;

  String? _cursor;
  bool _hasNextPage = true;

  @override
  Future<PageSlice<IssueOrPull>> fetchSlice({
    required String query,
    required int count,
    void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    if (!_hasNextPage) {
      return const PageSlice<IssueOrPull>(
        items: <IssueOrPull>[],
        hasNextPage: false,
      );
    }
    final page = await ref
        .read(globalServicesProvider)
        .search
        .searchIssuesPulls(
          query,
          first: count,
          after: _cursor,
          onRawResponse: onRawResponse,
        );
    _cursor = page.endCursor;
    _hasNextPage = page.hasNextPage;
    return PageSlice<IssueOrPull>(
      items: page.items,
      hasNextPage: page.hasNextPage,
      totalCount: page.totalCount,
    );
  }

  @override
  void resetState() {
    _cursor = null;
    _hasNextPage = true;
  }

  @override
  Widget buildItem(BuildContext context, IssueOrPull item, int index) {
    final Widget card;
    final EntityRef entityRef;
    switch (item) {
      case IssueResult(:final data):
        entityRef = IssueRef.fromIssueCardFields(data);
        card = IssuePullCard.fromIssue(
          data,
          showRepoName: showRepoNameOnIssues,
          showDescription: showDescription,
        );
      case PullResult(:final data):
        entityRef = PullRequestRef.fromPullCardFields(data);
        card = IssuePullCard.fromPullRequest(
          data,
          showRepoName: showRepoNameOnIssues,
          showDescription: showDescription,
        );
    }
    return Consumer(
      builder: (context, ref, _) => GestureDetector(
        onTap: () => entityRef.navigate(context, ref),
        behavior: HitTestBehavior.opaque,
        child: card,
      ),
    );
  }

  @override
  Widget buildLoadingShimmer(BuildContext context) =>
      ListLoadingShimmers.issuePullList(context);

  @override
  String itemId(IssueOrPull item) {
    return switch (item) {
      IssueResult(:final data) => data.id,
      PullResult(:final data) => data.id,
    };
  }
}
