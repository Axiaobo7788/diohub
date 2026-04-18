import 'package:diohub/services/base/base_service.dart';

/// Service scoped to a GitHub node by ID.
/// All capability services (reactable, labelable, etc.) extend this.
abstract class NodeService extends BaseService {
  const NodeService(super.apiClient, this.nodeId);

  /// The node ID this service operates on.
  final String nodeId;
}
