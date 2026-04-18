/// Contribution statistic type.
enum ContributionType {
  commits,
  pullRequests,
  issues,
  codeReview;

  factory ContributionType.fromString(String value) {
    final v = value.toLowerCase();
    if (v == 'commits') return ContributionType.commits;
    if (v == 'pullrequests' || v == 'pull_requests') return ContributionType.pullRequests;
    if (v == 'issues') return ContributionType.issues;
    if (v == 'codereview' || v == 'code_review') return ContributionType.codeReview;
    return ContributionType.commits;
  }
}
