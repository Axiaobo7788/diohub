/// Types of contribution chips that can be tapped for detailed views
enum ContributionChipType {
  commits,
  pullRequests,
  issues,
  reviews,
  createdRepos,
  private;

  /// Maps stat type string from [ContributionStatisticsSection.onStatTap] to enum.
  static ContributionChipType? fromStatType(final String statType) {
    switch (statType) {
      case 'commits':
        return ContributionChipType.commits;
      case 'pullRequests':
        return ContributionChipType.pullRequests;
      case 'issues':
        return ContributionChipType.issues;
      case 'reviews':
        return ContributionChipType.reviews;
      default:
        return null;
    }
  }
}
