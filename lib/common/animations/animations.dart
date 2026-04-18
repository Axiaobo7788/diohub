/// Unified animation system for DioHub
///
/// This library provides a consistent set of animation widgets to replace
/// the old scattered animation implementations.
///
/// ## Available Widgets
///
/// - [AnimatedVisibility]: Show/hide widgets with various transitions
/// - [AnimatedContentSwitcher]: Switch between different child widgets
/// - [StaggeredEntrance]: Animate list items with staggered delays
/// - [AnimatedAsyncSwitcher]: Animate async state transitions (Riverpod)
/// - [DelayedFadeAnimation]: Delayed fade-in for staggered entrances
///
/// ## Convention
///
/// Use [AsyncValueBuilder] / [SliverAsyncValueBuilder] (or [AnimatedAsyncValue.animatedWhen] /
/// [animatedWhenSliver]) for any async loading → content; avoid raw [AsyncValue.when] for that.
/// For non-async content swap use [AnimatedContentSwitcher]; for list item entrance use
/// [StaggeredEntrance].
///
/// ## Usage
///
/// ```dart
/// import 'package:diohub/common/animations/animations.dart';
///
/// AnimatedVisibility(
///   visible: isVisible,
///   transition: AnimationTransition.fadeSize,
///   child: MyWidget(),
/// )
/// ```
library;

import 'package:diohub/common/animations/animations.dart'
    show
        AnimatedContentSwitcher,
        AnimatedVisibility,
        DelayedFadeAnimation,
        StaggeredEntrance;
import 'package:diohub/common/riverpod/async_value_builder.dart'
    show AsyncValueBuilder, SliverAsyncValueBuilder;
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValue;

export 'animated_async_switcher.dart';
export 'animated_content_switcher.dart';
export '../widgets/animated_splash_content.dart';
// Core animation widgets
export 'animated_visibility.dart';
export 'delayed_fade_animation.dart';
// Motion tokens and configuration
export 'motion.dart';
export 'sliver_animated_switcher.dart';
export 'staggered_entrance.dart';
