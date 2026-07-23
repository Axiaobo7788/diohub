import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:diohub/models/repositories/public_repository.dart';
import 'package:diohub/services/repositories/public_repository_service.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PublicRepositoryService', () {
    test('searches public repositories through the shared REST path', () async {
      late String receivedPath;
      late Map<String, dynamic>? receivedQuery;
      final PublicRepositoryService service = PublicRepositoryService.withGet((
        final String path,
        final Map<String, dynamic>? query,
      ) async {
        receivedPath = path;
        receivedQuery = query;
        return <String, dynamic>{
          'items': <Map<String, dynamic>>[_repositoryJson],
        };
      });

      final List<PublicRepositorySummary> results = await service
          .searchRepositories(' flutter ', perPage: 100);

      expect(receivedPath, '/search/repositories');
      expect(receivedQuery, <String, dynamic>{
        'q': 'flutter',
        'page': 1,
        'per_page': 50,
      });
      expect(results, hasLength(1));
      expect(results.single.fullName, 'flutter/flutter');
      expect(results.single.defaultBranch, 'master');
    });

    test('encodes paths and sorts directories before files', () async {
      late String receivedPath;
      final PublicRepositoryService service = PublicRepositoryService.withGet((
        final String path,
        final Map<String, dynamic>? query,
      ) async {
        receivedPath = path;
        return <Map<String, dynamic>>[
          _entryJson(name: 'z.dart', path: 'docs and notes/z.dart'),
          _entryJson(
            name: 'assets',
            path: 'docs and notes/assets',
            type: 'dir',
          ),
        ];
      });

      final List<PublicRepositoryEntry> entries = await service.listContents(
        fullName: 'owner/repo',
        ref: 'main',
        path: 'docs and notes',
      );

      expect(receivedPath, '/repos/owner/repo/contents/docs%20and%20notes');
      expect(entries.first.kind, PublicRepositoryEntryKind.directory);
      expect(entries.last.name, 'z.dart');
    });

    test(
      'searches public issues and pull requests with real pagination',
      () async {
        late String receivedPath;
        late Map<String, dynamic>? receivedQuery;
        final PublicRepositoryService service = PublicRepositoryService.withGet(
          (final String path, final Map<String, dynamic>? query) async {
            receivedPath = path;
            receivedQuery = query;
            return <String, dynamic>{
              'total_count': 3,
              'items': <Map<String, dynamic>>[
                _issuePullJson(number: 1),
                _issuePullJson(number: 2, pullRequest: true, merged: true),
              ],
            };
          },
        );

        final PageSlice<PublicRepositoryIssuePullSummary> result = await service
            .searchIssuesPulls(
              repo: const RepoRef(owner: 'flutter', name: 'flutter'),
              query: ' repo:flutter/flutter is:open type:issue ',
              page: 1,
              perPage: 2,
            );

        expect(receivedPath, '/search/issues');
        expect(receivedQuery, <String, dynamic>{
          'q': 'repo:flutter/flutter is:open type:issue',
          'page': 1,
          'per_page': 2,
        });
        expect(result.totalCount, 3);
        expect(result.hasNextPage, isTrue);
        expect(result.items, hasLength(2));
        expect(result.items.first.isPullRequest, isFalse);
        expect(result.items.last.isPullRequest, isTrue);
        expect(result.items.last.isMerged, isTrue);
        expect(result.items.last.repo.fullName, 'flutter/flutter');
        expect(result.items.last.labels.single.name, 'bug');
      },
    );

    test('decodes base64 text and rejects binary files', () async {
      var binary = false;
      final PublicRepositoryService service = PublicRepositoryService.withGet((
        final String path,
        final Map<String, dynamic>? query,
      ) async {
        final List<int> bytes = binary
            ? <int>[0, 1, 2]
            : utf8.encode('hello public');
        return <String, dynamic>{
          'encoding': 'base64',
          'content': base64Encode(bytes),
        };
      });

      expect(
        await service.readTextFile(
          fullName: 'owner/repo',
          ref: 'main',
          path: 'README.md',
        ),
        'hello public',
      );

      binary = true;
      await expectLater(
        service.readTextFile(
          fullName: 'owner/repo',
          ref: 'main',
          path: 'logo.png',
        ),
        throwsUnsupportedError,
      );
    });

    test('uses the localized message for unsigned rate limits', () {
      final RequestOptions request = RequestOptions(path: '/search/issues');
      final DioException error = DioException(
        requestOptions: request,
        response: Response<Object?>(
          requestOptions: request,
          statusCode: 403,
          headers: Headers.fromMap(<String, List<String>>{
            'x-ratelimit-remaining': <String>['0'],
          }),
        ),
      );

      expect(
        publicGitHubErrorMessage(
          error,
          rateLimitMessage: 'localized rate limit',
        ),
        'localized rate limit',
      );
    });
  });
}

const Map<String, dynamic> _repositoryJson = <String, dynamic>{
  'id': 1,
  'name': 'flutter',
  'owner': <String, dynamic>{'login': 'flutter'},
  'full_name': 'flutter/flutter',
  'description': 'Flutter makes it easy and fast to build beautiful apps.',
  'html_url': 'https://github.com/flutter/flutter',
  'default_branch': 'master',
  'stargazers_count': 170000,
  'forks_count': 28000,
  'language': 'Dart',
  'archived': false,
};

Map<String, dynamic> _entryJson({
  required final String name,
  required final String path,
  final String type = 'file',
}) => <String, dynamic>{
  'name': name,
  'path': path,
  'sha': 'abc123',
  'type': type,
  'size': type == 'dir' ? 0 : 42,
  'html_url': 'https://github.com/owner/repo/blob/main/$path',
  'download_url': type == 'dir'
      ? null
      : 'https://raw.githubusercontent.com/owner/repo/main/$path',
};

Map<String, dynamic> _issuePullJson({
  required final int number,
  final bool pullRequest = false,
  final bool merged = false,
}) => <String, dynamic>{
  'id': number,
  'node_id': 'node-$number',
  'number': number,
  'title': pullRequest ? 'Improve the public list' : 'Public issue',
  'user': <String, dynamic>{'login': 'octocat'},
  'created_at': '2026-07-20T08:00:00Z',
  'closed_at': merged ? '2026-07-21T08:00:00Z' : null,
  'comments': number,
  'state': merged ? 'closed' : 'open',
  'state_reason': null,
  'labels': <Map<String, dynamic>>[
    <String, dynamic>{'name': 'bug', 'color': 'd73a4a'},
  ],
  'html_url':
      'https://github.com/flutter/flutter/${pullRequest ? 'pull' : 'issues'}/$number',
  if (pullRequest)
    'pull_request': <String, dynamic>{
      'url': 'https://api.github.com/repos/flutter/flutter/pulls/$number',
      'merged_at': merged ? '2026-07-21T08:00:00Z' : null,
    },
  if (pullRequest) 'draft': false,
};
