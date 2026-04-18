import 'package:diohub/common/misc/changed_files_list_card.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pull_file_edge_mapping.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class PullChangedFilesList extends ConsumerStatefulWidget {
  const PullChangedFilesList({
    required this.pullRef,
    super.key,
  });

  final PullRequestRef pullRef;

  @override
  ConsumerState<PullChangedFilesList> createState() => _PullChangedFilesListState();
}

class _PullChangedFilesListState extends ConsumerState<PullChangedFilesList> {
  late final PaginationController<
      PullFileEdge?,
      PullFileEdge> _controller;

  @override
  void initState() {
    super.initState();
    final apiClient = ref.read(apiClientProvider);
    final pullsService = widget.pullRef.services(apiClient);
    _controller = PaginationController<
        PullFileEdge?,
        PullFileEdge>(
      source: CursorForwardSource<
          PullFileEdge?>(
        fetch: ({required int first, String? after}) async {
          final r = await pullsService.getPullFilesGQLPage(
            first: first,
            after: after,
          );
          return CursorPage<PullFileEdge?>(
            items: r.items,
            hasNextPage: r.hasNextPage,
            endCursor: r.endCursor,
          );
        },
      ),
      idOf: (e) => e.cursor,
      transform: (raw) => raw
          .whereType<PullFileEdge>()
          .toList(),
      pageSize: 20,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return MultiSliver(
      children: <Widget>[
        PaginatedSliverList<PullFileEdge>(
          controller: _controller,
          itemBuilder: (
            final BuildContext context,
            final PullFileEdge edge,
            final int index,
          ) {
            final FileElement file = fileFromPullFileEdge(edge);
            return Padding(
              padding: EdgeInsets.only(
                bottom: context.spacing.sectionSpacing,
              ),
              child: ChangedFilesListCard(file),
            );
          },
        ),
      ],
    );
  }
}
