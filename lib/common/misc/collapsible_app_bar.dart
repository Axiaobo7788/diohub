import 'dart:ui';

import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/auto_sized_sliver_persistent_header.dart';
import 'package:diohub/common/misc/collapse_layout.dart';
import 'package:diohub/common/misc/glass_pill_constants.dart';
import 'package:diohub/common/misc/glass_pill_surface.dart';
import 'package:diohub/common/nav_center/shell/app_bar_pulse_overlay.dart';
import 'package:diohub/common/nav_center/shell/nav_center_refresh_scope.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

const double _kMaxOverscrollPixels = 140.0;

class CollapseBar {
  const CollapseBar({
    this.leading,
    required this.title,
    this.subtitle,
    this.statusIndicators,
    this.action,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;

  /// Always-visible row below the title (e.g. status flags). Not animated.
  final Widget? statusIndicators;
  final Widget? action;

  Widget buildContent(BuildContext context, CollapseMetrics metrics,
      {bool canPop = false}) {
    final t = metrics.progress;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double titleFontSize = lerpDouble(
      textTheme.titleLarge?.fontSize ?? 22,
      textTheme.titleMedium?.fontSize ?? 16,
      t,
    )!;

    final titleWidget = DefaultTextStyle.merge(
      style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
      child: title,
    );

    final collapsedAlignment = canPop ? Alignment.centerLeft : Alignment.center;
    final alignedTitle = Align(
      alignment: Alignment.lerp(Alignment.centerLeft, collapsedAlignment, t)!,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) leading!,
          if (leading != null) context.spacing.itemGap,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              if (subtitle != null)
                SizeTransition(
                  sizeFactor:
                      AlwaysStoppedAnimation<double>((1 - t).clamp(0.0, 1.0)),
                  axisAlignment: -1.0,
                  child: FadeTransition(
                    opacity:
                        AlwaysStoppedAnimation<double>((1 - t).clamp(0.0, 1.0)),
                    child: subtitle!,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    final Widget titleColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        alignedTitle,
        if (statusIndicators != null) ...[
          context.spacing.tightGap,
          LayoutBuilder(
            builder: (
              final BuildContext context,
              final BoxConstraints constraints,
            ) =>
                SizedBox(
              width: constraints.maxWidth,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: statusIndicators!,
              ),
            ),
          ),
        ],
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleColumn),
        if (action != null) action!,
      ],
    );
  }
}

/// Metrics for the scroll state of DynamicScroll, exposed to body builders.
@immutable
class DynamicScrollMetrics {
  const DynamicScrollMetrics({
    required this.innerBoxIsScrolled,
  });

  final bool innerBoxIsScrolled;

  static const initial = DynamicScrollMetrics(
    innerBoxIsScrolled: false,
  );
}

typedef DynamicScrollBodyBuilder = Widget Function(
  BuildContext context,
  DynamicScrollMetrics metrics,
);

typedef DynamicScrollBodySliverBuilder = List<Widget> Function(
  BuildContext context,
  DynamicScrollMetrics metrics,
);

class DynamicScroll extends StatefulWidget {
  const DynamicScroll({
    required this.bar,
    this.expanded,
    this.headerSlivers,
    this.headerVisible = true,
    this.body,
    super.key,
    this.bodyBuilder,
    this.bodySliverBuilder,
  });

  final CollapseBar bar;
  final WidgetBuilder? expanded;
  final List<Widget> Function(
    BuildContext context,
    bool innerBoxIsScrolled,
  )? headerSlivers;
  final bool headerVisible;
  final Widget? body;
  final DynamicScrollBodyBuilder? bodyBuilder;

  /// When set, body is built as [AppCustomScrollView] with these slivers (no nested scroll view).
  /// [AppCustomScrollView] automatically injects [SliverPinnedOverlapInjector] to respect pinned app bar overlap.
  final DynamicScrollBodySliverBuilder? bodySliverBuilder;

