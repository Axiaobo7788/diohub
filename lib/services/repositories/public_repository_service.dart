import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/models/repositories/public_repository.dart';

typedef PublicRepositoryGet =
    Future<Object?> Function(
      String path,
      Map<String, dynamic>? queryParameters,
    );

/// Read-only GitHub REST access used by the shared public home.
///
/// The production constructor reuses DioHub's existing REST handler, cache and
/// error handling. Requests automatically use the active account when available
/// and remain unsigned otherwise; this service never creates or stores a token.
class PublicRepositoryService {
  PublicRepositoryService(this._rest) : _getOverride = null;

  PublicRepositoryService.withGet(this._getOverride) : _rest = null;

  final RESTHandler? _rest;
  final PublicRepositoryGet? _getOverride;

  Future<List<PublicRepositorySummary>> searchRepositories(
    final String query, {
    final int page = 1,
    final int perPage = 30,
  }) async {
    final String normalized = query.trim();
    if (normalized.isEmpty) {
      return const <PublicRepositorySummary>[];
    }
    final Object? data = await _get('/search/repositories', <String, dynamic>{
      'q': normalized,
      'page': page,
      'per_page': perPage.clamp(1, 50),
    });
    final Map<String, dynamic> json = _expectMap(data, 'repository search');
    final Object? rawItems = json['items'];
    if (rawItems is! List<dynamic>) {
      throw const FormatException(
        'GitHub returned invalid public repository results.',
      );
    }
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(PublicRepositorySummary.fromJson)
        .toList(growable: false);
  }

  Future<List<PublicRepositoryEntry>> listContents({
    required final String fullName,
    required final String ref,
    final String path = '',
  }) async {
    final String endpoint = _contentsEndpoint(fullName, path);
    final Object? data = await _get(endpoint, <String, dynamic>{'ref': ref});
    if (data is! List<dynamic>) {
      throw const FormatException(
        'GitHub returned invalid repository contents.',
      );
    }
    final List<PublicRepositoryEntry> entries = data
        .whereType<Map<String, dynamic>>()
        .map(PublicRepositoryEntry.fromJson)
        .toList(growable: false);
    entries.sort((
      final PublicRepositoryEntry left,
      final PublicRepositoryEntry right,
    ) {
      if (left.isDirectory != right.isDirectory) {
        return left.isDirectory ? -1 : 1;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return entries;
  }

  Future<String> readTextFile({
    required final String fullName,
    required final String ref,
    required final String path,
  }) async {
    final Object? data = await _get(
      _contentsEndpoint(fullName, path),
      <String, dynamic>{'ref': ref},
    );
    final Map<String, dynamic> json = _expectMap(data, 'repository file');
    if (json['encoding'] != 'base64' || json['content'] is! String) {
      throw UnsupportedError('This file cannot be previewed here.');
    }
    final List<int> bytes = base64Decode(
      (json['content'] as String).replaceAll('\n', ''),
    );
    if (bytes.contains(0)) {
      throw UnsupportedError('Binary files cannot be previewed here.');
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String _contentsEndpoint(final String fullName, final String path) {
    final String encodedRepository = fullName
        .split('/')
        .map(Uri.encodeComponent)
        .join('/');
    final String encodedPath = path
        .split('/')
        .where((final String segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    return '/repos/$encodedRepository/contents'
        '${encodedPath.isEmpty ? '' : '/$encodedPath'}';
  }

  static Map<String, dynamic> _expectMap(
    final Object? value,
    final String operation,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw FormatException('GitHub returned an invalid $operation response.');
  }

  Future<Object?> _get(
    final String path,
    final Map<String, dynamic>? queryParameters,
  ) async {
    final PublicRepositoryGet? override = _getOverride;
    if (override != null) {
      return override(path, queryParameters);
    }
    return (await _rest!.get<Object?>(
      path,
      queryParameters: queryParameters,
    )).data;
  }
}

String publicGitHubErrorMessage(final Object error) {
  if (error is DioException) {
    final int? status = error.response?.statusCode;
    final Headers? headers = error.response?.headers;
    if ((status == 403 || status == 429) &&
        headers?.value('x-ratelimit-remaining') == '0') {
      return 'GitHub\'s unsigned API limit has been reached. Sign in for a higher limit or try again later.';
    }
    final Object? data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
  }
  return error.toString().replaceFirst('Exception: ', '');
}
