import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/authentication/authenticated_session.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:http_cache_drift_store/http_cache_drift_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/services/authentication/account_repository.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:diohub/services/authentication/token_refresh_service.dart';
import 'package:diohub/services/authentication/token_store.dart';
import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart' as gql_exec;
import 'package:diohub_gql_client/graphql_client.dart' as gql_client;
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:sentry_dio/sentry_dio.dart';

import 'package:diohub/app/talker.dart';
import 'package:uuid/uuid.dart';

part 'cache.dart';

typedef GQLResponse = gql_exec.Response;

class RESTHandler extends BaseAPIHandler {
  RESTHandler({
    required super.notifications,
    required super.tokenStore,
    required super.accountRepository,
    required super.authenticatedSession,
    super.tokenRefreshService,
    super.apiLogSettings,
    super.cacheOptions,
  }) : super(baseUrl: null);

  RESTHandler.external({
    required super.notifications,
    required super.tokenStore,
    required super.accountRepository,
    required super.authenticatedSession,
    required String super.baseUrl,
    super.tokenRefreshService,
    super.apiLogSettings,
    super.cacheOptions,
  }) : super(addAuthHeader: false);

  Future<Response<T>> get<T>(
    final String url, {
    final bool refreshCache = false,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final ProgressCallback? onReceiveProgress,
    final Map<String, dynamic>? requestHeaders,
  }) async {
    final Response<T> response =
        await _request(
          requestHeaders: requestHeaders,
          overrideAPICache: activeCacheOptions.copyWith(
            cachePolicy: refreshCache ? CachePolicy.refresh : null,
          ),
        ).get<T>(
          url,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );
    return response;
  }

