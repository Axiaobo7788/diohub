import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persisted state for all startup flows.
class StartupFlowsData {
  const StartupFlowsData({
    this.completedFlows = const <String>{},
    this.dismissedFlows = const <String>{},
    this.dismissedUntil = const <String, String>{},
    this.lastSeenVersion,
  });

  final Set<String> completedFlows;
  final Set<String> dismissedFlows;
  final Map<String, String> dismissedUntil;
  final String? lastSeenVersion;

  factory StartupFlowsData.fromJson(final Map<String, dynamic> json) {
    final List<dynamic>? completedList =
        json['completed_flows'] as List<dynamic>?;
    final List<dynamic>? dismissedList =
        json['dismissed_flows'] as List<dynamic>?;
    final Map<String, dynamic>? until =
        json['dismissed_until'] as Map<String, dynamic>?;
    return StartupFlowsData(
      completedFlows: completedList != null
          ? completedList.map((final e) => e as String).toSet()
          : const <String>{},
      dismissedFlows: dismissedList != null
          ? dismissedList.map((final e) => e as String).toSet()
          : const <String>{},
      dismissedUntil: until != null
          ? until.map((final k, final v) => MapEntry(k, v as String))
          : const <String, String>{},
      lastSeenVersion: json['last_seen_version'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'completed_flows': completedFlows.toList(),
        'dismissed_flows': dismissedFlows.toList(),
        'dismissed_until': dismissedUntil,
        'last_seen_version': lastSeenVersion,
      };

  StartupFlowsData copyWith({
    final Set<String>? completedFlows,
    final Set<String>? dismissedFlows,
    final Map<String, String>? dismissedUntil,
    final String? lastSeenVersion,
  }) =>
      StartupFlowsData(
        completedFlows: completedFlows ?? this.completedFlows,
        dismissedFlows: dismissedFlows ?? this.dismissedFlows,
        dismissedUntil: dismissedUntil ?? this.dismissedUntil,
        lastSeenVersion: lastSeenVersion ?? this.lastSeenVersion,
      );
}

Map<String, dynamic> _startupFlowsToJson(final StartupFlowsData v) =>
    v.toJson();

const SettingsDescriptor<StartupFlowsData> startupFlowsDescriptor =
    SettingsDescriptor<StartupFlowsData>(
  key: 'startup_flows',
  defaultValue: StartupFlowsData(),
  fromJson: StartupFlowsData.fromJson,
  toJson: _startupFlowsToJson,
);

final startupFlowsProvider =
    NotifierProvider<StartupFlowsNotifier, StartupFlowsData>(
  StartupFlowsNotifier.new,
);

class StartupFlowsNotifier extends Notifier<StartupFlowsData>
    with PersistedNotifier<StartupFlowsData> {
  @override
  SettingsDescriptor<StartupFlowsData> get descriptor =>
      startupFlowsDescriptor;

  Future<void> dismissFlow(final String flowId) async {
    await update((final StartupFlowsData s) => s.copyWith(
          dismissedFlows: {...s.dismissedFlows, flowId},
        ));
  }

  Future<void> markCompleted(final String flowId) async {
    await update((final StartupFlowsData s) => s.copyWith(
          completedFlows: {...s.completedFlows, flowId},
        ));
  }

  Future<void> dismissUntil(final String flowId, final DateTime date) async {
    await update((final StartupFlowsData s) => s.copyWith(
          dismissedUntil: {...s.dismissedUntil, flowId: date.toIso8601String()},
        ));
  }

  Future<void> setLastSeenVersion(final String version) async {
    await update((final StartupFlowsData s) =>
        s.copyWith(lastSeenVersion: version));
  }

  Future<void> clearDismissed(final String flowId) async {
    final dismissed = Set<String>.from(state.dismissedFlows)..remove(flowId);
    final until = Map<String, String>.from(state.dismissedUntil)
      ..remove(flowId);
    await update((final StartupFlowsData s) => s.copyWith(
          dismissedFlows: dismissed,
          dismissedUntil: until,
        ));
  }
}
