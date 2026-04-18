import 'package:diohub/common/misc/measure_size.dart';
import 'package:flutter/material.dart';

/// A fixed-height [SliverPersistentHeaderDelegate] that passes [overlapsContent]
/// to a builder function.
///
/// This delegate is useful for simple sticky headers that don't collapse and
/// only need to react to whether they're overlapping scrollable content.
///
/// Example:
/// ```dart
/// FixedOverlapDelegate(
///   height: 60,
///   builder: (context, overlapsContent) => Container(
///     color: overlapsContent ? Colors.blue : Colors.transparent,
///     child: Text('Header'),
///   ),
/// )
/// ```
class FixedOverlapDelegate extends SliverPersistentHeaderDelegate {
  const FixedOverlapDelegate({
    required this.height,
    required this.builder,
  });

  final double height;
  final Widget Function(BuildContext context, bool overlapsContent) builder;

  @override
  Widget build(
    final BuildContext context,
    final double shrinkOffset,
    final bool overlapsContent,
  ) =>
      builder(context, overlapsContent);

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant final FixedOverlapDelegate oldDelegate) =>
      height != oldDelegate.height;
}

/// A [SliverPersistentHeader] that automatically measures its child's height.
///
/// Eliminates the need to hardcode [maxExtent] values by measuring the child
/// on first render. Always uses [SliverPersistentHeader] to avoid widget tree
/// instability (no sliver type swapping).
///
/// Starts with a conservative initial height ([minExtent]) and grows to the
/// measured height after the first frame. The measurement happens offstage
/// within the delegate's render to prevent sliver geometry violations.
///
/// Example:
/// ```dart
/// AutoSizedSliverPersistentHeader(
///   pinned: true,
///   minExtent: kToolbarHeight,
///   child: myRawContent,
///   delegateBuilder: (measuredHeight) => MyDelegate(
///     maxExtent: measuredHeight,
///     child: myRawContent,
///   ),
/// )
/// ```
class AutoSizedSliverPersistentHeader extends StatefulWidget {
  const AutoSizedSliverPersistentHeader({
    required this.delegateBuilder,
    required this.child,
    this.pinned = true,
    this.floating = false,
    this.minExtent = 0,
    super.key,
  });

  /// Builder that creates the delegate when the measured height is available.
  final SliverPersistentHeaderDelegate Function(double measuredHeight)
      delegateBuilder;

  /// The child widget to measure (should be the raw content in expanded state).
  final Widget child;

  /// Whether the header should remain visible when scrolled away.
  final bool pinned;

  /// Whether the header should float back into view on scroll up.
  final bool floating;

  /// Minimum height for the header (used as initial height before measurement).
  final double minExtent;

  @override
  State<AutoSizedSliverPersistentHeader> createState() =>
      _AutoSizedSliverPersistentHeaderState();
}

class _AutoSizedSliverPersistentHeaderState
    extends State<AutoSizedSliverPersistentHeader> {
  double? _measuredHeight;

  void _handleMeasurement(final Size size) {
    final double newHeight = size.height;
    if (newHeight >= widget.minExtent && _measuredHeight != newHeight) {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        if (mounted && _measuredHeight != newHeight) {
          setState(() {
            _measuredHeight = newHeight;
          });
        }
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    final double effectiveHeight = _measuredHeight ?? widget.minExtent;

    return SliverPersistentHeader(
      pinned: widget.pinned,
      floating: widget.floating,
      delegate: _AutoSizingWrapperDelegate(
        measuredHeight: effectiveHeight,
        needsMeasurement: _measuredHeight == null,
        child: widget.child,
        onMeasured: _handleMeasurement,
        innerDelegateBuilder: widget.delegateBuilder,
      ),
    );
  }
}

/// Wrapper delegate that handles measurement and delegates to the actual delegate.
class _AutoSizingWrapperDelegate extends SliverPersistentHeaderDelegate {
  _AutoSizingWrapperDelegate({
    required this.measuredHeight,
    required this.needsMeasurement,
    required this.child,
    required this.onMeasured,
    required this.innerDelegateBuilder,
  }) : _innerDelegate = innerDelegateBuilder(measuredHeight);

  final double measuredHeight;
  final bool needsMeasurement;
  final Widget child;
  final void Function(Size) onMeasured;
  final SliverPersistentHeaderDelegate Function(double) innerDelegateBuilder;
  final SliverPersistentHeaderDelegate _innerDelegate;

  @override
  Widget build(
    final BuildContext context,
    final double shrinkOffset,
    final bool overlapsContent,
  ) {
    if (maxExtent <= 0) {
      return const SizedBox.shrink();
    }
    final Widget innerContent =
        _innerDelegate.build(context, shrinkOffset, overlapsContent);

    if (needsMeasurement) {
      return Stack(
        children: <Widget>[
          ClipRect(
            child: SizedBox(
              height: maxExtent,
              child: innerContent,
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: Offstage(
              child: MeasureSize(
                onChange: onMeasured,
                child: child,
              ),
            ),
          ),
        ],
      );
    }

    return innerContent;
  }

  @override
  double get maxExtent => _innerDelegate.maxExtent;

  @override
  double get minExtent => _innerDelegate.minExtent;

  @override
  bool shouldRebuild(covariant final _AutoSizingWrapperDelegate oldDelegate) =>
      measuredHeight != oldDelegate.measuredHeight ||
      needsMeasurement != oldDelegate.needsMeasurement ||
      _innerDelegate != oldDelegate._innerDelegate;
}
