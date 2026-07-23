import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/common/markdown_view/providers/markdown_image_providers.dart';
import 'package:diohub/common/markdown_view/readme_image_classifier.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/l10n/l10n.dart';
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
    final AsyncValue<ReadmeImageResult> imageResultAsync = ref.watch(
      readmeImageResultProvider(url),
    );

    return imageResultAsync.animatedWhen(
      data: (final ReadmeImageResult result) {
        final Widget failure = _ReadmeImageFailure(
          onRetry: () => ref.invalidate(readmeImageResultProvider(url)),
        );
        final Widget imageWidget = switch (result.kind) {
          ReadmeImageKind.svg => ScalableImageWidget.fromSISource(
            si: ScalableImageSource.fromSvgFile(url, () => result.svgString!),
            onError: (final BuildContext context) => failure,
          ),
          ReadmeImageKind.raster => LayoutBuilder(
            builder:
                (final BuildContext context, final BoxConstraints constraints) {
                  final double devicePixelRatio = MediaQuery.devicePixelRatioOf(
                    context,
                  );
                  final double? logicalWidth =
                      width ??
                      (constraints.hasBoundedWidth
                          ? constraints.maxWidth
                          : null);
                  return Image.memory(
                    result.bytes!,
                    height: height,
                    width: width,
                    cacheWidth: logicalWidth == null
                        ? null
                        : (logicalWidth * devicePixelRatio).round().clamp(
                            1,
                            2048,
                          ),
                    cacheHeight: height == null
                        ? null
                        : (height! * devicePixelRatio).round().clamp(1, 2048),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder:
                        (
                          final BuildContext context,
                          final Object error,
                          final StackTrace? stack,
                        ) => failure,
                  );
                },
          ),
          ReadmeImageKind.unavailable => failure,
        };

        if (height != null || width != null) {
          return SizedBox(height: height, width: width, child: imageWidget);
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

class _ReadmeImageFailure extends StatelessWidget {
  const _ReadmeImageFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) => Center(
    child: Tooltip(
      message: context.l10n.commonRetry,
      child: IconButton(
        key: const ValueKey<String>('readme-image-retry'),
        onPressed: onRetry,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 20,
        icon: const Icon(Icons.broken_image_outlined),
      ),
    ),
  );
}
