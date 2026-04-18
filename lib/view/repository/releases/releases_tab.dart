import 'package:diohub/common/cards/release_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/widgets/sort_option_row.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
// TODO(phase-10): Premium will provide create action via callback
// import 'package:diohub/view/repository/releases/create_release_screen.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds one release list item for use with [SliverListBody] (e.g. in repo shell).
/// Caller should wrap the list in [SliverPadding] with [AppSpacing.listInset] and add [AppSpacing.itemSpacing] between items.
/// Returns a [BorderedContainer]-wrapped [ReleaseCard].
Widget buildReleaseListItem(
  BuildContext context,
  RepoRef repoRef,
  ReleaseNode release,
) {
  return BorderedContainer(
    child: ReleaseCard(repoRef: repoRef, release: release),
  );
}

/// Paginated list of repository releases. Tap opens release assets sheet.
class ReleasesTab extends ConsumerStatefulWidget {
  const ReleasesTab({required this.repoRef, super.key});

  final RepoRef repoRef;

  @override
  ConsumerState<ReleasesTab> createState() => _ReleasesTabState();
}

class _ReleasesTabState extends ConsumerState<ReleasesTab> {
  ReleaseOrderField _releaseOrderField = ReleaseOrderField.CREATED_AT;
  late final PaginationController<ReleaseEdge, ReleaseEdge>
  _paginationController;

  @override
  void initState() {
    super.initState();
    _paginationController = PaginationController<ReleaseEdge, ReleaseEdge>(
      source: CursorForwardSource<ReleaseEdge>(
        fetch: ({required int first, String? after}) async {
          final apiClient = ref.read(apiClientProvider);
          final orderField = _releaseOrderField;
          final orderDirection =
              _releaseOrderField == ReleaseOrderField.CREATED_AT
              ? OrderDirection.DESC
              : OrderDirection.ASC;
          final PaginatedResult<ReleaseEdge> result = await widget.repoRef
              .releases(apiClient)
              .fetchReleasesPaginated(
                first: first,
                after: after,
                orderField: orderField,
                orderDirection: orderDirection,
                refresh: after == null,
              );
          return CursorPage<ReleaseEdge>(
            items: result.items,
            hasNextPage: result.hasNextPage,
            endCursor: result.endCursor,
            totalCount: result.totalCount,
          );
        },
      ),
      idOf: (e) => e.cursor,
      pageSize: 20,
    );
  }

  @override
  void dispose() {
    _paginationController.dispose();
    super.dispose();
  }

  ReleaseOrder _buildOrder() => ReleaseOrder(
    direction: _releaseOrderField == ReleaseOrderField.CREATED_AT
        ? OrderDirection.DESC
        : OrderDirection.ASC,
    field: _releaseOrderField,
  );

  @override
  Widget build(final BuildContext context) {
    final defaultBranch =
        ref
            .watch(repositoryProvider(widget.repoRef))
            .value
            ?.repository
            ?.defaultBranchRef
            ?.name ??
        'main';
    return MultiSliver(
      children: <Widget>[
        SliverToBoxAdapter(
          child: Row(
            children: <Widget>[
              Expanded(
                child: SortOptionRow<ReleaseOrderField>(
                  icon: Icons.sort_rounded,
                  current: _releaseOrderField,
                  options: const <ReleaseOrderField>[
                    ReleaseOrderField.CREATED_AT,
                    ReleaseOrderField.NAME,
                  ],
                  labelBuilder: (final ReleaseOrderField f) =>
                      f == ReleaseOrderField.CREATED_AT
                      ? 'Newest first'
                      : 'Name',
                  onChanged: (final ReleaseOrderField v) {
                    setState(() => _releaseOrderField = v);
                    _paginationController.refresh();
                  },
                ),
              ),
              // TODO(phase-10): Premium will inject create release button via callback
              // IconButton(...)
            ],
          ),
        ),
        SliverPadding(
          padding: context.spacing.listInset,
          sliver: PaginatedSliverList<ReleaseEdge>(
            controller: _paginationController,
            itemBuilder:
                (
                  final BuildContext context,
                  final ReleaseEdge edge,
                  final int index,
                ) {
                  final ReleaseNode? node = edge.node;
                  if (node == null) return const SizedBox.shrink();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (index > 0)
                        SizedBox(height: context.spacing.itemSpacing),
                      BorderedContainer(
                        child: ReleaseCard(
                          repoRef: widget.repoRef,
                          release: node,
                        ),
                      ),
                    ],
                  );
                },
          ),
        ),
      ],
    );
  }
}
