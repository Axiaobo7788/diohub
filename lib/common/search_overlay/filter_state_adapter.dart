import 'package:flutter/foundation.dart';
import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/filter_value.dart';

/// Generic interface for reading/writing filter state.
///
/// Decouples [UnifiedFilterSheet] from SearchStateNotifier so we can
/// use it for Bookmarks, Inbox, Threads, Commits, etc.
///
/// Concrete adapters wrap existing state notifiers (SearchStateNotifier,
/// bookmarkFilterProvider, notificationsFiltersProvider, etc.).
abstract class FilterStateAdapter with ChangeNotifier {
  /// The list of filter sections to render in the sheet.
  List<FilterSectionDef> get sections;

  /// Whether the section has an active value (non-default/non-empty).
  bool isActive(String sectionId);

  /// Get the current value for a section (wrapped in type-safe FilterValue).
  FilterValue getValue(String sectionId);

  /// Set the value for a section. Type must match section's expected value type.
  void setValue(String sectionId, FilterValue value);

  /// Clear all active filters (reset to defaults).
  void clearAll();

  /// Total count of active filters across all sections.
  int get activeCount;
}
