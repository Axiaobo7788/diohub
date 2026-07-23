import 'package:dio/dio.dart';
import 'package:diohub/models/github_changelog_item.dart';
import 'package:diohub/services/dashboard/github_changelog_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubChangelogService', () {
    test('uses the public endpoint and parses the latest four items', () async {
      late RequestOptions request;
      final Dio dio = _dioRespondingWith(<Map<String, dynamic>>[
        <String, dynamic>{
          'date_gmt': '2026-07-21T15:04:31',
          'link': 'https://github.blog/changelog/example-one',
          'title': <String, dynamic>{
            'rendered': 'Actions &amp; Packages &#8211; update',
          },
        },
        for (int index = 2; index <= 4; index++)
          <String, dynamic>{
            'date_gmt': '2026-07-2${index - 1}T12:00:00',
            'link': 'https://github.blog/changelog/example-$index',
            'title': <String, dynamic>{'rendered': 'Update $index'},
          },
      ], onRequest: (final RequestOptions value) => request = value);
      final GitHubChangelogService service = GitHubChangelogService.withDio(
        dio,
      );
      addTearDown(service.close);

      final List<GitHubChangelogItem> items = await service.fetchLatest();

      expect(request.baseUrl, 'https://github.blog');
      expect(request.path, '/wp-json/wp/v2/changelogs');
      expect(request.queryParameters, <String, Object>{
        'per_page': 4,
        '_fields': 'date_gmt,link,title',
      });
      expect(request.headers['Authorization'], isNull);
      expect(items, hasLength(4));
      expect(items.first.title, 'Actions & Packages – update');
      expect(items.first.publishedAt, DateTime.utc(2026, 7, 21, 15, 4, 31));
      expect(
        items.first.link,
        Uri.parse('https://github.blog/changelog/example-one'),
      );
    });

    test('rejects changelog links outside the official HTTPS origin', () {
      final Dio dio = _dioRespondingWith(<Map<String, dynamic>>[
        <String, dynamic>{
          'date_gmt': '2026-07-21T15:04:31',
          'link': 'https://example.com/not-github',
          'title': <String, dynamic>{'rendered': 'Untrusted link'},
        },
      ]);
      final GitHubChangelogService service = GitHubChangelogService.withDio(
        dio,
      );
      addTearDown(service.close);

      expect(service.fetchLatest(), throwsFormatException);
    });

    test('rejects malformed responses instead of returning fake data', () {
      final Dio dio = _dioRespondingWith(<String, dynamic>{'not': 'a list'});
      final GitHubChangelogService service = GitHubChangelogService.withDio(
        dio,
      );
      addTearDown(service.close);

      expect(service.fetchLatest(), throwsFormatException);
    });
  });
}

Dio _dioRespondingWith(
  final Object data, {
  final void Function(RequestOptions)? onRequest,
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://github.blog',
      headers: const <String, String>{'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest:
          (
            final RequestOptions options,
            final RequestInterceptorHandler handler,
          ) {
            onRequest?.call(options);
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                data: data,
                statusCode: 200,
              ),
            );
          },
    ),
  );
  return dio;
}
