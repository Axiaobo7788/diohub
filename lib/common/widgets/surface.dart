import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// A styled container that applies consistent surface decoration (border radius,
/// colors, borders, shadows) based on the theme's SurfaceStyle.
///
/// This abstracts the common Container + BoxDecoration pattern, reducing boilerplate.
class Surface extends StatelessWidget {
  const Surface({
    required this.child,
    super.key,
    this.size = RadiusSize.medium,
    this.corners,
    this.color,
    this.border,
    this.gradient,
    this.shadow,
    this.padding,
    this.margin,
    this.clipBehavior = Clip.none,
    this.width,
    this.height,
  });

  final RadiusSize size;
  final List<Corner>? corners;
  final Color? color;
  final Border? border;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Clip clipBehavior;
  final double? width;
  final double? height;
  final Widget child;

  @override
  Widget build(final BuildContext context) => Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        clipBehavior: clipBehavior,
        decoration: context.surfaceDecoration(
          size,
          corners: corners,
          color: color,
          border: border,
          gradient: gradient,
          shadow: shadow,
        ),
        child: child,
      );
}
