import 'dart:async';

import 'package:dio/dio.dart';
import 'package:diohub/models/github_changelog_item.dart';
import 'package:diohub/providers/dashboard/github_changelog_provider.dart';
import 'package:diohub/services/dashboard/github_changelog_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'provider exposes loading before the changelog request completes',
    () async {
      final Completer<void> gate = Completer<void>();
      final Dio dio = _delayedDio(gate.future);
      final GitHubChangelogService service = GitHubChangelogService.withDio(
        dio,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          githubChangelogServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(() {
        container.dispose();
        service.close();
      });

      expect(
        container.read(githubChangelogProvider),
        isA<AsyncLoading<List<GitHubChangelogItem>>>(),
      );

      gate.complete();
      final List<GitHubChangelogItem> items = await container.read(
        githubChangelogProvider.future,
      );

      expect(items.single.title, 'GitHub Changelog');
      expect(
        container.read(githubChangelogProvider),
        isA<AsyncData<List<GitHubChangelogItem>>>(),
      );
    },
  );

  test('provider preserves request failures as AsyncError', () async {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://github.blog'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (
              final RequestOptions options,
              final RequestInterceptorHandler handler,
            ) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  message: 'offline',
                ),
              );
            },
      ),
    );
    final GitHubChangelogService service = GitHubChangelogService.withDio(dio);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        githubChangelogServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(() {
      container.dispose();
      service.close();
    });

    await expectLater(
      container.read(githubChangelogProvider.future),
      throwsA(isA<DioException>()),
    );
    expect(
      container.read(githubChangelogProvider),
      isA<AsyncError<List<GitHubChangelogItem>>>(),
    );
  });
}

Dio _delayedDio(final Future<void> gate) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://github.blog'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest:
          (
            final RequestOptions options,
            final RequestInterceptorHandler handler,
          ) async {
            await gate;
            handler.resolve(
              Response<Object?>(
                requestOptions: options,
                statusCode: 200,
                data: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'date_gmt': '2026-07-21T15:04:31',
                    'link': 'https://github.blog/changelog/example',
                    'title': <String, dynamic>{'rendered': 'GitHub Changelog'},
                  },
                ],
              ),
            );
          },
    ),
  );
  return dio;
}
