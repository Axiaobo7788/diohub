import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Type-safe adapter bridging [SearchType] to [PaginationController]<T, T>.
/// Eliminates dynamic casts in the search scroll wrapper.
abstract class SearchTypeAdapter<T> {
  SearchTypeAdapter(this.ref);

  final WidgetRef ref;

  /// Fetch a page of results. Adapter manages cursor/page state internally.
  Future<PageSlice<T>> fetchSlice({
    required String query,
    required int count,
    void Function(Map<String, dynamic>? rawData)? onRawResponse,
  });

  /// Reset cursor/page state (e.g. on pull-to-refresh).
  void resetState();

  /// Build the item widget for a single result.
  Widget buildItem(BuildContext context, T item, int index);

  /// Build the loading shimmer for this search type.
  Widget buildLoadingShimmer(BuildContext context);

  /// Extract a unique ID from an item.
  String itemId(T item);
}
