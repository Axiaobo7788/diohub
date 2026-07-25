import 'resource_models.dart';
import 'resource_telemetry.dart';

abstract interface class ResourceRuntime {
  ResourceTelemetry get telemetry;

  ResourceLease<T> acquire<T>(
    ResourceSpec<T> spec, {
    ResourcePresence presence = ResourcePresence.visible,
  });

  PrefetchTicket prefetch<T>(
    ResourceSpec<T> spec, {
    ResourcePriority priority = ResourcePriority.prefetch,
  });

  void invalidate(ResourceSelector selector);
  void evictScope(ResourceScope scope);
  void updateEnvironment(ResourceEnvironment environment);
  void trimMemory();
  void dispose();
}
