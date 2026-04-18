import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/services/activity/notifications_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the shared [NotificationsService] instance.
/// Use [ref.read(notificationsServiceProvider)] in providers or widgets with [WidgetRef].
final Provider<NotificationsService> notificationsServiceProvider =
    Provider<NotificationsService>((ref) => NotificationsService(ref.read(apiClientProvider)));
