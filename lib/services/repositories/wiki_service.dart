import 'package:dio/dio.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/wiki_page.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:diohub/services/markdown/markdown_service.dart';


class WikiService extends EntityService<RepoRef> {
  WikiService(super.apiClient, super.ref);

  String get _wikiContentsPath => '${ref.apiPath}.wiki/contents';

  Future<List<WikiPageListItem>> fetchWikiPageList() async {
    try {
      final Response<dynamic> response = await rest.get<dynamic>(
        '$_wikiContentsPath/',
        requestHeaders: <String, String>{
          'Accept': 'application/vnd.github+json',
        },
      );
      final List<Object?> list = extractListFromResponse<Object?>(response);
      return list
          .whereType<Map<String, dynamic>>()
          .where((final Map<String, dynamic> e) =>
              (e['name'] as String? ?? '').endsWith('.md'))
          .map((final Map<String, dynamic> e) => WikiPageListItem.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return <WikiPageListItem>[];
      }
      rethrow;
    }
  }

  Future<String> fetchWikiPageContent(
    final String slug,
  ) async {
    final String pathSlug = slug.endsWith('.md') ? slug : '$slug.md';
    final Response<String> response = await rest.get<String>(
      '$_wikiContentsPath/$pathSlug',
      requestHeaders: <String, String>{
        'Accept': 'application/vnd.github.raw',
      },
    );
    return response.data ?? '';
  }

  Future<String> renderWikiMarkdown(
    final String markdown,
  ) async {
    return MarkdownService(apiClient).renderMarkdown(
      markdown,
      context: '${ref.owner}/${ref.name}.wiki',
    );
  }
}
