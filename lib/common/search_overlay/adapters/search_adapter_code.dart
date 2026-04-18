import 'package:diohub/common/cards/code_result_card.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/code_search_result.dart';
import 'package:diohub/services/global_services.dart';
import 'package:flutter/material.dart';

final class CodeSearchAdapter extends SearchTypeAdapter<CodeSearchResult> {
  CodeSearchAdapter(super.ref);

  int _page = 1;
  bool _hasNextPage = true;

  @override
  Future<PageSlice<CodeSearchResult>> fetchSlice({
    required String query,
    required int count,
    void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    if (!_hasNextPage) {
      return const PageSlice<CodeSearchResult>(
          items: <CodeSearchResult>[], hasNextPage: false);
    }
    final page = await ref.read(globalServicesProvider).search
        .searchCode(query, first: count, page: _page);
    _page++;
    _hasNextPage = page.hasNextPage;
    return PageSlice<CodeSearchResult>(
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
  Widget buildItem(BuildContext context, CodeSearchResult item, int index) {
    return BorderedContainer(
      ref: CodeFileRef(
        repo: RepoRef.fromFullName(item.repository.fullName),
        path: item.path,
        sha: item.sha,
      ),
      child: CodeResultCard(item),
    );
  }

  @override
  Widget buildLoadingShimmer(BuildContext context) =>
      ListLoadingShimmers.codeList(context);

  @override
  String itemId(CodeSearchResult item) =>
      '${item.repository.fullName}:${item.path}:${item.sha}';
}
