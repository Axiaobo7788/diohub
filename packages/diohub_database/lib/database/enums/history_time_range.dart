/// Time range filter for history tab. Replaces stringly-typed switch.
enum HistoryTimeRange {
  today('Today'),
  week('This week'),
  month('This month');

  const HistoryTimeRange(this.displayLabel);
  final String displayLabel;

  /// Polymorphic: each variant computes its own cutoff DateTime.
  DateTime get since {
    final DateTime now = DateTime.now();
    return switch (this) {
      HistoryTimeRange.today => DateTime(now.year, now.month, now.day),
      HistoryTimeRange.week => now.subtract(const Duration(days: 7)),
      HistoryTimeRange.month => now.subtract(const Duration(days: 30)),
    };
  }
}
