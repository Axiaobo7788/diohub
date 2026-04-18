import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:diohub_models/models/entity_ref.dart';

import '../../providers/notifier_update_extension.dart';
import '../../view/issues_pulls/widgets/pull_threads_view.dart';
import 'filter_section_def.dart';
import 'filter_state_adapter.dart';
import 'filter_value.dart';

/// FilterStateAdapter for PR Threads (all/unresolved/resolved).
class ThreadsFilterAdapter extends FilterStateAdapter {
  ThreadsFilterAdapter(this._ref, this._pullRef);

  final WidgetRef _ref;
  final PullRequestRef _pullRef;

  ThreadsFilter get _state => _ref.read(pullThreadsFilterProvider(_pullRef));

  @override
  List<FilterSectionDef> get sections => [
        StaticFilterSection(
          id: 'status',
          displayName: 'Status',
          icon: Octicons.comment_discussion,
          options: {
            'all': 'All',
            'unresolved': 'Unresolved',
            'resolved': 'Resolved',
          },
        ),
      ];

  @override
  bool isActive(String sectionId) {
    return sectionId == 'status' && _state != ThreadsFilter.all;
  }

  @override
  FilterValue getValue(String sectionId) {
    if (sectionId == 'status') {
      return FilterValue.singleSelect(
        switch (_state) {
          ThreadsFilter.all => 'all',
          ThreadsFilter.unresolved => 'unresolved',
          ThreadsFilter.resolved => 'resolved',
        },
      );
    }
    return FilterValue.singleSelect(null);
  }

  @override
  void setValue(String sectionId, FilterValue value) {
    if (sectionId == 'status') {
      value.when(
        singleSelect: (v) {
          final newFilter = switch (v) {
            'unresolved' => ThreadsFilter.unresolved,
            'resolved' => ThreadsFilter.resolved,
            _ => ThreadsFilter.all,
          };
          _ref
              .read(pullThreadsFilterProvider(_pullRef).notifier)
              .update((_) => newFilter);
          // Trigger refilter on pagination controller
          final controller = _ref.read(pullThreadsControllerProvider(_pullRef));
          controller?.refilter();
          notifyListeners();
        },
        multiSelect: (_) => throw ArgumentError('status expects singleSelect'),
        toggle: (_) => throw ArgumentError('status expects singleSelect'),
      );
    }
  }

  @override
  void clearAll() {
    _ref
        .read(pullThreadsFilterProvider(_pullRef).notifier)
        .update((_) => ThreadsFilter.all);
    final controller = _ref.read(pullThreadsControllerProvider(_pullRef));
    controller?.refilter();
    notifyListeners();
  }

  @override
  int get activeCount => _state != ThreadsFilter.all ? 1 : 0;
}
