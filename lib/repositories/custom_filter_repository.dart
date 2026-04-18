import 'dart:convert';

import 'package:diohub_database/database/database.dart';
import 'package:diohub/models/filters/custom_filter.dart';
import 'package:diohub/utils/json_decode_safe.dart';

const String _storageKey = 'custom_filters_v1';

/// Persists [CustomFilter] list via [AppMetaDao] (single key, JSON-encoded).
/// Used by [CustomFiltersNotifier]; keeps JSON and DAO access out of the notifier.
class CustomFilterRepository {
  const CustomFilterRepository(this._dao);

  final AppMetaDao _dao;

  Future<List<CustomFilter>> load() async {
    final raw = await _dao.getValue(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final List<dynamic> list = tryDecodeList(raw, tag: 'CustomFilterRepository.getAllFilters') ?? [];
    return list
        .map((e) => CustomFilter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<CustomFilter> filters) async {
    final list = filters.map((f) => f.toJson()).toList();
    await _dao.setValue(_storageKey, jsonEncode(list));
  }
}
