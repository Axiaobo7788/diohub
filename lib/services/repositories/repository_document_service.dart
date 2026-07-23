import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/models/repository_document.dart';
import 'package:diohub_models/models/entity_ref.dart';

typedef RepositoryDocumentGet =
    Future<Response<String>> Function(
      String path, {
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic>? requestHeaders,
    });

/// Fetches rendered repository community documents through GitHub's Contents
/// API without making them part of the repository page's initial data gate.
class RepositoryDocumentService {
  RepositoryDocumentService(this._rest, this.repoRef) : _getOverride = null;

  RepositoryDocumentService.withGet({
    required this.repoRef,
    required final RepositoryDocumentGet get,
  }) : _rest = null,
       _getOverride = get;

  static const String htmlMediaType = 'application/vnd.github.html+json';

  final RESTHandler? _rest;
  final RepositoryDocumentGet? _getOverride;
  final RepoRef repoRef;

  /// Returns the first recognized document for [kind] on [branch].
  ///
  /// Missing candidate files are skipped. If all candidates return 404 the
  /// document is absent and `null` is returned; every other HTTP failure is
  /// preserved for the caller's error state.
  Future<RepositoryDocument?> fetchHtml({
    required final RepositoryDocumentKind kind,
    required final String branch,
  }) async {
    final List<String> paths = switch (kind) {
      RepositoryDocumentKind.contributing => const <String>[
        '.github/CONTRIBUTING.md',
        'CONTRIBUTING.md',
        'docs/CONTRIBUTING.md',
      ],
      RepositoryDocumentKind.security => const <String>[
        '.github/SECURITY.md',
        'SECURITY.md',
        'docs/SECURITY.md',
      ],
      RepositoryDocumentKind.readme ||
      RepositoryDocumentKind.license => throw ArgumentError.value(
        kind,
        'kind',
        'README and license content use their existing providers.',
      ),
    };

    for (final String path in paths) {
      try {
        final Response<String> response = await _get(
          '${repoRef.apiPath}/contents/$path',
          queryParameters: <String, dynamic>{'ref': branch},
          requestHeaders: const <String, dynamic>{'Accept': htmlMediaType},
        );
        final String? content = response.data;
        if (content == null) {
          throw StateError(
            'GitHub returned an empty response for ${repoRef.fullName}/$path',
          );
        }
        return RepositoryDocument(
          kind: kind,
          branch: branch,
          content: content,
          format: RepositoryDocumentFormat.html,
          path: path,
        );
      } on DioException catch (error) {
        if (error.response?.statusCode == 404) {
          continue;
        }
        rethrow;
      }
    }
    return null;
  }

  Future<Response<String>> _get(
    final String path, {
    required final Map<String, dynamic> queryParameters,
    required final Map<String, dynamic> requestHeaders,
  }) {
    final RepositoryDocumentGet? override = _getOverride;
    if (override != null) {
      return override(
        path,
        queryParameters: queryParameters,
        requestHeaders: requestHeaders,
      );
    }
    return _rest!.get<String>(
      path,
      queryParameters: queryParameters,
      requestHeaders: requestHeaders,
    );
  }
}
