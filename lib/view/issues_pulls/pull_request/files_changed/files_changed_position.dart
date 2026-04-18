import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/changed_files_list_card.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/pagination/pagination_phase.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/common/popup/show_popup_menu.dart';
import 'package:diohub/common/pull_file_edge_mapping.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Returns slivers for the "Files Changed" position (for use with [SliverBuilderBody]).
List<Widget> buildFilesChangedSlivers(
  final BuildContext context,
  final WidgetRef ref,
  final PullRequestRef pullRef,
) {
  final controller = ref.watch(pullFilesFullListControllerProvider(pullRef));
  final FilesChangedSortOrder sortOrder =
      ref.watch(pullFilesSortOrderProvider(pullRef));

  return <Widget>[
    ValueListenableBuilder<
        PaginationState<PullFileEdge?>>(
      valueListenable: controller.state,
      builder: (final BuildContext context,
          final PaginationState<PullFileEdge?> state,
          final _) {
        final List<PullFileEdge> nonNull =
            state.items
                .whereType<PullFileEdge>()
                .toList();
        final List<PullFileEdge> sorted =
            FilesChangedPosition._sorted(nonNull, sortOrder);

        if (state.phase is LoadingForward && sorted.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: ListLoadingShimmers.commitList(context),
          );
        }
        if (state.phase is Failed) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                (state.phase as Failed).error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          );
        }
        if (sorted.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No changed files',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        }
        final AppSpacing spacing = context.spacing;
        return SliverPadding(
          padding: spacing.pagePadding,
          sliver: SliverList.separated(
            itemCount: sorted.length,
            separatorBuilder: (final _, final __) =>
                SizedBox(height: spacing.sectionSpacing),
            itemBuilder: (final _, final int i) {
              final PullFileEdge edge =
                  sorted[i];
              final FileElement file = fileFromPullFileEdge(edge);
              return ChangedFilesListCard(
                file,
                onViewChanges: (final BuildContext ctx, final FileElement f) {
                  AutoRouter.of(ctx).push(
                    FileDiffRoute(pullRef: pullRef, path: f.filename),
                  );
                },
              );
            },
          ),
        );
      },
    ),
  ];
}

/// Body for the "Files Changed" position: GQL-backed file list with sort (path / change type / Δ).
/// Tap opens [FileDiffScreen]. Use [buildFilesChangedSlivers] when inside the shell.
class FilesChangedPosition extends ConsumerWidget {
  const FilesChangedPosition({
    required this.pullRef,
    super.key,
  });

  final PullRequestRef pullRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return MultiSliver(
      children: buildFilesChangedSlivers(context, ref, pullRef),
    );
  }

  static List<PullFileEdge> _sorted(
    final List<PullFileEdge> edges,
    final FilesChangedSortOrder order,
  ) {
    final List<PullFileEdge> list =
        List<PullFileEdge>.from(edges);
    switch (order) {
      case FilesChangedSortOrder.byPath:
        list.sort((final a, final b) =>
            (a.node?.path ?? '').compareTo(b.node?.path ?? ''));
        break;
      case FilesChangedSortOrder.byChangeType:
        list.sort((final a, final b) {
          final String ta = a.node?.changeType.name ?? '';
          final String tb = b.node?.changeType.name ?? '';
          final int c = ta.compareTo(tb);
          if (c != 0) {
            return c;
          }
          return (a.node?.path ?? '').compareTo(b.node?.path ?? '');
        });
        break;
      case FilesChangedSortOrder.byDelta:
        list.sort((final a, final b) {
          final int da = (a.node?.additions ?? 0) + (a.node?.deletions ?? 0);
          final int db = (b.node?.additions ?? 0) + (b.node?.deletions ?? 0);
          if (da != db) {
            return db.compareTo(da);
          }
          return (a.node?.path ?? '').compareTo(b.node?.path ?? '');
        });
        break;
    }
    return list;
  }
}

/// Shows a menu to pick sort order for Files Changed and updates [pullFilesSortOrderProvider].
void showFilesChangedSortMenu(
  final BuildContext context,
  final WidgetRef ref,
  final PullRequestRef pullRef,
) {
  final void Function(FilesChangedSortOrder) setSort =
      (final FilesChangedSortOrder value) {
    ref.read(pullFilesSortOrderProvider(pullRef).notifier).state = value;
  };

  showPopupMenu(
    context,
    actions: <ActionButtonData>[
      MinorActionButton(
        icon: Octicons.file,
        label: 'By path',
        onTapWithDismiss: (final void Function() dismiss) {
          setSort(FilesChangedSortOrder.byPath);
          dismiss();
        },
      ),
      MinorActionButton(
        icon: Octicons.diff,
        label: 'By change type',
        onTapWithDismiss: (final void Function() dismiss) {
          setSort(FilesChangedSortOrder.byChangeType);
          dismiss();
        },
      ),
      MinorActionButton(
        icon: Octicons.graph,
        label: 'By Δ size',
        onTapWithDismiss: (final void Function() dismiss) {
          setSort(FilesChangedSortOrder.byDelta);
          dismiss();
        },
      ),
    ],
  );
}
