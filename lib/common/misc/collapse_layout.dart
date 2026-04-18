import 'dart:ui';

import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';

// Overscroll constants
const double _kMaxOverscrollOffset = 42;
const double _kOverscrollRadiusGrowth = 0.15;

// Animation phase constants
const double _kCollapseThreshold = 0.95;
const double _kMarginCollapseAccel = 1;

/// Values derived from scroll/overscroll for building the collapsible header.
class CollapseMetrics {
  const CollapseMetrics({
    required this.progress,
  });

  /// 0.0 = expanded, 1.0 = collapsed.
  final double progress;

  /// Metrics for the initial (fully expanded) measurement phase.
  static const CollapseMetrics initial = CollapseMetrics(
    progress: 0,
  );

  /// Returns true if the header is collapsed (progress > 0).
  bool get isCollapsed => progress > 0.0;
}

/// Pure geometry data for a collapsible header.
///
/// Created once per measurement cycle. No BuildContext dependency.
/// Pre-resolved theme values (radii) are passed in during creation.
@immutable
class CollapseGeometry {
  const CollapseGeometry._({
    required this.rawContentHeight,
    required this.minBarHeight,
    required this.statusBarHeight,
    required this.overscrollFraction,
    required this.expandedRadius,
    required this.collapsedRadius,
    required this.maxExtent,
    required this.minExtent,
    required this.innerPadding,
    required this.innerPaddingExpanded,
    required this.horizontalMargin,
    required this.expandedHorizontalMargin,
    required this.expandedTopMargin,
    required this.topMargin,
    required this.bottomMargin,
  });

  factory CollapseGeometry.resolve({
    required final double rawContentHeight,
    required final double minBarHeight,
    required final double statusBarHeight,
    required final double overscrollFraction,
    required final BorderRadius expandedRadius,
    required final BorderRadius collapsedRadius,
    required final EdgeInsets innerPadding,
    required final EdgeInsets innerPaddingExpanded,
    required final double horizontalMargin,
    required final double expandedHorizontalMargin,
    required final double expandedTopMargin,
    required final double topMargin,
    required final double bottomMargin,
  }) {
    final double overscrollExtra = overscrollFraction * _kMaxOverscrollOffset;

    // Round to whole pixels to prevent floating-point rounding errors that
    // cause SliverGeometry assertions (layoutExtent slightly exceeding
    // paintExtent by ~1e-14).
    final double maxExtent = (statusBarHeight +
            expandedTopMargin +
            rawContentHeight +
            innerPaddingExpanded.vertical +
            overscrollExtra)
        .roundToDouble();
    final double minExtent = (statusBarHeight +
            topMargin +
            minBarHeight +
            innerPadding.vertical +
            bottomMargin)
        .roundToDouble();

    assert(
      minExtent <= maxExtent,
      'minExtent ($minExtent) must be <= maxExtent ($maxExtent)',
    );

    final double safeMinExtent = minExtent.clamp(0.0, maxExtent);

    return CollapseGeometry._(
      rawContentHeight: rawContentHeight,
      minBarHeight: minBarHeight,
      statusBarHeight: statusBarHeight,
      overscrollFraction: overscrollFraction,
      expandedRadius: expandedRadius,
      collapsedRadius: collapsedRadius,
      maxExtent: maxExtent,
      minExtent: safeMinExtent,
      innerPadding: innerPadding,
      innerPaddingExpanded: innerPaddingExpanded,
      horizontalMargin: horizontalMargin,
      expandedHorizontalMargin: expandedHorizontalMargin,
      expandedTopMargin: expandedTopMargin,
      topMargin: topMargin,
      bottomMargin: bottomMargin,
    );
  }

  final double rawContentHeight;
  final double minBarHeight;
  final double statusBarHeight;
  final double overscrollFraction;
  final BorderRadius expandedRadius;
  final BorderRadius collapsedRadius;
  final double maxExtent;
  final double minExtent;
  final EdgeInsets innerPadding;
  final EdgeInsets innerPaddingExpanded;
  final double horizontalMargin;
  final double expandedHorizontalMargin;

  /// Top margin when expanded (t=0). Used in maxExtent and lerped to [topMargin] in frame.
  final double expandedTopMargin;

  /// Top margin when collapsed (t=1). Used in minExtent and lerped from [expandedTopMargin] in frame.
  final double topMargin;
  final double bottomMargin;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is CollapseGeometry &&
          rawContentHeight == other.rawContentHeight &&
          minBarHeight == other.minBarHeight &&
          statusBarHeight == other.statusBarHeight &&
          overscrollFraction == other.overscrollFraction &&
          expandedRadius == other.expandedRadius &&
          collapsedRadius == other.collapsedRadius &&
          innerPadding == other.innerPadding &&
          innerPaddingExpanded == other.innerPaddingExpanded &&
          horizontalMargin == other.horizontalMargin &&
          expandedHorizontalMargin == other.expandedHorizontalMargin &&
          expandedTopMargin == other.expandedTopMargin &&
          topMargin == other.topMargin &&
          bottomMargin == other.bottomMargin;

