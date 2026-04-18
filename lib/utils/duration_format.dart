/// Duration formatting granularity control.
enum DurationGranularity {
  /// Format down to seconds (e.g., "2m 30s", "45s")
  secondsUp,

  /// Format down to minutes (e.g., "2h 14m", "<1m")
  minutesUp,

  /// Format down to hours and larger units (e.g., "2h", "3d", "2w", "5mo", "1yr")
  hoursUp,
}

/// Human-readable duration formatting with configurable granularity.
///
/// **Examples:**
/// - `formatDuration(Duration(hours: 2, minutes: 14))` → "2h 14m"
/// - `formatDuration(Duration(seconds: 45), granularity: DurationGranularity.secondsUp)` → "45s"
/// - `formatDuration(Duration(days: 365), granularity: DurationGranularity.hoursUp)` → "1yr"
String formatDuration(
  Duration d, {
  DurationGranularity granularity = DurationGranularity.minutesUp,
}) {
  switch (granularity) {
    case DurationGranularity.secondsUp:
      if (d.inHours > 0) {
        return '${d.inHours}h ${d.inMinutes % 60}m';
      }
      if (d.inMinutes > 0) {
        return '${d.inMinutes}m ${d.inSeconds % 60}s';
      }
      return '${d.inSeconds}s';

    case DurationGranularity.minutesUp:
      if (d.inDays > 0) {
        if (d.inHours % 24 == 0) {
          return '${d.inDays}d';
        }
        return '${d.inDays}d ${d.inHours % 24}h';
      }
      if (d.inHours > 0) {
        if (d.inMinutes % 60 == 0) {
          return '${d.inHours}h';
        }
        return '${d.inHours}h ${d.inMinutes % 60}m';
      }
      if (d.inMinutes > 0) {
        return '${d.inMinutes}m';
      }
      return '<1m';

    case DurationGranularity.hoursUp:
      if (d.inSeconds <= 0) {
        return '<1h';
      }
      final int hours = d.inHours;
      if (hours < 1) {
        return '<1h';
      }
      if (hours < 24) {
        return '${hours}h';
      }
      final int days = d.inDays;
      if (days < 7) {
        return '${days}d';
      }
      if (days < 30) {
        return '${days ~/ 7}w';
      }
      if (days < 365) {
        return '${days ~/ 30}mo';
      }
      return '${days ~/ 365}yr';
  }
}
