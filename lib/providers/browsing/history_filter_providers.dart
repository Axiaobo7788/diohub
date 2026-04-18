import 'package:diohub_database/database/enums/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_filter_providers.freezed.dart';

/// Filter state for history tab.
@freezed
abstract class HistoryFilter with _$HistoryFilter {
  const HistoryFilter._();

  const factory HistoryFilter({
    EntityTypeFilter? entityType,
    HistoryTimeRange? timeRange,
    @Default(false) bool bookmarkedOnly,
    String? searchQuery,
  }) = _HistoryFilter;
}

class _HistoryFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => const HistoryFilter();
}

final historyFilterProvider =
    NotifierProvider<_HistoryFilterNotifier, HistoryFilter>(
  _HistoryFilterNotifier.new,
);