  bool get hasAttachedHeader => headerSlivers != null && headerVisible;

  @override
  State<DynamicScroll> createState() => _DynamicScrollState();
}

class _DynamicScrollState extends State<DynamicScroll>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _overscrollController;
  final ValueNotifier<bool> _innerBoxIsScrolledNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _overscrollController = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 1.0,
      duration: kMicroDuration,
    );
  }

  @override
  void dispose() {
    _innerBoxIsScrolledNotifier.dispose();
    _scrollController.dispose();
    _overscrollController.dispose();
    super.dispose();
  }

  void _animateToOverscroll(final double target) {
    final double normalizedTarget =
        (target / _kMaxOverscrollPixels).clamp(0.0, 1.0);
    _overscrollController.stop();

    if (normalizedTarget == 0.0) {
      _overscrollController
          .animateWith(
        SpringSimulation(
          kSpring,
          _overscrollController.value,
          0.0,
          0.0,
        ),
      )
          .whenComplete(() {
        if (mounted && _overscrollController.value < 0.01) {
          _overscrollController.value = 0.0;
        }
      });
    } else {
      _overscrollController.value = normalizedTarget;
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
      child: ExtendedNestedScrollView(
        controller: _scrollController,
        onlyOneScrollInBody: true,
        headerSliverBuilder:
            (final BuildContext context, final bool innerBoxIsScrolled) {
          if (_innerBoxIsScrolledNotifier.value != innerBoxIsScrolled) {
            _innerBoxIsScrolledNotifier.value = innerBoxIsScrolled;
          }
          return <Widget>[
            SliverOverlapAbsorber(
              handle: ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(
                  context),
              sliver: MultiSliver(
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _overscrollController,
                    builder: (context, _) => DynamicSliverAppBar(
                      scrollController: _scrollController,
                      overscrollFraction: _overscrollController.value,
                      bar: widget.bar,
                      expanded: widget.expanded,
                      headerSlivers: widget.headerSlivers,
                      headerContext: context,
                      innerBoxIsScrolled: innerBoxIsScrolled,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: ValueListenableBuilder<bool>(
          valueListenable: _innerBoxIsScrolledNotifier,
          builder: (context, innerBoxIsScrolled, _) {
            final metrics = DynamicScrollMetrics(
              innerBoxIsScrolled: innerBoxIsScrolled,
            );
            if (widget.bodySliverBuilder != null) {
              return AppCustomScrollView(
                slivers: widget.bodySliverBuilder!(context, metrics),
              );
            }
            return widget.bodyBuilder?.call(context, metrics) ??
                widget.body ??
                const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class DynamicSliverAppBar extends ConsumerStatefulWidget {
  const DynamicSliverAppBar({
    required this.bar,
    this.expanded,
    required this.scrollController,
    required this.overscrollFraction,
    super.key,
    this.pinned = true,
    this.headerSlivers,
    this.headerContext,
    this.innerBoxIsScrolled = false,
  });

  final CollapseBar bar;
  final WidgetBuilder? expanded;
  final ScrollController scrollController;
  final double overscrollFraction;
  final bool pinned;
  final List<Widget> Function(
    BuildContext context,
    bool innerBoxIsScrolled,
  )? headerSlivers;
  final BuildContext? headerContext;
  final bool innerBoxIsScrolled;

  @override
  ConsumerState<DynamicSliverAppBar> createState() =>
      _DynamicSliverAppBarState();
}

class _DynamicSliverAppBarState extends ConsumerState<DynamicSliverAppBar> {
  static Widget _buildContent({
    required BuildContext context,
    required CollapseBar bar,
    required CollapseMetrics metrics,
    WidgetBuilder? expanded,
    bool canPop = false,
  }) {
    final content = bar.buildContent(context, metrics, canPop: canPop);

    if (expanded == null) {
      return content;
    }

    final progress = metrics.progress;
    final expandedWidget = ClipRect(
      child: SizeTransition(
        sizeFactor:
            AlwaysStoppedAnimation<double>((1 - progress).clamp(0.0, 1.0)),
        axisAlignment: -1.0,
        child: FadeTransition(
          opacity:
              AlwaysStoppedAnimation<double>((1 - progress).clamp(0.0, 1.0)),
          child: expanded(context),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        content,
        Flexible(child: expandedWidget),
      ],
    );
  }

  Widget _buildRawContent(BuildContext context) {
    return _buildContent(
      context: context,
      bar: widget.bar,
      metrics: CollapseMetrics.initial,
      expanded: widget.expanded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pill = context.glassPill;
    final bool attached =
        ref.watch(appearanceProvider).appBarStyle == AppBarStyle.attached;
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = screenWidth - 2 * pill.appBarExpandedHorizontalMargin;

    return MultiSliver(
      children: [
        AutoSizedSliverPersistentHeader(
          pinned: widget.pinned,
          minExtent: kToolbarHeight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minWidth: maxWidth,
            ),
            child: _buildRawContent(context),
          ),
          delegateBuilder: (rawContentHeight) {
            final expandedRadius = context.radius(pill.expandedRadius);
            final double collapsedBottomRadiusValue = attached
                ? context.radius(pill.appBarAttachedCollapsedRadius).topLeft.x
                : context.radius(pill.appBarRadius).topLeft.x;
            final BorderRadius collapsedRadius = attached
                ? BorderRadius.only(
                    topLeft: Radius.zero,
                    topRight: Radius.zero,
                    bottomLeft: Radius.circular(collapsedBottomRadiusValue),
                    bottomRight: Radius.circular(collapsedBottomRadiusValue),
                  )
                : context.radius(pill.appBarRadius);
            final canPop = ModalRoute.canPopOf(context) ?? false;

            final geometry = CollapseGeometry.resolve(
              rawContentHeight: rawContentHeight,
              minBarHeight: kToolbarHeight,
              statusBarHeight: statusBarHeight,
              overscrollFraction: widget.overscrollFraction,
              expandedRadius: expandedRadius,
              collapsedRadius: collapsedRadius,
              innerPadding: pill.innerPadding,
              innerPaddingExpanded: pill.innerPaddingExpanded,
              horizontalMargin: attached ? 0.0 : pill.appBarHorizontalMargin,
              expandedHorizontalMargin: pill.appBarExpandedHorizontalMargin,
              expandedTopMargin: pill.appBarTopMargin,
              topMargin: attached ? 0.0 : pill.appBarTopMargin,
              bottomMargin: pill.appBarBottomMargin,
            );

            final double borderWidth =
                ref.read(appearanceProvider).glassBorderWidth;
            final Border? borderForShell = attached
                ? Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.tint,
                      width: borderWidth,
                    ),
                  )
                : null;

            return _DynamicSliverAppBarDelegate(
              geometry: geometry,
              bar: widget.bar,
              expanded: widget.expanded,
              scrollController: widget.scrollController,
              canPop: canPop,
              attached: attached,
              border: borderForShell,
            );
          },
        ),
        if (widget.headerSlivers != null && widget.headerContext != null)
          MultiSliver(
            children: widget.headerSlivers!(
              widget.headerContext!,
              widget.innerBoxIsScrolled,
            ),
          ),
      ],
    );
  }
}

class _DynamicSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _DynamicSliverAppBarDelegate({
    required this.geometry,
    required this.bar,
    this.expanded,
    required this.scrollController,
    required this.canPop,
    required this.attached,
    this.border,
  });

  final CollapseGeometry geometry;
  final CollapseBar bar;
  final WidgetBuilder? expanded;
  final ScrollController scrollController;
  final bool canPop;

  /// When true, app bar is attached to screen edges (no top border, bottom corners curved).
  final bool attached;

  /// When non-null (e.g. when [attached]), use this border for the glass surface.
  final Border? border;

  @override
  double get minExtent => geometry.minExtent;

  @override
  double get maxExtent => geometry.maxExtent;

  void _animateToExpanded() {
    if (!scrollController.hasClients) return;

    final ScrollPosition position = scrollController.position;
    if (position.pixels <= 0) return;

    scrollController.animateTo(
      0,
      duration: kStateDuration,
      curve: kStateCurve,
    );
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final frame = geometry.frameAt(shrinkOffset);

    final Widget wrappedContent = expanded != null
        ? ClipRect(
            child: _DynamicSliverAppBarState._buildContent(
              context: context,
              bar: bar,
              metrics: frame.metrics,
              expanded: expanded,
              canPop: canPop,
            ),
          )
        : _DynamicSliverAppBarState._buildContent(
            context: context,
            bar: bar,
            metrics: frame.metrics,
            expanded: expanded,
            canPop: canPop,
          );

    final gestureContent = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: frame.isCollapsed ? (_) => _animateToExpanded() : null,
      onVerticalDragStart:
          frame.isCollapsed ? (_) => _animateToExpanded() : null,
      child: wrappedContent,
    );

    return CollapsibleHeaderShell(
      frame: frame,
      canPop: canPop,
      border: border,
      child: gestureContent,
    );
  }

  @override
  bool shouldRebuild(covariant _DynamicSliverAppBarDelegate oldDelegate) {
    return geometry != oldDelegate.geometry ||
        bar != oldDelegate.bar ||
        expanded != oldDelegate.expanded ||
        canPop != oldDelegate.canPop ||
        attached != oldDelegate.attached ||
        border != oldDelegate.border;
  }
}

/// Shell widget that owns all chrome for the collapsible header.
///
/// Strict nesting: margin -> SizedBox(headerHeight) -> glass ->
/// padding -> SizedBox(contentHeight) -> content
class CollapsibleHeaderShell extends StatelessWidget {
  const CollapsibleHeaderShell({
    required this.frame,
    required this.canPop,
    required this.child,
    this.border,
    super.key,
  });

  final CollapseFrame frame;
  final bool canPop;
  final Widget child;

  /// When non-null, use this border for the glass surface (e.g. attached app bar:
  /// left/right/bottom only, no top). Passed from the delegate.
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
          return const SizedBox.shrink();
        }
        if (frame.headerHeight <= 0) {
          return Padding(
            padding: frame.margin,
            child: const SizedBox.shrink(),
          );
        }
        final colorScheme = Theme.of(context).colorScheme;
        final leadingHeight =
            (frame.contentHeight - frame.innerPadding.vertical)
                .clamp(0.0, double.infinity);

        Widget pill = RepaintBoundary(
          child: GlassPillSurface(
            glassReveal: frame.glassReveal,
            borderRadius: frame.borderRadius,
            animate: false,
            restingColor: colorScheme.surfaceContainer,
            innerPadding: EdgeInsets.zero,
            border: border,
            child: Padding(
              padding: frame.innerPadding,
              child: ClipRect(
                child: SizedBox(
                  height: frame.contentHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (canPop)
                        SizedBox(
                          height: leadingHeight,
                          width: kToolbarHeight,
                          child: Center(
                            child: IconButton(
                              icon: const BackButtonIcon(),
                              onPressed: () => Navigator.maybePop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              splashRadius: 20,
                            ),
                          ),
                        ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        final refreshNotifier = NavCenterRefreshScope.of(context);
        if (refreshNotifier != null) {
          pill = Stack(
            clipBehavior: Clip.none,
            children: [
              pill,
              Positioned.fill(
                child: AppBarPulseOverlay(
                  isRefreshing: refreshNotifier,
                  borderRadius: frame.borderRadius,
                ),
              ),
            ],
          );
        }

        final result = ClipRect(
          child: SizedBox(
            height: frame.headerHeight,
            child: pill,
          ),
        );

        return Padding(
          padding: frame.margin,
          child: result,
        );
      },
    );
  }
}
