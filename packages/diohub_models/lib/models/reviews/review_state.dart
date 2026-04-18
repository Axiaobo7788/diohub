/// GitHub PR review state.
enum ReviewState {
  approved,
  changesRequested,
  commented,
  dismissed,
  pending;

  factory ReviewState.fromString(String state) {
    return switch (state.toUpperCase()) {
      'APPROVED' => ReviewState.approved,
      'CHANGES_REQUESTED' => ReviewState.changesRequested,
      'COMMENTED' => ReviewState.commented,
      'DISMISSED' => ReviewState.dismissed,
      'PENDING' => ReviewState.pending,
      _ => ReviewState.pending,
    };
  }

  String get displayName => switch (this) {
    ReviewState.approved => 'Approved',
    ReviewState.changesRequested => 'Changes Requested',
    ReviewState.commented => 'Commented',
    ReviewState.dismissed => 'Dismissed',
    ReviewState.pending => 'Pending',
  };
}
