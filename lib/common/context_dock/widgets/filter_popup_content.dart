import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/models/filters/custom_filter.dart';
import 'package:diohub/models/search/quick_filter.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/providers/filters/custom_filters_notifier.dart';
import 'package:diohub/providers/repository/repo_filter_counts_provider.dart';
import 'package:diohub/providers/search/filter_counts_provider.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:auto_route/auto_route.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter popup content: quick filters, custom filters, save current, manage.
///
/// Shown in a bottom sheet when user taps the filter control on a tab
/// that has [searchScope]. [onSelectIndex] switches to that tab;
/// [onDismissOverlay] closes the nav overlay; [onCloseSheet] closes the sheet.
class FilterPopupContent extends ConsumerWidget {
  const FilterPopupContent({
    required this.scope,
    required this.positionLabel,
    required this.tabIndex,
    required this.currentIndex,
    required this.onSelectIndex,
    required this.onDismissOverlay,
    required this.onCloseSheet,
    this.showSaveFilter = true,
    super.key,
  });

  final SearchScope scope;
  final String positionLabel;
  final int tabIndex;
  final int currentIndex;
  final VoidCallback onSelectIndex;
  final VoidCallback onDismissOverlay;
  final VoidCallback onCloseSheet;

  /// When false, the "Save current as filter" button is hidden.
  /// Set to false when the tab is not filterable (e.g. no [searchScope]).
  final bool showSaveFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.spacing;
    final theme = Theme.of(context);
    // Ensure repo filter counts are pushed when popup is open for repo scope.
    switch (scope) {
      case RepoIssuesScope(repo: final repoRef):
      case RepoPullsScope(repo: final repoRef):
        ref.watch(repoFilterCountsProvider(repoRef));
        break;
      default:
        break;
    }
    final quickCounts = ref.watch(quickFilterCountsProvider(scope));
    final customCounts = ref.watch(customFilterCountsProvider(scope));
    final customFilters = ref
        .read(customFiltersNotifierProvider.notifier)
        .forScope(scope);
    final searchState = ref.watch(searchStateNotifierProvider(scope));

    return Padding(
      padding: spacing.sheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$positionLabel filters',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacing.itemSpacing),
          ...scope.quickFilters.map((QuickFilter filter) {
            final count = quickCounts[filter.aliasKeyForScope(scope)];
            final isActive = searchState.activeQuickFilter == filter;
            return _FilterRow(
              label: filter.displayLabel,
              count: count,
              isActive: isActive,
              onTap: () {
                if (currentIndex != tabIndex) onSelectIndex();
                ref
                    .read(searchStateNotifierProvider(scope).notifier)
                    .toggleQuickFilter(filter);
                onCloseSheet();
                onDismissOverlay();
              },
            );
          }),
          if (customFilters.isNotEmpty) ...[
            SizedBox(height: spacing.sectionSpacing),
            Text(
              'Saved filters',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.tightSpacing),
            ...customFilters.map((CustomFilter filter) {
              final count = customCounts[filter.id];
              return _FilterRow(
                label: filter.name,
                count: count,
                isActive: false,
                onTap: () {
                  if (currentIndex != tabIndex) onSelectIndex();
                  ref
                      .read(searchStateNotifierProvider(scope).notifier)
                      .applyCustomFilter(filter);
                  onCloseSheet();
                  onDismissOverlay();
                },
              );
            }),
          ],
          if (showSaveFilter) ...[
            SizedBox(height: spacing.sectionSpacing),
            OutlinedButton.icon(
              onPressed: () async {
                onCloseSheet();
                final created = await AppSheet.form<bool?>(
                  context,
                  header: AppSheetHeader.text('Save filter'),
                  bodyBuilder: (BuildContext ctx, StateSetter setState) =>
                      SaveFilterSheet(
                        scope: scope,
                        initialState: searchState,
                        mode: SaveFilterMode.create,
                      ),
                );
                if (created == true) onDismissOverlay();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Save current as filter…'),
            ),
            SizedBox(height: spacing.tightSpacing),
          ],
          // Filter management feature moved to premium
          // TextButton.icon(
          //   onPressed: () {
          //     onCloseSheet();
          //     onDismissOverlay();
          //     context.router.push(const FilterManagementRoute());
          //   },
          //   icon: const Icon(Icons.tune_rounded, size: 18),
          //   label: const Text('Manage filters'),
          // ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: count != null && count! > 0
          ? buildModernCountBadge(context, count!)
          : null,
      selected: isActive,
      onTap: onTap,
    );
  }
}

