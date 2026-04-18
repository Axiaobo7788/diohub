import 'package:diohub/app/settings/settings_descriptor.dart';

/// Screen types that support tab pinning and collapsed visibility (NavCenter positions).
enum ScreenTabType {
  repository,
  profile,
  issuePull,
  commitInfo,
  fileViewer;

  String get name => switch (this) {
        ScreenTabType.repository => 'repository',
        ScreenTabType.profile => 'profile',
        ScreenTabType.issuePull => 'issuePull',
        ScreenTabType.commitInfo => 'commitInfo',
        ScreenTabType.fileViewer => 'fileViewer',
      };

  static ScreenTabType fromName(final String name) =>
      ScreenTabType.values.firstWhere(
        (final ScreenTabType e) => e.name == name,
        orElse: () => ScreenTabType.repository,
      );
}

/// Persisted tab behavior: pinned tab labels and collapsed visibility overrides per screen.
class TabBehaviorSettings {
  const TabBehaviorSettings({
    this.pinnedTabs = const {},
    this.collapsedVisibleOverrides = const {},
  });

  factory TabBehaviorSettings.fromJson(final Map<String, dynamic> json) {
    final Map<ScreenTabType, Set<String>> pinned = _decodeMapOfSets(
      json['pinnedTabs'] as Map<String, dynamic>?,
    );
    final Map<ScreenTabType, Set<String>> collapsed = _decodeMapOfSets(
      json['collapsedVisibleOverrides'] as Map<String, dynamic>?,
    );
    return TabBehaviorSettings(
      pinnedTabs: pinned,
      collapsedVisibleOverrides: collapsed,
    );
  }

  static Map<ScreenTabType, Set<String>> _decodeMapOfSets(
    final Map<String, dynamic>? raw,
  ) {
    if (raw == null) return {};
    final Map<ScreenTabType, Set<String>> result = {};
    for (final MapEntry<String, dynamic> e in raw.entries) {
      final List<dynamic> list =
          e.value is List ? e.value as List<dynamic> : [];
      result[ScreenTabType.fromName(e.key)] =
          list.map((final dynamic x) => x as String).toSet();
    }
    return result;
  }

  static Map<String, dynamic> _encodeMapOfSets(
    final Map<ScreenTabType, Set<String>> map,
  ) {
    final Map<String, dynamic> result = {};
    for (final MapEntry<ScreenTabType, Set<String>> e in map.entries) {
      result[e.key.name] = e.value.toList();
    }
    return result;
  }

  final Map<ScreenTabType, Set<String>> pinnedTabs;
  final Map<ScreenTabType, Set<String>> collapsedVisibleOverrides;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'pinnedTabs': _encodeMapOfSets(pinnedTabs),
        'collapsedVisibleOverrides':
            _encodeMapOfSets(collapsedVisibleOverrides),
      };

  TabBehaviorSettings copyWith({
    final Map<ScreenTabType, Set<String>>? pinnedTabs,
    final Map<ScreenTabType, Set<String>>? collapsedVisibleOverrides,
  }) =>
      TabBehaviorSettings(
        pinnedTabs: pinnedTabs ?? this.pinnedTabs,
        collapsedVisibleOverrides:
            collapsedVisibleOverrides ?? this.collapsedVisibleOverrides,
      );
}

Map<String, dynamic> _tabBehaviorToJson(final TabBehaviorSettings v) =>
    v.toJson();

const SettingsDescriptor<TabBehaviorSettings> tabBehaviorDescriptor =
    SettingsDescriptor<TabBehaviorSettings>(
  key: 'app_tab_behavior',
  defaultValue: TabBehaviorSettings(),
  fromJson: TabBehaviorSettings.fromJson,
  toJson: _tabBehaviorToJson,
);
