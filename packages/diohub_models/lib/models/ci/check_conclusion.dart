/// CI check conclusion states from GitHub's check runs API.
///
/// Covers both GraphQL (UPPERCASE) and REST (lowercase) variants.
enum CheckConclusion {
  success,
  failure,
  cancelled,
  timedOut,
  actionRequired,
  neutral,
  skipped,
  stale,
  startupFailure;

  /// Parse from API string (case-insensitive).
  static CheckConclusion? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.toLowerCase().replaceAll('_', '');
    return switch (normalized) {
      'success' => CheckConclusion.success,
      'failure' => CheckConclusion.failure,
      'cancelled' => CheckConclusion.cancelled,
      'timedout' => CheckConclusion.timedOut,
      'actionrequired' || 'action_required' => CheckConclusion.actionRequired,
      'neutral' => CheckConclusion.neutral,
      'skipped' => CheckConclusion.skipped,
      'stale' => CheckConclusion.stale,
      'startupfailure' || 'startup_failure' => CheckConclusion.startupFailure,
      _ => null,
    };
  }

  /// User-friendly display name.
  String get displayName => switch (this) {
        CheckConclusion.success => 'Success',
        CheckConclusion.failure => 'Failure',
        CheckConclusion.cancelled => 'Cancelled',
        CheckConclusion.timedOut => 'Timed Out',
        CheckConclusion.actionRequired => 'Action Required',
        CheckConclusion.neutral => 'Neutral',
        CheckConclusion.skipped => 'Skipped',
        CheckConclusion.stale => 'Stale',
        CheckConclusion.startupFailure => 'Startup Failure',
      };
}
