import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// Linear interpolation for doubles that handles boundary cases to avoid precision issues.
double sanitizedLerpDouble(
  final double a,
  final double b,
  final double t,
) {
  if (t <= 0.0) return a;
  if (t >= 1.0) return b;
  final double? lerped = lerpDouble(a, b, t);
  if (lerped != null) return lerped;
  return a + (b - a) * t;
}

/// Linear interpolation for BorderRadius that handles boundary cases.
BorderRadius sanitizedLerpBorderRadius(
  final BorderRadius? a,
  final BorderRadius? b,
  final double t,
) {
  if (t <= 0.0) return a ?? BorderRadius.zero;
  if (t >= 1.0) return b ?? BorderRadius.zero;
  final BorderRadius? lerped = BorderRadius.lerp(a, b, t);
  if (lerped != null) return lerped;
  return a ?? BorderRadius.zero;
}

/// Linear interpolation for Color that handles boundary cases.
Color? sanitizedLerpColor(
  final Color? a,
  final Color? b,
  final double t,
) {
  if (t <= 0.0) return a;
  if (t >= 1.0) return b;
  final Color? lerped = Color.lerp(a, b, t);
  if (lerped != null) return lerped;
  return a;
}
