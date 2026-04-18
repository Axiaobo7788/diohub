enum SecuritySeverity {
  critical,
  high,
  medium,
  low;

  static SecuritySeverity? fromString(String? value) {
    if (value == null) return null;
    return switch (value.toUpperCase()) {
      'CRITICAL' => SecuritySeverity.critical,
      'HIGH' => SecuritySeverity.high,
      'MEDIUM' => SecuritySeverity.medium,
      'LOW' => SecuritySeverity.low,
      _ => null,
    };
  }
}
