import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart';

/// Scale alignment for an anchored overlay based on [Placement].
///
/// The overlay scales from the edge closest to the anchor (e.g. from top when
/// placement is [Placement.bottom]). Use with [AnchorScaleTransition].
Alignment placementToScaleAlignment(final Placement placement) {
  switch (placement) {
    case Placement.top:
    case Placement.topStart:
    case Placement.topEnd:
      return Alignment.bottomCenter;
    case Placement.bottom:
    case Placement.bottomStart:
    case Placement.bottomEnd:
      return Alignment.topCenter;
    case Placement.left:
    case Placement.leftStart:
    case Placement.leftEnd:
      return Alignment.centerRight;
    case Placement.right:
    case Placement.rightStart:
    case Placement.rightEnd:
      return Alignment.centerLeft;
  }
}

/// Reusable scale transition for anchor-based overlays (popup, peek).
///
/// Uses [kPopupDuration] / [kPopupCurveIn] / [kPopupCurveOut] and scales
/// from the edge implied by [placement]. Pass as [Anchor.transitionBuilder].
class AnchorScaleTransition extends StatelessWidget {
  const AnchorScaleTransition({
    required this.placement,
    required this.animation,
    required this.child,
    super.key,
  });

  final Placement placement;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(final BuildContext context) => ScaleTransition(
        scale: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: animation,
            curve: kPopupCurveIn,
            reverseCurve: kPopupCurveOut,
          ),
        ),
        alignment: placementToScaleAlignment(placement),
        child: child,
      );
}
