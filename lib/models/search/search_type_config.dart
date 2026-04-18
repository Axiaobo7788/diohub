import 'package:diohub/common/search_overlay/adapters/search_adapters.dart';
import 'package:diohub/common/search_overlay/search_type.dart';
import 'package:diohub/common/search_overlay/search_type_adapter.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Strategy for fetching and rendering search results of a specific type.
/// Wraps [SearchTypeAdapter] so [SearchScrollSlivers] uses a single config API.
class SearchTypeConfig {
  SearchTypeConfig(this._adapter);

  final SearchTypeAdapter<Object> _adapter;

  /// Fetch a page of results.
  Future<PageSlice<Object>> fetchSlice({
    required String query,
    required int count,
    void Function(Map<String, dynamic>? rawData)? onRawResponse,
  }) =>
      _adapter.fetchSlice(
        query: query,
        count: count,
        onRawResponse: onRawResponse,
      );

  /// Reset cursor/page state.
  void resetState() => _adapter.resetState();

  /// Build the item widget for a single result.
  Widget buildItem(BuildContext context, Object item, int index) =>
      _adapter.buildItem(context, item, index);

  /// Build the loading shimmer for this search type.
  Widget buildLoadingShimmer(BuildContext context) =>
      _adapter.buildLoadingShimmer(context);

  /// Extract a unique ID from an item.
  String itemId(Object item) => _adapter.itemId(item);
}

/// Extension to get [SearchTypeConfig] for a [SearchType].
extension SearchTypeConfigExt on SearchType {
  SearchTypeConfig config(
    WidgetRef ref, {
    bool showRepoOwner = true,
    bool showRepoNameOnIssues = true,
  }) =>
      SearchTypeConfig(
        adapterForSearchType(
          this,
          ref: ref,
          showRepoOwner: showRepoOwner,
          showRepoNameOnIssues: showRepoNameOnIssues,
        ),
      );
}
