import 'package:diohub_database/database/database.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Section for "By Time" history: one date bucket with one or more groups.
class HistorySection {
  const HistorySection({
    required this.date,
    required this.groups,
  });
  final DateTime date;
  final List<HistoryGroup> groups;

  String get label => dateLabel(date);
}

/// One group within a [HistorySection]: either a search session (listId set) or standalone visits.
class HistoryGroup {
  const HistoryGroup({
    required this.entries,
    this.listId,
    this.searchQuery,
    this.isSearchSession = false,
  });
  final List<HistoryWithEntity> entries;
  final String? listId;
  final String? searchQuery;
  final bool isSearchSession;

  int get count => entries.length;
}

/// Human-readable label for a date in history sections.
String dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateOnly = DateTime(date.year, date.month, date.day);

  if (dateOnly == today) return 'Today';
  if (dateOnly == yesterday) return 'Yesterday';

  final weekStart = today.subtract(Duration(days: now.weekday - 1));
  if (dateOnly.isAfter(weekStart.subtract(const Duration(days: 1))) &&
      dateOnly.isBefore(today.add(const Duration(days: 1)))) {
    return 'This week';
  }

  final monthStart = DateTime(now.year, now.month, 1);
  if (dateOnly.isAfter(monthStart.subtract(const Duration(days: 1))) &&
      dateOnly.isBefore(today.add(const Duration(days: 1)))) {
    return 'This month';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

Map<K, List<T>> _groupBy<K, T>(List<T> list, K Function(T) keyOf) {
  final map = <K, List<T>>{};
  for (final e in list) {
    map.putIfAbsent(keyOf(e), () => []).add(e);
  }
  return map;
}

/// Grouped history by date, then by listId (search session). Used when [HistoryViewMode.byTime].
final groupedHistoryProvider =
    Provider<AsyncValue<List<HistorySection>>>((ref) {
  final entries = ref.watch(filteredHistoryProvider);
  return entries.when(
    data: (list) {
      final byDate = _groupBy<DateTime, HistoryWithEntity>(
        list,
        (e) => DateTime(e.visit.visitedAt.year, e.visit.visitedAt.month,
            e.visit.visitedAt.day),
      );
      final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

      final sections = sortedDates.map((dateKey) {
        final dayEntries = byDate[dateKey]!;
        // Single group per day (HistoryEntry has no listId/session).
        final group = HistoryGroup(
          entries: dayEntries,
          listId: null,
          searchQuery: null,
          isSearchSession: false,
        );
        return HistorySection(date: dateKey, groups: [group]);
      }).toList();

      return AsyncData(sections);
    },
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});
