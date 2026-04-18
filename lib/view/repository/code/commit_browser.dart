import 'dart:async';

import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/misc/list_loading_shimmers.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommitBrowser extends ConsumerStatefulWidget {
  const CommitBrowser({
    this.controller,
    this.currentSHA,
    this.isLocked,
    this.onSelected,
    this.path,
    this.repo,
    this.branchName,
    super.key,
  });

  final ScrollController? controller;
  final String? currentSHA;
  final bool? isLocked;
  final void Function(String sha, String treeOid)? onSelected;
  final String? path;
  final RepoRef? repo;
  final String? branchName;

  @override
  ConsumerState<CommitBrowser> createState() => _CommitBrowserState();
}

class _CommitBrowserState extends ConsumerState<CommitBrowser> {
  bool? isLocked;
  late List<String> path;
  late final PaginationController<CommitEdge,
      CommitEdge> _paginationController;

  @override
  void initState() {
    super.initState();
    path = widget.path!.split('/');
    isLocked = widget.isLocked;
    if (path.first.isEmpty || isLocked!) {
      path = <String>[];
    }
    _paginationController = PaginationController<CommitEdge,
        CommitEdge>(
      source: CursorForwardSource<CommitEdge>(
        fetch: ({required int first, String? after}) async {
          final history = await widget.repo!.services(ref.read(apiClientProvider)).getCommitsListGQL(
            first: first,
            after: after,
            path: path.isEmpty ? null : path.join('/'),
            ref: isLocked!
                ? null
                : (widget.branchName != null
                    ? 'refs/heads/${widget.branchName}'
                    : null),
            oid: isLocked! ? widget.currentSHA : null,
          );
          final edges = history.edges
                  ?.whereType<CommitEdge>()
                  .toList() ??
              <CommitEdge>[];
          final pageInfo = history.pageInfo;
          return CursorPage<CommitEdge>(
            items: edges,
            hasNextPage: pageInfo.hasNextPage,
            endCursor: pageInfo.endCursor,
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

  @override
  Widget build(final BuildContext context) => Padding(
        padding: context.spacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Visibility(
              visible: isLocked!,
              child: Button(
                onTap: () {
                  setState(() {
                    isLocked = false;
                  });
                  unawaited(_paginationController.refresh());
                },
                child: const Text('Load latest commits.'),
              ),
            ),
            Visibility(
              visible: path.isNotEmpty,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    ' Showing history for',
                    style: TextStyle(),
                  ),
                  SizedBox(
                    height: 30,
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: path.length + 1,
                      separatorBuilder:
                          (final BuildContext context, final int index) =>
                              const Center(child: Text(' /')),
                      itemBuilder:
                          (final BuildContext context, final int index) =>
                              TapFeedback(
                        onTap: () {
                          setState(() {
                            if (index == 0) {
                              path = <String>[];
                            } else {
                              path = path.sublist(0, index);
                            }
                          });
                          unawaited(_paginationController.refresh());
                        },
                        child: Center(
                          child: Text(
                            ' ${index == 0 ? widget.repo!.name : path[index - 1]}',
                            style: TextStyle(
                              color: index == path.length
                                  ? context.colorScheme.primary
                                  : context.colorScheme.onSurface,
                              fontWeight: index == path.length
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                ],
              ),
            ),
            Expanded(
              child: AppCustomScrollView(
                controller: widget.controller,
                slivers: <Widget>[
                  PaginatedSliverList<CommitEdge>(
                    controller: _paginationController,
                    loadingBuilder: (final BuildContext context) =>
                        ListLoadingShimmers.commitList(context),
                    itemBuilder: (
                      final BuildContext context,
                      final CommitEdge edge,
                      final int index,
                    ) {
                      final CommitNode? node =
                          edge.node;
                      if (node == null) return const SizedBox.shrink();
                      final RepoRef repo = widget.repo!;
                      final String treeOid = node.tree.oid;
                      final CommitListItemModel model =
                          CommitListItemModel.fromGcommitListItem(node, repo);
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: context.spacing.sectionSpacing,
                        ),
                        child: BorderedContainer(
                          ref: CommitRef(repo: repo, oid: model.sha),
                          child: InkWell(
                            onTap: () {
                              widget.onSelected!(model.sha, treeOid);
                              Navigator.pop(context);
                            },
                            child: CommitCard(
                              data: model,
                              highlighted:
                                  isLocked! && widget.currentSHA == model.sha,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
