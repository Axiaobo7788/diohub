/// Discriminator for log_entries.level column.
/// Replaces 10 magic string sites.
enum LogLevel {
  error('error'),
  warning('warning'),
  info('info'),
  verbose('verbose');

  const LogLevel(this.dbValue);
  final String dbValue;

  /// Display name for UI filter chips.
  String get displayLabel => switch (this) {
        LogLevel.error => 'Errors',
        LogLevel.warning => 'Warnings',
        LogLevel.info => 'Info',
        LogLevel.verbose => 'Verbose',
      };

  bool get isError => this == LogLevel.error;
  bool get isWarning => this == LogLevel.warning;

  /// Parse from DB string; returns null if [v] is null or unknown.
  static LogLevel? fromDb(String? v) {
    if (v == null) return null;
    for (final e in LogLevel.values) {
      if (e.dbValue == v) return e;
    }
    return null;
  }
}
