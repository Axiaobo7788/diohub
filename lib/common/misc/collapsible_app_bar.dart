import 'dart:ui';

import 'package:diohub/common/misc/scroll_dynamic_elevation.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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
    this.headerSlivers,
    this.body,
    // this.bottom,
    this.actions,
    super.key,
    this.bodyBuilder,
  });

  final Widget collapsedWidget;
  final Widget expandedWidget;
  final List<Widget>? headerSlivers;
  // final Widget? bottom;
  final Widget? body;
  final WidgetBuilder? bodyBuilder;
  final List<Widget>? actions;

  @override
  State<DynamicScroll> createState() => _DynamicScrollState();
}

class _DynamicScrollState extends State<DynamicScroll>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _overscrollController;
  double _targetOverscroll = 0.0;

  @override
  void initState() {
    super.initState();
    _overscrollController = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 200,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _overscrollController.dispose();
    super.dispose();
  }

  void _animateToOverscroll(final double target) {
    final double clampedTarget =
        target.clamp(0.0, _overscrollController.upperBound);
    if ((_targetOverscroll - clampedTarget).abs() < 0.1 &&
        (_overscrollController.value - clampedTarget).abs() < 0.1) {
      return;
    }

    _targetOverscroll = clampedTarget;
    _overscrollController.stop();

    if (clampedTarget == 0.0) {
      // Spring animation only on release for smooth snap-back
      _overscrollController.animateWith(
        SpringSimulation(
          const SpringDescription(
            mass: 1,
            stiffness: 280,
            damping: 20,
          ),
          _overscrollController.value,
          0.0,
          0.0,
        ),
      );
    } else {
      // During pull: set value immediately for responsive following
      _overscrollController.value = clampedTarget;
    }
  }

  bool _handleScrollNotification(final ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final ScrollMetrics metrics = notification.metrics;

      if (metrics.pixels < 0) {
        _animateToOverscroll(-metrics.pixels);
      } else if (_overscrollController.value > 0 && metrics.pixels >= 0) {
        _animateToOverscroll(0.0);
      }
    }
    return false;
  }

  @override
  Widget build(final BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (final BuildContext context, final bool value) =>
            <Widget>[
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: MultiSliver(
              children: <Widget>[
                AnimatedBuilder(
                  animation: _overscrollController,
                  builder: (context, _) => DynamicSliverAppBar(
                    scrollController: _scrollController,
                    overscrollAmount: _overscrollController.value,
                    expanded: widget.expandedWidget,
                    collapsed: widget.collapsedWidget,
                  ),
                ),
                if (widget.headerSlivers != null) ...widget.headerSlivers!,
              ],
            ),
          ),
        ],
        body: Builder(
          builder: (final BuildContext context) =>
              widget.bodyBuilder?.call(context) ??
              widget.body ??
              const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// --- DynamicSliverAppBar implementation and helpers ---

class _RoundedExpandedWidget extends StatelessWidget {
  const _RoundedExpandedWidget({
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 8),
    this.borderRadius,
    this.overscrollHeight = 0.0,
    this.showBackButton = false,
    this.backButtonOpacity = 1.0,
  });

  final Widget child;
  final EdgeInsets margin;
  final BorderRadius? borderRadius;
  final double overscrollHeight;
  final bool showBackButton;
  final double backButtonOpacity;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color backgroundColor = colorScheme.surfaceContainer;
    final BorderRadius resolvedBorderRadius = borderRadius ??
        Theme.of(context)
            .surfaceStyle
            .borderRadius(size: BorderRadiusSize.veryLarge);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double containerHeight = constraints.maxHeight;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          height: containerHeight,
          margin: margin,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: resolvedBorderRadius,
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.06),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: -1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: resolvedBorderRadius,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: resolvedBorderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    backgroundColor,
                    backgroundColor.withOpacity(0.98),
                  ],
                ),
              ),
              child: showBackButton
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: backButtonOpacity,
                          child: const BackButton(),
                        ),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: child,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: child,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class DynamicSliverAppBar extends StatefulWidget {
  const DynamicSliverAppBar({
    required this.expanded,
    required this.collapsed,
    required this.scrollController,
    required this.overscrollAmount,
    super.key,
    this.pinned = true,
  });

  final Widget expanded;
  final Widget collapsed;
  final ScrollController scrollController;
  final double overscrollAmount;
  final bool pinned;

  @override
  State<DynamicSliverAppBar> createState() => _DynamicSliverAppBarState();
}

