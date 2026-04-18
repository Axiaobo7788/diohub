/// Time range filter for log viewer.
enum LogTimeRange {
  hour('Last hour'),
  day('Last 24h'),
  week('Last 7 days');

  const LogTimeRange(this.displayLabel);
  final String displayLabel;

  DateTime get since => DateTime.now().subtract(
        switch (this) {
          LogTimeRange.hour => const Duration(hours: 1),
          LogTimeRange.day => const Duration(days: 1),
          LogTimeRange.week => const Duration(days: 7),
        },
      );
}
