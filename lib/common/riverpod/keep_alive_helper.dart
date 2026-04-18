/// Helper that prevents both memory leaks (from unbounded `ref.keepAlive()`)
/// and unnecessary refetches (from instant auto-dispose).
///
/// Convention: screen-level entity providers use [kEntityCacheDuration] (or
/// [keepAliveFor] with that duration). Call in `build()` of any family
/// [AsyncNotifier] that represents screen-level data:
/// ```dart
/// @override
/// Future<T> build(Arg arg) async {
///   keepAliveFor(ref, duration: kEntityCacheDuration);
///   return _fetch();
/// }
/// ```
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/framework.dart';

/// Default cache duration for entity/screen-level providers. Use so a single
/// change updates all call sites.
const Duration kEntityCacheDuration = Duration(minutes: 5);

/// Keeps the provider alive for [duration] after the last watcher detaches,
/// then allows auto-dispose.
///
/// **Must only be used with autoDispose providers.** On non-autoDispose
/// providers, `ref.onCancel` and `ref.onResume` never fire, so this call is
/// a no-op and the provider stays alive indefinitely.
///
/// - `ref.onCancel()` fires when the last watcher unsubscribes — starts a
///   countdown.
/// - `ref.onResume()` fires when a new watcher subscribes — cancels the
///   countdown.
/// - `ref.onDispose()` cleans up the timer.
void keepAliveFor(
  final Ref ref, {
  final Duration duration = kEntityCacheDuration,
}) {
  final KeepAliveLink link = ref.keepAlive();
  Timer? timer;
  ref.onCancel(() {
    // Last watcher detached — start countdown to allow disposal
    timer = Timer(duration, link.close);
  });
  ref.onResume(() {
    // New watcher attached — cancel countdown
    timer?.cancel();
  });
  ref.onDispose(() => timer?.cancel());
}
