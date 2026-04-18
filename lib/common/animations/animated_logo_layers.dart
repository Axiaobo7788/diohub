import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jovial_svg/jovial_svg.dart';

/// Composable animated logo widget using SVG layers.
///
/// Renders the logo as two independent SVG layers (circle + inner) that can
/// be animated independently. Used by [AnimatedSplashContent] and
/// [LogoProgressIndicator] to ensure all logo animations derive from the same
/// SVG source files.
///
/// The circle layer can be rotated (indeterminate spin) or clipped
/// (determinate progress arc). The inner layer can fade or scale.
class AnimatedLogoLayers extends StatelessWidget {
  const AnimatedLogoLayers({
    required this.size,
    this.circleRotation,
    this.innerOpacity,
    this.clipProgress,
    super.key,
  });

  final double size;
  
  /// Rotation animation for the circle layer (in radians). Used for
  /// indeterminate spin and splash "come alive" animation.
  final Animation<double>? circleRotation;
  
  /// Opacity animation for the inner layer. Used for breathe effect.
  final Animation<double>? innerOpacity;
  
  /// Clip progress for determinate mode (0.0-1.0). If provided, the circle
  /// layer is clipped to an arc sector. Null = no clip (full circle visible).
  final double? clipProgress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildCircleLayer(),
          _buildInnerLayer(),
        ],
      ),
    );
  }

  Widget _buildCircleLayer() {
    Widget circleWidget = ScalableImageWidget.fromSISource(
      si: ScalableImageSource.fromSvg(
        rootBundle,
        'assets/icon/svg/circle_ios.svg',
      ),
    );

    if (clipProgress != null) {
      circleWidget = ClipPath(
        clipper: _ArcSectorClipper(progress: clipProgress!),
        child: circleWidget,
      );
    }

    if (circleRotation != null) {
      return AnimatedBuilder(
        animation: circleRotation!,
        builder: (context, child) => Transform.rotate(
          angle: circleRotation!.value,
          child: child,
        ),
        child: circleWidget,
      );
    }

    return circleWidget;
  }

  Widget _buildInnerLayer() {
    Widget innerWidget = ScalableImageWidget.fromSISource(
      si: ScalableImageSource.fromSvg(
        rootBundle,
        'assets/icon/svg/inner_ios.svg',
      ),
    );

    if (innerOpacity != null) {
      return AnimatedBuilder(
        animation: innerOpacity!,
        builder: (context, child) => Opacity(
          opacity: innerOpacity!.value,
          child: child,
        ),
        child: innerWidget,
      );
    }

    return innerWidget;
  }
}

/// Trivial arc sector clipper for determinate progress.
///
/// Draws a pie-slice path from center. The arc angle = progress * 2 * pi.
/// Does NOT encode logo geometry -- just a simple sector clip.
class _ArcSectorClipper extends CustomClipper<Path> {
  _ArcSectorClipper({required this.progress});

  final double progress;

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -pi/2 (12 o'clock)
      progress * 6.2832, // progress * 2*pi
      false,
    );
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _ArcSectorClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
