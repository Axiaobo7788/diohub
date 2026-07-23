import 'package:diohub/common/bottom_sheet/paginated_select_sheet.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper around [PaginatedSelectSheet] for single branch selection.
class BranchSelectSheet extends ConsumerWidget {
  const BranchSelectSheet(
    this.repoRef, {
    this.defaultBranch,
    this.currentBranch,
    this.onSelected,
    this.controller,
    super.key,
  });

  final RepoRef repoRef;
  final String? defaultBranch;
  final String? currentBranch;
  final ValueChanged<String>? onSelected;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginatedSelectSheet<BranchEdge>(
      mode: SelectMode.single,
      searchable: true,
      searchHint: context.l10n.repoSearchBranches,
      scrollController: controller,
      sourceBuilder: (String? query) => CursorForwardSource<BranchEdge>(
        fetch: ({required int first, String? after}) async {
          final apiClient = ref.read(apiClientProvider);
          final r = await repoRef
              .branches(apiClient)
              .fetchBranchesPaginated(first: first, after: after, query: query);
          return CursorPage<BranchEdge>(
            items: r.items,
            hasNextPage: r.hasNextPage,
            endCursor: r.endCursor,
          );
        },
      ),
      idOf: (e) => e.node?.name ?? '',
      titleOf: (e) => e.node?.name ?? '',
      subtitleOf: (e) {
        final String name = e.node?.name ?? '';
        if (name.isEmpty) return null;
        final List<String> parts = <String>[];
        if (name == defaultBranch) parts.add(context.l10n.repoDefault);
        if (name == currentBranch) parts.add(context.l10n.repoCurrent);
        return parts.isEmpty ? null : parts.join(' · ');
      },
      onSelectSingle: (BranchEdge item) {
        final String name = item.node?.name ?? '';
        onSelected?.call(name);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
