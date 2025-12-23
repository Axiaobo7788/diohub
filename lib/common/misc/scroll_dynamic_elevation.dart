import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

class ScrollDynamicElevation extends StatefulWidget {
  const ScrollDynamicElevation({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<ScrollDynamicElevation> createState() => _ScrollDynamicElevationState();
}

class _ScrollDynamicElevationState extends State<ScrollDynamicElevation> {
  static const double _tintDistance = 120;

  ScrollNotificationObserverState? _scrollNotificationObserver;
  bool _scrolledUnder = false;
  double _scrolledFraction = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollNotificationObserverState? previousObserver =
        _scrollNotificationObserver;
    previousObserver?.removeListener(_handleScrollNotification);

    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_handleScrollNotification);
  }

  @override
  void dispose() {
    final ScrollNotificationObserverState? observer =
        _scrollNotificationObserver;
    observer?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = null;
    super.dispose();
  }

  void _handleScrollNotification(final ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification ||
        !defaultScrollNotificationPredicate(notification)) {
      return;
    }

    final bool oldScrolledUnder = _scrolledUnder;
    final double oldFraction = _scrolledFraction;
    final ScrollMetrics metrics = notification.metrics;

    double? scrollDistance;
    switch (metrics.axisDirection) {
      case AxisDirection.up:
        scrollDistance = metrics.extentAfter;
      case AxisDirection.down:
        scrollDistance = metrics.extentBefore;
      case AxisDirection.right:
      case AxisDirection.left:
        // Only consider vertical scrolling for elevation changes.
        break;
    }

    if (scrollDistance == null) {
      return;
    }

    _scrolledUnder = scrollDistance > 0;
    _scrolledFraction =
        (scrollDistance / _tintDistance).clamp(0.0, 1.0).toDouble();

    if (_scrolledUnder != oldScrolledUnder ||
        _scrolledFraction != oldFraction) {
      setState(() {});
    }
  }

  @override
  Widget build(final BuildContext context) {
    final FlexibleSpaceBarSettings? settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();

    final Set<MaterialState> states = <MaterialState>{
      if (settings?.isScrolledUnder ?? _scrolledUnder)
        MaterialState.scrolledUnder,
    };

    final bool scrolledUnder = states.contains(MaterialState.scrolledUnder);
    final Color base = context.colorScheme.background;
    final Color tinted = context.colorScheme.surfaceContainer;
    final double fraction =
        scrolledUnder ? _scrolledFraction.clamp(0.05, 1.0) : 0;
    final Color background = Color.lerp(base, tinted, fraction) ?? base;

    return ColoredBox(
      color: background,
      child: widget.child,
    );
  }
}

bool defaultScrollNotificationPredicate(
  final ScrollNotification notification,
) =>
    notification.depth == 0;
