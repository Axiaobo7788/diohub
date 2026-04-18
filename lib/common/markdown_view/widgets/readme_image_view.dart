import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/common/markdown_view/providers/markdown_image_providers.dart';
import 'package:diohub/common/markdown_view/readme_image_classifier.dart';
import 'package:diohub/common/misc/image_loader.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jovial_svg/jovial_svg.dart';

/// Widget that fetches and classifies images, then displays them appropriately
class ReadmeImageView extends ConsumerWidget {
  const ReadmeImageView({
    required this.url,
    this.height,
    this.width,
    super.key,
  });

  final String url;
  final double? height;
  final double? width;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<ReadmeImageResult> imageResultAsync =
        ref.watch(readmeImageResultProvider(url));

    return imageResultAsync.animatedWhen(
      data: (final ReadmeImageResult result) {
        Widget imageWidget;

        if (result.kind == ReadmeImageKind.svg) {
          // Render SVG using jovial_svg
          imageWidget = ScalableImageWidget.fromSISource(
            si: ScalableImageSource.fromSvgHttpUrl(Uri.parse(url)),
          );
        } else {
          // Render raster image using ImageLoader
          imageWidget = ImageLoader(
            url,
            height: height,
            width: width,
          );
        }

        if (height != null || width != null) {
          return SizedBox(
            height: height,
            width: width,
            child: imageWidget,
          );
        }

        return imageWidget;
      },
      loading: () => SizedBox(
        height: height ?? 20,
        width: width ?? 20,
        child: const LoadingIndicator(),
      ),
      error: (final Object error, final StackTrace stackTrace) => SizedBox(
        height: height ?? 20,
        width: width ?? 20,
        child: const Icon(Icons.error_outline),
      ),
      transition: AnimationTransition.fadeSize,
    );
  }
}
