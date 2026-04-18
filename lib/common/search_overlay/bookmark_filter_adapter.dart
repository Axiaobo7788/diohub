import 'package:diohub_database/database/enums/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart' show Octicons;

import '../../providers/filter_state_providers.dart';
import '../../providers/notifier_update_extension.dart';
import 'filter_section_def.dart';
import 'filter_state_adapter.dart';
import 'filter_value.dart';

/// FilterStateAdapter for BookmarkFilter.
class BookmarkFilterAdapter extends FilterStateAdapter {
  BookmarkFilterAdapter(this._ref, this._provider);

  final WidgetRef _ref;
  final NotifierProvider<Notifier<BookmarkFilter>, BookmarkFilter> _provider;

  BookmarkFilter get _state => _ref.read(_provider);
  Notifier<BookmarkFilter> get _notifier => _ref.read(_provider.notifier);

  @override
  List<FilterSectionDef> get sections => [
        MultiSelectFilterSection(
          id: 'entityType',
          displayName: 'Type',
          icon: Octicons.tag,
          options: {
            'null': 'All types',
            'repo': 'Repository',
            'issue': 'Issue',
            'pr': 'Pull Request',
            'commit': 'Commit',
            'release': 'Release',
          },
        ),
        StaticFilterSection(
          id: 'state',
          displayName: 'State',
          icon: Octicons.issue_opened,
          options: {
            'null': 'All',
            'open': 'Open',
            'closed': 'Closed',
            'merged': 'Merged',
          },
        ),
        ToggleFilterSection(
          id: 'hasDrafts',
          displayName: 'With drafts',
          icon: Icons.edit_note_rounded,
        ),
        ToggleFilterSection(
          id: 'hasDownloads',
          displayName: 'With downloads',
          icon: Icons.download_rounded,
        ),
      ];

  @override
  bool isActive(String sectionId) {
    return switch (sectionId) {
      'entityType' => _state.entityType != null,
      'state' => _state.state != null,
      'hasDrafts' => _state.hasDrafts,
      'hasDownloads' => _state.hasDownloads,
      _ => false,
    };
  }

  @override
  FilterValue getValue(String sectionId) {
    return switch (sectionId) {
      'entityType' => FilterValue.singleSelect(_state.entityType?.dbValue),
      'state' => FilterValue.singleSelect(_state.state?.dbValue),
      'hasDrafts' => FilterValue.toggle(_state.hasDrafts),
      'hasDownloads' => FilterValue.toggle(_state.hasDownloads),
      _ => FilterValue.singleSelect(null),
    };
  }

  @override
  void setValue(String sectionId, FilterValue value) {
    switch (sectionId) {
      case 'entityType':
        value.when(
          singleSelect: (v) {
            final typeValue = v == 'null' || v == null
                ? null
                : EntityTypeFilter.values.firstWhere((t) => t.dbValue == v);
            _notifier.update((s) => s.copyWith(entityType: typeValue));
          },
          multiSelect: (_) => throw ArgumentError('entityType expects singleSelect'),
          toggle: (_) => throw ArgumentError('entityType expects singleSelect'),
        );
      case 'state':
        value.when(
          singleSelect: (v) {
            final stateValue = v == 'null' || v == null
                ? null
                : EntityState.values.firstWhere((s) => s.dbValue == v);
            _notifier.update((s) => s.copyWith(state: stateValue));
          },
          multiSelect: (_) => throw ArgumentError('state expects singleSelect'),
          toggle: (_) => throw ArgumentError('state expects singleSelect'),
        );
      case 'hasDrafts':
        value.when(
          singleSelect: (_) => throw ArgumentError('hasDrafts expects toggle'),
          multiSelect: (_) => throw ArgumentError('hasDrafts expects toggle'),
          toggle: (v) => _notifier.update((s) => s.copyWith(hasDrafts: v)),
        );
      case 'hasDownloads':
        value.when(
          singleSelect: (_) => throw ArgumentError('hasDownloads expects toggle'),
          multiSelect: (_) => throw ArgumentError('hasDownloads expects toggle'),
          toggle: (v) => _notifier.update((s) => s.copyWith(hasDownloads: v)),
        );
    }
    notifyListeners();
  }

  @override
  void clearAll() {
    _notifier.update((_) => const BookmarkFilter());
    notifyListeners();
  }

  @override
  int get activeCount {
    int count = 0;
    if (_state.entityType != null) count++;
    if (_state.state != null) count++;
    if (_state.hasDrafts) count++;
    if (_state.hasDownloads) count++;
    return count;
  }
}
