import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/search/repo_list_filter_controller.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet to pick a repository from the viewer's repos.
class RepoPickerBottomSheet {
  RepoPickerBottomSheet._();

  /// Shows the sheet. Returns the selected [RepoRef] or null if dismissed.
  static Future<RepoRef?> show(
    BuildContext context,
    String viewerLogin,
  ) async {
    final ValueNotifier<String> queryNotifier = ValueNotifier<String>('');
    final userRef = UserRef(login: viewerLogin);

    return AppSheet.scrollable<RepoRef>(
      context,
      header: AppSheetHeader.text(
        'Select Repository',
        bottom: SheetFilterField(
          queryNotifier: queryNotifier,
          hintText: 'Search repositories...',
        ),
      ),
      bodyBuilder: (
        BuildContext context,
        StateSetter setState,
        ScrollController scrollController,
      ) =>
          _RepoPickerBody(
        userRef: userRef,
        queryNotifier: queryNotifier,
        scrollController: scrollController,
      ),
    );
  }
}

class _RepoPickerBody extends ConsumerStatefulWidget {
  const _RepoPickerBody({
    required this.userRef,
    required this.queryNotifier,
    required this.scrollController,
  });

  final UserRef userRef;
  final ValueNotifier<String> queryNotifier;
  final ScrollController scrollController;

  @override
  ConsumerState<_RepoPickerBody> createState() => _RepoPickerBodyState();
}

class _RepoPickerBodyState extends ConsumerState<_RepoPickerBody> {
  late final RepoListFilterController _filterController;

  @override
  void initState() {
    super.initState();
    _filterController = RepoListFilterController(
      userRef: widget.userRef,
      queryNotifier: widget.queryNotifier,
      ref: ref,
      pageSize: 20,
    );
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _filterController.controller;
    return AppCustomScrollView(
      controller: widget.scrollController,
      slivers: <Widget>[
        PaginatedSliverList<UserRepoEdge>(
          controller: controller,
          itemBuilder: (
            final BuildContext context,
            final UserRepoEdge edge,
            final int index,
          ) {
            final node = edge.node;
            if (node == null) return const SizedBox.shrink();
            final String nameWithOwner =
                node.nameWithOwner ?? '${node.owner.login}/${node.name}';
            final String? description = node.description;
            final bool isPrivate = node.isPrivate;
            final bool isFork = node.isFork;
            final String? langName = node.primaryLanguage?.name;
            final String? langColor = node.primaryLanguage?.color;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TapFeedback(
                  onTap: () {
                    Navigator.of(context)
                        .pop(RepoRef.fromFullName(nameWithOwner));
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacing.screenPadding.left,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                nameWithOwner,
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPrivate)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 14,
                                  color: context
                                      .colorScheme.onSurfaceVariant.secondary,
                                ),
                              ),
                            if (isFork)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.call_split,
                                  size: 14,
                                  color: context
                                      .colorScheme.onSurfaceVariant.secondary,
                                ),
                              ),
                          ],
                        ),
                        if (description != null && description.isNotEmpty) ...[
                          context.spacing.tightGap,
                          Text(
                            description,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context
                                  .colorScheme.onSurfaceVariant.secondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (langName != null) ...[
                          context.spacing.tightGap,
                          Row(
                            children: <Widget>[
                              if (langColor != null)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _parseColor(langColor),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              if (langColor != null) const SizedBox(width: 6),
                              Text(
                                langName,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: context
                                      .colorScheme.onSurfaceVariant.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: context.colorScheme.outline.subtle,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  static Color _parseColor(String hex) {
    return tryParseHexColor(hex, fallback: Colors.grey) ?? Colors.grey;
  }
}
