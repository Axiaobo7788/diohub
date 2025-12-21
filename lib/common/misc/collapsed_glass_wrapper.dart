import 'package:diohub/common/misc/liquid_glass_wrapper.dart';
import 'package:flutter/material.dart';

/// Wraps a widget with liquid glass effect when the app bar is collapsed.
///
/// Detects collapse state using FlexibleSpaceBarSettings and applies
/// the liquid glass effect only when collapsed, allowing content to show through.
class CollapsedGlassWrapper extends StatefulWidget {
  const CollapsedGlassWrapper({
    required this.child,
    this.blur,
    this.glassColorOpacity,
    this.thickness,
    this.refractiveIndex,
    super.key,
  });

  final Widget child;
  final double? blur;
  final double? glassColorOpacity;
  final double? thickness;
  final double? refractiveIndex;

  @override
  State<CollapsedGlassWrapper> createState() => _CollapsedGlassWrapperState();
}

class _CollapsedGlassWrapperState extends State<CollapsedGlassWrapper> {
  ScrollPosition? _position;
  bool? _isCollapsed;

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _removeListener();
    _addListener();
  }

  void _addListener() {
    _position = Scrollable.maybeOf(context)?.position;
    _position?.addListener(_positionListener);
    _positionListener();
  }

  void _removeListener() {
    _position?.removeListener(_positionListener);
  }

  void _positionListener() {
    final FlexibleSpaceBarSettings? settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final bool collapsed =
        settings == null || settings.currentExtent <= settings.minExtent;
    if (_isCollapsed != collapsed) {
      setState(() {
        _isCollapsed = collapsed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply liquid glass only when collapsed
    if (_isCollapsed == true) {
      return LiquidGlassWrapper(
        blur: widget.blur,
        glassColorOpacity: widget.glassColorOpacity ?? 0.3,
        thickness: widget.thickness,
        refractiveIndex: widget.refractiveIndex,
        child: widget.child,
      );
    }
    // When expanded, return child without glass effect
    return widget.child;
  }
}

