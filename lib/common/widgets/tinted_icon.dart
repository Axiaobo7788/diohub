import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';

/// A reusable widget showing an icon in a tinted box or circle.
///
/// This abstracts the common pattern of "icon in a colored box" seen in
/// event cards, action buttons, avatar placeholders, etc.
class TintedIcon extends StatelessWidget {
  const TintedIcon({
    required this.icon,
    required this.color,
    super.key,
    this.iconSize = 16,
    this.boxSize,
    this.circle = false,
    this.size = RadiusSize.small,
  });

  final IconData icon;
  final Color color;
  final double iconSize;
  final double? boxSize;
  final bool circle;
  final RadiusSize size;

  @override
  Widget build(final BuildContext context) {
    final double effectiveBoxSize = boxSize ?? iconSize * 2.5;

    return Container(
      width: effectiveBoxSize,
      height: effectiveBoxSize,
      decoration: BoxDecoration(
        color: color.tint,
        borderRadius: circle
            ? BorderRadius.circular(effectiveBoxSize / 2)
            : BorderRadius.circular(
                Theme.of(context).surface.radius(size),
              ),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: color,
      ),
    );
  }
}
