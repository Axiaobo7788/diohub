import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notifications/notifications_filters_provider.dart';
import 'filter_section_def.dart';
import 'filter_state_adapter.dart';
import 'filter_value.dart';

/// FilterStateAdapter for NotificationsFiltersState.
class NotificationsFilterAdapter extends FilterStateAdapter {
  NotificationsFilterAdapter(this._ref);

  final WidgetRef _ref;

  NotificationsFiltersState get _state => _ref.read(notificationsFiltersProvider);
  NotificationsFiltersNotifier get _notifier =>
      _ref.read(notificationsFiltersProvider.notifier);

  @override
  List<FilterSectionDef> get sections => [
        ToggleFilterSection(
          id: 'onlyUnread',
          displayName: 'Only unread',
          icon: Icons.mark_email_unread_rounded,
        ),
        MultiSelectFilterSection(
          id: 'showOnlyReasons',
          displayName: 'Show only',
          icon: Icons.filter_list_rounded,
          options: {
            for (final item in notificationFilterReasonItems)
              item.id: item.label,
          },
        ),
      ];

  @override
  bool isActive(String sectionId) {
    return switch (sectionId) {
      'onlyUnread' => _state.onlyUnread,
      'showOnlyReasons' => _state.showOnlyReasons.isNotEmpty,
      _ => false,
    };
  }

  @override
  FilterValue getValue(String sectionId) {
    return switch (sectionId) {
      'onlyUnread' => FilterValue.toggle(_state.onlyUnread),
      'showOnlyReasons' => FilterValue.multiSelect(_state.showOnlyReasons),
      _ => FilterValue.singleSelect(null),
    };
  }

  @override
  void setValue(String sectionId, FilterValue value) {
    switch (sectionId) {
      case 'onlyUnread':
        value.when(
          singleSelect: (_) => throw ArgumentError('onlyUnread expects toggle'),
          multiSelect: (_) => throw ArgumentError('onlyUnread expects toggle'),
          toggle: (v) => _notifier.setOnlyUnread(v),
        );
      case 'showOnlyReasons':
        value.when(
          singleSelect: (_) => throw ArgumentError('showOnlyReasons expects multiSelect'),
          multiSelect: (v) => _notifier.setShowOnlyReasons(v),
          toggle: (_) => throw ArgumentError('showOnlyReasons expects multiSelect'),
        );
    }
    notifyListeners();
  }

  @override
  void clearAll() {
    _notifier.setOnlyUnread(false);
    _notifier.setShowOnlyReasons([]);
    notifyListeners();
  }

  @override
  int get activeCount {
    int count = 0;
    if (_state.onlyUnread) count++;
    if (_state.showOnlyReasons.isNotEmpty) count++;
    return count;
  }
}
