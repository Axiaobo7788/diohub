import 'dart:ui';

import 'package:diohub/common/misc/scroll_dynamic_elevation.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';

class FrostedBackdrop extends StatelessWidget {
  const FrostedBackdrop({
    required this.child,
    this.blurSigma = 22,
    this.opacity = 0.18,
    this.padding,
    this.borderRadius,
    this.showBorder = false,
    super.key,
  });

  final Widget child;
  final double blurSigma;
  final double opacity;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // color: Theme.of(context)
            //     .colorScheme
            //     .surface
            //     .withOpacity(opacity),
            borderRadius: radius,
            border: showBorder
                ? Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 0.6,
                  )
                : null,
          ),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class DynamicScroll extends StatefulWidget {
  const DynamicScroll({
    required this.expandedWidget,
    required this.collapsedWidget,
     this.body,
    this.bottom,
    this.actions,
    super.key, this.bodyBuilder,
  });

  final Widget collapsedWidget;
  final Widget expandedWidget;
  final Widget? bottom;
  final Widget? body;
  final WidgetBuilder? bodyBuilder;
  final List<Widget>? actions;

  @override
  State<DynamicScroll> createState() => _DynamicScrollState();
}

class _DynamicScrollState extends State<DynamicScroll> {
  final ScrollController _scrollController = ScrollController();


  @override
  Widget build(final BuildContext context) => NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (final BuildContext context, final bool value) =>
            <Widget>[
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverSafeArea(
              sliver: MultiSliver(
                children: <Widget>[
                  DynamicSliverAppBar(
                    scrollController: _scrollController,
                    expanded: _RoundedExpandedWidget(
                      child: widget.expandedWidget,
                    ),
                    collapsed: widget.collapsedWidget,
                  ),
                  if (widget.bottom != null)
                    SliverPinnedHeader(
                      child: ScrollDynamicElevation(
                        child: widget.bottom!,
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
        body: Builder(
          builder: (final BuildContext context) => widget.bodyBuilder?.call(context) ?? widget.body ?? const SizedBox.shrink(),
        ),
      );
}

// --- DynamicSliverAppBar implementation and helpers ---

class _RoundedExpandedWidget extends StatelessWidget {
  const _RoundedExpandedWidget({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        Theme.of(context).colorScheme.surfaceContainer;

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
    required this.scrollController,
    super.key,
    this.pinned = true,
  });

  final Widget expanded;
  final Widget collapsed;
  final ScrollController scrollController;
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
        scrollController: widget.scrollController,
      ),
    );
  }
}

class _DynamicSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _DynamicSliverAppBarDelegate({
    required this.expandedHeight,
    required this.expanded,
    required this.collapsed,
    required this.scrollController,
  });

  final double expandedHeight;
  final Widget expanded;
  final Widget collapsed;
  final ScrollController scrollController;

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
    final bool isCollapsed = t >= 0.95;

    void animateToExpanded() {
      if (!scrollController.hasClients) {
        return;
      }

      final ScrollPosition position = scrollController.position;
      if (position.pixels <= 0) {
        return;
      }

      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    final Widget collapsedContent = isCollapsed
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (_) => animateToExpanded(),
            onVerticalDragStart: (_) => animateToExpanded(),
            child: collapsed,
          )
        : collapsed;
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
                child: ColoredBox(
                  color: context.colorScheme.surfaceContainer,
                  child: canPop
                      ? Row(
                          children: [
                            const SafeArea(
                              child: BackButton(),
                            ),
                            Expanded(
                              child: collapsedContent,
                            ),
                          ],
                        )
                      : collapsedContent,
                ),
              ),
            ),
          ),
        ),
        if (canPop && t < 0.95)
          const Positioned(
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
