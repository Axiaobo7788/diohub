import 'package:dio/dio.dart';
import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/logo_progress_indicator.dart';
import 'package:diohub/common/misc/button.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart'
    show AsyncValueBuilder;
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dio-aware API error widget with optional retry button.
///
/// Shows a branded [LogoProgressIndicator] at 0.0 (empty ring, error state)
/// with the error message and retry button below.
/// Use with [AsyncValueBuilder] when the error may be a [DioException];
/// shows status code/message for badResponse and message for unknown.
class ApiErrorWidget extends ConsumerWidget {
  const ApiErrorWidget({
    required this.error,
    this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final String message;
    if (error is DioException) {
      final DioException dio = error as DioException;
      if (dio.type == DioExceptionType.badResponse) {
        message =
            '${dio.response!.statusCode}. ${dio.response!.statusMessage}.';
      } else if (dio.type == DioExceptionType.unknown) {
        message = dio.message ?? 'Something went wrong.';
      } else {
        message =
            kReleaseMode ? 'Something went wrong.' : error.toString();
      }
    } else {
      message =
          kReleaseMode ? 'Something went wrong.' : error.toString();
    }

    final AnimationPreset preset = ref.watch(appearanceProvider).animationPreset;
    final bool useBranded =
        preset == AnimationPreset.normal || preset == AnimationPreset.enhanced;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (useBranded) ...[
          LogoProgressIndicator(
            size: 56,
            value: 0.0,
            trackColor: Theme.of(context).colorScheme.error.withOpacity(0.2),
            showPercentage: false,
          ),
          context.spacing.itemGap,
        ],
        Padding(
          padding: context.spacing.spaciousPadding,
          child: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        if (onRetry != null)
          Button(onTap: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

/// Centered error message for body-only error display (no scaffold).
///
/// Use with [AsyncValueBuilder] when the error is shown inside an existing
/// scaffold body (e.g. repository screen, profile screen, commit graph).
class CenteredError extends StatelessWidget {
  const CenteredError(this.message, {super.key});

  final String message;

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: context.spacing.pagePadding,
          child: Text(message),
        ),
      );
}

/// Full-screen error with optional app bar and optional [SafeArea].
///
/// Use for commit info (SafeArea, no app bar), issue/pull screens (with app bar).
class ScaffoldError extends StatelessWidget {
  const ScaffoldError(
    this.message, {
    super.key,
    this.appBar,
    this.safeArea = false,
  });

  final String message;
  final PreferredSizeWidget? appBar;
  final bool safeArea;

  @override
  Widget build(final BuildContext context) {
    final Center body = Center(
      child: Padding(
        padding: context.spacing.pagePadding,
        child: Text(message),
      ),
    );
    return Scaffold(
      appBar: appBar,
      body: safeArea
          ? SafeArea(
              bottom: false,
              child: body,
            )
          : body,
    );
  }
}

/// A centered empty state display with optional icon and action button.
///
/// Shows a muted [LogoIcon] watermark behind the message for brand presence.
/// Used consistently across the app for "no data" scenarios.
class EmptyState extends ConsumerWidget {
  const EmptyState({
    required this.message,
    this.icon,
    this.action,
    super.key,
  });

  final String message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnimationPreset preset = ref.watch(appearanceProvider).animationPreset;
    final bool showWatermark =
        preset == AnimationPreset.normal || preset == AnimationPreset.enhanced;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (showWatermark)
              Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/icon/splash_logo.png',
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.width * 0.4,
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (action != null) ...[
                  const SizedBox(height: 16),
                  action!,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
