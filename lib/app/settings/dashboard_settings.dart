import 'package:diohub/app/settings/settings_descriptor.dart';

enum DashboardSectionId {
  stats,
  contributions,
  reviewRequests,
  assignedIssues,
  yourPRs,
  pinnedRepos,
  bookmarks,
  savedSearches,
  recentHistory,
}

class DashboardSectionConfig {
  const DashboardSectionConfig({this.visible = true, this.limit = 3});

  final bool visible;
  final int limit;

  factory DashboardSectionConfig.fromJson(Map<String, dynamic> json) {
    return DashboardSectionConfig(
      visible: json['visible'] as bool? ?? true,
      limit: json['limit'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
        'visible': visible,
        'limit': limit,
      };

  DashboardSectionConfig copyWith({bool? visible, int? limit}) {
    return DashboardSectionConfig(
      visible: visible ?? this.visible,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardSectionConfig &&
          runtimeType == other.runtimeType &&
          visible == other.visible &&
          limit == other.limit;

  @override
  int get hashCode => visible.hashCode ^ limit.hashCode;
}

class DashboardSettings {
  const DashboardSettings({
    this.sectionOrder = DashboardSectionId.values,
    this.sections = const {},
  });

  final List<DashboardSectionId> sectionOrder;
  final Map<DashboardSectionId, DashboardSectionConfig> sections;

  DashboardSectionConfig configFor(DashboardSectionId id) =>
      sections[id] ?? const DashboardSectionConfig();

  bool isVisible(DashboardSectionId id) => configFor(id).visible;

  int limitFor(DashboardSectionId id) => configFor(id).limit;

  factory DashboardSettings.fromJson(Map<String, dynamic> json) {
    final List<DashboardSectionId> order;
    if (json['sectionOrder'] != null) {
      order = (json['sectionOrder'] as List)
          .map((e) => DashboardSectionId.values.firstWhere(
                (id) => id.name == e,
                orElse: () => DashboardSectionId.stats,
              ))
          .toList();
    } else {
      order = DashboardSectionId.values;
    }

    final Map<DashboardSectionId, DashboardSectionConfig> sectionsMap = {};
    if (json['sections'] != null) {
      final sectionsJson = json['sections'] as Map<String, dynamic>;
      for (final entry in sectionsJson.entries) {
        try {
          final id = DashboardSectionId.values.firstWhere(
            (id) => id.name == entry.key,
          );
          sectionsMap[id] =
              DashboardSectionConfig.fromJson(entry.value as Map<String, dynamic>);
        } catch (_) {
          // Skip invalid section IDs
        }
      }
    }

    return DashboardSettings(
      sectionOrder: order,
      sections: sectionsMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'sectionOrder': sectionOrder.map((e) => e.name).toList(),
        'sections': Map.fromEntries(
          sections.entries.map((e) => MapEntry(e.key.name, e.value.toJson())),
        ),
      };

  DashboardSettings copyWith({
    List<DashboardSectionId>? sectionOrder,
    Map<DashboardSectionId, DashboardSectionConfig>? sections,
  }) {
    return DashboardSettings(
      sectionOrder: sectionOrder ?? this.sectionOrder,
      sections: sections ?? this.sections,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardSettings &&
          runtimeType == other.runtimeType &&
          _listEquals(sectionOrder, other.sectionOrder) &&
          _mapEquals(sections, other.sections);

  @override
  int get hashCode => sectionOrder.hashCode ^ sections.hashCode;
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}

Map<String, dynamic> _dashboardToJson(DashboardSettings value) => value.toJson();

const dashboardDescriptor = SettingsDescriptor<DashboardSettings>(
  key: 'dashboard_layout',
  defaultValue: DashboardSettings(),
  fromJson: DashboardSettings.fromJson,
  toJson: _dashboardToJson,
);
