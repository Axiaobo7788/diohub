/// Constants for keys stored in [WatcherContext].
///
/// Using these constants instead of raw strings avoids typos and provides
/// a single place to document the semantics of each key.
library;

/// Keys used by the watcher engine and base watcher classes.
abstract final class WatcherContextKeys {
  /// ISO-8601 UTC timestamp of the last successful check.
  ///
  /// Written automatically by [PollingWatcher.check].
  static const String lastChecked = '_lastChecked';
}
