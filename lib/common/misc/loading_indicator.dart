import 'package:diohub/common/animations/logo_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A centered loading indicator using the branded logo progress animation.
///
/// This is the default loading indicator used throughout the app.
class LoadingIndicator extends ConsumerWidget {
  const LoadingIndicator({
    super.key,
    this.color,
    this.size = 25.0,
  });

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
        child: LogoProgressIndicator(
          size: size,
          color: color,
        ),
      );
}

/// A centered circular progress indicator with customizable size and stroke width.
///
/// Used for full-page or section loading states.
class CenteredSpinner extends ConsumerWidget {
  const CenteredSpinner({
    this.size = 36,
    this.strokeWidth = 4,
    super.key,
  });

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: LogoProgressIndicator(
        size: size,
      ),
    );
  }
}

/// A small circular progress indicator for inline button/action loading states.
///
/// Optimized for button trailing/leading positions with compact size.
class ButtonSpinner extends ConsumerWidget {
  const ButtonSpinner({
    this.size = 20,
    this.strokeWidth = 2,
    this.color,
    super.key,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LogoProgressIndicator(
      size: size,
      color: color,
      showHub: false,
      showBar: false,
    );
  }
}