class _DynamicSliverAppBarState extends State<DynamicSliverAppBar> {
  double? _expandedHeight;

  @override
  Widget build(BuildContext context) {
    if (_expandedHeight == null) {
      final double statusPadding = MediaQuery.paddingOf(context).top;
      return SliverToBoxAdapter(
        child: Offstage(
          child: MeasureSize(
            onChange: (size) {
              setState(() {
                // size.height already includes statusPadding from the Padding widget
                _expandedHeight = size.height;
              });
            },
            child: Padding(
              padding: EdgeInsets.only(top: statusPadding),
              child: widget.expanded,
            ),
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
        overscrollAmount: widget.overscrollAmount,
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
    this.overscrollAmount = 0.0,
  });

  final double expandedHeight;
  final Widget expanded;
  final Widget collapsed;
  final ScrollController scrollController;
  final double overscrollAmount;

  @override
  double get minExtent => kToolbarHeight;

  /// Calculates max height including overscroll effects to prevent clipping.
  @override
  double get maxExtent {
    final double pullFactor = _calculateOverscrollFactor();
    final double scaleExtra = _calculateOverscrollScaleExtra(pullFactor);
    final double offsetExtra = _calculateOverscrollOffsetExtra();
    final double result = expandedHeight + scaleExtra + offsetExtra + 1;
    return result;
  }

  /// Normalizes overscroll amount to 0.0-1.0 factor, eased and clamped.
  double _calculateOverscrollFactor() {
    const double maxOverscroll = 140.0;
    final double raw = (overscrollAmount / maxOverscroll).clamp(0.0, 1.0);
    return Curves.easeOutQuad.transform(raw);
  }

  /// Extra height needed when widget scales up during overscroll (up to 5%).
  double _calculateOverscrollScaleExtra(final double pullFactor) {
    return expandedHeight * 0.05 * pullFactor;
  }

  /// Extra height needed for downward translation during overscroll (30% of overscroll).
  double _calculateOverscrollOffsetExtra() {
    return overscrollAmount * 0.3;
  }

  /// Accelerated collapse progress (2x) for border radius animations to reach final value at halfway collapse.
  double _calculateSlowCollapseProgress(final double t) {
    return (t * 2.0).clamp(0.0, 1.0);
  }

  /// Calculates top margin offset: 0.0 (default) -> 16.0 (overscroll) -> 0.0 (collapsed).
  double _calculateTopMargin({
    required double collapseProgress,
    required double overscrollFactor,
  }) {
    const double baseTopMargin = 0.0;
    const double overscrollTopMargin = 16.0;

    // Phase 1: Overscroll (when collapseProgress is near 0)
    // Interpolate from baseTopMargin to overscrollTopMargin based on overscrollFactor
    if (collapseProgress < 0.1 && overscrollAmount > 0) {
      return sanitizedLerpDouble(
        baseTopMargin,
        overscrollTopMargin,
        overscrollFactor,
      );
    }

    // Phase 2: Collapse (when scrolling down)
    // Determine starting margin: if we overscrolled, start from overscrollTopMargin, else baseTopMargin
    final double startTopMargin = overscrollAmount > 0 && overscrollFactor > 0.5
        ? overscrollTopMargin
        : baseTopMargin;

    // Interpolate from startTopMargin to baseTopMargin based on collapse progress
    return sanitizedLerpDouble(
      startTopMargin,
      baseTopMargin,
      collapseProgress,
    );
  }

  /// Calculates horizontal margin: 8.0 (default) -> 16.0 (overscroll) -> 0.0 (collapsed).
  double _calculateHorizontalMargin({
    required double collapseProgress,
    required double overscrollFactor,
  }) {
    const double baseMargin = 8.0;
    const double overscrollMargin = 24.0;
    const double collapsedMargin = 0.0;

    // Phase 1: Overscroll (when collapseProgress is near 0)
    // Interpolate from baseMargin to overscrollMargin based on overscrollFactor
    if (collapseProgress < 0.1 && overscrollAmount > 0) {
      final double margin =
          sanitizedLerpDouble(baseMargin, overscrollMargin, overscrollFactor);
      return margin;
    }

    // Phase 2: Collapse (when scrolling down)
    // Determine starting margin: if we overscrolled, start from overscrollMargin, else baseMargin
    final double startMargin = overscrollAmount > 0 && overscrollFactor > 0.5
        ? overscrollMargin
        : baseMargin;

    // Interpolate from startMargin to collapsedMargin based on collapse progress
    return sanitizedLerpDouble(
      startMargin,
      collapsedMargin,
      collapseProgress,
    );
  }

  /// Height increase for stretch effect during overscroll (30% of overscroll + 1px buffer).
  double _calculateOverscrollHeight() {
    return (overscrollAmount * 0.3) + 1;
  }

  /// Interpolates border radius from base to zero using slow collapse progress.
  BorderRadius _calculateCollapsedRadius({
    required BuildContext context,
    required double t,
  }) {
    final double slowCollapseProgress = _calculateSlowCollapseProgress(t);
    final BorderRadius baseRadius = Theme.of(context)
        .surfaceStyle
        .borderRadius(size: BorderRadiusSize.veryLarge);
    return sanitizedLerpBorderRadius(
        baseRadius, BorderRadius.zero, slowCollapseProgress);
  }

  /// Applies overscroll scale effect to border radius (up to 2x when fully pulled).
  BorderRadius _calculateAnimatedRadius({
    required BorderRadius collapsedRadius,
    required double overscrollFactor,
  }) {
    final double easedFactor = Curves.easeOutQuad.transform(overscrollFactor);
    final double overscrollRadiusScale = lerpDouble(1.0, 2.0, easedFactor)!;
    return _scaleBorderRadius(collapsedRadius, overscrollRadiusScale);
  }

  /// Scales all corners of a BorderRadius uniformly by the given factor.
  BorderRadius _scaleBorderRadius(BorderRadius radius, double scale) =>
      BorderRadius.only(
        topLeft: Radius.elliptical(
          radius.topLeft.x * scale,
          radius.topLeft.y * scale,
        ),
        topRight: Radius.elliptical(
          radius.topRight.x * scale,
          radius.topRight.y * scale,
        ),
        bottomLeft: Radius.elliptical(
          radius.bottomLeft.x * scale,
          radius.bottomLeft.y * scale,
        ),
        bottomRight: Radius.elliptical(
          radius.bottomRight.x * scale,
          radius.bottomRight.y * scale,
        ),
      );

  /// Scale factor for pull effect: 1.0 (normal) to 1.05 (5% larger) based on overscroll.
  double _calculatePullScale(final double overscrollFactor) {
    if (overscrollAmount > 0) {
      final double eased = Curves.easeOut.transform(overscrollFactor);
      return lerpDouble(1.0, 1.04, eased)!;
    }
    return 1.0;
  }

  /// Combined scale: collapse reduces to 0.95, multiplied by pull scale (1.0-1.05).
  double _calculateExpandedWidgetScale(final double t, final double pullScale) {
    // Ease the collapse to reduce mid-collapse blur and harshness
    final double eased = Curves.easeInOutCubic.transform(
      (t * 2.0).clamp(0.0, 1.0),
    );
    const double scaleStart = 1.0;
    const double scaleEnd = 0.90;
    return (scaleStart + (scaleEnd - scaleStart) * eased) * pullScale;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double range = maxExtent - minExtent;
    final double t = range == 0 ? 1 : (shrinkOffset / range).clamp(0.0, 1.0);

    final bool canPop = ModalRoute.of(context)?.canPop ?? false;
    final bool isCollapsed = t >= 0.95;
    final double elevation = t * 2.0;
    final double backgroundOpacity = t.clamp(0.0, 1.0);

    // Scale interpolation with easing to reduce blur in fast first half
    final double scale = _calculateExpandedWidgetScale(t, 1.0);

    // Calculate overscroll progress
    final double overscrollFactor = _calculateOverscrollFactor();

    // Calculate margin accounting for overscroll and collapse
    // Accelerate collapse progress (2x) so margin reaches 0 at halfway through collapse
    final double marginCollapseProgress = (t * 2.0).clamp(0.0, 1.0);
    final double horizontalMargin = _calculateHorizontalMargin(
      collapseProgress: marginCollapseProgress,
      overscrollFactor: overscrollFactor,
    );
    final double topMarginOffset = _calculateTopMargin(
      collapseProgress: marginCollapseProgress,
      overscrollFactor: overscrollFactor,
    );

    // Calculate height increase for stretch effect during overscroll
    final double overscrollHeight = _calculateOverscrollHeight();
    final BorderRadius collapsedRadius = _calculateCollapsedRadius(
      context: context,
      t: t,
    );
    final BorderRadius animatedRadius = _calculateAnimatedRadius(
      collapsedRadius: collapsedRadius,
      overscrollFactor: overscrollFactor,
    );

    final double pullScale = _calculatePullScale(overscrollFactor);

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

    final ColorScheme colorScheme = context.colorScheme;
    final Color collapsedBackground = sanitizedLerpColor(
          Colors.transparent,
          colorScheme.surfaceContainer,
          backgroundOpacity,
        ) ??
        colorScheme.surfaceContainer;

    return ScrollDynamicElevation(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (t < 0.95)
            Align(
              alignment: Alignment.topCenter,
              child: Builder(
                builder: (builderContext) {
                  final double builderStatusPadding =
                      MediaQuery.paddingOf(builderContext).top;
                  final double sizedBoxHeight =
                      expandedHeight + overscrollHeight;
                  return SizedBox(
                    height: sizedBoxHeight,
                    child: Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _calculateExpandedWidgetScale(t, pullScale),
                        alignment: Alignment.topCenter,
                        child: _RoundedExpandedWidget(
                          margin: EdgeInsets.fromLTRB(
                            horizontalMargin,
                            builderStatusPadding + topMarginOffset,
                            horizontalMargin,
                            0,
                          ),
                          borderRadius: animatedRadius,
                          overscrollHeight: overscrollHeight,
                          showBackButton: canPop,
                          backButtonOpacity: (1 - t).clamp(0.0, 1.0),
                          child: expanded,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: minExtent,
              child: Material(
                color: Colors.transparent,
                elevation: elevation,
                shadowColor:
                    colorScheme.shadow.withOpacity(0.1 * backgroundOpacity),
                child: Container(
                  decoration: BoxDecoration(
                    color: collapsedBackground,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outline
                            .withOpacity(0.08 * backgroundOpacity),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: SafeArea(
                      bottom: false,
                      child: canPop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Transform.scale(
                                  scale: scale,
                                  alignment: Alignment.center,
                                  child: const BackButton(),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    child: Transform.scale(
                                      scale: scale,
                                      alignment: Alignment.centerLeft,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: collapsedContent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Transform.scale(
                                scale: scale,
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: collapsedContent,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DynamicSliverAppBarDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        expanded != oldDelegate.expanded ||
        collapsed != oldDelegate.collapsed ||
        (overscrollAmount - oldDelegate.overscrollAmount).abs() > 0.1;
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
