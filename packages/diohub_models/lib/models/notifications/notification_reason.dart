/// Reason why a GitHub notification was sent to the user.
enum NotificationReason {
  assign,
  author,
  comment,
  ciActivity,
  invitation,
  manual,
  mention,
  pushNotification,
  reviewRequested,
  securityAlert,
  stateChange,
  subscribed,
  teamMention;

  /// Parse from API string (case-insensitive, snake_case to camelCase).
  static NotificationReason? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.toLowerCase().replaceAll('_', '');
    return switch (normalized) {
      'assign' => NotificationReason.assign,
      'author' => NotificationReason.author,
      'comment' => NotificationReason.comment,
      'ciactivity' || 'ci_activity' => NotificationReason.ciActivity,
      'invitation' => NotificationReason.invitation,
      'manual' => NotificationReason.manual,
      'mention' => NotificationReason.mention,
      'push' => NotificationReason.pushNotification,
      'reviewrequested' || 'review_requested' => NotificationReason.reviewRequested,
      'securityalert' || 'security_alert' => NotificationReason.securityAlert,
      'statechange' || 'state_change' => NotificationReason.stateChange,
      'subscribed' => NotificationReason.subscribed,
      'teammention' || 'team_mention' => NotificationReason.teamMention,
      _ => null,
    };
  }

  /// User-friendly display name.
  String get displayName => switch (this) {
        NotificationReason.assign => 'Assigned',
        NotificationReason.author => 'Author',
        NotificationReason.comment => 'Comment',
        NotificationReason.ciActivity => 'CI Activity',
        NotificationReason.invitation => 'Invitation',
        NotificationReason.manual => 'Manual',
        NotificationReason.mention => 'Mention',
        NotificationReason.pushNotification => 'Push',
        NotificationReason.reviewRequested => 'Review Requested',
        NotificationReason.securityAlert => 'Security Alert',
        NotificationReason.stateChange => 'State Change',
        NotificationReason.subscribed => 'Subscribed',
        NotificationReason.teamMention => 'Team Mention',
      };
}
