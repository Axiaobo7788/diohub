import 'package:diohub/common/cards/package_card.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/package_search_result.dart';
import 'package:diohub/services/global_services.dart';
import 'package:flutter/material.dart';

final class PackageSearchAdapter
    extends SearchTypeAdapter<PackageSearchResult> {
  PackageSearchAdapter(super.ref);

  int _page = 1;
  bool _hasNextPage = true;

  @override
  Future<PageSlice<PackageSearchResult>> fetchSlice({
    required String query,
    required int count,
    void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) async {
    if (!_hasNextPage) {
      return const PageSlice<PackageSearchResult>(
          items: <PackageSearchResult>[], hasNextPage: false);
    }
    final page = await ref.read(globalServicesProvider).search
        .searchPackages(query, first: count, page: _page);
    _page++;
    _hasNextPage = page.hasNextPage;
    return PageSlice<PackageSearchResult>(
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
  Widget buildItem(BuildContext context, PackageSearchResult item, int index) {
    return BorderedContainer(
      ref: PackageRef(htmlUrl: item.htmlUrl),
      child: PackageCard(item),
    );
  }

  @override
  Widget buildLoadingShimmer(BuildContext context) =>
      ListLoadingShimmers.packageList(context);

  @override
  String itemId(PackageSearchResult item) => item.htmlUrl;
}
