import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/widgets/sort_option_row.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Builds one project list item for use with [SliverListBody] (e.g. in repo shell).
/// Caller should wrap the list in [SliverPadding] with [AppSpacing.listInset] and add [AppSpacing.itemSpacing] between items.
Widget buildProjectListItem(BuildContext context, ProjectV2Node project) {
  return _ProjectCard(project: project);
}

/// Paginated list of repository projects (ProjectV2).
class ProjectsTab extends ConsumerStatefulWidget {
  const ProjectsTab({required this.repoRef, super.key});

  final RepoRef repoRef;

  @override
  ConsumerState<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends ConsumerState<ProjectsTab> {
  ProjectV2OrderField _orderField = ProjectV2OrderField.UPDATED_AT;
  late final PaginationController<ProjectV2Edge, ProjectV2Edge>
  _paginationController;

  @override
  void initState() {
    super.initState();
    _paginationController = PaginationController<ProjectV2Edge, ProjectV2Edge>(
      source: CursorForwardSource<ProjectV2Edge>(
        fetch: ({required int first, String? after}) async {
          final apiClient = ref.read(apiClientProvider);
          final PaginatedResult<ProjectV2Edge> result = await widget.repoRef
              .services(apiClient)
              .fetchProjectsPaginated(
                first: first,
                after: after,
                orderBy: _buildOrder(),
                refresh: after == null,
              );
          return CursorPage<ProjectV2Edge>(
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

  ProjectV2Order _buildOrder() => ProjectV2Order(
    direction: _orderField == ProjectV2OrderField.UPDATED_AT
        ? OrderDirection.DESC
        : OrderDirection.ASC,
    field: _orderField,
  );

  @override
  Widget build(final BuildContext context) {
    return MultiSliver(
      children: <Widget>[
        SliverToBoxAdapter(
          child: SortOptionRow<ProjectV2OrderField>(
            icon: Icons.sort_rounded,
            current: _orderField,
            options: const <ProjectV2OrderField>[
              ProjectV2OrderField.UPDATED_AT,
              ProjectV2OrderField.CREATED_AT,
              ProjectV2OrderField.TITLE,
            ],
            labelBuilder: (final ProjectV2OrderField f) =>
                f == ProjectV2OrderField.UPDATED_AT
                ? 'Recently updated'
                : f == ProjectV2OrderField.CREATED_AT
                ? 'Newest first'
                : 'Title',
            onChanged: (final ProjectV2OrderField v) {
              setState(() => _orderField = v);
              _paginationController.refresh();
            },
          ),
        ),
        SliverPadding(
          padding: context.spacing.listInset,
          sliver: PaginatedSliverList<ProjectV2Edge>(
            controller: _paginationController,
            itemBuilder:
                (
                  final BuildContext context,
                  final ProjectV2Edge edge,
                  final int index,
                ) {
                  final ProjectV2Node? node = edge.node;
                  if (node == null) return const SizedBox.shrink();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (index > 0)
                        SizedBox(height: context.spacing.itemSpacing),
                      _ProjectCard(project: node),
                    ],
                  );
                },
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final ProjectV2Node project;

  @override
  Widget build(final BuildContext context) {
    final int itemCount = project.items.totalCount;
    final bool hasItems = itemCount > 0;

    return BorderedContainer(
      onTap: () => launchUrl(project.url),
      padding: context.spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.dashboard_customize_rounded,
                size: 20,
                color: context.colorScheme.primary,
              ),
              context.spacing.itemGap,
              Expanded(
                child: Text(
                  project.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (project.closed)
                Container(
                  padding: context.spacing.badgePadding,
                  decoration: BoxDecoration(
                    color: context.colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Closed',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.outline,
                    ),
                  ),
                ),
            ],
          ),
          if (project.shortDescription != null &&
              project.shortDescription!.isNotEmpty) ...<Widget>[
            context.spacing.compactGap,
            Text(
              project.shortDescription!,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant.secondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          context.spacing.itemGap,
          Row(
            children: <Widget>[
              if (project.creator != null) ...[
                CircleAvatar(
                  radius: 10,
                  backgroundImage: CachedNetworkImageProvider(
                    project.creator!.avatarUrl.toString(),
                  ),
                ),
                context.spacing.compactGap,
              ],
              if (hasItems)
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant.secondary,
                  ),
                ),
              context.spacing.itemGap,
              Text(
                'Updated ${project.updatedAt.toRelativeDate(shorten: false)}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
