/// Discussion/review thread resolution status.
enum DiscussionResolutionReason {
  resolved,
  outdated,
  duplicate,
  unresolved;

  factory DiscussionResolutionReason.fromString(String reason) {
    return switch (reason.toUpperCase()) {
      'RESOLVED' => DiscussionResolutionReason.resolved,
      'OUTDATED' => DiscussionResolutionReason.outdated,
      'DUPLICATE' => DiscussionResolutionReason.duplicate,
      _ => DiscussionResolutionReason.unresolved,
    };
  }

  String get displayName => switch (this) {
    DiscussionResolutionReason.resolved => 'Resolved',
    DiscussionResolutionReason.outdated => 'Outdated',
    DiscussionResolutionReason.duplicate => 'Duplicate',
    DiscussionResolutionReason.unresolved => 'Unresolved',
  };
}
