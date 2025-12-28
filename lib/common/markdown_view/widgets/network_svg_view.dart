import 'package:flutter/material.dart';
import 'package:jovial_svg/jovial_svg.dart';

/// Widget that fetches SVG data from network and renders it using jovial_svg's ScalableImageWidget
/// @deprecated Use ReadmeImageView instead
@Deprecated('Use ReadmeImageView instead')
class NetworkSvgView extends StatelessWidget {
  const NetworkSvgView({
    required this.url,
    this.height,
    this.width,
    super.key,
  });

  final String url;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final svgWidget = ScalableImageWidget.fromSISource(
      si: ScalableImageSource.fromSvgHttpUrl(Uri.parse(url)),
    );

    if (height != null || width != null) {
      return SizedBox(
        height: height,
        width: width,
        child: svgWidget,
      );
    }

    return svgWidget;
  }
}

