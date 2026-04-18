import 'package:diohub/common/widgets/dashboard_section_header.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Dashboard saved searches section.
class DashboardSavedSearchesSection extends ConsumerWidget {
  const DashboardSavedSearchesSection({required this.limit, super.key});

  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final savedSearchesAsync = ref.watch(allSavedSearchesProvider);

    return savedSearchesAsync.when(
      data: (searches) {
        if (searches.isEmpty) {
          return const SizedBox.shrink();
        }

        final displaySearches = searches.take(limit).toList();

        return Padding(
          padding: spacing.screenPadding.copyWith(top: spacing.sectionSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardSectionHeader(
                title: 'Saved Searches',
                icon: Octicons.search,
              ),
              spacing.itemGap,
              Wrap(
                spacing: spacing.itemSpacing,
                runSpacing: spacing.itemSpacing,
                children: displaySearches
                    .map(
                      (search) => ActionChip(
                        label: Text(search.label ?? 'Unnamed Search'),
                        onPressed: () {
                          // TODO: Execute saved search
                        },
                      ),
                    )
                    .toList(),
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
