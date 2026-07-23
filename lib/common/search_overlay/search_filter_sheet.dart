import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/filters.dart';
import 'package:diohub/common/search_overlay/filters/filter_section_tile.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter bottom sheet: reads/writes [searchStateNotifierProvider(scope)].
/// Each toggle calls notifier.addQualifier/removeQualifier/updateSort immediately.
/// "Done" pops; "Clear All" calls the supplied reset callback or
/// notifier.clear().
///
/// Callers must pass [scrollController] from [AppSheet.scrollable] bodyBuilder
/// and use [SearchFilterSheet.buildHeader] for the sheet header.
class SearchFilterSheet extends ConsumerStatefulWidget {
  const SearchFilterSheet({
    required this.scope,
    required this.scrollController,
    super.key,
  });

  final SearchScope scope;
  final ScrollController scrollController;

  /// Builds the header row (Filters title + Clear All / Done). Use as
  /// [AppSheet.scrollable] headerBuilder when showing this sheet.
  static Widget buildHeader(
    BuildContext context,
    SearchScope scope,
    WidgetRef ref, {
    VoidCallback? onClearAll,
  }) {
    final notifier = ref.read(searchStateNotifierProvider(scope).notifier);
    final spacing = context.spacing;
    final l10n = context.l10n;
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
            l10n.repoFilters,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              if (onClearAll != null) {
                onClearAll();
              } else {
                notifier.clear();
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(l10n.filterClearAll),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.filterDone),
          ),
        ],
      ),
    );
  }

  @override
  ConsumerState<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends ConsumerState<SearchFilterSheet> {
  bool _advancedExpanded = false;
  final TextEditingController _advancedController = TextEditingController();

  @override
  void dispose() {
    _advancedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SearchState state = ref.watch(
      searchStateNotifierProvider(widget.scope),
    );
    final notifier = ref.read(
      searchStateNotifierProvider(widget.scope).notifier,
    );
    final SearchType type = ref.watch(selectedSearchTypeProvider(widget.scope));
    final List<FilterSectionDef> promoted = widget.scope.promotedSections(type);
    final List<FilterSectionDef> more = widget.scope.moreSections(type);
    final AppSpacing spacing = context.spacing;

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: <Widget>[
        ...promoted.map(
          (FilterSectionDef section) => SliverToBoxAdapter(
            child: FilterSectionTile(scope: widget.scope, section: section),
          ),
        ),
        if (more.isNotEmpty) ...<Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: spacing.tightSpacing,
                horizontal: spacing.pagePadding.left,
              ),
              child: Text(
                context.l10n.filterMoreFilters,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          ...more.map(
            (FilterSectionDef section) => SliverToBoxAdapter(
              child: FilterSectionTile(scope: widget.scope, section: section),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: ExpansionTile(
            title: Text(
              context.l10n.filterAdvanced,
              style: context.textTheme.titleSmall,
            ),
            initiallyExpanded: _advancedExpanded,
            onExpansionChanged: (bool v) {
              setState(() => _advancedExpanded = v);
            },
            children: <Widget>[
              Padding(
                padding: spacing.pagePadding,
                child: TextField(
                  controller: _advancedController,
                  decoration: InputDecoration(
                    hintText: context.l10n.filterAdvancedQueryHint,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onSubmitted: (String text) {
                    notifier.updateFreeText('${state.freeText} $text'.trim());
                  },
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(child: context.spacing.spaciousGap),
      ],
    );
  }
}
