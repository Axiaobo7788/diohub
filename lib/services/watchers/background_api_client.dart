/// Lightweight REST-only API client for background isolate watcher execution.
///
/// This client is designed to be used in the background isolate where full
/// Riverpod/Dio infrastructure is not available. It provides only the minimal
/// functionality needed by watchers: authenticated REST GET requests.
library;

import 'package:dio/dio.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/services/base/base_service.dart';

/// Minimal API client for background watchers.
///
/// Provides authenticated REST access using a pre-fetched token. No caching,
/// no GraphQL, no UI notifications. Suitable for use in Workmanager background
/// isolate.
class BackgroundApiClient implements WatcherApiClient {
  BackgroundApiClient({
    required String token,
    required String baseUrl,
  })  : _token = token,
        _baseUrl = baseUrl {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'token $_token',
        'Accept': 'application/vnd.github.v3+json',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  final String _token;
  final String _baseUrl;
  late final Dio _dio;

  /// Make a GET request to the REST API.
  ///
  /// Returns the full [Response] object or throws [DioException] on error.
  @override
  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      AppLogger.warning(
        'Background API request failed: $path',
        error: e,
        tag: 'BackgroundApiClient',
      );
      rethrow;
    }
  }

  /// Make a GET request that returns a map.
  Future<Map<String, dynamic>> getMap(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Empty response body',
        );
      }
      return response.data!;
    } on DioException catch (e) {
      AppLogger.warning(
        'Background API request failed: $path',
        error: e,
        tag: 'BackgroundApiClient',
      );
      rethrow;
    }
  }

  /// Make a GET request that returns a list.
  Future<List<dynamic>> getList(String path) async {
    try {
      final response = await _dio.get<List<dynamic>>(path);
      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Empty response body',
        );
      }
      return response.data!;
    } on DioException catch (e) {
      AppLogger.warning(
        'Background API request failed: $path',
        error: e,
        tag: 'BackgroundApiClient',
      );
      rethrow;
    }
  }

  /// Dispose the client (cancel any pending requests).
  void dispose() {
    _dio.close();
  }
}
