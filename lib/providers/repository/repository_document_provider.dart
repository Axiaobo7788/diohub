import 'dart:async';

import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/models/repository_document.dart';
import 'package:diohub/providers/code_browser/repository_code_resource_presence_provider.dart';
import 'package:diohub/providers/repository/repository_document_resource.dart';
import 'package:diohub/providers/repository/repository_security_resource_presence_provider.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

typedef RepositoryDocumentKey = ({
  RepoRef repoRef,
  String branch,
  RepositoryDocumentKind kind,
});

enum RepositoryDocumentConsumer { code, security }

typedef RepositoryDocumentRequest = ({
  RepositoryDocumentKey key,
  RepositoryDocumentConsumer consumer,
});

final AsyncNotifierProviderFamily<
  RepositoryDocumentNotifier,
  RepositoryDocumentArtifact?,
  RepositoryDocumentRequest
>
repositoryDocumentProvider = AsyncNotifierProvider.autoDispose
    .family<
      RepositoryDocumentNotifier,
      RepositoryDocumentArtifact?,
      RepositoryDocumentRequest
    >(RepositoryDocumentNotifier.new);

/// Riverpod adapter for Repository community-document resources.
///
/// Code and Security use separate leases so each page owns its presence, while
/// both leases resolve the same Runtime source/artifact identity.
class RepositoryDocumentNotifier
    extends AsyncNotifier<RepositoryDocumentArtifact?> {
  RepositoryDocumentNotifier(this._request);

  final RepositoryDocumentRequest _request;
  ResourceRuntime? _runtime;
  ResourceScope? _scope;
  ResourceLease<RepositoryDocumentArtifact?>? _lease;
  StreamSubscription<ResourceSnapshot<RepositoryDocumentArtifact?>>?
  _subscription;
  Completer<RepositoryDocumentArtifact?>? _firstValue;
  bool _buildSettled = false;

  @override
  Future<RepositoryDocumentArtifact?> build() async {
    _releaseRuntimeLease();
    _buildSettled = false;
    final RepositoryDocumentKey key = _request.key;
    if (_request.consumer == RepositoryDocumentConsumer.security &&
        key.kind != RepositoryDocumentKind.security) {
      throw ArgumentError.value(
        key.kind,
        'kind',
        'The Security consumer only accepts a SECURITY document.',
      );
    }
    final ResourceScope? scope = ref.watch(activeResourceScopeProvider);
    if (scope == null) {
      throw StateError('Repository document requested before account resolved');
    }
    final RepositoryDocumentResourceSpecs specs = ref.watch(
      repositoryDocumentResourceSpecFactoryProvider,
    )(key: key, scope: scope);
    final provider = switch (_request.consumer) {
      RepositoryDocumentConsumer.code => repositoryCodeResourcePresenceProvider(
        key.repoRef,
      ),
      RepositoryDocumentConsumer.security =>
        repositorySecurityResourcePresenceProvider(key.repoRef),
    };
    final ResourcePresence presence = ref.read(provider);
    ref.listen<ResourcePresence>(provider, (
      final ResourcePresence? _,
      final ResourcePresence next,
    ) {
      _lease?.setPresence(next);
    });
    final ResourceRuntime runtime = ref.watch(resourceRuntimeProvider);
    final ResourceLease<RepositoryDocumentArtifact?> lease = runtime.acquire(
      specs.artifact,
      presence: presence,
    );
    _runtime = runtime;
    _scope = scope;
    _lease = lease;
    final Completer<RepositoryDocumentArtifact?> firstValue =
        Completer<RepositoryDocumentArtifact?>();
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
    final ResourceSnapshot<RepositoryDocumentArtifact?> snapshot,
  ) {
    final Completer<RepositoryDocumentArtifact?>? firstValue = _firstValue;
    if (!_buildSettled && firstValue != null && !firstValue.isCompleted) {
      switch (snapshot) {
        case ResourceLoading<RepositoryDocumentArtifact?>():
          return;
        case ResourceData<RepositoryDocumentArtifact?>(:final data):
          firstValue.complete(data);
          return;
        case ResourceFailure<RepositoryDocumentArtifact?>(
          :final error,
          :final stackTrace,
        ):
          firstValue.completeError(error, stackTrace ?? StackTrace.current);
          return;
      }
    }
    switch (snapshot) {
      case ResourceLoading<RepositoryDocumentArtifact?>():
        state = const AsyncLoading<RepositoryDocumentArtifact?>();
      case ResourceData<RepositoryDocumentArtifact?>(:final data):
        state = AsyncData<RepositoryDocumentArtifact?>(data);
      case ResourceFailure<RepositoryDocumentArtifact?>(
        :final error,
        :final stackTrace,
      ):
        state = AsyncError<RepositoryDocumentArtifact?>(
          error,
          stackTrace ?? StackTrace.current,
        );
    }
  }

  Future<void> refreshResource() async {
    final ResourceRuntime? runtime = _runtime;
    final ResourceScope? scope = _scope;
    final ResourceLease<RepositoryDocumentArtifact?>? lease = _lease;
    if (runtime == null || scope == null || lease == null) return;
    invalidateRepositoryDocumentResource(
      runtime: runtime,
      scope: scope,
      key: _request.key,
    );
    await lease.refresh();
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
