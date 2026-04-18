/// State for download_history_entries.state column.
enum DownloadState {
  completed('completed'),
  downloading('downloading'),
  failed('failed');

  const DownloadState(this.dbValue);
  final String dbValue;

  String get displayLabel => switch (this) {
        DownloadState.completed => 'Completed',
        DownloadState.downloading => 'Downloading',
        DownloadState.failed => 'Failed',
      };

  /// Parse from DB string; returns null if [v] is null or unknown.
  static DownloadState? fromDb(String? v) {
    if (v == null) return null;
    for (final e in DownloadState.values) {
      if (e.dbValue == v) return e;
    }
    return null;
  }
}
