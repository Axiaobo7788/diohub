/// Sealed state class for standalone fire-and-forget mutations
/// (fork, create issue, etc.) that don't own cached data but need
/// loading / success / error UI state.
///
/// Includes [MutationNotifierMixin] for safe auto-reset with timer disposal.
library;

import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mutation_state.freezed.dart';

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Represents the lifecycle of a standalone mutation.
@Freezed(genericArgumentFactories: true)
sealed class MutationState<T> with _$MutationState<T> {
  const factory MutationState.idle() = MutationIdle<T>;
  const factory MutationState.loading() = MutationLoading<T>;
  const factory MutationState.success(T data) = MutationSuccess<T>;
  const factory MutationState.error(Object error, StackTrace stackTrace) =
      MutationError<T>;
}

// ---------------------------------------------------------------------------
// Convenience extension
// ---------------------------------------------------------------------------

extension MutationStateX<T> on MutationState<T> {
  bool get isIdle => this is MutationIdle<T>;
  bool get isLoading => this is MutationLoading<T>;
  bool get isSuccess => this is MutationSuccess<T>;
  bool get isError => this is MutationError<T>;
}

// ---------------------------------------------------------------------------
// Mixin for family notifiers that manage MutationState
// ---------------------------------------------------------------------------

/// Mixin for [Notifier]s that manage [MutationState] with safe
/// auto-reset. Uses [ref.onDispose()] to cancel pending timers and prevent
/// post-dispose state writes.
///
/// Works with both family and non-family notifiers.
mixin MutationNotifierMixin<T> on Notifier<MutationState<T>> {
  Timer? _resetTimer;

  /// Schedules a reset back to [MutationIdle] after [delay].
  ///
  /// Any previously-scheduled reset is cancelled first. The timer is also
  /// cancelled automatically when the notifier is disposed.
  void scheduleReset([final Duration delay = const Duration(seconds: 2)]) {
    _resetTimer?.cancel();
    _resetTimer = Timer(delay, () {
      state = const MutationState.idle();
    });
  }

  /// Call from [build] to wire up safe timer disposal:
  /// ```dart
  /// @override
  /// MutationState build(Arg arg) {
  ///   initMutationDisposal();
  ///   return const MutationState.idle();
  /// }
  /// ```
  void initMutationDisposal() {
    ref.onDispose(() => _resetTimer?.cancel());
  }

  /// Executes a mutation with automatic state management.
  ///
  /// Handles guard checks, loading state, success/error state transitions,
  /// and automatic reset scheduling. Returns the result on success, null on error or if already loading.
  ///
  /// Example:
  /// ```dart
  /// Future<void> delete() => runMutation(() => service.deleteItem(id));
  /// ```
  Future<T?> runMutation(Future<T> Function() action) async {
    if (state is MutationLoading<T>) return null;
    state = MutationState.loading();
    try {
      final result = await action();
      state = MutationState.success(result);
      scheduleReset();
      return result;
    } catch (e, st) {
      AppLogger.error('Mutation failed', error: e, stackTrace: st, tag: 'Mutation');
      state = MutationState.error(e, st);
      scheduleReset();
      return null;
    }
  }
}
