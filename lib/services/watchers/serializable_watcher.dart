/// Serialisation support for watchers that run in the background isolate.
///
/// The background task reconstructs watchers from JSON via [WatcherFactory].
/// Watchers that never run in background do not need this mixin.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/watchers/watcher_definition.dart';

mixin SerializableWatcher on WatcherDefinition {
  /// Serialise this watcher's identity and config. Must include 'key'.
  Map<String, dynamic> toJson();

  /// Helper: Add repo ref fields to a toJson map.
  static Map<String, dynamic> serializeRepoBase({
    required String key,
    required RepoRef repoRef,
    required Duration interval,
    required bool enabled,
  }) =>
      {
        'key': key,
        'repoOwner': repoRef.owner,
        'repoName': repoRef.name,
        'interval': interval.inSeconds,
        'enabled': enabled,
      };

  /// Helper: Extract repo ref from a fromJson map.
  static RepoRef deserializeRepoRef(Map<String, dynamic> json) => RepoRef(
        owner: json['repoOwner'] as String,
        name: json['repoName'] as String,
      );
}

/// Reconstructs watchers from JSON for background isolate execution.
class WatcherFactory {
  WatcherFactory._();

  static final Map<String, WatcherDefinition Function(Map<String, dynamic>)>
      _factories = {};

  /// Register a factory. Call once at app startup for each watcher type.
  static void register(
    String key,
    WatcherDefinition Function(Map<String, dynamic>) factory,
  ) {
    _factories[key] = factory;
  }

  /// Reconstruct a watcher from its serialised form.
  static WatcherDefinition? fromJson(Map<String, dynamic> json) {
    final key = json['key'] as String?;
    if (key == null) return null;
    return _factories[key]?.call(json);
  }
}
