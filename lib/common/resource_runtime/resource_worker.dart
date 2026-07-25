import 'dart:isolate';

/// Executes sendable, pure resource transformations away from the caller.
abstract interface class ResourceWorker {
  Future<O> run<I, O>(final I input, final O Function(I input) operation);
}

/// Production worker backed by a short-lived Dart isolate.
final class IsolateResourceWorker implements ResourceWorker {
  const IsolateResourceWorker();

  @override
  Future<O> run<I, O>(final I input, final O Function(I input) operation) =>
      Isolate.run<O>(
        () => operation(input),
        debugName: 'diohub-resource-worker',
      );
}

/// Deterministic worker for unit tests that do not test isolate behavior.
final class InlineResourceWorker implements ResourceWorker {
  const InlineResourceWorker();

  @override
  Future<O> run<I, O>(
    final I input,
    final O Function(I input) operation,
  ) async => operation(input);
}
