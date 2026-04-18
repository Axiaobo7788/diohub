/// Centralized access to timeline node [id] for issue/PR timeline items.
///
/// Timeline items are GQL union types (Issue vs PullRequest) with many variants
/// that all expose [id]. This helper avoids scattering `(event as dynamic).id`
/// at call sites. Uses a single dynamic cast internally (pragmatic choice to avoid
/// generated when() per union).
library;

import 'package:diohub/app/app_logger.dart';

/// Returns the node id as a string, or null if not available.
@pragma('vm:prefer-inline')
String? timelineNodeIdOf(Object? node) {
  if (node == null) return null;
  try {
    final id = (node as dynamic).id;
    if (id == null) return null;
    return id.toString();
  } catch (e, st) {
    AppLogger.warning(
      'timelineNodeIdOf: node has no id',
      error: e,
      stackTrace: st,
      tag: 'Timeline',
    );
    return null;
  }
}
