import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/filters/date_range_picker.dart';
import 'package:diohub/common/search_overlay/filters/dynamic_chip_row.dart';
import 'package:diohub/common/search_overlay/filters/filter_paginated_picker.dart';
import 'package:diohub/common/search_overlay/filters/number_range_picker.dart';
import 'package:diohub/common/search_overlay/filters/preloaded_picker.dart';
import 'package:diohub/common/search_overlay/filters/static_chip_row.dart';
import 'package:diohub/common/search_overlay/filters/text_picker.dart';
import 'package:diohub/common/search_overlay/filters/user_search_picker.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/search/filter_data_provider.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterSectionTile extends ConsumerWidget {
  const FilterSectionTile({
    required this.scope,
    required this.section,
    super.key,
  });

  final SearchScope scope;
  final FilterSectionDef section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SearchState state = ref.watch(searchStateNotifierProvider(scope));
    final notifier = ref.read(searchStateNotifierProvider(scope).notifier);
    final padding = Padding(
      padding: context.spacing.pagePadding,
      child: _buildPicker(context, ref, section, scope, state, notifier),
    );

    return ExpansionTile(
      leading: Icon(
        section.icon,
        size: 20,
        color: context.colorScheme.onSurface,
      ),
      title: Text(
        section.displayName,
        style: context.textTheme.titleSmall,
      ),
      children: <Widget>[padding],
    );
  }

  Widget _buildPicker(
    BuildContext context,
    WidgetRef ref,
    FilterSectionDef section,
    SearchScope scope,
    SearchState state,
    SearchStateNotifier notifier,
  ) {
    return switch (section) {
      StaticFilterSection() => StaticChipRow(
          scope: scope,
          section: section,
          state: state,
          notifier: notifier,
        ),
      MultiSelectFilterSection() => StaticChipRow(
          scope: scope,
          section: section,
          state: state,
          notifier: notifier,
        ),
      ToggleFilterSection() => Text(
          'Toggle filters not supported in SearchFilterSheet',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      PaginatedFilterSection(:final repo) => FilterPaginatedPicker(
          scope: scope,
          section: section,
          repoRef: repo,
          state: state,
          notifier: notifier,
        ),
      PreloadedFilterSection() => _buildPreloadedPicker(
          context,
          ref,
          section,
          scope,
          state,
          notifier,
        ),
      UserSearchFilterSection() => UserSearchPicker(
          scope: scope,
          section: section,
          state: state,
          notifier: notifier,
        ),
      DateFilterSection() => DateRangePicker(
          scope: scope,
          section: section,
          state: state,
          notifier: notifier,
        ),
      NumberFilterSection() => NumberRangePicker(
          scope: scope,
          section: section,
          state: state,
          notifier: notifier,
        ),
      TextFilterSection() => TextPicker(
          scope: scope,
          section: section,
          state: state,
          notifier: notifier,
        ),
    };
  }

  Widget _buildPreloadedPicker(
    BuildContext context,
    WidgetRef ref,
    PreloadedFilterSection section,
    SearchScope scope,
    SearchState state,
    SearchStateNotifier notifier,
  ) {
    if (section.load != null) {
      return PreloadedPicker(
        section: section,
        scope: scope,
        state: state,
        notifier: notifier,
      );
    }
    final cacheKey = scope.cacheKey;
    final dataAsync = ref
        .watch(filterDataProvider((cacheKey: cacheKey, sectionId: section.id)));
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
        return DynamicChipRow(
          scope: scope,
          section: section,
          state: state,
          notifier: notifier,
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