  @override
  int get hashCode => Object.hash(
        rawContentHeight,
        minBarHeight,
        statusBarHeight,
        overscrollFraction,
        expandedRadius,
        collapsedRadius,
        innerPadding,
        innerPaddingExpanded,
        horizontalMargin,
        expandedHorizontalMargin,
        expandedTopMargin,
        topMargin,
        bottomMargin,
      );

  /// Compute layout frame for a given shrinkOffset.
  CollapseFrame frameAt(final double shrinkOffset) {
    final double availableHeight =
        (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);
    final double range = maxExtent - minExtent;
    final double t = range == 0 ? 1 : (shrinkOffset / range).clamp(0.0, 1.0);

    final double layoutProgress = phaseProgress(
      (t * _kMarginCollapseAccel).clamp(0.0, 1.0),
      curve: kScrollCurve,
    );

    final double glassProgress =
        phaseProgress(t, start: 0.15, curve: kScrollCurve);

    // Margin computation - lerp all margins to match floating pill padding in collapsed state
    final double animatedHorizontalMargin = lerpDouble(
      expandedHorizontalMargin,
      horizontalMargin,
      layoutProgress,
    )!;
    final double targetTopMargin = lerpDouble(
      expandedTopMargin,
      topMargin,
      layoutProgress,
    )!;
    final double targetBottomMargin = lerpDouble(
      0.0,
      bottomMargin,
      layoutProgress,
    )!;

    final EdgeInsets margin = EdgeInsets.fromLTRB(
      animatedHorizontalMargin,
      statusBarHeight + targetTopMargin,
      animatedHorizontalMargin,
      targetBottomMargin,
    );

    // Content budget = available - margin.vertical
    // This becomes the headerHeight directly (whole-to-parts derivation)
    final double contentBudget = availableHeight - margin.vertical;

    // Partition content budget into innerPadding + contentHeight
    final EdgeInsets animatedInnerPadding = EdgeInsets.lerp(
      innerPaddingExpanded,
      innerPadding,
      layoutProgress,
    )!;

    // headerHeight is the budget (exact, no round-trip)
    final double headerHeight = contentBudget;

    // Reuse overscrollExtra computation from resolve()
    final double overscrollExtra = overscrollFraction * _kMaxOverscrollOffset;

    // Derive contentHeight from headerHeight for inner SizedBox
    final double contentHeight = (headerHeight - animatedInnerPadding.vertical)
        .clamp(minBarHeight, rawContentHeight + overscrollExtra);

    final BorderRadius baseRadius = BorderRadius.lerp(
      expandedRadius,
      collapsedRadius,
      t,
    )!;

    final BorderRadius borderRadius = _calculateAnimatedRadius(
      baseRadius: baseRadius,
      overscrollFraction: overscrollFraction,
    );

    final double glassReveal = glassProgress.clamp(0.0, 1.0);
    final bool isCollapsed = t >= _kCollapseThreshold;

    return CollapseFrame(
      t: t,
      margin: margin,
      innerPadding: animatedInnerPadding,
      borderRadius: borderRadius,
      headerHeight: headerHeight,
      contentHeight: contentHeight,
      glassReveal: glassReveal,
      isCollapsed: isCollapsed,
      statusBarHeight: statusBarHeight,
    );
  }

  static EdgeInsets expandedMeasurementMargin(final double horizontalMargin) =>
      EdgeInsets.symmetric(horizontal: horizontalMargin);

  static BorderRadius _calculateAnimatedRadius({
    required final BorderRadius baseRadius,
    required final double overscrollFraction,
  }) {
    final double diminishingFactor = overscrollFraction > 0
        ? (overscrollFraction * _kOverscrollRadiusGrowth).clamp(0.0, 1.0)
        : 0.0;
    final double radiusGrowth = baseRadius.topLeft.x * diminishingFactor;

    return BorderRadius.only(
      topLeft: Radius.circular(baseRadius.topLeft.x + radiusGrowth),
      topRight: Radius.circular(baseRadius.topRight.x + radiusGrowth),
      bottomLeft: Radius.circular(baseRadius.bottomLeft.x + radiusGrowth),
      bottomRight: Radius.circular(baseRadius.bottomRight.x + radiusGrowth),
    );
  }
}

/// Layout values for one frame of the collapsible header.
@immutable
class CollapseFrame {
  const CollapseFrame({
    required this.t,
    required this.margin,
    required this.innerPadding,
    required this.borderRadius,
    required this.headerHeight,
    required this.contentHeight,
    required this.glassReveal,
    required this.isCollapsed,
    required this.statusBarHeight,
  });

  final double t;
  final EdgeInsets margin;
  final EdgeInsets innerPadding;
  final BorderRadius borderRadius;

  /// Total height of the header (including innerPadding.vertical).
  /// Source of truth - contentHeight is derived from this.
  final double headerHeight;

  /// Height available for content (excludes innerPadding.vertical).
  /// Used by inner SizedBox for layout.
  final double contentHeight;

  final double glassReveal;
  final bool isCollapsed;
  final double statusBarHeight;

  CollapseMetrics get metrics => CollapseMetrics(
        progress: t,
      );
}
