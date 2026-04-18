import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:flutter/material.dart';

class ImageLoader extends StatelessWidget {
  const ImageLoader(
    this.url, {
    this.height,
    this.errorBuilder,
    this.width,
    super.key,
  });
  final String url;
  final double? height;
  final double? width;
  final WidgetBuilder? errorBuilder;
  @override
  Widget build(final BuildContext context) {
    final double? w = width;
    final double? h = height;
    final int? memW = w != null
        ? (w * MediaQuery.of(context).devicePixelRatio).round().clamp(1, 1024)
        : null;
    final int? memH = h != null
        ? (h * MediaQuery.of(context).devicePixelRatio).round().clamp(1, 1024)
        : null;
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: width,
      memCacheWidth: memW,
      memCacheHeight: memH,
      fit: BoxFit.contain,
      errorWidget: (final BuildContext context, final _, final __) =>
          errorBuilder != null ? errorBuilder!(context) : Container(),
      placeholder: (final BuildContext context, final String string) =>
          (height != null || width != null)
              ? ShimmerScope(
                  child: ShimmerBone.block(
                    height: height ?? 100,
                    width: width,
                  ),
                )
              : Container(),
    );
  }
}
