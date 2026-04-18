import 'dart:async';

import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub_models/models/pagination/unfinished_list.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_stack/image_stack.dart';

class AssigneeInfoCard extends ConsumerWidget {
  const AssigneeInfoCard({
    required this.availableList,
    required this.titleBuilder,
    required this.fetchActorsList,
    this.onTap,
    this.trailing,
    super.key,
  });

  final UnfinishedList<NodeWithPaginationInfo<Actor>> availableList;
  final String Function(
    UnfinishedList<NodeWithPaginationInfo<Actor>> availableList,
  ) titleBuilder;

  /// Fetches a page of assignees. [pageSize] is the requested count;
  /// [afterItem] is the last item of the previous page (cursor-based).
  final Future<List<NodeWithPaginationInfo<Actor>>> Function({
    required int pageSize,
    NodeWithPaginationInfo<Actor>? afterItem,
  }) fetchActorsList;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final spacing = context.spacing;
    final theme = Theme.of(context);
    return BorderedContainer(
      onTap: availableList.limitedAvailableList.isEmpty
          ? null
          : () async {
              if (availableList.totalCount > 1) {
                await AppSheet.scrollable<void>(
                  context,
                  header: AppSheetHeader.text(titleBuilder.call(availableList)),
                  bodyBuilder: (
                    final BuildContext context,
                    final StateSetter setState,
                    final ScrollController scrollController,
                  ) =>
                      _AssigneesSheetBody(
                    scrollController: scrollController,
                    fetchActorsList: fetchActorsList,
                  ),
                );
              } else {
                unawaited(
                  UserRef(
                    login: availableList.limitedAvailableList.first.node.login,
                  ).navigate(context, ref),
                );
              }
            },
      padding: spacing.cardContentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                titleBuilder.call(availableList),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (_getIcon(availableList.totalCount) != null)
                _getIcon(availableList.totalCount)!,
            ],
          ),
          SizedBox(height: spacing.tightSpacing),
          _buildChild(context),
        ],
      ),
    );
  }

  Widget _buildChild(BuildContext context) =>
      switch (availableList.totalCount) {
        0 => Text(
            'None assigned',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        1 => ProfileTile.login(
            padding: const EdgeInsets.all(4),
            avatarUrl: availableList.limitedAvailableList.first.node.avatarUrl
                .toString(),
            userLogin: availableList.limitedAvailableList.first.node.login,
            disableTap: true,
          ),
        _ => ImageStack.widgets(
            totalCount: availableList.totalCount,
            widgetBorderColor: Colors.transparent,
            widgetBorderWidth: 0,
            children: availableList.limitedAvailableList
                .map(
                  (final NodeWithPaginationInfo<Actor> e) => ProfileTile.avatar(
                    avatarUrl: e.node.avatarUrl.toString(),
                    padding: EdgeInsets.zero,
                  ),
                )
                .toList(),
          ),
      };
}

class _AssigneesSheetBody extends StatefulWidget {
  const _AssigneesSheetBody({
    required this.scrollController,
    required this.fetchActorsList,
  });

  final ScrollController scrollController;
  final Future<List<NodeWithPaginationInfo<Actor>>> Function({
    required int pageSize,
    NodeWithPaginationInfo<Actor>? afterItem,
  }) fetchActorsList;

  @override
  State<_AssigneesSheetBody> createState() => _AssigneesSheetBodyState();
}

class _AssigneesSheetBodyState extends State<_AssigneesSheetBody> {
  NodeWithPaginationInfo<Actor>? _lastItem;
  late final PaginationController<NodeWithPaginationInfo<Actor>,
      NodeWithPaginationInfo<Actor>> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaginationController<NodeWithPaginationInfo<Actor>,
        NodeWithPaginationInfo<Actor>>(
      source: SliceForwardSource<NodeWithPaginationInfo<Actor>>(
        fetch: (final int count) async {
          final data = await widget.fetchActorsList(
            pageSize: count,
            afterItem: _lastItem,
          );
          if (data.isNotEmpty) {
            _lastItem = data.last;
          }
          return PageSlice<NodeWithPaginationInfo<Actor>>(
            items: data,
            hasNextPage: data.length >= count,
          );
        },
        resetState: () {
          _lastItem = null;
        },
      ),
      idOf: (final NodeWithPaginationInfo<Actor> e) => e.cursor,
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
    return AppCustomScrollView(
      controller: widget.scrollController,
      slivers: <Widget>[
        PaginatedSliverList<NodeWithPaginationInfo<Actor>>(
          controller: _controller,
          itemBuilder: (
            final BuildContext context,
            final NodeWithPaginationInfo<Actor> item,
            final int index,
          ) {
            return Padding(
              padding: context.spacing.listInset,
              child: BorderedContainer(
                backgroundColor: context.colorScheme.surface,
                padding: EdgeInsets.zero,
                child: ProfileTile.login(
                  avatarUrl: item.node.avatarUrl.toString(),
                  userLogin: item.node.login,
                  wrapperBuilder: (final Widget child) => Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            left: context.spacing.sectionSpacing),
                        child: Text(
                          '${index + 1}',
                          style: context.textTheme.bodySmall,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(context.spacing.itemSpacing),
                        child: child,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

Icon? _getIcon(final int listLength) => switch (listLength) {
      0 => null,
      1 => Icon(Icons.adaptive.arrow_forward_rounded),
      _ => const Icon(
          Icons.arrow_drop_down_rounded,
        ),
    };
