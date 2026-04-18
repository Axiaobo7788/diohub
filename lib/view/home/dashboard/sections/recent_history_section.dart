import 'package:diohub/common/widgets/entity_store_card.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/view/home/dashboard/sections/dashboard_async_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class DashboardRecentHistorySection extends ConsumerWidget {
  const DashboardRecentHistorySection({
    required this.limit,
    super.key,
  });

  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(allHistoryProvider);

    return DashboardAsyncListSection(
      data: historyAsync,
      title: 'Recent',
      icon: Octicons.history,
      limit: limit,
      itemBuilder: (entry) => EntityStoreCard(entry: HistoryEntry(entry)),
    );
  }
}
