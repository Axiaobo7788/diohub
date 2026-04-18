import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';

/// Typed result of an issue/PR mutation (labels, assignees, close, reopen, milestone, etc.).
/// Services parse the mutation response into this instead of passing raw [Map].
/// Exactly one of [issue] or [pullRequest] is non-null.
class SubjectMutationPayload {
  const SubjectMutationPayload._({this.issue, this.pullRequest})
      : assert(issue != null || pullRequest != null),
        assert(issue == null || pullRequest == null);

  final IssueInfo? issue;
  final PullInfo? pullRequest;

  /// Parses mutation response JSON (subject/labelable/assignable) into a typed payload.
  static SubjectMutationPayload? fromJson(final Map<String, dynamic>? json) {
    if (json == null) return null;
    final String? typename = json['__typename'] as String?;
    if (typename == 'Issue') {
      final IssueInfo? issue =
          IssueInfo.fromJson(json);
      return issue != null ? SubjectMutationPayload._(issue: issue) : null;
    }
    if (typename == 'PullRequest') {
      final PullInfo? pr =
          PullInfo.fromJson(json);
      return pr != null ? SubjectMutationPayload._(pullRequest: pr) : null;
    }
    return null;
  }
}
