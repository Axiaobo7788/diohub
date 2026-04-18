/// Drop-in widgets for loading / data / error with Riverpod's [AsyncValue].
///
/// Uses the existing [AnimatedAsyncValue] extension for animated transitions
/// between loading, data, and error states.
///
/// Convention: Use [AsyncValueBuilder] / [SliverAsyncValueBuilder] (or
/// [AnimatedAsyncValue.animatedWhen] / [animatedWhenSliver]) for any async
/// loading → content; avoid raw [AsyncValue.when] for that.
library;

import 'package:diohub/common/animations/animated_async_switcher.dart';
import 'package:diohub/common/animations/logo_progress_indicator.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The presentation strategy for loading states.
///
/// Explicitly choose how a loading state should be presented:
/// - [branded]: Shows the DioHub [LogoProgressIndicator] centered. Use for
///   screen-level first loads where the entire UI is loading.
/// - [skeleton]: Shows a shimmer/skeleton matching the content layout. Use for
///   refresh states where the user has seen the content before, or for
///   partial/sectional loading with stale data visible.
/// - [inline]: Shows a small [LoadingIndicator]. Use for sub-sections within
///   an already-loaded screen or for inline loading actions.
enum LoadingPresentation {
  /// Branded loading with [LogoProgressIndicator]. Screen-level first loads.
  branded,

  /// Shimmer/skeleton loading. Refreshes and partial loads.
  skeleton,

  /// Small inline spinner. Sub-sections within loaded screens.
  inline,
}

/// Builds a widget that animates transitions between async states.
///
/// Example:
/// ```dart
/// final repoAsync = ref.watch(repositoryProvider(widget.repo));
/// return AsyncValueBuilder<RepoData>(
///   value: repoAsync,
///   data: (repo) => RepoContent(repo),
/// );
/// ```
class AsyncValueBuilder<T> extends StatelessWidget {
  const AsyncValueBuilder({
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.skeleton,
    this.presentation = LoadingPresentation.skeleton,
    this.transition = AnimationTransition.fade,
    this.duration,
    this.skipLoadingOnRefresh = true,
    super.key,
  });

  /// The [AsyncValue] to render.
  final AsyncValue<T> value;

  /// Builder for the data state.
  final Widget Function(T data) data;

  /// Optional builder for the loading state.
  final WidgetBuilder? loading;

  /// Optional builder for the error state.
  final Widget Function(Object error, StackTrace stack)? error;

  /// Optional skeleton widget shown during initial load.
  /// Falls back to [loading] or a default based on [presentation].
  final WidgetBuilder? skeleton;

  /// The loading presentation strategy. Defaults to [LoadingPresentation.skeleton].
  /// Use [LoadingPresentation.branded] for screen-level first loads.
  final LoadingPresentation presentation;

  /// The transition animation type.
  final AnimationTransition transition;

  /// Optional custom duration for the transition.
  final Duration? duration;

  /// When `true` and the provider already has cached data, shows the stale
  /// data rather than replacing it with a loading spinner on refresh.
  final bool skipLoadingOnRefresh;

  @override
  Widget build(final BuildContext context) {
    final AsyncValue<T> effectiveValue =
        skipLoadingOnRefresh ? value.whenData((final d) => d) : value;

    // Use skipLoadingOnRefresh: if we have previous data during a refresh,
    // keep showing it instead of flashing a loading state.
    if (skipLoadingOnRefresh && value.isRefreshing && value.hasValue) {
      return data(value.requireValue);
    }

    return effectiveValue.animatedWhen(
      data: data,
      loading: () =>
          skeleton?.call(context) ??
          loading?.call(context) ??
          _defaultLoading(context, presentation),
      error: (final Object err, final StackTrace stack) =>
          error?.call(err, stack) ?? _defaultError(context, err, stack),
      transition: transition,
      duration: duration,
    );
  }

  Widget _defaultLoading(
      final BuildContext context, final LoadingPresentation presentation) {
    switch (presentation) {
      case LoadingPresentation.branded:
        return const Center(
          child: LogoProgressIndicator(
            size: 56,
            showPercentage: false,
          ),
        );
      case LoadingPresentation.skeleton:
        return const LoadingIndicator();
      case LoadingPresentation.inline:
        return const LoadingIndicator(size: 16);
    }
  }

  Widget _defaultError(final BuildContext context, final Object err,
          final StackTrace stack) =>
      Padding(
        padding: EdgeInsets.all(context.spacing.itemSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(context.spacing.itemSpacing),
              child: Text(err.toString()),
            ),
            // We can't provide retry here without a ref. The caller should
            // provide an error builder with retry when needed.
          ],
        ),
      );
}

/// Sliver variant of [AsyncValueBuilder].
///
/// Uses the existing [AnimatedAsyncValue.animatedWhenSliver] extension.
class SliverAsyncValueBuilder<T> extends StatelessWidget {
  const SliverAsyncValueBuilder({
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.skeleton,
    this.presentation = LoadingPresentation.skeleton,
    this.transition = AnimationTransition.fade,
    this.duration,
    this.skipLoadingOnRefresh = true,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final WidgetBuilder? loading;
  final Widget Function(Object error, StackTrace stack)? error;
  final WidgetBuilder? skeleton;
  final LoadingPresentation presentation;
  final AnimationTransition transition;
  final Duration? duration;
  final bool skipLoadingOnRefresh;

  @override
  Widget build(final BuildContext context) {
    // During a refresh with existing data, keep showing the data.
    if (skipLoadingOnRefresh && value.isRefreshing && value.hasValue) {
      return data(value.requireValue);
    }

    return value.animatedWhenSliver(
      data: data,
      loading: () =>
          skeleton?.call(context) ??
          loading?.call(context) ??
          _defaultLoadingSliver(context, presentation),
      error: (final Object err, final StackTrace stack) =>
          error?.call(err, stack) ??
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(context.spacing.itemSpacing),
              child: ApiErrorWidget(error: err),
            ),
          ),
      transition: transition,
      duration: duration,
    );
  }

  Widget _defaultLoadingSliver(
      final BuildContext context, final LoadingPresentation presentation) {
    switch (presentation) {
      case LoadingPresentation.branded:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: LogoProgressIndicator(
              size: 56,
              showPercentage: false,
            ),
          ),
        );
      case LoadingPresentation.skeleton:
        return const SliverToBoxAdapter(child: LoadingIndicator());
      case LoadingPresentation.inline:
        return const SliverToBoxAdapter(child: LoadingIndicator(size: 16));
    }
  }
}
