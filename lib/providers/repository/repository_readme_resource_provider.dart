import 'dart:async';

import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/code_browser/repository_code_resource_presence_provider.dart';
import 'package:diohub/providers/repository/repository_readme_resource.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final AsyncNotifierProviderFamily<
  RepositoryReadmeArtifactNotifier,
  RepositoryReadmeArtifact?,
  RepositoryReadmeKey
>
repositoryReadmeArtifactProvider = AsyncNotifierProvider.autoDispose
    .family<
      RepositoryReadmeArtifactNotifier,
      RepositoryReadmeArtifact?,
      RepositoryReadmeKey
    >(RepositoryReadmeArtifactNotifier.new);

/// Riverpod-to-Runtime adapter for the Repository Code README.
///
/// Riverpod owns the widget subscription; ResourceRuntime owns freshness,
/// retention, Single Flight, dependency invalidation, and executor budgets.
class RepositoryReadmeArtifactNotifier
    extends AsyncNotifier<RepositoryReadmeArtifact?> {
  RepositoryReadmeArtifactNotifier(this._key);

  final RepositoryReadmeKey _key;
  ResourceRuntime? _runtime;
  ResourceScope? _scope;
  ResourceLease<RepositoryReadmeArtifact?>? _lease;
  StreamSubscription<ResourceSnapshot<RepositoryReadmeArtifact?>>?
  _subscription;
  Completer<RepositoryReadmeArtifact?>? _firstValue;
  bool _buildSettled = false;

  @override
  Future<RepositoryReadmeArtifact?> build() async {
    _releaseRuntimeLease();
    _buildSettled = false;
    final ResourceScope? scope = ref.watch(activeResourceScopeProvider);
    if (scope == null) {
      throw StateError('Repository README requested before account resolved');
    }
    final RepositoryReadmeResourceSpecs specs = ref.watch(
      repositoryReadmeResourceSpecFactoryProvider,
    )(key: _key, scope: scope);
    final ResourcePresence presence = ref.read(
      repositoryCodeResourcePresenceProvider(_key.repoRef),
    );
    ref.listen<ResourcePresence>(
      repositoryCodeResourcePresenceProvider(_key.repoRef),
      (final ResourcePresence? _, final ResourcePresence next) {
        _lease?.setPresence(next);
      },
    );
    final ResourceRuntime runtime = ref.watch(resourceRuntimeProvider);
    final ResourceLease<RepositoryReadmeArtifact?> lease = runtime.acquire(
      specs.artifact,
      presence: presence,
    );
    _runtime = runtime;
    _scope = scope;
    _lease = lease;
    final Completer<RepositoryReadmeArtifact?> firstValue =
        Completer<RepositoryReadmeArtifact?>();
    _firstValue = firstValue;
    _subscription = lease.changes.listen(_handleSnapshot);
    ref.onDispose(_releaseRuntimeLease);
    _handleSnapshot(lease.value);
    try {
      return await firstValue.future;
    } finally {
      _buildSettled = true;
    }
  }

  void _handleSnapshot(
    final ResourceSnapshot<RepositoryReadmeArtifact?> snapshot,
  ) {
    final Completer<RepositoryReadmeArtifact?>? firstValue = _firstValue;
    if (!_buildSettled && firstValue != null && !firstValue.isCompleted) {
      switch (snapshot) {
        case ResourceLoading<RepositoryReadmeArtifact?>():
          return;
        case ResourceData<RepositoryReadmeArtifact?>(:final data):
          firstValue.complete(data);
          return;
        case ResourceFailure<RepositoryReadmeArtifact?>(
          :final error,
          :final stackTrace,
        ):
          firstValue.completeError(error, stackTrace ?? StackTrace.current);
          return;
      }
    }
    switch (snapshot) {
      case ResourceLoading<RepositoryReadmeArtifact?>():
        state = const AsyncLoading<RepositoryReadmeArtifact?>();
      case ResourceData<RepositoryReadmeArtifact?>(:final data):
        state = AsyncData<RepositoryReadmeArtifact?>(data);
      case ResourceFailure<RepositoryReadmeArtifact?>(
        :final error,
        :final stackTrace,
      ):
        state = AsyncError<RepositoryReadmeArtifact?>(
          error,
          stackTrace ?? StackTrace.current,
        );
    }
  }

  Future<void> refreshResource() async {
    final ResourceRuntime? runtime = _runtime;
    final ResourceScope? scope = _scope;
    final ResourceLease<RepositoryReadmeArtifact?>? lease = _lease;
    if (runtime == null || scope == null || lease == null) return;
    invalidateRepositoryReadmeResource(
      runtime: runtime,
      scope: scope,
      key: _key,
    );
    await lease.refresh();
  }

  void setPresence(final ResourcePresence presence) {
    _lease?.setPresence(presence);
  }

  void _releaseRuntimeLease() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _lease?.release();
    _lease = null;
    _runtime = null;
    _scope = null;
    _firstValue = null;
  }
}
