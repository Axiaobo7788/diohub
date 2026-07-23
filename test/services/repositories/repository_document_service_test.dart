import 'package:dio/dio.dart';
import 'package:diohub/models/repository_document.dart';
import 'package:diohub/services/repositories/repository_document_service.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RepoRef repoRef = RepoRef(owner: 'owner', name: 'repo');

  group('RepositoryDocumentService', () {
    test('falls through 404 candidates and returns rendered HTML', () async {
      final List<String> paths = <String>[];
      final List<Map<String, dynamic>?> queries = <Map<String, dynamic>?>[];
      final List<Map<String, dynamic>?> headers = <Map<String, dynamic>?>[];
      final RepositoryDocumentService service =
          RepositoryDocumentService.withGet(
            repoRef: repoRef,
            get:
                (
                  final String path, {
                  final Map<String, dynamic>? queryParameters,
                  final Map<String, dynamic>? requestHeaders,
                }) async {
                  paths.add(path);
                  queries.add(queryParameters);
                  headers.add(requestHeaders);
                  if (path.endsWith('.github/CONTRIBUTING.md')) {
                    throw _httpError(path, 404);
                  }
                  return Response<String>(
                    requestOptions: RequestOptions(path: path),
                    statusCode: 200,
                    data: '<h1>Contributing</h1>',
                  );
                },
          );

      final RepositoryDocument? document = await service.fetchHtml(
        kind: RepositoryDocumentKind.contributing,
        branch: 'feature/docs',
      );

      expect(paths, <String>[
        '/repos/owner/repo/contents/.github/CONTRIBUTING.md',
        '/repos/owner/repo/contents/CONTRIBUTING.md',
      ]);
      expect(queries, everyElement(<String, dynamic>{'ref': 'feature/docs'}));
      expect(
        headers,
        everyElement(<String, dynamic>{
          'Accept': RepositoryDocumentService.htmlMediaType,
        }),
      );
      expect(document?.kind, RepositoryDocumentKind.contributing);
      expect(document?.branch, 'feature/docs');
      expect(document?.format, RepositoryDocumentFormat.html);
      expect(document?.path, 'CONTRIBUTING.md');
      expect(document?.content, '<h1>Contributing</h1>');
    });

    test('returns null when every supported location is missing', () async {
      var requests = 0;
      final RepositoryDocumentService service =
          RepositoryDocumentService.withGet(
            repoRef: repoRef,
            get:
                (
                  final String path, {
                  final Map<String, dynamic>? queryParameters,
                  final Map<String, dynamic>? requestHeaders,
                }) async {
                  requests += 1;
                  throw _httpError(path, 404);
                },
          );

      final RepositoryDocument? document = await service.fetchHtml(
        kind: RepositoryDocumentKind.security,
        branch: 'main',
      );

      expect(document, isNull);
      expect(requests, 3);
    });

    test('preserves non-404 errors for the provider error state', () async {
      late DioException forbidden;
      final RepositoryDocumentService service =
          RepositoryDocumentService.withGet(
            repoRef: repoRef,
            get:
                (
                  final String path, {
                  final Map<String, dynamic>? queryParameters,
                  final Map<String, dynamic>? requestHeaders,
                }) async {
                  forbidden = _httpError(path, 403);
                  throw forbidden;
                },
          );

      await expectLater(
        service.fetchHtml(
          kind: RepositoryDocumentKind.security,
          branch: 'main',
        ),
        throwsA(same(forbidden)),
      );
    });
  });
}

DioException _httpError(final String path, final int statusCode) {
  final RequestOptions request = RequestOptions(path: path);
  return DioException(
    requestOptions: request,
    response: Response<String>(requestOptions: request, statusCode: statusCode),
  );
}
