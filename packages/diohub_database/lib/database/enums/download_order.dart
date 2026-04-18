/// Sort order for downloads. Pure data — no Drift dependency.
/// The DAO maps this to OrderingTerm internally.
enum DownloadOrder {
  newest('Newest first'),
  oldest('Oldest first'),
  largest('Largest first');

  const DownloadOrder(this.displayLabel);
  final String displayLabel;

  /// Parse from filter string ('newest' | 'oldest' | 'largest'); defaults to newest.
  static DownloadOrder fromDb(String? v) => switch (v) {
        'oldest' => DownloadOrder.oldest,
        'largest' => DownloadOrder.largest,
        _ => DownloadOrder.newest,
      };
}
