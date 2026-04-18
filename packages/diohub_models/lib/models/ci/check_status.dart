/// CI check status from GitHub's check runs API.
///
/// Covers both GraphQL (UPPERCASE) and REST (lowercase) variants.
enum CheckStatus {
  completed,
  inProgress,
  queued,
  waiting,
  requested,
  pending;

  /// Parse from API string (case-insensitive).
  static CheckStatus? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.toLowerCase().replaceAll('_', '');
    return switch (normalized) {
      'completed' => CheckStatus.completed,
      'inprogress' || 'in_progress' => CheckStatus.inProgress,
      'queued' => CheckStatus.queued,
      'waiting' => CheckStatus.waiting,
      'requested' => CheckStatus.requested,
      'pending' => CheckStatus.pending,
      _ => null,
    };
  }

  /// User-friendly display name.
  String get displayName => switch (this) {
        CheckStatus.completed => 'Completed',
        CheckStatus.inProgress => 'In Progress',
        CheckStatus.queued => 'Queued',
        CheckStatus.waiting => 'Waiting',
        CheckStatus.requested => 'Requested',
        CheckStatus.pending => 'Pending',
      };
}
