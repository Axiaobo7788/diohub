import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/services/base/base_service.dart';


class MarkdownService {
  MarkdownService(ApiClient client)
      : _restHandler = client.rest;

  final RESTHandler _restHandler;

  Future<String> renderMarkdown(
    final String data, {
    required final String? context,
  }) async {
    final Response<String> res = await _restHandler.post<String>(
      '/markdown',
      data: <String, String>{
        'text': data,
        'mode': 'gfm',
        if (context != null) 'context': context,
      },
    );
    return res.data!;
  }
}
