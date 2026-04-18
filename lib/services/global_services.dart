import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/markdown/markdown_service.dart';
import 'package:diohub/services/search/search_service.dart';
import 'package:diohub/services/users/viewer_info_service.dart';

/// Singleton container for global (entity-independent) services.
/// Accessible in generated tool code via top-level getter.
class GlobalServices {
  GlobalServices(this._apiClient);

  final ApiClient _apiClient;

  SearchService get search => SearchService(_apiClient);
  ViewerInfoService get viewerInfo => ViewerInfoService(_apiClient);
  MarkdownService get markdown => MarkdownService(_apiClient);
}
