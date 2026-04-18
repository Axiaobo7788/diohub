part of 'bottom_sheets.dart';

/// Scrollable sheet body: [AppCustomScrollView] with [scrollController] and
/// [slivers]. Use from [AppSheet.scrollable] bodyBuilder when the body is
/// a single scroll view (e.g. [PaginatedSliverList]).
class SheetScrollBody extends StatelessWidget {
  const SheetScrollBody({
    required this.scrollController,
    required this.slivers,
    super.key,
  });

  final ScrollController scrollController;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) => AppCustomScrollView(
        controller: scrollController,
        slivers: slivers,
      );
}

class SheetBodyList extends StatelessWidget {
  const SheetBodyList({
    required this.children,
    super.key,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });
  final EdgeInsets itemPadding;
  final List<Widget> children;
  @override
  Widget build(final BuildContext context) => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemBuilder: (final BuildContext context, final int index) => Padding(
          padding: itemPadding,
          child: children[index],
        ),
        separatorBuilder: (final BuildContext context, final int index) =>
            Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: context.colorScheme.outline.subtle,
        ),
        itemCount: children.length,
      );
}

typedef ScrollBuilder = Widget Function(
  BuildContext context,
  void Function(void Function()) setState,
  ScrollController scrollController,
);
