import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reusable body for [AppSheet.scrollable]: paginated list with optional
/// trailing widget (e.g. an "Add" form). Use as the [bodyBuilder] child.
///
/// [createController] is invoked once in [initState]; the controller is
/// disposed when the widget is disposed. [trailingBuilder] receives
/// [VoidCallback refresh] so the trailing widget can refetch after adding.
///
/// Example (sub-flow of existing sheet infra):
/// ```dart
/// await AppSheet.scrollable<void>(
///   context,
///   header: AppSheetHeader.text('Deploy Keys'),
///   bodyBuilder: (ctx, setState, scrollController) =>
///       PaginatedListSheetBody<DeployKeyItem>(
///     scrollController: scrollController,
///     createController: () => PaginationController(...),
///     itemBuilder: (context, ref, item, index, applyPatch) => ...,
///     emptyBuilder: (context) => Text('No deploy keys yet'),
///     trailingBuilder: (refresh) => _AddDeployKeyForm(onAdded: refresh),
///   ),
/// );
/// ```
class PaginatedListSheetBody<T> extends ConsumerStatefulWidget {
  const PaginatedListSheetBody({
    required this.scrollController,
    required this.createController,
    required this.itemBuilder,
    this.emptyBuilder,
    this.trailingBuilder,
    super.key,
  });

  final ScrollController scrollController;
  final PaginationController<T, T> Function() createController;

  /// [applyPatch] can be used to remove or update an item (e.g. after delete).
  final Widget Function(
    BuildContext context,
    WidgetRef ref,
    T item,
    int index,
    void Function(ItemPatch patch) applyPatch,
  ) itemBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Optional trailing widget builder; receives [VoidCallback refresh].
  final Widget Function(VoidCallback refresh)? trailingBuilder;

  @override
  ConsumerState<PaginatedListSheetBody<T>> createState() =>
      _PaginatedListSheetBodyState<T>();
}

class _PaginatedListSheetBodyState<T>
    extends ConsumerState<PaginatedListSheetBody<T>> {
  late final PaginationController<T, T> _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.createController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    final scrollBody = SheetScrollBody(
      scrollController: widget.scrollController,
      slivers: [
        SliverPadding(
          padding: spacing.sheetPadding,
          sliver: PaginatedSliverList<T>(
            controller: _controller,
            itemBuilder: (BuildContext context, T item, int index) =>
                widget.itemBuilder(
              context,
              ref,
              item,
              index,
              _controller.applyPatch,
            ),
            emptyBuilder: widget.emptyBuilder,
          ),
        ),
      ],
    );

    if (widget.trailingBuilder == null) return scrollBody;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(child: scrollBody),
        Padding(
          padding: spacing.sheetPadding,
          child: widget.trailingBuilder!(_controller.refresh),
        ),
      ],
    );
  }
}
