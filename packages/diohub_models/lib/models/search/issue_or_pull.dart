import 'package:diohub_graphql/fragments/fragment_typedefs.dart';

/// Result item from issues/pulls search (typed, no [dynamic]).
sealed class IssueOrPull {
  const IssueOrPull();
}

final class IssueResult extends IssueOrPull {
  const IssueResult(this.data);
  final IssueCardData data;
}

final class PullResult extends IssueOrPull {
  const PullResult(this.data);
  final PullCardData data;
}
