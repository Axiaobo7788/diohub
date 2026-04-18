import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/authentication/authenticated_session.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/services/authentication/account_repository.dart';
import 'package:diohub/services/authentication/token_refresh_service.dart';
import 'package:diohub/services/authentication/token_store.dart';
import 'package:dio/dio.dart';

/// Minimal API surface needed by watchers.
abstract interface class WatcherApiClient {
  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters});
}

/// Container for HTTP handlers with dependency injection.
class ApiClient implements WatcherApiClient {
  ApiClient({
    required NotificationService notifications,
    required TokenStore tokenStore,
    required AccountRepository accountRepository,
    required AuthenticatedSession? authenticatedSession,
    TokenRefreshService? tokenRefreshService,
  })  : gql = GraphqlHandler(
          notifications: notifications,
          tokenStore: tokenStore,
          accountRepository: accountRepository,
          authenticatedSession: authenticatedSession,
          tokenRefreshService: tokenRefreshService,
        ),
        rest = RESTHandler(
          notifications: notifications,
          tokenStore: tokenStore,
          accountRepository: accountRepository,
          authenticatedSession: authenticatedSession,
          tokenRefreshService: tokenRefreshService,
        ),
        gqlVerbose = GraphqlHandler(
          notifications: notifications,
          tokenStore: tokenStore,
          accountRepository: accountRepository,
          authenticatedSession: authenticatedSession,
          tokenRefreshService: tokenRefreshService,
          apiLogSettings: APILoggingSettings.comprehensive(),
        ),
        restVerbose = RESTHandler(
          notifications: notifications,
          tokenStore: tokenStore,
          accountRepository: accountRepository,
          authenticatedSession: authenticatedSession,
          tokenRefreshService: tokenRefreshService,
          apiLogSettings: APILoggingSettings.comprehensive(),
        );

  final GraphqlHandler gql;
  final RESTHandler rest;
  final GraphqlHandler gqlVerbose;
  final RESTHandler restVerbose;

  /// Convenience for REST GET (used by watchers).
  @override
  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) =>
      rest.get(path, queryParameters: queryParameters);
}

/// Standard handler access for all API services.
abstract class BaseService {
  const BaseService(this.apiClient);

  final ApiClient apiClient;

  /// GraphQL handler — shared across all services.
  GraphqlHandler get gql => apiClient.gql;

  /// REST handler — shared across all services.
  RESTHandler get rest => apiClient.rest;

  /// REST handler with comprehensive request/response logging.
  RESTHandler get restVerbose => apiClient.restVerbose;

  /// GQL handler with comprehensive logging.
  GraphqlHandler get gqlVerbose => apiClient.gqlVerbose;
}

/// Base for services bound to a specific entity via its [EntityRef].
///
/// Provides a typed [ref] field so instance methods can access the entity's
/// identifiers (owner, name, number, apiPath, etc.) without taking them
/// as parameters.
abstract class EntityService<R extends EntityRef> extends BaseService {
  const EntityService(super.apiClient, this.ref);

  /// The entity this service operates on.
  final R ref;

  /// Log an error scoped to this service's entity.
  void logError(String message, [Object? error, StackTrace? st]) =>
      AppLogger.scopedError(message, ref, error: error, stackTrace: st);

  /// Log a warning scoped to this service's entity.
  void logWarning(String message, [Object? error, StackTrace? st]) =>
      AppLogger.scopedWarning(message, ref, error: error, stackTrace: st);
}
