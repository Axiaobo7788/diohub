import 'package:diohub/workbench/domain/workbench_models.dart';

enum GitHubGatewayFailureKind {
  offline,
  permissionDenied,
  rateLimited,
  notFound,
  invalidData,
  unknown,
}

/// Stable error exposed to the Workbench application layer.
final class GitHubGatewayException implements Exception {
  const GitHubGatewayException({
    required this.kind,
    required this.message,
    this.retryAt,
    this.statusCode,
  });

  final GitHubGatewayFailureKind kind;
  final String message;
  final DateTime? retryAt;
  final int? statusCode;

  @override
  String toString() => 'GitHubGatewayException($kind): $message';
}

/// Read-only GitHub boundary consumed by the Workbench application layer.
///
/// The contract does not expose legacy service, GraphQL, REST, Riverpod, or
/// Flutter types.
abstract interface class GitHubGateway {
  Future<WorkbenchRepository> fetchRepository(
    final GitHubRepositoryRef repository, {
    final bool refresh = false,
  });

  Future<WorkbenchWorkflowRunsPage> listWorkflowRuns(
    final GitHubRepositoryRef repository, {
    final String? branch,
    final int page = 1,
    final int perPage = 20,
    final bool refresh = false,
  });

  Future<WorkbenchWorkflowRun> fetchWorkflowRun(
    final GitHubRepositoryRef repository, {
    required final int runId,
  });

  Future<WorkbenchWorkflowJobsPage> listWorkflowJobs(
    final GitHubRepositoryRef repository, {
    required final int runId,
    final String? filter,
    final int page = 1,
    final int perPage = 30,
  });

  /// Resolves pull requests and checks for a local HEAD.
  ///
  /// [branch] is optional because detached HEADs remain a valid Workbench
  /// state. When supplied, it is also used to find branch-associated pull
  /// requests that GitHub has not attached to the commit result.
  Future<WorkbenchHeadStatus> fetchHeadStatus(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    final String? branch,
    final String? headOwner,
    final bool refresh = false,
  });

  Future<List<WorkbenchCheckAnnotation>> listCheckAnnotations(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    final bool refresh = false,
  });
}
