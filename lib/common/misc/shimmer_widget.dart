import 'package:diohub/style/border_radiuses.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  const ShimmerWidget({
    this.child,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    super.key,
  });

  ShimmerWidget.container({
    this.baseColor,
    this.highlightColor,
    final double? height,
    final double? width,
    this.borderRadius,
    super.key,
  }) : child = _shimmerContainer(width: width, height: height);
  final Widget? child;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  static Widget _shimmerContainer({
    final double? height,
    final double? width,
  }) =>
      Builder(
        builder: (final BuildContext context) => Container(
          height: height ?? 20,
          width: width ?? double.infinity,
          color: context.colorScheme.onSurface,
        ),
      );

  @override
  Widget build(final BuildContext context) => ClipRRect(
        borderRadius: borderRadius ??
            context.themeData.borderRadiusTheme?.medBorderRadius ??
            Theme.of(context).surfaceStyle.borderRadius(
              size: BorderRadiusSize.small,
            ),
        child: Shimmer.fromColors(
          baseColor: baseColor ?? context.colorScheme.onSurface.withOpacity(0.06),
          highlightColor: highlightColor ?? context.colorScheme.onSurface.withOpacity(0.12),
          child: child ?? Container(),
        ),
      );
}
