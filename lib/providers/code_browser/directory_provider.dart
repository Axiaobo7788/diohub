import 'dart:async';

import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/code_browser/directory_resource.dart';
import 'package:diohub/providers/code_browser/repository_code_resource_presence_provider.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:diohub/providers/code_browser/directory_resource.dart'
    show DirectoryKey;

/// Provides the list of [CodeTreeNode] entries for a directory path.
final directoryProvider = AsyncNotifierProvider.autoDispose
    .family<DirectoryNotifier, List<CodeTreeNode>, DirectoryKey>(
      DirectoryNotifier.new,
    );

class DirectoryNotifier extends AsyncNotifier<List<CodeTreeNode>> {
  DirectoryNotifier(this._key);
  final DirectoryKey _key;
  ResourceLease<List<CodeTreeNode>>? _lease;
  StreamSubscription<ResourceSnapshot<List<CodeTreeNode>>>? _subscription;
  Completer<List<CodeTreeNode>>? _firstValue;
  bool _buildSettled = false;

  @override
  Future<List<CodeTreeNode>> build() async {
    _releaseRuntimeLease();
    _buildSettled = false;

    final ResourceScope? scope = ref.watch(activeResourceScopeProvider);
    if (scope == null) {
      throw StateError(
        'Repository directory requested before account resolved',
      );
    }
    final DirectoryResourceSpecFactory specFactory = ref.watch(
      directoryResourceSpecFactoryProvider,
    );
    final ResourcePresence presence = ref.read(
      repositoryCodeResourcePresenceProvider(_key.repo),
    );
    ref.listen<ResourcePresence>(
      repositoryCodeResourcePresenceProvider(_key.repo),
      (final ResourcePresence? _, final ResourcePresence next) {
        _lease?.setPresence(next);
      },
    );
    final ResourceLease<List<CodeTreeNode>> lease = ref
        .watch(resourceRuntimeProvider)
        .acquire(
          specFactory(key: _key, scope: scope),
          presence: presence,
        );
    _lease = lease;
    final Completer<List<CodeTreeNode>> firstValue =
        Completer<List<CodeTreeNode>>();
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

  void _handleSnapshot(final ResourceSnapshot<List<CodeTreeNode>> snapshot) {
    final Completer<List<CodeTreeNode>>? firstValue = _firstValue;
    if (!_buildSettled && firstValue != null && !firstValue.isCompleted) {
      switch (snapshot) {
        case ResourceLoading<List<CodeTreeNode>>():
          return;
        case ResourceData<List<CodeTreeNode>>(:final data):
          firstValue.complete(data);
          return;
        case ResourceFailure<List<CodeTreeNode>>(
          :final error,
          :final stackTrace,
        ):
          firstValue.completeError(error, stackTrace ?? StackTrace.current);
          return;
      }
    }
    switch (snapshot) {
      case ResourceLoading<List<CodeTreeNode>>():
        state = const AsyncLoading<List<CodeTreeNode>>();
      case ResourceData<List<CodeTreeNode>>(:final data):
        state = AsyncData<List<CodeTreeNode>>(data);
      case ResourceFailure<List<CodeTreeNode>>(:final error, :final stackTrace):
        state = AsyncError<List<CodeTreeNode>>(
          error,
          stackTrace ?? StackTrace.current,
        );
    }
  }

  Future<void> refreshResource() async {
    final ResourceLease<List<CodeTreeNode>>? lease = _lease;
    if (lease != null) await lease.refresh();
  }

  void setPresence(final ResourcePresence presence) {
    _lease?.setPresence(presence);
  }

  void _releaseRuntimeLease() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _lease?.release();
    _lease = null;
    _firstValue = null;
  }
}