  Future<Response<T>> post<T>(
    final String url, {
    final Object? data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final ProgressCallback? onSendProgress,
    final ProgressCallback? onReceiveProgress,
    final Map<String, dynamic>? requestHeaders,
  }) async {
    final Response<T> response = await _request(requestHeaders: requestHeaders)
        .post<T>(
          url,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
    return response;
  }

  Future<Response<T>> put<T>(
    final String url, {
    final Object? data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final ProgressCallback? onSendProgress,
    final ProgressCallback? onReceiveProgress,
    final Map<String, dynamic>? requestHeaders,
  }) async {
    final Response<T> response = await _request(requestHeaders: requestHeaders)
        .put<T>(
          url,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
    return response;
  }

  Future<Response<T>> delete<T>(
    final String url, {
    final Object? data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final Map<String, dynamic>? requestHeaders,
  }) async {
    final Response<T> response = await _request(requestHeaders: requestHeaders)
        .delete<T>(
          url,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        );
    return response;
  }

  Future<Response<T>> patch<T>(
    final String url, {
    final Object? data,
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final Map<String, dynamic>? requestHeaders,
    final ProgressCallback? onSendProgress,
    final ProgressCallback? onReceiveProgress,
  }) async {
    final Response<T> response = await _request(requestHeaders: requestHeaders)
        .patch<T>(
          url,
          data: data,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress,
        );
    return response;
  }

  static const String _githubAPIVersion = '2022-11-28';

  @override
  Future<void> onRequest(
    final RequestOptions options,
    final RequestInterceptorHandler handler,
  ) {
    options.headers['X-GitHub-Api-Version'] = _githubAPIVersion;
    return super.onRequest(options, handler);
  }
}

class GraphqlHandler extends BaseAPIHandler {
  GraphqlHandler({
    required super.notifications,
    required super.tokenStore,
    required super.accountRepository,
    required super.authenticatedSession,
    super.tokenRefreshService,
    super.apiLogSettings,
    super.cacheOptions,
  });

  @override
  String get path => '/graphql';

  Future<GQLResponse> mutation(
    final DocumentNode document,
    final Map<String, dynamic> variables, {
    final Map<String, dynamic>? requestHeaders,
  }) async {
    final client = await _createClient();
    return client.mutation(document, variables, requestHeaders: requestHeaders);
  }

  Future<GQLResponse> query(
    final DocumentNode document,
    final Map<String, dynamic> variables, {
    final bool refreshCache = false,
    final Map<String, dynamic>? requestHeaders,
  }) async {
    final client = await _createClient();
    return client.query(
      document,
      variables,
      refreshCache: refreshCache,
      requestHeaders: requestHeaders,
    );
  }

  Future<GQLResponse> rawQuery(
    final String documentString, {
    final Map<String, dynamic> variables = const {},
    final Map<String, dynamic>? requestHeaders,
  }) async {
    final client = await _createClient();
    return client.rawQuery(
      documentString,
      variables: variables,
      requestHeaders: requestHeaders,
    );
  }

  Future<gql_client.GraphqlClient> _createClient() async {
    final session = authenticatedSession;
    final serverConfig = session?.serverConfig;
    final graphqlUrl =
        serverConfig?.graphqlUrl ?? 'https://api.github.com/graphql';

    return gql_client.GraphqlClient(
      graphqlUrl: graphqlUrl,
      cacheStore: BaseAPIHandler._cacheStore!,
      getAuthToken: () => session?.token,
      onAuthRetry: (tokenRefreshService != null && session != null)
          ? () => tokenRefreshService!.forceRefresh(session)
          : null,
      onTokenInvalidated: () => AuthRepository.emitTokenInvalidated(),
      onError: (final DioException error) {
        AppLogger.error('GraphQL error', error: error, tag: 'GraphQL');
      },
      logRequest: apiLogSettings?.logGQLRequests == true
          ? (final String message) {
              AppLogger.info('GQL Request: $message', tag: 'GraphQL');
            }
          : null,
      logResponse: apiLogSettings?.logGQLResponses == true
          ? (final String message, {final bool isError = false}) {
              if (isError) {
                AppLogger.error('GQL Response: $message', tag: 'GraphQL');
              } else {
                AppLogger.info('GQL Response: $message', tag: 'GraphQL');
              }
            }
          : null,
    );
  }

  @override
  APICache get _defaultCacheOptions => APICache.gql();

  @override
  Future<void> onResponse(
    final Response<Object?> response,
    final ResponseInterceptorHandler handler,
  ) async {
    // GraphQL responses are handled by the GraphqlClient directly
    handler.next(response);
  }
}

abstract class BaseAPIHandler {
  BaseAPIHandler({
    required this.notifications,
    required this.tokenStore,
    required this.accountRepository,
    required this.authenticatedSession,
    this.tokenRefreshService,
    this.cacheOptions,
    this.apiLogSettings,
    this.addAuthHeader = true,
    this.propagateMessagesToUI = true,
    this.baseUrl,
  });

  /// Whether to enable Sentry HTTP tracking (set at app startup from ErrorTrackingSettings).
  static bool enableSentryHttpTracking = true;

  final NotificationService notifications;
  final TokenStore tokenStore;
  final AccountRepository accountRepository;
  final AuthenticatedSession? authenticatedSession;
  final TokenRefreshService? tokenRefreshService;

  final String? baseUrl;

  final bool addAuthHeader;
  final APICache? cacheOptions;
  final bool propagateMessagesToUI;

  APICache get _defaultCacheOptions => APICache();

  APICache get activeCacheOptions => cacheOptions ?? _defaultCacheOptions;

  final APILoggingSettings? apiLogSettings;

  APILoggingSettings? get defaultAPILogSettings => APILoggingSettings();

  /// Optional path to append to the base URL (e.g., '/graphql' for GraphQL handler)
  String? get path => null;

  Future<void> onError(
    final DioException error,
    final ErrorInterceptorHandler handler,
  ) async {}

  Future<void> onRequest(
    final RequestOptions options,
    final RequestInterceptorHandler handler,
  ) async {}

  Future<void> onResponse(
    final Response<Object?> response,
    final ResponseInterceptorHandler handler,
  ) async {}

  Dio _request({
    final Map<String, dynamic>? requestHeaders,
    final APICache? overrideAPICache,
  }) {
    final APICache cache =
        overrideAPICache ?? cacheOptions ?? _defaultCacheOptions;

    final Dio dio = Dio(
      BaseOptions(
        validateStatus: (final int? status) =>
            status != null && (status >= 200 && status < 300 || status == 304),
      ),
    );
    // Log the request in the console if `apiLogSettings` is not null.
    final APILoggingSettings? logSettings =
        apiLogSettings ?? defaultAPILogSettings;
    if (logSettings != null) {
      dio.interceptors.add(
        TalkerDioLogger(
          talker: appTalker,
          settings: TalkerDioLoggerSettings(
            printRequestHeaders: logSettings.requestHeader,
            printRequestData: logSettings.requestBody,
            printResponseHeaders: logSettings.responseHeader,
            printResponseData: logSettings.responseBody,
          ),
        ),
      );
    }

    if (addAuthHeader) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final session = authenticatedSession;
            String? token = session?.token;
            if (session != null && tokenRefreshService != null) {
              token =
                  await tokenRefreshService!.refreshIfNeeded(session) ?? token;
            }
            if (token != null) {
              options.headers['Authorization'] = 'token $token';
            }
            handler.next(options);
          },
        ),
      );
    }
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (
              final RequestOptions options,
              final RequestInterceptorHandler handler,
            ) async {
              // Use authenticated session's server config if available
              final serverConfig =
                  authenticatedSession?.serverConfig ??
                  ServerConfig.gitHubDotCom;
              final String apiBase = baseUrl ?? serverConfig.restBaseUrl;

              // Append path if handler defines one (e.g., '/graphql' for GraphQL)
              if (path != null) {
                options.baseUrl = '$apiBase$path';
              } else {
                options.baseUrl = apiBase;
              }

              options.headers['Accept'] = 'application/json';
              options.headers['setContentType'] = 'application/json';
              options.headers['User-Agent'] = 'com.felix.diohub';
              if (requestHeaders != null) {
                options.headers.addAll(requestHeaders);
              }

              // Normalize path: ensure relative paths start with '/'
              if (!options.path.startsWith('http') &&
                  !options.path.startsWith('/')) {
                options.path = '/${options.path}';
              }

              await onRequest(options, handler);
              // Proceed with the request.
              handler.next(options);
            },
        onResponse:
            (
              final Response<Object?> response,
              final ResponseInterceptorHandler handler,
            ) async {
              await onResponse(response, handler);
              try {
                handler.next(response);
              } catch (e, st) {
                AppLogger.warning(
                  'Response handler.next failed (handler may have been called by onResponse override)',
                  error: e,
                  stackTrace: st,
                  tag: 'Dio',
                );
              }
            },
        onError: (final DioException error, final ErrorInterceptorHandler handler) async {
          await onError(error, handler);

          // Log every HTTP error to console. Use scoped log when entityRef is in extra.
          final entityRef =
              error.requestOptions.extra['entityRef'] as EntityRef?;
          final msg =
              'HTTP ${error.response?.statusCode ?? 'N/A'} '
              '${error.requestOptions.method} ${error.requestOptions.uri}: '
              '${error.message ?? error.type.name}';
          if (entityRef != null) {
            AppLogger.scopedError(msg, entityRef, error: error, tag: 'Dio');
          } else {
            AppLogger.error(msg, error: error, tag: 'Dio');
          }

          if (error.response == null) {
            handler.next(error);
            return;
          } else {
            // Check for "Bad credentials" (invalid/revoked token) and try refresh
            if (AuthRepository.isTokenInvalidError(error)) {
              final session = authenticatedSession;
              if (session != null && tokenRefreshService != null) {
                final refreshed = await tokenRefreshService!.forceRefresh(
                  session,
                );
                if (refreshed != null) {
                  final retry = error.requestOptions;
                  retry.headers['Authorization'] = 'token $refreshed';
                  try {
                    handler.resolve(await dio.fetch(retry));
                    return;
                  } catch (_) {
                    // Retry with refreshed token failed - fall through to token invalidation
                  }
                }
              }
              AuthRepository.emitTokenInvalidated();
            }

            if (propagateMessagesToUI) {
              if (error.response?.data is Map &&
                  (error.response?.data as Map).containsKey('message')) {
                notifications.error(
                  (error.response!.data as Map)['message'] as String,
                );
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    // Sentry Dio integration for HTTP breadcrumbs and tracing
    // The beforeBreadcrumb callback in sentry_config.dart scrubs auth headers
    if (enableSentryHttpTracking) {
      dio.addSentry(captureFailedRequests: true);
    }

    // Check cache first and return cached data if supplied maxAge
    // has not elapsed. Skipped if cacheOptions is null as the default
    // behaviour in that case is to refresh the data.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (
              final RequestOptions options,
              final RequestInterceptorHandler handler,
            ) async {
              final bool checkCache =
                  cache.cacheOptions.policy != CachePolicy.noCache &&
                  cache.cacheOptions.policy != CachePolicy.refresh &&
                  cache.maxAge != null;
              if (checkCache) {
                final String key = cache.cacheOptions.keyBuilder(
                  url: options.uri,
                  headers: options.headers.cast(),
                );
                final CacheResponse? cacheData = await _cacheStore!.get(key);
                final bool cacheIsBeforeExpiry =
                    cacheData != null &&
                    DateTime.now().isBefore(
                      cacheData.responseDate.add(cache.maxAge!),
                    );
                if (cacheIsBeforeExpiry) {
                  // Resolve the request and pass cached data as response.
                  return handler.resolve(cacheData.toResponse(options));
                }
              }
              handler.next(options);
            },
      ),
    );
    // Add the interceptor to handle caching.
    dio.interceptors.add(DioCacheInterceptor(options: cache.cacheOptions));

    return dio;
  }

  static CacheStore? _cacheStore;

  static Future<void> setupDioAPICache() async {
    if (_cacheStore != null) return;
    final directory = await getApplicationDocumentsDirectory();
    _cacheStore = DriftCacheStore(
      databasePath: p.join(directory.path, 'dio_api_cache.db'),
    );
  }

  static Future<void> clearCache() async {
    await _cacheStore!.clean();
  }

  Map<String, dynamic> acceptHeader(final String header) => <String, dynamic>{
    'Accept': header,
  };
}

/// Settings for [TalkerDioLogger]; only the four booleans are used.
class APILoggingSettings {
  APILoggingSettings({
    this.requestHeader = false,
    this.requestBody = false,
    this.responseHeader = false,
    this.responseBody = false,
    this.logGQLRequests = false,
    this.logGQLResponses = false,
  });

  APILoggingSettings.comprehensive()
    : requestHeader = true,
      requestBody = true,
      responseHeader = true,
      responseBody = true,
      logGQLRequests = true,
      logGQLResponses = true;

  APILoggingSettings.none()
    : requestHeader = false,
      requestBody = false,
      responseHeader = false,
      responseBody = false,
      logGQLRequests = false,
      logGQLResponses = false;

  final bool requestHeader;
  final bool requestBody;
  final bool responseHeader;
  final bool responseBody;
  final bool logGQLRequests;
  final bool logGQLResponses;
}
