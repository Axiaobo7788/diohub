import 'dart:async';

import 'package:diohub/common/animations/animations.dart';
import 'package:diohub/common/markdown_view/providers/markdown_image_providers.dart';
import 'package:diohub/common/markdown_view/readme_image_classifier.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jovial_svg/jovial_svg.dart';

/// Widget that fetches and classifies images, then displays them appropriately
class ReadmeImageView extends ConsumerStatefulWidget {
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
  ConsumerState<ReadmeImageView> createState() => _ReadmeImageViewState();
}

class _ReadmeImageViewState extends ConsumerState<ReadmeImageView> {
  AsyncValue<ReadmeImageResult>? _lastOnstageResult;

  @override
  Widget build(final BuildContext context) {
    final bool onstage = TickerMode.valuesOf(context).enabled;
    final AsyncValue<ReadmeImageResult> latestResult = ref.watch(
      readmeImageResultProvider(widget.url),
    );
    if (onstage) {
      _lastOnstageResult = latestResult;
    }
    // Repository tabs are retained to preserve their scroll/query state.
    // Continue the ResourceRuntime lease in the background, but do not
    // materialize a late image inside an inactive sliver tree: Flutter can
    // otherwise relayout that tree while the selected tab is changing. The
    // latest completed result is rendered as soon as this tab becomes active.
    final AsyncValue<ReadmeImageResult> imageResultAsync = onstage
        ? latestResult
        : _lastOnstageResult ?? const AsyncLoading<ReadmeImageResult>();

    return imageResultAsync.animatedWhen(
      data: (final ReadmeImageResult result) {
        final Widget failure = _ReadmeImageFailure(
          onRetry: () => unawaited(
            ref
                .read(readmeImageResultProvider(widget.url).notifier)
                .refreshResource(),
          ),
        );
        final Widget imageWidget = switch (result.kind) {
          ReadmeImageKind.svg => ScalableImageWidget.fromSISource(
            si: ScalableImageSource.fromSvgFile(
              widget.url,
              () => result.svgString!,
            ),
            onError: (final BuildContext context) => failure,
          ),
          ReadmeImageKind.raster => Image.memory(
            result.bytes!,
            height: widget.height,
            width: widget.width,
            cacheWidth:
                ((widget.width ?? MediaQuery.sizeOf(context).width) *
                        MediaQuery.devicePixelRatioOf(context))
                    .round()
                    .clamp(1, 2048),
            cacheHeight: widget.height == null
                ? null
                : (widget.height! * MediaQuery.devicePixelRatioOf(context))
                      .round()
                      .clamp(1, 2048),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder:
                (
                  final BuildContext context,
                  final Object error,
                  final StackTrace? stack,
                ) => failure,
          ),
          ReadmeImageKind.unavailable => failure,
        };

        if (widget.height != null || widget.width != null) {
          return SizedBox(
            height: widget.height,
            width: widget.width,
            child: imageWidget,
          );
        }

        return imageWidget;
      },
      loading: () => SizedBox(
        height: widget.height ?? 20,
        width: widget.width ?? 20,
        child: const LoadingIndicator(),
      ),
      error: (final Object error, final StackTrace stackTrace) =>
          _ReadmeImageFailure(
            onRetry: () => unawaited(
              ref
                  .read(readmeImageResultProvider(widget.url).notifier)
                  .refreshResource(),
            ),
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
