import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/bottom_sheet/paginated_select_sheet.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/filter_localizations.dart';
import 'package:diohub/common/search_overlay/search_filter_helpers.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/models/search/search_state.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterPaginatedPicker extends ConsumerWidget {
  const FilterPaginatedPicker({
    required this.scope,
    required this.section,
    required this.repoRef,
    required this.state,
    required this.notifier,
    super.key,
  });

  final SearchScope scope;
  final PaginatedFilterSection section;
  final RepoRef repoRef;
  final SearchState state;
  final SearchStateNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String key = qualifierKeyForSection(section);
    final List<String> activeValues = state.activeQualifierValues(key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (activeValues.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: activeValues.map((String v) {
              final QualifierExpression? qe = findQualifierExpression(
                state,
                key,
                v,
              );
              return Chip(
                label: Text(v),
                onDeleted: qe != null
                    ? () => notifier.removeQualifier(qe)
                    : null,
              );
            }).toList(),
          ),
        if (activeValues.isNotEmpty)
          SizedBox(height: context.spacing.tightSpacing),
        ActionChip(
          label: Text(
            context.l10n.filterSelect(
              localizedFilterSectionName(context, section),
            ),
          ),
          onPressed: () => _openPaginatedPicker(
            context,
            ref,
            scope,
            section,
            state,
            notifier,
          ),
        ),
      ],
    );
  }

  static Future<void> _openPaginatedPicker(
    BuildContext context,
    WidgetRef ref,
    SearchScope scope,
    PaginatedFilterSection section,
    SearchState state,
    SearchStateNotifier notifier,
  ) async {
    final String key = qualifierKeyForSection(section);
    final Set<String> initialIds = state.activeQualifierValues(key).toSet();

    await AppSheet.scrollable<void>(
      context,
      header: AppSheetHeader.text(localizedFilterSectionName(context, section)),
      bodyBuilder:
          (
            BuildContext ctx,
            StateSetter setState,
            ScrollController scrollController,
          ) {
            return _FilterSheetContent(
              scope: scope,
              sheetContext: ctx,
              section: section,
              initialSelectedIds: initialIds,
              notifier: notifier,
              scrollController: scrollController,
            );
          },
    );
  }
}

class _FilterSheetContent extends ConsumerWidget {
  const _FilterSheetContent({
    required this.scope,
    required this.sheetContext,
    required this.section,
    required this.initialSelectedIds,
    required this.notifier,
    required this.scrollController,
  });

  final SearchScope scope;
  final BuildContext sheetContext;
  final PaginatedFilterSection section;
  final Set<String> initialSelectedIds;
  final SearchStateNotifier notifier;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String key = qualifierKeyForSection(section);
    final SearchState state = ref.watch(searchStateNotifierProvider(scope));
    final RepoRef repoRef = section.repo;

