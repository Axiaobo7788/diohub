import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart' show parseString;
import 'package:gql_dio_link/gql_dio_link.dart';
import 'package:gql_exec/gql_exec.dart' as gql_exec;
import 'package:gql_link/gql_link.dart';
import 'package:uuid/uuid.dart';

export 'package:gql_exec/gql_exec.dart' show Response;

typedef GQLResponse = gql_exec.Response;
typedef GQLRequest = gql_exec.Request;
typedef GQLOperation = gql_exec.Operation;

/// A simple GraphQL client that sends requests over Dio.
///
/// Signature changed from Ferry's OperationRequest to plain DocumentNode + variables Map.
class GraphqlClient {
  GraphqlClient({
    required this.graphqlUrl,
    required this.cacheStore,
    this.getAuthToken,
    this.onAuthRetry,
    this.onTokenInvalidated,
    this.onError,
    this.logRequest,
    this.logResponse,
  });

  final String graphqlUrl;
  final CacheStore cacheStore;
  final String? Function()? getAuthToken;
  final Future<String?> Function()? onAuthRetry;
  final void Function()? onTokenInvalidated;
  final void Function(DioException error)? onError;
  final void Function(String message)? logRequest;
  final void Function(String message, {bool isError})? logResponse;

  Future<GQLResponse> query(
    DocumentNode document,
    Map<String, dynamic> variables, {
    bool refreshCache = false,
    Map<String, dynamic>? requestHeaders,
  }) async {
    return _executeQuery(
      document,
      variables,
      requestHeaders: requestHeaders,
      cachePolicy:
          refreshCache ? CachePolicy.refresh : CachePolicy.refreshForceCache,
    );
  }

  Future<GQLResponse> mutation(
    DocumentNode document,
    Map<String, dynamic> variables, {
    Map<String, dynamic>? requestHeaders,
  }) async {
    return _executeQuery(
      document,
      variables,
      requestHeaders: requestHeaders,
      cachePolicy: CachePolicy.noCache,
    );
  }

  Future<GQLResponse> rawQuery(
    String documentString, {
    Map<String, dynamic> variables = const {},
    Map<String, dynamic>? requestHeaders,
  }) async {
    final document = parseString(documentString);
    return _executeQuery(
      document,
      variables,
      requestHeaders: requestHeaders,
      cachePolicy: CachePolicy.noCache,
    );
  }

  Future<GQLResponse> _executeQuery(
    DocumentNode document,
    Map<String, dynamic> variables, {
    required CachePolicy cachePolicy,
    Map<String, dynamic>? requestHeaders,
  }) async {
    final operation =
        gql_exec.Operation(document: document, operationName: null);
    final request = GQLRequest(operation: operation, variables: variables);

    final dio =
        _createDio(cachePolicy: cachePolicy, requestHeaders: requestHeaders);

    logRequest?.call('GraphQL ${operation.operationName ?? "query"}');

    return DioLink(graphqlUrl, client: dio)
        .request(request)
        .first
        .onError<DioLinkServerException>(
      (error, stackTrace) {
        // Handle 304 Not Modified from cache
        if (error.response.statusCode == 304) {
          final gqlResponse = const ResponseParser()
              .parseResponse(error.response.data as Map<String, dynamic>);
          return GQLResponse(
            data: gqlResponse.data,
            errors: gqlResponse.errors,
            response: gqlResponse.response,
          );
        }
        throw error;
      },
    ).onError<LinkException>(
      (error, stackTrace) {
        // Try to recover partial data from Dio exceptions
        if (error.originalException is DioException) {
          final dioEx = error.originalException! as DioException;
          final responseData = dioEx.response?.data;
          if (responseData is Map<String, dynamic>) {
            final data = responseData['data'];
            if (data is Map && data.isNotEmpty) {
              logResponse?.call(
                'GraphQL: recovering partial data from LinkException (errors: ${responseData['errors']})',
                isError: true,
              );
              final gqlResponse =
                  const ResponseParser().parseResponse(responseData);
              return GQLResponse(
                data: gqlResponse.data,
                errors: gqlResponse.errors,
                response: gqlResponse.response,
              );
            }
          }
        }
        logResponse?.call('GraphQL: unrecoverable LinkException: $error',
            isError: true);
        throw error;
      },
    );
  }

  Dio _createDio({
    required CachePolicy cachePolicy,
    Map<String, dynamic>? requestHeaders,
  }) {
    final dio = Dio(
      BaseOptions(
        validateStatus: (status) =>
            status != null && (status >= 200 && status < 300 || status == 304),
      ),
    );

    // Auth interceptor
    final token = getAuthToken?.call();
    if (token != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'token $token';
            handler.next(options);
          },
        ),
      );
    }

    // Additional headers
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Accept'] = 'application/json';
          options.headers['Content-Type'] = 'application/json';
          options.headers['User-Agent'] = 'com.felix.diohub';
          if (requestHeaders != null) {
            options.headers.addAll(requestHeaders);
          }
          handler.next(options);
        },
      ),
    );

    // Response error handler
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final gqlResponse = const ResponseParser()
              .parseResponse(response.data! as Map<String, dynamic>);
          if (gqlResponse.errors != null) {
            final hasData = gqlResponse.data != null &&
                gqlResponse.data is Map &&
                (gqlResponse.data! as Map).isNotEmpty;

            if (hasData) {
              logResponse?.call(
                'GraphQL partial errors (data present): ${gqlResponse.errors}',
                isError: true,
              );
            } else {
              logResponse?.call('GraphQL total failure: ${gqlResponse.errors}',
                  isError: true);
              handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  error: gqlResponse.errors,
                ),
              );
              return;
            }
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          // 401-retry with token refresh
          if (error.response?.statusCode == 401 && onAuthRetry != null) {
            final newToken = await onAuthRetry!();
            if (newToken != null) {
              final retry = error.requestOptions;
              retry.headers['Authorization'] = 'token $newToken';
              try {
                handler.resolve(await dio.fetch(retry));
                return;
              } catch (_) {
                // Retry with refreshed token failed - fall through to token invalidation
              }
            }
            // Retry failed or refresh returned null -- token is permanently invalid
            onTokenInvalidated?.call();
          }
          onError?.call(error);
          handler.next(error);
        },
      ),
    );

    // Cache interceptor
    dio.interceptors.add(
      DioCacheInterceptor(
        options: CacheOptions(
          store: cacheStore,
          policy: cachePolicy,
          keyBuilder: (
              {required Uri url, Map<String, String>? headers, Object? body}) {
            final uuid = const Uuid();
            return uuid.v5(
                Uuid.NAMESPACE_URL, url.toString() + (body?.toString() ?? ''));
          },
          allowPostMethod: true,
          maxStale: const Duration(days: 7),
        ),
      ),
    );

    return dio;
  }
}
