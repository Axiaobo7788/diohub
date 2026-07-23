import 'package:dio/dio.dart';
import 'package:diohub/models/github_changelog_item.dart';
import 'package:html/parser.dart' show parseFragment;

/// Loads the public GitHub product changelog without account credentials.
///
/// This service deliberately owns a standalone [Dio] client. It must not use
/// the authenticated GitHub API client because the WordPress endpoint is on a
/// different origin and does not need an authorization header.
final class GitHubChangelogService {
  GitHubChangelogService() : _dio = _createDio();

  /// Allows an isolated Dio client to be supplied by unit tests.
  GitHubChangelogService.withDio(final Dio dio) : _dio = dio;

  static const String changelogPageUrl = 'https://github.blog/changelog/';
  static const String _baseUrl = 'https://github.blog';
  static const String _endpoint = '/wp-json/wp/v2/changelogs';
  static const int _itemCount = 4;

  final Dio _dio;

  static Dio _createDio() => Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const <String, String>{'Accept': 'application/json'},
    ),
  );

  Future<List<GitHubChangelogItem>> fetchLatest() async {
    final Response<Object?> response = await _dio.get<Object?>(
      _endpoint,
      queryParameters: const <String, Object>{
        'per_page': _itemCount,
        '_fields': 'date_gmt,link,title',
      },
    );
    final Object? data = response.data;
    if (data is! List<dynamic>) {
      throw const FormatException(
        'GitHub Changelog response must be a JSON array.',
      );
    }
    return List<GitHubChangelogItem>.unmodifiable(data.map(_parseItem));
  }

  static GitHubChangelogItem _parseItem(final Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException(
        'GitHub Changelog item must be a JSON object.',
      );
    }

    final Object? titleValue = value['title'];
    final Object? renderedTitle = titleValue is Map<String, dynamic>
        ? titleValue['rendered']
        : null;
    if (renderedTitle is! String) {
      throw const FormatException('GitHub Changelog item has no title.');
    }
    final String title = (parseFragment(renderedTitle).text ?? '').trim();
    if (title.isEmpty) {
      throw const FormatException('GitHub Changelog item has an empty title.');
    }

    final Object? linkValue = value['link'];
    final Uri? link = linkValue is String ? Uri.tryParse(linkValue) : null;
    if (link == null || link.scheme != 'https' || link.host != 'github.blog') {
      throw const FormatException('GitHub Changelog item has an invalid link.');
    }

    final Object? dateValue = value['date_gmt'];
    if (dateValue is! String || dateValue.trim().isEmpty) {
      throw const FormatException(
        'GitHub Changelog item has no publication date.',
      );
    }
    final String rawDate = dateValue.trim();
    final bool hasTimeZone = RegExp(
      r'(?:[zZ]|[+-]\d{2}:\d{2})$',
    ).hasMatch(rawDate);
    final DateTime? publishedAt = DateTime.tryParse(
      hasTimeZone ? rawDate : '${rawDate}Z',
    );
    if (publishedAt == null) {
      throw const FormatException(
        'GitHub Changelog item has an invalid publication date.',
      );
    }

    return GitHubChangelogItem(
      title: title,
      link: link,
      publishedAt: publishedAt.toUtc(),
    );
  }

  void close() => _dio.close();
}
