/// Time frame for repository traffic (views/clones) over the last 14 days.
enum TrafficPeriod {
  day,
  week;

  /// Query value for GitHub REST API: `per` (day | week).
  String get apiValue => name;
}
