import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches and caches the subject details for a notification thread.
///
/// Keyed by the subject URL. Returns raw JSON map; callers deserialize
/// to their specific model type.
final notificationSubjectProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
  (final Ref ref, final String subjectUrl) async =>
      ref.read(notificationsServiceProvider).fetchSubjectDetails(subjectUrl),
);
