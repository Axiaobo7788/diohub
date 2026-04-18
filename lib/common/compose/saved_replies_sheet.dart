import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Saved replies bottom sheet using the app's [AppSheet.scrollable] flow.
/// Use [SavedRepliesSheet.show] to present; returns the selected reply body or null.
class SavedRepliesSheet {
  SavedRepliesSheet._();

  /// Shows the app bottom sheet for saved replies.
  /// Returns the selected reply body, or null if dismissed without selection.
  static Future<String?> show(BuildContext context) {
    return AppSheet.scrollable<String?>(
      context,
      header: AppSheetHeader.text('Saved Replies'),
      bodyBuilder: (
        BuildContext ctx,
        StateSetter setState,
        ScrollController scrollController,
      ) =>
          _SavedRepliesSheetBody(scrollController: scrollController),
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
    );
  }
}

/// Body for [AppSheet.scrollable] — cursor-paginated list of saved replies.
/// Tapping an item pops with that reply's body.
class _SavedRepliesSheetBody extends ConsumerStatefulWidget {
  const _SavedRepliesSheetBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<_SavedRepliesSheetBody> createState() =>
      _SavedRepliesSheetBodyState();
}

class _SavedRepliesSheetBodyState
    extends ConsumerState<_SavedRepliesSheetBody> {
  static const int _pageSize = 20;

  late final PaginationController<
      SavedReplyEdge?,
      SavedReplyEdge?> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaginationController<
        SavedReplyEdge?,
        SavedReplyEdge?>(
      source:
          CursorForwardSource<SavedReplyEdge?>(
        fetch: ({required int first, String? after}) async {
          return ref.read(userInfoServiceProvider).getSavedReplies(
                first: first,
                after: after,
              );
        },
      ),
      idOf: (e) => e?.cursor ?? '',
      pageSize: _pageSize,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return SheetScrollBody(
      scrollController: widget.scrollController,
      slivers: [
        SliverPadding(
          padding: spacing.sheetPadding,
          sliver: PaginatedSliverList<
              SavedReplyEdge?>(
            controller: _controller,
            itemBuilder: (
              BuildContext context,
              SavedReplyEdge? edge,
              int index,
            ) {
              final reply = edge?.node;
              if (reply == null) return const SizedBox.shrink();
              return ListTile(
                title: Text(reply.title),
                subtitle: Text(
                  reply.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(context).pop(reply.body),
              );
            },
            emptyBuilder: (ctx) => Center(
              child: Padding(
                padding: spacing.pagePadding,
                child: Text(
                  'No saved replies yet.\nCreate them in GitHub Settings → Saved replies.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
