/// Numeric range for GitHub search qualifiers (e.g. stars:>100, comments:10..50).
sealed class NumericRange {
  const NumericRange();
  String toRangeString();
}

final class ExactNumeric extends NumericRange {
  const ExactNumeric(this.value);
  final int value;
  @override
  String toRangeString() => '$value';
}

final class GreaterThanNumeric extends NumericRange {
  const GreaterThanNumeric(this.value);
  final int value;
  @override
  String toRangeString() => '>$value';
}

final class GreaterOrEqualNumeric extends NumericRange {
  const GreaterOrEqualNumeric(this.value);
  final int value;
  @override
  String toRangeString() => '>=$value';
}

final class LessThanNumeric extends NumericRange {
  const LessThanNumeric(this.value);
  final int value;
  @override
  String toRangeString() => '<$value';
}

final class LessOrEqualNumeric extends NumericRange {
  const LessOrEqualNumeric(this.value);
  final int value;
  @override
  String toRangeString() => '<=$value';
}

final class BetweenNumeric extends NumericRange {
  const BetweenNumeric(this.low, this.high);
  final int low;
  final int high;
  @override
  String toRangeString() => '$low..$high';
}

/// Date range for GitHub search qualifiers (e.g. created:>2024-01-01).
sealed class DateRange {
  const DateRange();
  String toRangeString();
}

final class ExactDate extends DateRange {
  const ExactDate(this.value);
  final DateTime value;
  @override
  String toRangeString() => _format(value);
}

final class AfterDate extends DateRange {
  const AfterDate(this.value);
  final DateTime value;
  @override
  String toRangeString() => '>${_format(value)}';
}

final class BeforeDate extends DateRange {
  const BeforeDate(this.value);
  final DateTime value;
  @override
  String toRangeString() => '<${_format(value)}';
}

final class BetweenDate extends DateRange {
  const BetweenDate(this.start, this.end);
  final DateTime start;
  final DateTime end;
  @override
  String toRangeString() => '${_format(start)}..${_format(end)}';
}

String _format(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Parse a string like "100", ">100", ">=100", "<100", "<=100", "10..50".
NumericRange? tryParseNumericRange(String s) {
  final t = s.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('..')) return null;
  if (t.contains('..')) {
    final parts = t.split('..');
    if (parts.length != 2) return null;
    final low = int.tryParse(parts[0].trim());
    final high = int.tryParse(parts[1].trim());
    if (low == null || high == null || low > high) return null;
    return BetweenNumeric(low, high);
  }
  final isGte = t.startsWith('>=');
  final isLte = t.startsWith('<=');
  final isGt = t.startsWith('>') && !isGte;
  final isLt = t.startsWith('<') && !isLte;
  final numPart = (isGte || isLte)
      ? t.substring(2).trim()
      : (isGt || isLt)
          ? t.substring(1).trim()
          : t;
  final v = int.tryParse(numPart);
  if (v == null) return null;
  if (isGte) return GreaterOrEqualNumeric(v);
  if (isGt) return GreaterThanNumeric(v);
  if (isLte) return LessOrEqualNumeric(v);
  if (isLt) return LessThanNumeric(v);
  return ExactNumeric(v);
}

/// Parse a string like "2024-01-01", ">2024-01-01", "<2024-06-01", "2024-01-01..2024-06-01".
DateRange? tryParseDateRange(String s) {
  final t = s.trim();
  if (t.isEmpty) return null;
  DateTime? parseOne(String x) {
    final parts = x.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  if (t.contains('..')) {
    final parts = t.split('..');
    if (parts.length != 2) return null;
    final start = parseOne(parts[0].trim());
    final end = parseOne(parts[1].trim());
    if (start == null || end == null || start.isAfter(end)) return null;
    return BetweenDate(start, end);
  }
  final isGt = t.startsWith('>');
  final isLt = t.startsWith('<');
  final numPart = (isGt || isLt) ? t.substring(1).trim() : t;
  final v = parseOne(numPart);
  if (v == null) return null;
  if (isGt) return AfterDate(v);
  if (isLt) return BeforeDate(v);
  return ExactDate(v);
}
