import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jovial_svg/jovial_svg.dart';

/// Small tintable logo icon rendering the inner logo layer from SVG.
///
/// Use this for small icon contexts (e.g., VersionInfoWidget at 13px)
/// where a tinted, vector-sharp icon is needed.
///
/// For full-color static logos, use [LogoAsset].
/// For animated contexts, use [AnimatedLogoLayers].
class SvgLogoIcon extends StatelessWidget {
  const SvgLogoIcon({required this.size, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    Widget icon = ScalableImageWidget.fromSISource(
      si: ScalableImageSource.fromSvg(
        rootBundle,
        'assets/icon/svg/inner_ios.svg',
      ),
    );

    if (color != null) {
      icon = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: icon,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: icon,
    );
  }
}
