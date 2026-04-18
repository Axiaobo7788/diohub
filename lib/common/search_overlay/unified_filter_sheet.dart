import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/filter_state_adapter.dart';
import 'package:diohub/common/search_overlay/filter_value.dart';
import 'package:diohub/providers/search/filter_data_provider.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generic filter bottom sheet that works with any [FilterStateAdapter].
///
/// Replaces SearchFilterSheet for tabs that don't use SearchScope (Bookmarks, Inbox, etc.).
/// For search tabs, use SearchFilterSheet (which wraps SearchStateNotifier).
///
/// Callers must pass [scrollController] from [AppSheet.scrollable] bodyBuilder
/// and use [UnifiedFilterSheet.buildHeader] for the sheet header.
class UnifiedFilterSheet extends ConsumerStatefulWidget {
  const UnifiedFilterSheet({
    required this.adapter,
    required this.scrollController,
    this.cacheKey,
    super.key,
  });

  final FilterStateAdapter adapter;
  final ScrollController scrollController;

  /// Optional cache key for preloaded sections that use filterDataProvider.
  /// If null, preloaded sections with no explicit load function will show "No options".
  final String? cacheKey;

  /// Builds the header row (Filters title + Clear All / Done). Use as
  /// [AppSheet.scrollable] headerBuilder when showing this sheet.
  static Widget buildHeader(BuildContext context, FilterStateAdapter adapter) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.pagePadding.left,
        spacing.itemSpacing,
        spacing.pagePadding.right,
        spacing.tightSpacing,
      ),
      child: Row(
        children: <Widget>[
          Text(
            'Filters',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              adapter.clearAll();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  ConsumerState<UnifiedFilterSheet> createState() => _UnifiedFilterSheetState();
}

class _UnifiedFilterSheetState extends ConsumerState<UnifiedFilterSheet> {
  @override
  Widget build(BuildContext context) {
    final List<FilterSectionDef> sections = widget.adapter.sections;
    final AppSpacing spacing = context.spacing;

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: <Widget>[
        ...sections.map(
          (FilterSectionDef section) => SliverToBoxAdapter(
            child: _FilterSectionTile(
              adapter: widget.adapter,
              section: section,
              cacheKey: widget.cacheKey,
            ),
          ),
        ),
        SliverToBoxAdapter(child: spacing.spaciousGap),
      ],
    );
  }
}

/// Tile for a single filter section within UnifiedFilterSheet.
class _FilterSectionTile extends ConsumerWidget {
  const _FilterSectionTile({
    required this.adapter,
    required this.section,
    this.cacheKey,
  });

  final FilterStateAdapter adapter;
  final FilterSectionDef section;
  final String? cacheKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = Padding(
      padding: context.spacing.pagePadding,
      child: _buildPicker(context, ref),
    );

    return ExpansionTile(
      leading: Icon(
        section.icon,
        size: 20,
        color: context.colorScheme.onSurface,
      ),
      title: Text(section.displayName, style: context.textTheme.titleSmall),
      children: <Widget>[padding],
    );
  }

  Widget _buildPicker(BuildContext context, WidgetRef ref) {
    return switch (section) {
      StaticFilterSection s => _GenericStaticChipRow(
        adapter: adapter,
        section: s,
      ),
      ToggleFilterSection s => _ToggleSwitch(adapter: adapter, section: s),
      MultiSelectFilterSection s => _GenericStaticChipRow(
        adapter: adapter,
        section: s,
      ),
      PaginatedFilterSection s => _GenericPaginatedPicker(
        adapter: adapter,
        section: s,
        repoRef: s.repo,
      ),
      PreloadedFilterSection s => _buildPreloadedPicker(context, ref, s),
      UserSearchFilterSection s => _GenericUserSearchPicker(
        adapter: adapter,
        section: s,
      ),
      DateFilterSection s => _GenericDateRangePicker(
        adapter: adapter,
        section: s,
      ),
      NumberFilterSection s => _GenericNumberRangePicker(
        adapter: adapter,
        section: s,
      ),
      TextFilterSection s => _GenericTextPicker(adapter: adapter, section: s),
    };
  }

  Widget _buildPreloadedPicker(
    BuildContext context,
    WidgetRef ref,
    PreloadedFilterSection section,
  ) {
    if (section.load != null) {
      return _GenericPreloadedPicker(adapter: adapter, section: section);
    }
    if (cacheKey == null) {
      return Text(
        'No options',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final dataAsync = ref.watch(
      filterDataProvider((cacheKey: cacheKey!, sectionId: section.id)),
    );
    return dataAsync.when(
      data: (FilterDataOptions? data) {
        if (data == null || data.options.isEmpty) {
          return Text(
            'No options',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          );
        }
        return _GenericDynamicChipRow(
          adapter: adapter,
          section: section,
          options: data.options,
        );
      },
      loading: () => SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colorScheme.primary,
            ),
          ),
        ),
      ),
      error: (Object _, StackTrace? __) => Text(
        'Could not load options',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.error,
        ),
      ),
    );
  }
}

