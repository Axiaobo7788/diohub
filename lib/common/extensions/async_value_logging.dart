import 'package:diohub/app/app_logger.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension for AsyncValue that provides error logging.
extension AsyncValueErrorLogging<T> on AsyncValue<T> {
  /// Like [when], but the error branch logs via [AppLogger] and returns
  /// [SizedBox.shrink]. Use for optional/supplementary UI sections that
  /// can legitimately hide on error without confusing the user.
  ///
  /// Always provide a [debugLabel] to make logs easily traceable.
  Widget whenOrShrink({
    required Widget Function(T data) data,
    Widget Function()? loading,
    String? debugLabel,
  }) {
    return when(
      loading: loading ?? () => const SizedBox.shrink(),
      error: (Object e, StackTrace st) {
        AppLogger.warning(
          'AsyncValue error${debugLabel != null ? ' ($debugLabel)' : ''}',
          error: e,
          stackTrace: st,
          tag: 'UI',
        );
        return const SizedBox.shrink();
      },
      data: data,
    );
  }
}
