/// Sealed operation types for issue/PR mutations.
///
/// Each mutation type defines the data needed to perform a specific
/// mutation operation on an issue or pull request (labels, assignees,
/// close, reopen, comment, etc.).
library;

import 'package:diohub_graphql/schema_typedefs.dart';

/// Sealed base class for all issue/PR mutation operations.
sealed class IssuePullMutation {
  const IssuePullMutation();
  
  /// Error message to show if the mutation fails.
  String get errorMessage;

  /// Success toast message; null means no toast.
  String? get successMessage => null;
}

class AddLabels extends IssuePullMutation {
  const AddLabels(this.labelIds);
  final List<String> labelIds;
  
  @override
  String get errorMessage => "Couldn't add labels";
  
  @override
  String? get successMessage => 'Labels updated';
}

class RemoveLabels extends IssuePullMutation {
  const RemoveLabels(this.labelIds);
  final List<String> labelIds;
  
  @override
  String get errorMessage => "Couldn't remove labels";
  
  @override
  String? get successMessage => 'Labels updated';
}

class AddAssignees extends IssuePullMutation {
  const AddAssignees(this.assigneeIds);
  final List<String> assigneeIds;
  
  @override
  String get errorMessage => "Couldn't add assignees";
  
  @override
  String? get successMessage => 'Assignees updated';
}

class RemoveAssignees extends IssuePullMutation {
  const RemoveAssignees(this.assigneeIds);
  final List<String> assigneeIds;
  
  @override
  String get errorMessage => "Couldn't remove assignees";
  
  @override
  String? get successMessage => 'Assignees updated';
}

class CloseIssue extends IssuePullMutation {
  const CloseIssue([this.reason]);
  final IssueClosedStateReason? reason;
  
  @override
  String get errorMessage => "Couldn't close issue";
  
  @override
  String? get successMessage => 'Issue closed';
}

class ReopenIssue extends IssuePullMutation {
  const ReopenIssue();
  
  @override
  String get errorMessage => "Couldn't reopen issue";
  
  @override
  String? get successMessage => 'Issue reopened';
}

class ClosePullRequest extends IssuePullMutation {
  const ClosePullRequest();
  
  @override
  String get errorMessage => "Couldn't close pull request";
  
  @override
  String? get successMessage => 'Pull request closed';
}

class ReopenPullRequest extends IssuePullMutation {
  const ReopenPullRequest();
  
  @override
  String get errorMessage => "Couldn't reopen pull request";
  
  @override
  String? get successMessage => 'Pull request reopened';
}

class AddComment extends IssuePullMutation {
  const AddComment(this.body);
  final String body;
  
  @override
  String get errorMessage => "Couldn't add comment";
}

class SetIssueMilestone extends IssuePullMutation {
  const SetIssueMilestone(this.milestoneId);
  final String? milestoneId;
  
  @override
  String get errorMessage => "Couldn't set milestone";
  
  @override
  String? get successMessage => 'Milestone updated';
}

class SetPullRequestMilestone extends IssuePullMutation {
  const SetPullRequestMilestone(this.milestoneId);
  final String? milestoneId;
  
  @override
  String get errorMessage => "Couldn't set milestone";
  
  @override
  String? get successMessage => 'Milestone updated';
}

class UpdateIssue extends IssuePullMutation {
  const UpdateIssue({
    this.title,
    this.body,
    this.state,
    this.assigneeIds,
    this.labelIds,
    this.milestoneId,
  });
  
  final String? title;
  final String? body;
  final IssueState? state;
  final List<String>? assigneeIds;
  final List<String>? labelIds;
  final String? milestoneId;
  
  @override
  String get errorMessage => "Couldn't update issue";
  
  @override
  String? get successMessage => 'Issue updated';
}

class UpdatePullRequest extends IssuePullMutation {
  const UpdatePullRequest({
    this.title,
    this.body,
    this.maintainerCanModify,
    this.assigneeIds,
    this.labelIds,
    this.milestoneId,
    this.baseRefName,
    this.state,
  });
  
  final String? title;
  final String? body;
  final bool? maintainerCanModify;
  final List<String>? assigneeIds;
  final List<String>? labelIds;
  final String? milestoneId;
  final String? baseRefName;
  final PullRequestUpdateState? state;
  
  @override
  String get errorMessage => "Couldn't update pull request";
  
  @override
  String? get successMessage => 'Pull request updated';
}
