/// Sort order for bookmarks. Pure data — no Drift dependency.
/// The DAO maps this to OrderingTerm internally.
enum BookmarkOrder {
  newest('Newest first'),
  stars('Stars'),
  updated('Recently updated'),
  alpha('A–Z');

  const BookmarkOrder(this.displayLabel);
  final String displayLabel;
}
