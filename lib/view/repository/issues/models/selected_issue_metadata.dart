/// Lightweight model for a label selected in the new issue form
/// (chips and passing IDs to createIssue).
class SelectedLabel {
  const SelectedLabel({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final String color;
}

/// Lightweight model for an assignee selected in the new issue form
/// (chips and passing IDs to createIssue).
class SelectedAssignee {
  const SelectedAssignee({
    required this.id,
    required this.login,
    required this.avatarUrl,
  });

  final String id;
  final String login;
  final String avatarUrl;
}
