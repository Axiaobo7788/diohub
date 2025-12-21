import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

class DynamicScroll extends StatefulWidget {
  const DynamicScroll({
    required this.expandedWidget,
    required this.collapsedWidget,
    required this.body,
    this.bottom,
    this.pinnedWidget,
    this.actions,
    super.key,
  });

  final Widget collapsedWidget;
  final Widget expandedWidget;
  final Widget? bottom;
  final Widget? pinnedWidget;
  final Widget body;
  final List<Widget>? actions;

  @override
  State<DynamicScroll> createState() => _DynamicScrollState();
}

class _DynamicScrollState extends State<DynamicScroll> {
  @override
  Widget build(final BuildContext context) => NestedScrollView(
        headerSliverBuilder: (final BuildContext context, final bool value) =>
            <Widget>[
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverSafeArea(
              // bottom: false,
              sliver: MultiSliver(children: <Widget>[
                DynamicSliverAppBar(
                  expanded: _RoundedExpandedWidget(
                    child: widget.expandedWidget,
                  ),
                  collapsed: widget.collapsedWidget,
                ),
                if (widget.pinnedWidget != null)
                  SliverPinnedHeader(
                    child: widget.pinnedWidget!,
                  ),
                if (widget.bottom != null)
                  SliverPinnedHeader(
                    child: widget.bottom!,
                  )
              ], ),
            ),
          ),
        ],
        body: widget.body,
      );
}

// --- DynamicSliverAppBar implementation and helpers ---

class _RoundedExpandedWidget extends StatelessWidget {
  const _RoundedExpandedWidget({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Theme.of(context).colorScheme.surfaceContainer;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: child,
    );
  }
}

class DynamicSliverAppBar extends StatefulWidget {
  const DynamicSliverAppBar({
    required this.expanded,
    required this.collapsed,
    super.key,
    this.pinned = true,
  });

  final Widget expanded;
  final Widget collapsed;
  final bool pinned;

  @override
  State<DynamicSliverAppBar> createState() => _DynamicSliverAppBarState();
}

class _DynamicSliverAppBarState extends State<DynamicSliverAppBar> {
  double? _expandedHeight;

  @override
  Widget build(BuildContext context) {
    if (_expandedHeight == null) {
      return SliverToBoxAdapter(
        child: Offstage(
          child: MeasureSize(
            onChange: (size) {
              setState(() {
                _expandedHeight = size.height;
              });
            },
            child: widget.expanded,
          ),
        ),
      );
    }

    return SliverPersistentHeader(
      pinned: widget.pinned,
      delegate: _DynamicSliverAppBarDelegate(
        expandedHeight: _expandedHeight!,
        expanded: widget.expanded,
        collapsed: widget.collapsed,
      ),
    );
  }
}

class _DynamicSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _DynamicSliverAppBarDelegate({
    required this.expandedHeight,
    required this.expanded,
    required this.collapsed,
  });

  final double expandedHeight;
  final Widget expanded;
  final Widget collapsed;

  @override
  double get minExtent => kToolbarHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double range = maxExtent - minExtent;
    final double t = range == 0 ? 1 : (shrinkOffset / range).clamp(0.0, 1.0);

    final bool canPop = Navigator.canPop(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (t < 0.95)
          IgnorePointer(
            child: ClipRect(
              child: Opacity(
                opacity: 1 - t,
                child: expanded,
              ),
            ),
          ),
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: minExtent,
            child: Material(
              color: Colors.transparent,
              child: Opacity(
                opacity: t,
                child: canPop
                    ? Row(
                        children: [
                          SafeArea(
                            child: BackButton(),
                          ),
                          Expanded(
                            child: collapsed,
                          ),
                        ],
                      )
                    : collapsed,
              ),
            ),
          ),
        ),
        if (canPop && t < 0.95)
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: BackButton(),
            ),
          ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _DynamicSliverAppBarDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        expanded != oldDelegate.expanded ||
        collapsed != oldDelegate.collapsed;
  }
}

class MeasureSize extends StatefulWidget {
  const MeasureSize({
    required this.child,
    required this.onChange,
    super.key,
  });

  final Widget child;
  final ValueChanged<Size> onChange;

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        final newSize = box.size;
        if (_oldSize != newSize) {
          _oldSize = newSize;
          widget.onChange(newSize);
        }
      }
    });

    return widget.child;
  }
}
