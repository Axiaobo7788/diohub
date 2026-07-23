import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/animated_content_switcher.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Internal widget that wraps [AnimatedContentSwitcher] with appearance-driven
/// duration (Consumer watches [appearanceProvider]).
class _AppearanceAwareContentSwitcher extends StatelessWidget {
  const _AppearanceAwareContentSwitcher({
    required this.child,
    required this.transition,
    this.duration,
  });

  final Widget child;
  final AnimationTransition transition;
  final Duration? duration;

  @override
  Widget build(final BuildContext context) => Consumer(
    builder: (final BuildContext context, final WidgetRef ref, final _) {
      final AppearanceSettings appearance = ref.watch(appearanceProvider);
      final bool disableAnimations =
          appearance.disableAnimations ||
          (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
      final Duration effectiveDuration = disableAnimations
          ? Duration.zero
          : duration ?? Duration(milliseconds: appearance.animationDurationMs);
      return AnimatedContentSwitcher(
        transition: transition,
        duration: effectiveDuration,
        child: child,
      );
    },
  );
}

/// Extension on [AsyncValue] that provides animated transitions between
/// loading, data, and error states.
///
/// This replaces the previous `AnimatedAsyncSwitcher.when()` static method
/// with a more ergonomic extension method API.
///
/// Example:
/// ```dart
/// final userAsync = ref.watch(userProvider);
///
/// return userAsync.animatedWhen(
///   data: (user) => UserProfile(user),
///   loading: () => LoadingIndicator(),
///   error: (error, stack) => Text('Error: $error'),
///   transition: AnimationTransition.fadeSize,
/// );
/// ```
extension AnimatedAsyncValue<T> on AsyncValue<T> {
  /// Builds a widget that animates transitions between async states.
  ///
  /// [data] is called when data is available.
  /// [loading] is called during loading state (nullable, defaults to empty).
  /// [error] is called when an error occurs (nullable, defaults to error text).
  /// [transition] specifies the animation type.
  /// [duration] overrides the default animation duration.
  Widget animatedWhen({
    required final Widget Function(T) data,
    final Widget Function()? loading,
    final Widget Function(Object, StackTrace)? error,
    final AnimationTransition transition = AnimationTransition.fadeSize,
    final Duration? duration,
  }) {
    final KeyedSubtree childWidget = when(
      data: (final d) =>
          KeyedSubtree(key: ValueKey('data-${d.hashCode}'), child: data(d)),
      loading: () => KeyedSubtree(
        key: const ValueKey('loading'),
        child: loading?.call() ?? const SizedBox.shrink(),
      ),
      error: (final Object err, final StackTrace stack) => KeyedSubtree(
        key: ValueKey('error-${err.hashCode}'),
        child: error?.call(err, stack) ?? Text('Error: $err'),
      ),
    );
    return _AppearanceAwareContentSwitcher(
      transition: transition,
      duration: duration,
      child: childWidget,
    );
  }

  Widget animatedWhenSliver({
    required final Widget Function(T) data,
    final Widget Function()? loading,
    final Widget Function(Object, StackTrace)? error,
    final AnimationTransition transition = AnimationTransition.fadeSize,
    final Duration? duration,
  }) {
    final KeyedSubtree childWidget = when(
      data: (final d) =>
          KeyedSubtree(key: ValueKey('data-${d.hashCode}'), child: data(d)),
      loading: () => KeyedSubtree(
        key: const ValueKey('loading'),
        child: loading?.call() ?? const SizedBox.shrink(),
      ),
      error: (final Object err, final StackTrace stack) => KeyedSubtree(
        key: ValueKey('error-${err.hashCode}'),
        child: error?.call(err, stack) ?? Text('Error: $err'),
      ),
    );
    return SliverToBoxAdapter(
      child: _AppearanceAwareContentSwitcher(
        transition: transition,
        duration: duration,
        child: childWidget,
      ),
    );
  }
}
