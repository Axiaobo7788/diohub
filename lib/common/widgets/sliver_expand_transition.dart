import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart'
    show SliverStickyHeader;
import 'package:sliver_tools/sliver_tools.dart';

/// A sliver that animates its children's visible extent from 0 (collapsed)
/// to their natural extent (expanded).
///
/// This replaces the box-based `AnimatedSwitcher` + `SizeTransition` pattern
/// used for pull-to-expand metadata sections, enabling child slivers
/// (e.g. [SliverStickyHeader]) to retain their sticky behavior.
///
/// The [sizeFactor] animation drives the reveal:
///  - 0.0 → children are fully hidden (zero layout and paint extent)
///  - 1.0 → children are fully shown at their natural size
///
/// Children are laid out at their natural size regardless of [sizeFactor],
/// but the reported [SliverGeometry] is scaled and the paint is clipped.
///
/// Uses a custom [_SliverClipExtent] instead of [SliverAnimatedPaintExtent]
/// to avoid "RenderObject mutated during performLayout" (sliver_tools calls
/// markNeedsLayout from inside its performLayout).
class SliverExpandTransition extends StatelessWidget {
  const SliverExpandTransition({
    required this.sizeFactor,
    required this.children,
    this.axisAlignment = 0.0,
    super.key,
  });

  /// Animation value controlling the visible fraction of children.
  /// 0.0 = fully collapsed, 1.0 = fully expanded.
  final Animation<double> sizeFactor;

  /// Alignment along the main axis when partially expanded.
  /// -1.0 = top-aligned, 0.0 = center, 1.0 = bottom-aligned.
  final double axisAlignment;

  /// The sliver children to reveal/hide.
  final List<Widget> children;

  @override
  Widget build(final BuildContext context) => _SliverClipExtent(
        sizeFactor: sizeFactor,
        axisAlignment: axisAlignment,
        child: MultiSliver(children: children),
      );
}

/// Internal sliver that clips its child's extent based on [sizeFactor].
///
/// Lays out the child at its natural size, then reports scaled geometry
/// and clips the paint region.
class _SliverClipExtent extends SingleChildRenderObjectWidget {
  const _SliverClipExtent({
    required this.sizeFactor,
    required this.axisAlignment,
    required final Widget child,
  }) : super(child: child);

  final Animation<double> sizeFactor;
  final double axisAlignment;

  @override
  _RenderSliverClipExtent createRenderObject(final BuildContext context) =>
      _RenderSliverClipExtent(
        sizeFactor: sizeFactor,
        axisAlignment: axisAlignment,
      );

  @override
  void updateRenderObject(
    final BuildContext context,
    final _RenderSliverClipExtent renderObject,
  ) {
    renderObject
      ..sizeFactor = sizeFactor
      ..axisAlignment = axisAlignment;
  }
}

class _RenderSliverClipExtent extends RenderProxySliver {
  _RenderSliverClipExtent({
    required final Animation<double> sizeFactor,
    required final double axisAlignment,
  })  : _sizeFactor = sizeFactor,
        _axisAlignment = axisAlignment {
    _sizeFactor.addListener(_handleAnimationChanged);
  }

  Animation<double> get sizeFactor => _sizeFactor;
  Animation<double> _sizeFactor;
  set sizeFactor(final Animation<double> value) {
    if (_sizeFactor == value) return;
    _sizeFactor.removeListener(_handleAnimationChanged);
    _sizeFactor = value;
    _sizeFactor.addListener(_handleAnimationChanged);
    markNeedsLayout();
  }

  double get axisAlignment => _axisAlignment;
  double _axisAlignment;
  set axisAlignment(final double value) {
    if (_axisAlignment == value) return;
    _axisAlignment = value;
    markNeedsLayout();
  }

  void _handleAnimationChanged() {
    markNeedsLayout();
  }

  @override
  void detach() {
    _sizeFactor.removeListener(_handleAnimationChanged);
    super.detach();
  }

  @override
  void performLayout() {
    // Layout child at its natural size.
    child!.layout(constraints, parentUsesSize: true);

    final SliverGeometry childGeometry = child!.geometry!;
    final double factor = _sizeFactor.value.clamp(0.0, 1.0);

    // Scale the extents.
    final double clampedScrollExtent = childGeometry.scrollExtent * factor;
    final double paintExtent = (childGeometry.paintExtent * factor)
        .clamp(0.0, constraints.remainingPaintExtent);
    final double layoutExtent =
        (childGeometry.layoutExtent * factor).clamp(0.0, paintExtent);
    final double maxPaintExtent = childGeometry.maxPaintExtent * factor;

    geometry = SliverGeometry(
      scrollExtent: clampedScrollExtent,
      paintExtent: paintExtent,
      layoutExtent: layoutExtent,
      maxPaintExtent: maxPaintExtent,
      hasVisualOverflow: factor < 1.0 || childGeometry.hasVisualOverflow,
      paintOrigin: childGeometry.paintOrigin,
      cacheExtent: childGeometry.cacheExtent * factor,
      hitTestExtent: paintExtent,
    );
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    final double factor = _sizeFactor.value.clamp(0.0, 1.0);
    if (factor == 0.0) return;

    if (factor < 1.0) {
      final SliverGeometry childGeometry = child!.geometry!;
      final double childPaintExtent = childGeometry.paintExtent;
      final double visibleExtent = childPaintExtent * factor;

      // Calculate offset for axis alignment.
      // -1.0 = top (no offset), 0.0 = center, 1.0 = bottom
      final double alignmentOffset =
          (childPaintExtent - visibleExtent) * (_axisAlignment + 1.0) / 2.0;

      final Rect clipRect;
      switch (constraints.axis) {
        case Axis.vertical:
          clipRect = Rect.fromLTWH(
            0,
            0,
            constraints.crossAxisExtent,
            visibleExtent,
          );
        case Axis.horizontal:
          clipRect = Rect.fromLTWH(
            0,
            0,
            visibleExtent,
            constraints.crossAxisExtent,
          );
      }

      context.pushClipRect(
        needsCompositing,
        offset,
        clipRect,
        (final PaintingContext innerContext, final Offset innerOffset) {
          final Offset childOffset;
          switch (constraints.axis) {
            case Axis.vertical:
              childOffset = Offset(0, -alignmentOffset);
            case Axis.horizontal:
              childOffset = Offset(-alignmentOffset, 0);
          }
          innerContext.paintChild(child!, innerOffset + childOffset);
        },
      );
    } else {
      context.paintChild(child!, offset);
    }
  }
}
