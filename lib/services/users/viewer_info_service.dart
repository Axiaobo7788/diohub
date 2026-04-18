import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:lens_annotations/lens_annotations.dart';
import 'package:diohub_graphql/queries/users/viewer_info.graphql.dart';

@LensService(scope: Scope.global, group: 'viewer')
class ViewerInfoService extends BaseService {
  const ViewerInfoService(super.apiClient);

  @Lens(
    'get_viewer_info',
    'Get authenticated viewer (current user) information.',
    category: ToolCategory.user,
  )
  Future<ViewerInfo> getViewerInfo() async {
    final GQLResponse response = await gql.query(
      documentNodeQueryviewerInfo,
      <String, dynamic>{},
    );
    return ViewerInfoData.fromJson(response.data!).viewer;
  }
}
