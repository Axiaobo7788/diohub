import 'package:diohub/common/widgets/entity_store_card.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/view/home/dashboard/sections/dashboard_async_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardBookmarksSection extends ConsumerWidget {
  const DashboardBookmarksSection({
    required this.limit,
    super.key,
  });

  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(allBookmarksProvider);

    return DashboardAsyncListSection(
      data: bookmarksAsync,
      title: 'Bookmarks',
      icon: Icons.bookmark_rounded,
      limit: limit,
      itemBuilder: (bookmark) => EntityStoreCard(entry: BookmarkEntry(bookmark)),
    );
  }
}
