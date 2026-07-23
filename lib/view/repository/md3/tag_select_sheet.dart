import 'package:diohub/common/bottom_sheet/paginated_select_sheet.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Material tag picker backed by the existing repository branch service.
class TagSelectSheet extends ConsumerWidget {
  const TagSelectSheet(
    this.repoRef, {
    this.currentTag,
    this.onSelected,
    super.key,
  });

  final RepoRef repoRef;
  final String? currentTag;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return PaginatedSelectSheet<TagEdge>(
      mode: SelectMode.single,
      searchable: true,
      searchHint: context.l10n.repoSearchTags,
      sourceBuilder: (final String? query) => CursorForwardSource<TagEdge>(
        fetch: ({required final int first, final String? after}) async {
          final result = await repoRef
              .branches(ref.read(apiClientProvider))
              .fetchTagsPaginated(first: first, after: after, query: query);
          return CursorPage<TagEdge>(
            items: result.items,
            hasNextPage: result.hasNextPage,
            endCursor: result.endCursor,
          );
        },
      ),
      idOf: (final TagEdge edge) => edge.node?.name ?? '',
      titleOf: (final TagEdge edge) => edge.node?.name ?? '',
      subtitleOf: (final TagEdge edge) {
        final String name = edge.node?.name ?? '';
        return name == currentTag ? context.l10n.repoCurrent : null;
      },
      onSelectSingle: (final TagEdge edge) {
        final String name = edge.node?.name ?? '';
        if (name.isNotEmpty) {
          onSelected?.call(name);
        }
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
