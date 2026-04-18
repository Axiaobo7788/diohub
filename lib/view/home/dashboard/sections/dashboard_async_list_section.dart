import 'package:diohub/common/widgets/dashboard_section_header.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardAsyncListSection<T> extends ConsumerWidget {
  const DashboardAsyncListSection({
    required this.data,
    required this.title,
    required this.icon,
    required this.itemBuilder,
    required this.limit,
    this.onTap,
    super.key,
  });

  final AsyncValue<List<T>> data;
  final String title;
  final IconData icon;
  final Widget Function(T item) itemBuilder;
  final int limit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;

    return data.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayItems = items.take(limit).toList();

        return Padding(
          padding: spacing.screenPadding.copyWith(top: spacing.sectionSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardSectionHeader(title: title, icon: icon, onTap: onTap),
              spacing.itemGap,
              ...displayItems.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                  child: itemBuilder(item),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
