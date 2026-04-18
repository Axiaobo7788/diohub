import 'package:flutter/material.dart';

/// Static logo widget rendering the composed splash logo PNG.
///
/// This is the primary logo widget for static, full-color contexts.
/// Uses `splash_logo.png` (the same asset as the native splash screen)
/// to guarantee pixel-perfect visual consistency.
///
/// For small tintable icons (e.g., VersionInfoWidget), use [SvgLogoIcon].
/// For animated contexts, use [AnimatedLogoLayers].
class LogoAsset extends StatelessWidget {
  const LogoAsset({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/icon/splash_logo.png',
        width: size,
        height: size,
      );
}