/// Mode for [SaveFilterSheet]: create new or edit existing.
enum SaveFilterMode { create, edit }

/// Bottom sheet to name and optionally set repo scope for a saved filter.
class SaveFilterSheet extends ConsumerStatefulWidget {
  const SaveFilterSheet({
    required this.scope,
    required this.initialState,
    required this.mode,
    this.existing,
    super.key,
  });

  final SearchScope scope;
  final SearchState initialState;
  final SaveFilterMode mode;
  final CustomFilter? existing;

  @override
  ConsumerState<SaveFilterSheet> createState() => _SaveFilterSheetState();
}

class _SaveFilterSheetState extends ConsumerState<SaveFilterSheet> {
  late final TextEditingController _nameController;
  bool _repoScope = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _repoScope = widget.existing?.repoScope != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final theme = Theme.of(context);

    return Padding(
      padding: spacing.sheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.mode == SaveFilterMode.edit ? 'Edit filter' : 'Save filter',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacing.itemSpacing),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. My open issues',
            ),
            autofocus: true,
          ),
          SizedBox(height: spacing.itemSpacing),
          Text(
            widget.initialState.displayQuery.isEmpty
                ? 'No qualifiers'
                : widget.initialState.displayQuery,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (scope is RepoIssuesScope || scope is RepoPullsScope) ...[
            SizedBox(height: spacing.itemSpacing),
            CheckboxListTile(
              value: _repoScope,
              onChanged: (v) => setState(() => _repoScope = v ?? false),
              title: const Text('Limit to this repository'),
            ),
          ],
          SizedBox(height: spacing.sectionSpacing),
          FilledButton(
            onPressed: () => _save(context),
            child: Text(widget.mode == SaveFilterMode.edit ? 'Update' : 'Save'),
          ),
        ],
      ),
    );
  }

  SearchScope get scope => widget.scope;

  Future<void> _save(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final notifier = ref.read(customFiltersNotifierProvider.notifier);
    RepoRef? repoScope;
    if (_repoScope && (scope is RepoIssuesScope || scope is RepoPullsScope)) {
      repoScope = switch (scope) {
        RepoIssuesScope(repo: final r) => r,
        RepoPullsScope(repo: final r) => r,
        _ => null,
      };
    }
    try {
      if (widget.mode == SaveFilterMode.edit && widget.existing != null) {
        final updated = CustomFilter(
          id: widget.existing!.id,
          name: name,
          searchType: scope.searchType,
          qualifiers: widget.initialState.activeQualifiers,
          sort: widget.initialState.sort,
          freeText: widget.initialState.freeText.isEmpty
              ? null
              : widget.initialState.freeText,
          repoScope: repoScope,
          createdAt: widget.existing!.createdAt,
        );
        await notifier.updateFilter(updated);
      } else {
        final filter = CustomFilter(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          searchType: scope.searchType,
          qualifiers: widget.initialState.activeQualifiers,
          sort: widget.initialState.sort,
          freeText: widget.initialState.freeText.isEmpty
              ? null
              : widget.initialState.freeText,
          repoScope: repoScope,
          createdAt: DateTime.now(),
        );
        await notifier.save(filter);
      }
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // Handle errors silently in OSS
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving filter: $e')));
      }
    }
  }
}
