import 'package:diohub/common/bottom_sheet/paginated_list_sheet.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One linked project item (for display and remove).
class ProjectItemInfo {
  const ProjectItemInfo({
    required this.itemId,
    required this.projectId,
    required this.projectTitle,
  });
  final String itemId;
  final String projectId;
  final String projectTitle;
}

/// Bottom sheet body to add/remove issue or PR from repository projects (V2).
/// Use inside [AppSheet.scrollable]; pass [scrollController].
/// [contentId] is the issue or PR node ID. [initialItems] are currently linked projects.
/// [onAdd] and [onRemove] are called when the user adds or removes a project.
class ProjectSelectSheet extends ConsumerWidget {
  const ProjectSelectSheet({
    super.key,
    required this.scrollController,
    required this.repoRef,
    required this.contentId,
    required this.initialItems,
    required this.onAdd,
    required this.onRemove,
  });

  final ScrollController scrollController;
  final RepoRef repoRef;
  final String contentId;
  final List<ProjectItemInfo> initialItems;

  /// Called when user adds to a project. Pass [projectTitle] and [projectUrl] for optimistic UI.
  final Future<void> Function(String projectId,
      {String? projectTitle, Uri? projectUrl}) onAdd;
  final void Function(String itemId, String projectId) onRemove;

  Set<String> get _linkedProjectIds =>
      initialItems.map((final ProjectItemInfo i) => i.projectId).toSet();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (initialItems.isNotEmpty) ...<Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Linked',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            ...initialItems.map(
              (final ProjectItemInfo item) => ListTile(
                title: Text(item.projectTitle),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    onRemove(item.itemId, item.projectId);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            const Divider(height: 1),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Add to project',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: PaginatedListSheetBody<
                ProjectV2PickerEdge?>(
              scrollController: scrollController,
              createController: () => PaginationController<
                  ProjectV2PickerEdge?,
                  ProjectV2PickerEdge?>(
                source: CursorForwardSource<
                    ProjectV2PickerEdge?>(
                  fetch: ({required int first, String? after}) async {
                    final r = await repoRef.services(ref.read(apiClientProvider))
                        .listProjectsV2GQL(first: first, after: after);
                    return CursorPage<
                        ProjectV2PickerEdge?>(
                      items: r.items,
                      hasNextPage: r.hasNextPage,
                      endCursor: r.endCursor,
                    );
                  },
                ),
                idOf: (e) => e?.cursor ?? '',
                pageSize: 20,
              ),
              itemBuilder: (context, ref, edge, index, applyPatch) {
                final rawNode = edge?.node;
                if (rawNode == null) {
                  return const SizedBox.shrink();
                }
                final node = rawNode;
                final isLinked = _linkedProjectIds.contains(node.id);
                return ListTile(
                  title: Text(node.title),
                  subtitle: node.closed
                      ? const Text('Closed', style: TextStyle(fontSize: 12))
                      : null,
                  enabled: !isLinked,
                  onTap: isLinked
                      ? null
                      : () async {
                          await onAdd(node.id,
                              projectTitle: node.title, projectUrl: node.url);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                );
              },
              emptyBuilder: (context) => Padding(
                padding: context.spacing.spaciousPadding,
                child: const EmptyState(message: 'No projects'),
              ),
              trailingBuilder: (_) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Button(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
