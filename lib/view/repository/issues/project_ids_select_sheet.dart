import 'package:diohub/common/bottom_sheet/paginated_select_sheet.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around [PaginatedSelectSheet] for project V2 multi-select.
/// Use inside [AppSheet.scrollable]; pass [scrollController].
class ProjectIdsSelectSheet extends ConsumerWidget {
  const ProjectIdsSelectSheet({
    required this.scrollController,
    required this.repoRef,
    required this.initialSelectedIds,
    required this.onSelected,
    super.key,
  });

  final ScrollController scrollController;
  final RepoRef repoRef;
  final Set<String> initialSelectedIds;
  final void Function(List<String> ids) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginatedSelectSheet<
        ProjectV2PickerEdge?>(
      mode: SelectMode.multi,
      searchable: false,
      initialSelectedIds: initialSelectedIds,
      scrollController: scrollController,
      applyLabel: 'Done',
      sourceBuilder: (_) => CursorForwardSource<
          ProjectV2PickerEdge?>(
        fetch: ({required int first, String? after}) async {
          final apiClient = ref.read(apiClientProvider);
          final r = await repoRef.services(apiClient).listProjectsV2GQL(
            first: first,
            after: after,
          );
          return CursorPage<
              ProjectV2PickerEdge?>(
            items: r.items,
            hasNextPage: r.hasNextPage,
            endCursor: r.endCursor,
          );
        },
      ),
      idOf: (e) => e?.node?.id ?? '',
      titleOf: (e) => e?.node?.title ?? '',
      onApplyMulti:
          (List<ProjectV2PickerEdge?>
              selected) {
        final List<String> ids = selected
            .map((e) => e?.node?.id)
            .whereType<String>()
            .toList()
          ..sort();
        onSelected(ids);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