    switch (section.id) {
      case 'label':
        return PaginatedSelectSheet<LabelEdge>(
          mode: SelectMode.multi,
          searchable: true,
          searchHint: localizedFilterSearchHint(context, section),
          applyLabel: context.l10n.filterApply,
          initialSelectedIds: initialSelectedIds,
          scrollController: scrollController,
          sourceBuilder: (String? query) => CursorForwardSource<LabelEdge>(
            fetch: ({required int first, String? after}) async {
              final r = await repoRef
                  .labelsAndMilestones(ref.read(apiClientProvider))
                  .listAvailableLabelsGQL(
                    first: first,
                    after: after,
                    query: query,
                  );
              final List<LabelEdge> items = r.items
                  .whereType<LabelEdge>()
                  .toList();
              return CursorPage<LabelEdge>(
                items: items,
                hasNextPage: r.hasNextPage,
                endCursor: r.endCursor,
              );
            },
          ),
          idOf: (e) => e.node?.name ?? '',
          titleOf: (e) => e.node?.name ?? '',
          onApplyMulti: (List<LabelEdge> selected) {
            removeAllForKey(notifier, state, key);
            for (final LabelEdge e in selected) {
              final String name = e.node?.name ?? '';
              if (name.isEmpty) continue;
              addQualifierFromValue(notifier, state, section, key, name);
            }
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
        );
      case 'assignee':
        return PaginatedSelectSheet<AssignableUserEdge>(
          mode: SelectMode.multi,
          searchable: true,
          searchHint: localizedFilterSearchHint(context, section),
          applyLabel: context.l10n.filterApply,
          initialSelectedIds: initialSelectedIds,
          scrollController: scrollController,
          sourceBuilder: (String? query) =>
              CursorForwardSource<AssignableUserEdge>(
                fetch: ({required int first, String? after}) async {
                  final r = await repoRef
                      .collaborators(ref.read(apiClientProvider))
                      .listAssignableUsersGQL(
                        first: first,
                        after: after,
                        query: query,
                      );
                  final List<AssignableUserEdge> items = r.items
                      .whereType<AssignableUserEdge>()
                      .toList();
                  return CursorPage<AssignableUserEdge>(
                    items: items,
                    hasNextPage: r.hasNextPage,
                    endCursor: r.endCursor,
                  );
                },
              ),
          idOf: (e) => e.node?.login ?? '',
          titleOf: (e) {
            final n = e.node;
            return (n?.name?.isNotEmpty == true) ? n!.name! : (n?.login ?? '');
          },
          onApplyMulti: (List<AssignableUserEdge> selected) {
            removeAllForKey(notifier, state, key);
            for (final AssignableUserEdge e in selected) {
              final String login = e.node?.login ?? '';
              if (login.isEmpty) continue;
              addQualifierFromValue(notifier, state, section, key, login);
            }
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
        );
      case 'milestone':
        return PaginatedSelectSheet<MilestoneEdge?>(
          mode: SelectMode.single,
          searchable: false,
          initialSelectedIds: initialSelectedIds,
          scrollController: scrollController,
          headerWidget: ListTile(
            title: Text(context.l10n.filterNoMilestone),
            onTap: () {
              removeAllForKey(notifier, state, key);
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            },
          ),
          sourceBuilder: (_) => CursorForwardSource<MilestoneEdge?>(
            fetch: ({required int first, String? after}) async {
              final r = await repoRef
                  .labelsAndMilestones(ref.read(apiClientProvider))
                  .listMilestonesGQL(
                    first: first,
                    after: after,
                    states: <MilestoneState>[MilestoneState.OPEN],
                  );
              return CursorPage<MilestoneEdge?>(
                items: r.items,
                hasNextPage: r.hasNextPage,
                endCursor: r.endCursor,
              );
            },
          ),
          idOf: (e) => e?.node?.title ?? '',
          titleOf: (e) => e?.node?.title ?? '',
          onSelectSingle: (MilestoneEdge? item) {
            removeAllForKey(notifier, state, key);
            final String title = item?.node?.title ?? '';
            if (title.isNotEmpty) {
              addQualifierFromValue(notifier, state, section, key, title);
            }
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
        );
      case 'base':
      case 'head':
        return PaginatedSelectSheet<BranchEdge>(
          mode: SelectMode.single,
          searchable: true,
          searchHint: localizedFilterSearchHint(context, section),
          initialSelectedIds: initialSelectedIds,
          scrollController: scrollController,
          sourceBuilder: (String? query) => CursorForwardSource<BranchEdge>(
            fetch: ({required int first, String? after}) async {
              final r = await repoRef
                  .branches(ref.read(apiClientProvider))
                  .fetchBranchesPaginated(
                    first: first,
                    after: after,
                    query: query,
                  );
              final List<BranchEdge> items = r.items;
              return CursorPage<BranchEdge>(
                items: items,
                hasNextPage: r.hasNextPage,
                endCursor: r.endCursor,
              );
            },
          ),
          idOf: (e) => e.node?.name ?? '',
          titleOf: (e) => e.node?.name ?? '',
          onSelectSingle: (BranchEdge item) {
            removeAllForKey(notifier, state, key);
            final String name = item.node?.name ?? '';
            if (name.isNotEmpty) {
              addQualifierFromValue(notifier, state, section, key, name);
            }
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
        );
      default:
        return Center(child: Text(context.l10n.filterUnsupportedPicker));
    }
  }
}
