import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart' show IconData;

/// Shared status options for issues/PRs filter section.
const Map<String, String> kIssuesPullsStatusOptions = <String, String>{
  'open': 'Open',
  'closed': 'Closed',
  'merged': 'Merged',
};

/// One selectable option in a filter chip row or paginated picker.
class FilterOption {
  const FilterOption(this.display, this.value);
  final String display;
  final String value;
}

/// Base for all filter sections shown in SearchFilterSheet.
/// Each subtype is rendered by the sheet via a single switch; no pickerType dispatch.
sealed class FilterSectionDef {
  const FilterSectionDef({
    required this.id,
    required this.displayName,
    required this.icon,
    this.multiSelect = false,
  });

  final String id;
  final String displayName;
  final IconData icon;
  final bool multiSelect;

  /// Options for static chip rows; null for non-static sections.
  Map<String, String>? get optionsOrNull => null;
}

/// Fixed set of chips (status: open/closed, sort options).
final class StaticFilterSection extends FilterSectionDef {
  const StaticFilterSection({
    required super.id,
    required super.displayName,
    required super.icon,
    required this.options,
    super.multiSelect,
  });

  final Map<String, String> options;

  @override
  Map<String, String>? get optionsOrNull => options;
}

/// Paginated list picker backed by an API call (labels, assignees, milestones, branches).
/// [repo] is required for repo-scoped pickers; fetch is resolved in the sheet via provider.
final class PaginatedFilterSection extends FilterSectionDef {
  const PaginatedFilterSection({
    required super.id,
    required super.displayName,
    required super.icon,
    required this.repo,
    this.searchable = true,
    this.searchHint,
    super.multiSelect,
  });

  final RepoRef repo;
  final bool searchable;
  final String? searchHint;
}

/// Preloaded chip list from a one-shot async call (e.g. viewer orgs).
/// When [load] is null, the sheet uses filterDataProvider(cacheKey, id).
final class PreloadedFilterSection extends FilterSectionDef {
  const PreloadedFilterSection({
    required super.id,
    required super.displayName,
    required super.icon,
    this.load,
    super.multiSelect,
  });

  final Future<List<FilterOption>> Function()? load;
}

/// User search with text field (author, assignee outside repo context).
final class UserSearchFilterSection extends FilterSectionDef {
  const UserSearchFilterSection({
    required super.id,
    required super.displayName,
    required super.icon,
    super.multiSelect,
  });
}

/// Date range picker (created, updated, closed, merged).
final class DateFilterSection extends FilterSectionDef {
  const DateFilterSection({
    required super.id,
    required super.displayName,
    required super.icon,
  });
}

/// Numeric range picker (stars, forks, comments).
final class NumberFilterSection extends FilterSectionDef {
  const NumberFilterSection({
    required super.id,
    required super.displayName,
    required super.icon,
  });
}

/// Free text input (repo in non-repo context, path, filename).
final class TextFilterSection extends FilterSectionDef {
  const TextFilterSection({
    required super.id,
    required super.displayName,
    required super.icon,
  });
}

/// Toggle switch (e.g. "Only unread", "Has drafts", "Has downloads").
final class ToggleFilterSection extends FilterSectionDef {
  const ToggleFilterSection({
    required super.id,
    required super.displayName,
    required super.icon,
  });
}

/// Multi-select from a fixed list (e.g. notification reasons, entity types).
final class MultiSelectFilterSection extends FilterSectionDef {
  const MultiSelectFilterSection({
    required super.id,
    required super.displayName,
    required super.icon,
    required this.options,
  });

  final Map<String, String> options;
}
