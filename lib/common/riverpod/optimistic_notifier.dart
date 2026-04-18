/// Mixins that provide one-line optimistic updates with automatic rollback
/// for Riverpod [AsyncNotifier] providers.
///
/// Usage:
/// ```dart
/// class RepositoryNotifier
///     extends FamilyAsyncNotifier<RepoData, RepoRef>
///     with OptimisticFamilyAsyncNotifier {
///
///   Future<void> toggleStar() => optimistic(
///     transform: (repo) => repo.rebuild((b) => b..viewerHasStarred = !repo.viewerHasStarred),
///     mutation: () => _services.changeStar(...),
///     errorMessage: (_, __) => "Couldn't star repository",
///   );
/// }
/// ```
library;

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/mutation_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of an optimistic update attempt.
sealed class OptimisticResult<R> {}

/// Successful optimistic update.
class OptimisticSuccess<R> extends OptimisticResult<R> {
  OptimisticSuccess(this.value);
  final R value;
}

/// Failed optimistic update with error details.
class OptimisticFailure<R> extends OptimisticResult<R> {
  OptimisticFailure(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

/// Shared implementation for optimistic updates.
///
/// Pure function: captures current state, applies [transform] optimistically,
/// runs async [mutation], and rolls back on failure. Returns a result record
/// indicating success or failure.
Future<OptimisticResult<R>> _runOptimistic<T, R>({
  required final AsyncValue<T> Function() getState,
  required final void Function(AsyncValue<T>) setState,
  required final T Function(T current) transform,
  required final Future<R> Function() mutation,
  final T Function(T current, R response)? applyResponse,
}) async {
  final T previous = getState().requireValue;
  setState(AsyncData(transform(previous)));
  try {
    final R result = await mutation();
    if (applyResponse != null && result != null) {
      setState(AsyncData(applyResponse(previous, result)));
    }
    return OptimisticSuccess(result);
  } catch (e, st) {
    setState(AsyncData(previous));
    return OptimisticFailure(e, st);
  }
}

/// Mixin for non-family [AsyncNotifier] providers.
mixin OptimisticAsyncNotifier<T> on AsyncNotifier<T> {
  /// Performs an optimistic update with automatic rollback on failure.
  ///
  /// - [transform]: Applies the optimistic change until the mutation completes.
  /// - [mutation]: The async API call that persists the change.
  /// - [errorMessage]: Optional callback to provide user-facing error message.
  ///   When provided, the mixin handles logging + toast + haptic automatically.
  /// - [onError]: Optional error handler for custom logic beyond toast.
  /// - [applyResponse]: When provided and the mutation succeeds, state is set
  ///   from [applyResponse](previous, result) so state always reflects the response.
  Future<R?> optimistic<R>({
    required final T Function(T current) transform,
    required final Future<R> Function() mutation,
    final String Function(Object error, StackTrace stack)? errorMessage,
    final void Function(Object error, StackTrace stack)? onError,
    final T Function(T current, R response)? applyResponse,
  }) async {
    final result = await _runOptimistic(
      getState: () => state,
      setState: (final AsyncValue<T> v) => state = v,
      transform: transform,
      mutation: mutation,
      applyResponse: applyResponse,
    );
    switch (result) {
      case OptimisticSuccess(:final value):
        return value;
      case OptimisticFailure(:final error, :final stackTrace):
        final message = errorMessage?.call(error, stackTrace);
        AppLogger.error(
          message ?? 'Optimistic update failed',
          error: error,
          stackTrace: stackTrace,
          tag: 'Mutation',
        );
        if (message != null) {
          await showMutationError(ref, message, error: error, stackTrace: stackTrace);
        }
        onError?.call(error, stackTrace);
        return null;
    }
  }
}

/// Mixin for family [AsyncNotifier] providers.
mixin OptimisticFamilyAsyncNotifier<T> on AsyncNotifier<T> {
  /// Performs an optimistic update with automatic rollback on failure.
  ///
  /// - [transform]: Applies the optimistic change until the mutation completes.
  /// - [mutation]: The async API call that persists the change.
  /// - [errorMessage]: Optional callback to provide user-facing error message.
  ///   When provided, the mixin handles logging + toast + haptic automatically.
  /// - [onError]: Optional error handler for custom logic beyond toast.
  /// - [applyResponse]: When provided and the mutation succeeds, state is set
  ///   from [applyResponse](previous, result) so state always reflects the response.
  Future<R?> optimistic<R>({
    required final T Function(T current) transform,
    required final Future<R> Function() mutation,
    final String Function(Object error, StackTrace stack)? errorMessage,
    final void Function(Object error, StackTrace stack)? onError,
    final T Function(T current, R response)? applyResponse,
  }) async {
    final result = await _runOptimistic(
      getState: () => state,
      setState: (final AsyncValue<T> v) => state = v,
      transform: transform,
      mutation: mutation,
      applyResponse: applyResponse,
    );
    switch (result) {
      case OptimisticSuccess(:final value):
        return value;
      case OptimisticFailure(:final error, :final stackTrace):
        final message = errorMessage?.call(error, stackTrace);
        AppLogger.error(
          message ?? 'Optimistic update failed',
          error: error,
          stackTrace: stackTrace,
          tag: 'Mutation',
        );
        if (message != null) {
          await showMutationError(ref, message, error: error, stackTrace: stackTrace);
        }
        onError?.call(error, stackTrace);
        return null;
    }
  }
}
