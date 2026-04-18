import 'package:diohub/models/contributions/contribution_query_models.dart';

/// Utility functions for building contribution query keys and checking date ranges

/// Builds a typed provider key based on selected year or custom date range
/// Only recalculates when date range changes, not on every build
ContributionQueryKey buildContributionQueryKey({
  required final String userName,
  final int? selectedYear,
  final DateTime? customFromDate,
  final DateTime? customToDate,
  final bool useCustomRange = false,
}) {
  if (useCustomRange && customFromDate != null && customToDate != null) {
    // Normalize dates to day level for stable keys
    final DateTime from = DateTime(
      customFromDate.year,
      customFromDate.month,
      customFromDate.day,
    );
    final DateTime to = DateTime(
      customToDate.year,
      customToDate.month,
      customToDate.day,
    );
    return ContributionQueryKey.customRange(
      userName: userName,
      from: from,
      to: to,
    );
  }

  if (selectedYear == null) {
    // Default: last year from today
    return ContributionQueryKey.lastYear(userName);
  } else {
    // Specific year
    return ContributionQueryKey.year(userName, selectedYear);
  }
}

/// Checks if the current custom range matches "Since joining GitHub"
bool isSinceJoining({
  required final bool useCustomRange,
  required final DateTime? customFromDate,
  required final DateTime? createdAt,
}) {
  if (!useCustomRange || customFromDate == null || createdAt == null) {
    return false;
  }
  return customFromDate.year == createdAt.year &&
      customFromDate.month == createdAt.month &&
      customFromDate.day == createdAt.day;
}

/// Generates list of available years from joined date to current year
List<int> generateAvailableYears(final DateTime? createdAt) {
  if (createdAt == null) return <int>[];

  final int currentYear = DateTime.now().year;
  final int joinedYear = createdAt.year;

  return List.generate(
    currentYear - joinedYear + 1,
    (final int index) => joinedYear + index,
  ).reversed.toList();
}
