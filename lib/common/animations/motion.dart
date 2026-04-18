/// Unified motion token system for DioHub
///
/// Single source of truth for all animation parameters.
/// Organized by animation intent, not by component.
library;

import 'package:flutter/animation.dart';

// State transitions: bool flips (show/hide, float/unfloat, glass on/off)
// Examples: tab bar visibility, glass header padding, elevation tint
const Duration kStateDuration = Duration(milliseconds: 300);
const Curve kStateCurve = Curves.easeInOutCubic;

// Content switches: one widget replaces another (crossfade, size swap)
// Examples: tab content, async state, icon swap
const Duration kSwitchDuration = Duration(milliseconds: 300);
const Curve kSwitchCurveIn = Curves.easeOutCubic;
const Curve kSwitchCurveOut = Curves.easeInCubic;

// Micro-interactions: small, fast feedback
// Examples: button press, chevron rotate, icon swap
const Duration kMicroDuration = Duration(milliseconds: 200);
const Curve kMicroCurve = Curves.easeOutCubic;

// Entrances: first-time appearance, staggered lists
// Examples: list item stagger, page transitions
const Duration kEntranceDuration = Duration(milliseconds: 500);
const Curve kEntranceCurve = Curves.easeOutCubic;
const Duration kStaggerInterval = Duration(milliseconds: 50);
const Duration kMaxStaggerDelay = Duration(milliseconds: 300);

// Scroll-driven: no duration, driven by scroll offset t ∈ [0, 1]
// Examples: app bar collapse, radius interpolation, padding interpolation
const Curve kScrollCurve = Curves.easeInOutCubic;
const Curve kScrollCurveDelayed = Curves.easeInCubic;
const Curve kOverscrollCurve = Curves.easeOutCubic;

// Springs: gesture-driven physics
const SpringDescription kSpring = SpringDescription(
  mass: 1.2,
  stiffness: 300,
  damping: 26,
);
const SpringDescription kSpringSnappy = SpringDescription(
  mass: 1,
  stiffness: 400,
  damping: 22,
);

/// Pill bounce — spring entrance/exit for dock pills appearing/disappearing.
const SpringDescription kPillSpring = SpringDescription(
  mass: 0.8,
  stiffness: 350,
  damping: 20,
);

// Splash entrance: premium logo scale + staggered reveal
const Duration kSplashEntranceDuration = Duration(milliseconds: 600);
const Duration kSplashExitDuration = Duration(milliseconds: 400);

/// Splash spring — slightly bouncier than kSpring for a premium feel.
const SpringDescription kSplashSpring = SpringDescription(
  mass: 1.0,
  stiffness: 280,
  damping: 22,
);

// Popups and overlays: emphasis animations
const Duration kPopupDuration = Duration(milliseconds: 300);
const Curve kPopupCurveIn = Curves.easeOutBack;
const Curve kPopupCurveOut = Curves.easeInCubic;

/// Maps a raw progress [t] (0.0-1.0) to a sub-phase starting at [start] and
/// ending at [end], with optional [curve] easing.
///
/// Returns 0.0 before [start], 1.0 after [end], and the eased interpolation
/// between them.
///
/// This utility makes animation choreography readable by defining when effects
/// occur within an overall progress timeline.
///
/// Example:
/// ```dart
/// // Margins collapse during first half (0.0 -> 0.5)
/// final marginProgress = phaseProgress(t, end: 0.5, curve: kScrollCurve);
/// final margin = EdgeInsets.lerp(expanded, collapsed, marginProgress);
///
/// // Glass reveals during second half (0.5 -> 1.0)
/// final glassProgress = phaseProgress(t, start: 0.5, curve: kScrollCurve);
/// final opacity = 1.0 - glassProgress;
/// ```
double phaseProgress(
  final double t, {
  final double start = 0.0,
  final double end = 1.0,
  final Curve curve = Curves.linear,
}) {
  final double normalized = ((t - start) / (end - start)).clamp(0.0, 1.0);
  return curve.transform(normalized);
}

// Animation transition types
enum AnimationTransition {
  /// Fade in/out or crossfade
  fade,

  /// Size expand/collapse
  size,

  /// Combined fade + size transition
  fadeSize,

  /// Scale in/out
  scale,

  /// Combined fade + scale transition
  fadeScale,

  /// Combined fade + slide transition (content switcher only)
  fadeSlide,
}