/// Generic static chip row that reads/writes via adapter.
class _GenericStaticChipRow extends StatelessWidget {
  const _GenericStaticChipRow({required this.adapter, required this.section});

  final FilterStateAdapter adapter;
  final FilterSectionDef section;

  @override
  Widget build(BuildContext context) {
    final Map<String, String> options;
    if (section is StaticFilterSection) {
      options = (section as StaticFilterSection).options;
    } else if (section is MultiSelectFilterSection) {
      options = (section as MultiSelectFilterSection).options;
    } else {
      return const SizedBox.shrink();
    }

    final multiSelect = section.multiSelect;
    final value = adapter.getValue(section.id);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final isSelected = value.when(
          singleSelect: (v) => !multiSelect && v == entry.key,
          multiSelect: (values) => multiSelect && values.contains(entry.key),
          toggle: (_) => false,
        );

        return FilterChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (selected) {
            if (multiSelect) {
              value.when(
                singleSelect: (_) =>
                    throw StateError('Expected multiSelect value'),
                multiSelect: (current) {
                  adapter.setValue(
                    section.id,
                    FilterValue.multiSelect(
                      selected
                          ? [...current, entry.key]
                          : current.where((k) => k != entry.key).toList(),
                    ),
                  );
                },
                toggle: (_) => throw StateError('Expected multiSelect value'),
              );
            } else {
              adapter.setValue(
                section.id,
                FilterValue.singleSelect(selected ? entry.key : null),
              );
            }
          },
        );
      }).toList(),
    );
  }
}

/// Toggle switch for boolean filters.
class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({required this.adapter, required this.section});

  final FilterStateAdapter adapter;
  final ToggleFilterSection section;

  @override
  Widget build(BuildContext context) {
    final value = adapter
        .getValue(section.id)
        .when(
          singleSelect: (_) => false,
          multiSelect: (_) => false,
          toggle: (v) => v,
        );
    return SwitchListTile(
      title: Text(section.displayName),
      value: value,
      onChanged: (v) => adapter.setValue(section.id, FilterValue.toggle(v)),
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// Generic paginated picker (labels, assignees, etc.).
class _GenericPaginatedPicker extends StatelessWidget {
  const _GenericPaginatedPicker({
    required this.adapter,
    required this.section,
    required this.repoRef,
  });

  final FilterStateAdapter adapter;
  final PaginatedFilterSection section;
  final dynamic repoRef;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.construction_outlined,
            size: 20,
            color: theme.disabledColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${section.displayName} (coming soon)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic preloaded picker.
class _GenericPreloadedPicker extends StatelessWidget {
  const _GenericPreloadedPicker({required this.adapter, required this.section});

  final FilterStateAdapter adapter;
  final PreloadedFilterSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.construction_outlined,
            size: 20,
            color: theme.disabledColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${section.displayName} (coming soon)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic dynamic chip row.
class _GenericDynamicChipRow extends StatelessWidget {
  const _GenericDynamicChipRow({
    required this.adapter,
    required this.section,
    required this.options,
  });

  final FilterStateAdapter adapter;
  final FilterSectionDef section;
  final List<FilterOption> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.construction_outlined,
            size: 20,
            color: theme.disabledColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${section.displayName} (coming soon)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic user search picker.
class _GenericUserSearchPicker extends StatelessWidget {
  const _GenericUserSearchPicker({
    required this.adapter,
    required this.section,
  });

  final FilterStateAdapter adapter;
  final UserSearchFilterSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.construction_outlined,
            size: 20,
            color: theme.disabledColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${section.displayName} (coming soon)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic date range picker.
class _GenericDateRangePicker extends StatelessWidget {
  const _GenericDateRangePicker({required this.adapter, required this.section});

  final FilterStateAdapter adapter;
  final DateFilterSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.construction_outlined,
            size: 20,
            color: theme.disabledColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${section.displayName} (coming soon)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic number range picker.
class _GenericNumberRangePicker extends StatelessWidget {
  const _GenericNumberRangePicker({
    required this.adapter,
    required this.section,
  });

  final FilterStateAdapter adapter;
  final NumberFilterSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.construction_outlined,
            size: 20,
            color: theme.disabledColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${section.displayName} (coming soon)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic text picker.
class _GenericTextPicker extends StatelessWidget {
  const _GenericTextPicker({required this.adapter, required this.section});

  final FilterStateAdapter adapter;
  final TextFilterSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.construction_outlined,
            size: 20,
            color: theme.disabledColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${section.displayName} (coming soon)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
