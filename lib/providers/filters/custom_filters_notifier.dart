import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/models/filters/custom_filter.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/repositories/custom_filter_repository.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customFilterRepositoryProvider = Provider<CustomFilterRepository>(
  (ref) => CustomFilterRepository(ref.watch(appMetaDaoProvider)),
);

final customFiltersNotifierProvider =
    AsyncNotifierProvider<CustomFiltersNotifier, List<CustomFilter>>(
      CustomFiltersNotifier.new,
    );

class CustomFiltersNotifier extends AsyncNotifier<List<CustomFilter>> {
  @override
  Future<List<CustomFilter>> build() async => _load();

  Future<List<CustomFilter>> _load() async {
    try {
      return ref.read(customFilterRepositoryProvider).load();
    } catch (e, st) {
      AppLogger.warning(
        'Failed to load custom filters from storage',
        error: e,
        stackTrace: st,
        tag: 'CustomFiltersNotifier',
      );
      return [];
    }
  }

  Future<void> _persist(List<CustomFilter> list) async {
    await ref.read(customFilterRepositoryProvider).save(list);
  }

  /// Filters that apply to [scope].
  List<CustomFilter> forScope(SearchScope scope) {
    final list = (state.hasValue ? state.value : null) ?? [];
    return list.where((f) => f.appliesTo(scope)).toList();
  }

  Future<void> save(CustomFilter filter) async {
    final list = state.requireValue;
    final newList = [...list, filter];
    state = AsyncData(newList);
    await _persist(newList);
  }

  Future<void> updateFilter(CustomFilter filter) async {
    final list = state.requireValue;
    final newList = [for (final f in list) f.id == filter.id ? filter : f];
    state = AsyncData(newList);
    await _persist(newList);
  }

  Future<void> delete(String id) async {
    final list = state.requireValue.where((f) => f.id != id).toList();
    state = AsyncData(list);
    await _persist(list);
  }

  Future<void> reorder(List<CustomFilter> ordered) async {
    final list = state.requireValue;
    final ids = ordered.map((e) => e.id).toSet();
    final rest = list.where((f) => !ids.contains(f.id)).toList();
    final newList = [...ordered, ...rest];
    state = AsyncData(newList);
    await _persist(newList);
  }

  Future<CustomFilter> duplicate(CustomFilter filter) async {
    final list = state.requireValue;
    final copy = CustomFilter(
      id: '${filter.id}_copy_${DateTime.now().millisecondsSinceEpoch}',
      name: '${filter.name} (copy)',
      searchType: filter.searchType,
      qualifiers: filter.qualifiers,
      sort: filter.sort,
      freeText: filter.freeText,
      repoScope: filter.repoScope,
      createdAt: DateTime.now(),
    );
    final newList = [...list, copy];
    state = AsyncData(newList);
    await _persist(newList);
    return copy;
  }
}
