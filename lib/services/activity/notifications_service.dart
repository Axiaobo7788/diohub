import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub_models/models/notifications/thread_subscription.dart';

/// Service for GitHub notification operations.
///
/// Uses the generated [Thread] model for type-safe notification handling.
/// Ref: https://docs.github.com/en/rest/activity/notifications
class NotificationsService {
  NotificationsService(ApiClient client)
      : _restHandler = client.rest;

  static const String _url = '/notifications';
  final RESTHandler _restHandler;

  /// Fetch notifications for the authenticated user.
  ///
  /// [page] and [perPage] control pagination.
  /// [filters] is a map of API query parameters:
  ///   - `all` (bool): Include read notifications.
  ///   - `participating` (bool): Only participating/mentioned. Default: false.
  ///   - `since` (String): ISO 8601 datetime filter.
  ///   - `before` (String): ISO 8601 datetime filter.
  Future<List<Thread>> getNotifications({
    final int? perPage,
    final int? page,
    final Map<String, dynamic>? filters,
  }) async {
    final Map<String, dynamic> queryParameters = <String, dynamic>{
      'per_page': perPage,
      'page': page,
    };
    if (filters != null) {
      queryParameters.addAll(filters);
    }
    final Response<List<dynamic>> response =
        await _restHandler.get<List<dynamic>>(
      _url,
      queryParameters: queryParameters,
      // Must refresh to avoid 304 on this endpoint.
      refreshCache: true,
    );
    return response.data!
        .map((final dynamic e) => Thread.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns the number of unread notifications (length of first page, max 50).
  Future<int> getUnreadCount({final int perPage = 50}) async {
    final List<Thread> list = await getNotifications(
      perPage: perPage,
      page: 1,
      filters: <String, dynamic>{'all': false},
    );
    return list.length;
  }

  /// Mark a single notification thread as read.
  Future<void> markThreadAsRead(final String id) async {
    await _restHandler.patch('/notifications/threads/$id');
  }

  /// Mark a notification thread as done (permanently removes from inbox).
  /// REST DELETE /notifications/threads/{id}. Returns 204/205 on success.
  Future<void> markThreadAsDone(final String threadId) async {
    await _restHandler.delete<void>('/notifications/threads/$threadId');
  }

  /// Mark all notifications as read up to now.
  Future<void> markAllAsRead() async {
    await _restHandler.put(
      '/notifications',
      queryParameters: <String, dynamic>{
        'last_read_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get the subscription state of a notification thread.
  ///
  /// Returns [ThreadSubscription] (subscribed, ignored, reason, created_at).
  /// On 404 (no subscription), returns default [ThreadSubscription].
  /// Ref: https://docs.github.com/en/rest/activity/notifications#get-a-thread-subscription-for-the-authenticated-user
  Future<ThreadSubscription> getThreadSubscription(
    final String threadId,
  ) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _restHandler.get<Map<String, dynamic>>(
        '/notifications/threads/$threadId/subscription',
      );
      return ThreadSubscription.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const ThreadSubscription();
      }
      rethrow;
    }
  }

  /// Subscribe to a notification thread.
  ///
  /// Sets subscribed: true so the user receives notifications for this thread.
  /// Ref: https://docs.github.com/en/rest/activity/notifications#set-a-thread-subscription
  Future<ThreadSubscription> subscribeToThread(
    final String threadId,
  ) async {
    final Response<Map<String, dynamic>> response =
        await _restHandler.put<Map<String, dynamic>>(
      '/notifications/threads/$threadId/subscription',
      data: <String, dynamic>{'subscribed': true, 'ignored': false},
    );
    return ThreadSubscription.fromJson(response.data!);
  }

  /// Unsubscribe / mute a notification thread.
  ///
  /// Sets ignored: true so the user stops receiving notifications for this thread.
  Future<void> muteThread(final String threadId) async {
    await _restHandler.put<Object>(
      '/notifications/threads/$threadId/subscription',
      data: <String, dynamic>{'subscribed': false, 'ignored': true},
    );
  }

  /// Delete thread subscription entirely (resets to default notification behavior).
  Future<void> deleteThreadSubscription(final String threadId) async {
    await _restHandler.delete<Object>(
      '/notifications/threads/$threadId/subscription',
    );
  }

  /// Fetch a single resource by its full API URL.
  ///
  /// Used to lazy-load issue/PR details from [ThreadSubject.url].
  /// Returns the raw JSON map for the caller to deserialize.
  Future<Map<String, dynamic>> fetchSubjectDetails(
    final String fullUrl, {
    final bool refresh = false,
    final String? acceptHeader,
  }) async {
    final Response<Map<String, dynamic>> response =
        await _restHandler.get<Map<String, dynamic>>(
      fullUrl,
      refreshCache: refresh,
      requestHeaders:
          acceptHeader != null ? _restHandler.acceptHeader(acceptHeader) : null,
    );
    return response.data!;
  }

  /// Fetch subject details using an [EntityRef] (uses [ref.apiPath]).
  ///
  /// [serverConfig] is the active server (e.g. from [activeServerConfigProvider]).
  Future<Map<String, dynamic>> fetchSubjectDetailsForRef(
    final EntityRef ref, {
    required final ServerConfig serverConfig,
    final bool refresh = false,
    final String? acceptHeader,
  }) async {
    final String fullUrl = ref.apiPath.startsWith('http')
        ? ref.apiPath
        : '${serverConfig.restBaseUrl}${ref.apiPath}';
    return fetchSubjectDetails(
      fullUrl,
      refresh: refresh,
      acceptHeader: acceptHeader,
    );
  }
}
