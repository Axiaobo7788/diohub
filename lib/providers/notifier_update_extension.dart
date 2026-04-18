import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension so that [Notifier] can be used like legacy [StateController] with
/// [StateController.update]. Keeps call sites working after StateProvider →
/// NotifierProvider migration.
extension NotifierUpdate<T> on Notifier<T> {
  /// Updates state via a callback; equivalent to `state = fn(state)`.
  void update(T Function(T state) fn) {
    state = fn(state);
  }
}
