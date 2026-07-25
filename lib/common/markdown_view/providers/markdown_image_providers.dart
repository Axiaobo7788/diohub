import 'dart:async';

import 'package:dio/dio.dart';
import 'package:diohub/common/markdown_view/readme_image_classifier.dart';
import 'package:diohub/common/markdown_view/readme_image_resource.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Dedicated public asset client. It carries no GitHub account interceptors or
/// Authorization defaults because README images may be third-party URLs.
final Provider<ReadmeImageClassifier> readmeImageClassifierProvider =
    Provider<ReadmeImageClassifier>(
      (final Ref ref) => ReadmeImageClassifier(
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 12),
          ),
        ),
      ),
    );

final Provider<ReadmeImageResourceSpecFactory>
readmeImageResourceSpecFactoryProvider =
    Provider<ReadmeImageResourceSpecFactory>((final Ref ref) {
      final ReadmeImageClassifier classifier = ref.watch(
        readmeImageClassifierProvider,
      );
      return ({
        required final String url,
        required final ResourceScope scope,
      }) => readmeImageResourceSpecs(
        url: url,
        scope: scope,
        classifier: classifier,
      );
    });

final AsyncNotifierProviderFamily<
  ReadmeImageResultNotifier,
  ReadmeImageResult,
  String
>
readmeImageResultProvider = AsyncNotifierProvider.autoDispose
    .family<ReadmeImageResultNotifier, ReadmeImageResult, String>(
      ReadmeImageResultNotifier.new,
    );

/// Thin Riverpod adapter. ResourceRuntime owns identity, Single Flight,
/// retention, dependency freshness, and the bounded byte cache.
final class ReadmeImageResultNotifier extends AsyncNotifier<ReadmeImageResult> {
  ReadmeImageResultNotifier(this._url);

  final String _url;
  ResourceRuntime? _runtime;
  ResourceScope? _scope;
  ResourceLease<ReadmeImageResult>? _lease;
  StreamSubscription<ResourceSnapshot<ReadmeImageResult>>? _subscription;
  Completer<ReadmeImageResult>? _pendingFirstValue;
  int _buildGeneration = 0;
  bool _buildSettled = false;

  @override
  Future<ReadmeImageResult> build() async {
    _releaseRuntimeLease();
    final int generation = ++_buildGeneration;
    _buildSettled = false;
    final ResourceScope? scope = ref.watch(activeResourceScopeProvider);
    if (scope == null) {
      throw StateError('README image requested before account resolved');
    }
    final ReadmeImageResourceSpecs specs = ref.watch(
      readmeImageResourceSpecFactoryProvider,
    )(url: _url, scope: scope);
    final ResourceRuntime runtime = ref.watch(resourceRuntimeProvider);
    final ResourceLease<ReadmeImageResult> lease = runtime.acquire(
      specs.artifact,
    );
    _runtime = runtime;
    _scope = scope;
    _lease = lease;
    final Completer<ReadmeImageResult> firstValue =
        Completer<ReadmeImageResult>();
    _pendingFirstValue = firstValue;
    _subscription = lease.changes.listen(
      (final ResourceSnapshot<ReadmeImageResult> snapshot) =>
          _handleSnapshot(snapshot, generation, firstValue),
    );
    ref.onDispose(_releaseRuntimeLease);
    _handleSnapshot(lease.value, generation, firstValue);
    try {
      return await firstValue.future;
    } finally {
      if (generation == _buildGeneration) {
        _buildSettled = true;
      }
    }
  }

  void _handleSnapshot(
    final ResourceSnapshot<ReadmeImageResult> snapshot,
    final int generation,
    final Completer<ReadmeImageResult> firstValue,
  ) {
    if (generation != _buildGeneration) {
      return;
    }
    if (!_buildSettled && !firstValue.isCompleted) {
      switch (snapshot) {
        case ResourceLoading<ReadmeImageResult>():
          return;
        case ResourceData<ReadmeImageResult>(
          data: final ReadmeImageResult data,
        ):
          firstValue.complete(data);
          return;
        case ResourceFailure<ReadmeImageResult>(
          error: final Object error,
          stackTrace: final StackTrace? stackTrace,
        ):
          firstValue.completeError(error, stackTrace ?? StackTrace.current);
          return;
      }
    }
    switch (snapshot) {
      case ResourceLoading<ReadmeImageResult>():
        state = const AsyncLoading<ReadmeImageResult>();
      case ResourceData<ReadmeImageResult>(data: final ReadmeImageResult data):
        state = AsyncData<ReadmeImageResult>(data);
      case ResourceFailure<ReadmeImageResult>(
        error: final Object error,
        stackTrace: final StackTrace? stackTrace,
      ):
        state = AsyncError<ReadmeImageResult>(
          error,
          stackTrace ?? StackTrace.current,
        );
    }
  }

  Future<void> refreshResource() async {
    final ResourceRuntime? runtime = _runtime;
    final ResourceScope? scope = _scope;
    final ResourceLease<ReadmeImageResult>? lease = _lease;
    if (runtime == null || scope == null || lease == null) {
      return;
    }
    invalidateReadmeImageResource(runtime: runtime, scope: scope, url: _url);
    await lease.refresh();
  }

  void _releaseRuntimeLease() {
    _buildGeneration++;
    final Completer<ReadmeImageResult>? firstValue = _pendingFirstValue;
    if (firstValue != null && !firstValue.isCompleted) {
      firstValue.complete(ReadmeImageResult.unavailable());
    }
    _pendingFirstValue = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _lease?.release();
    _lease = null;
    _runtime = null;
    _scope = null;
  }
}
