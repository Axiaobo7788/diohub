import 'package:diohub/common/bottom_sheet/paginated_select_sheet.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
/// Thin wrapper around [PaginatedSelectSheet] for single milestone selection.
/// Use inside [AppSheet.scrollable] bodyBuilder; pass [scrollController].
/// Calls [onSelected] with the milestone node ID, or null for "No milestone".
class MilestoneSelectSheet extends ConsumerWidget {
  const MilestoneSelectSheet({
    required this.scrollController,
    required this.repoRef,
    required this.onSelected,
    super.key,
    this.initialMilestoneId,
  });

  final ScrollController scrollController;
  final RepoRef repoRef;
  final String? initialMilestoneId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> initialIds =
        initialMilestoneId != null ? <String>{initialMilestoneId!} : <String>{};
    final apiClient = ref.read(apiClientProvider);

    return PaginatedSelectSheet<
        MilestoneEdge?>(
      mode: SelectMode.single,
      searchable: false,
      initialSelectedIds: initialIds,
      scrollController: scrollController,
      headerWidget: ListTile(
        title: const Text('No milestone'),
        selected: initialMilestoneId == null,
        onTap: () {
          onSelected(null);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
      sourceBuilder: (_) => CursorForwardSource<
          MilestoneEdge?>(
        fetch: ({required int first, String? after}) async {
          final r = await repoRef.labelsAndMilestones(apiClient).listMilestonesGQL(
            first: first,
            after: after,
            states: <MilestoneState>[MilestoneState.OPEN],
          );
          return CursorPage<
              MilestoneEdge?>(
            items: r.items,
            hasNextPage: r.hasNextPage,
            endCursor: r.endCursor,
          );
        },
      ),
      idOf: (e) => e?.node?.id ?? '',
      titleOf: (e) => e?.node?.title ?? '',
      subtitleOf: (e) {
        final d = e?.node?.description;
        return (d != null && d.isNotEmpty) ? d : null;
      },
      onSelectSingle:
          (MilestoneEdge? item) {
        final String? id = item?.node?.id;
        onSelected(id);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
