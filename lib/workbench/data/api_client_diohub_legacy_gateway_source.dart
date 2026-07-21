import 'package:dio/dio.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/workbench/data/diohub_legacy_github_gateway.dart';
import 'package:diohub/workbench/domain/workbench_models.dart';
import 'package:diohub_graphql/queries/repositories/check_annotations.graphql.dart';
import 'package:diohub_graphql/queries/repositories/commit_info.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/workflow_job.dart';
import 'package:diohub_models/models/repositories/workflow_run.dart';

typedef _AnnotationCommit = Query$CheckAnnotations$repository$object$$Commit;
typedef _AnnotationSuite =
    Query$CheckAnnotations$repository$object$$Commit$checkSuites$nodes;
typedef _AnnotationRun =
    Query$CheckAnnotations$repository$object$$Commit$checkSuites$nodes$checkRuns$nodes;
typedef _AnnotationNode =
    Query$CheckAnnotations$repository$object$$Commit$checkSuites$nodes$checkRuns$nodes$annotations$nodes;
typedef _CommitCheckNode =
    Query$commitInfo$repository$object$$Commit$statusCheckRollup$contexts$nodes;
typedef _CommitCheckRun =
    Query$commitInfo$repository$object$$Commit$statusCheckRollup$contexts$nodes$$CheckRun;
typedef _CommitStatusContext =
    Query$commitInfo$repository$object$$Commit$statusCheckRollup$contexts$nodes$$StatusContext;

/// Production source that delegates to DioHub's existing API client/services.
///
/// This is the only Workbench file in the first slice that imports the legacy
/// service layer. The gateway contract and model mapping remain pure Dart.
final class ApiClientDioHubLegacyGatewaySource
    implements DioHubLegacyGatewaySource {
  const ApiClientDioHubLegacyGatewaySource(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<DioHubLegacyRepositoryData> fetchRepository(
    final GitHubRepositoryRef repository, {
    required final bool refresh,
  }) async {
    final RepoInfo legacyRepository = await _repoRef(
      repository,
    ).services(_apiClient).fetchRepositoryGraphQL(refresh: refresh);

    return DioHubLegacyRepositoryData(
      nodeId: legacyRepository.id,
      htmlUrl: legacyRepository.url,
      description: legacyRepository.description,
      defaultBranch: legacyRepository.defaultBranchRef?.name,
      isPrivate: legacyRepository.isPrivate,
      isArchived: legacyRepository.isArchived,
    );
  }

  @override
  Future<DioHubLegacyHeadStatusData> fetchHeadStatus(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    required final String? branch,
    required final String? headOwner,
    required final bool refresh,
  }) async {
    final CommitInfo commit = await _repoRef(
      repository,
    ).services(_apiClient).getCommitInfo(oid: headSha, refresh: refresh);

    final List<DioHubLegacyPullRequestData> pullRequests =
        <DioHubLegacyPullRequestData>[
          ..._mapAssociatedPullRequests(commit),
          ...await _listPullRequestsByBranch(
            repository,
            branch: branch,
            headOwner: headOwner,
            refresh: refresh,
          ),
        ];

    return DioHubLegacyHeadStatusData(
      headSha: headSha,
      branch: branch,
      rollupState: commit.statusCheckRollup?.state.toJson(),
      pullRequests: pullRequests,
      checks: _mapChecks(commit),
    );
  }

  @override
  Future<WorkflowRunItem> fetchWorkflowRun(
    final GitHubRepositoryRef repository, {
    required final int runId,
  }) => _repoRef(repository).workflows(_apiClient).getWorkflowRun(runId: runId);

  @override
  Future<WorkflowJobsResponse> listWorkflowJobs(
    final GitHubRepositoryRef repository, {
    required final int runId,
    required final String? filter,
    required final int page,
    required final int perPage,
  }) => _repoRef(repository)
      .workflows(_apiClient)
      .listJobsForRun(
        runId: runId,
        filter: filter,
        page: page,
        perPage: perPage,
      );

  @override
  Future<List<DioHubLegacyAnnotationData>> listCheckAnnotations(
    final GitHubRepositoryRef repository, {
    required final String headSha,
    required final bool refresh,
  }) async {
    _repoRef(repository);
    final GQLResponse response = await _apiClient.gql.query(
      documentNodeQueryCheckAnnotations,
      Variables$Query$CheckAnnotations(
        owner: repository.owner,
        name: repository.name,
        sha: headSha,
      ).toJson(),
      refreshCache: refresh,
    );
    final Query$CheckAnnotations$repository$object? object =
        Query$CheckAnnotations.fromJson(response.data!).repository?.object;
    final _AnnotationCommit? commit = object?.maybeWhen(
      commit: (final _AnnotationCommit value) => value,
      orElse: () => null,
    );
    if (commit == null) {
      return const <DioHubLegacyAnnotationData>[];
    }

    final List<DioHubLegacyAnnotationData> result =
        <DioHubLegacyAnnotationData>[];
    final List<_AnnotationSuite?>? suites = commit.checkSuites?.nodes;
    if (suites == null) {
      return result;
    }
    for (final _AnnotationSuite? suite in suites) {
      final List<_AnnotationRun?>? runs = suite?.checkRuns?.nodes;
      if (runs == null) {
        continue;
      }
      for (final _AnnotationRun? run in runs) {
        if (run == null) {
          continue;
        }
        final List<_AnnotationNode?>? annotations = run.annotations?.nodes;
        if (annotations == null) {
          continue;
        }
        for (final _AnnotationNode? annotation in annotations) {
          if (annotation == null) {
            continue;
          }
          result.add(
            DioHubLegacyAnnotationData(
              checkName: run.name,
              checkConclusion: run.conclusion?.toJson(),
              path: annotation.path,
              level: annotation.annotationLevel?.toJson(),
              message: annotation.message,
              title: annotation.title,
              rawDetails: annotation.rawDetails,
              startLine: annotation.location.start.line,
              startColumn: annotation.location.start.column,
              endLine: annotation.location.end.line,
              endColumn: annotation.location.end.column,
            ),
          );
        }
      }
    }
    return result;
  }

  @override
  Future<WorkflowRunsResponse> listWorkflowRuns(
    final GitHubRepositoryRef repository, {
    required final String? branch,
    required final int page,
    required final int perPage,
    required final bool refresh,
  }) => _repoRef(repository)
      .workflows(_apiClient)
      .listWorkflowRuns(
        branch: branch,
        page: page,
        perPage: perPage,
        refresh: refresh,
      );

  List<DioHubLegacyPullRequestData> _mapAssociatedPullRequests(
    final CommitInfo commit,
  ) {
    final List<CommitAssociatedPREdge?>? edges =
        commit.associatedPullRequests?.edges;
    if (edges == null) {
      return const <DioHubLegacyPullRequestData>[];
    }
    return edges
        .map((final CommitAssociatedPREdge? edge) => edge?.node)
        .whereType<CommitAssociatedPRNode>()
        .map(
          (final CommitAssociatedPRNode pull) => DioHubLegacyPullRequestData(
            number: pull.number,
            title: pull.title,
            htmlUrl: pull.url,
            state: pull.state.toJson(),
            isDraft: pull.isDraft,
          ),
        )
        .toList(growable: false);
  }

  List<DioHubLegacyCheckData> _mapChecks(final CommitInfo commit) {
    final List<_CommitCheckNode?>? nodes =
        commit.statusCheckRollup?.contexts.nodes;
    if (nodes == null) {
      return const <DioHubLegacyCheckData>[];
    }
    return nodes
        .whereType<_CommitCheckNode>()
        .map(
          (final _CommitCheckNode node) =>
              node.maybeWhen<DioHubLegacyCheckData?>(
                checkRun: (final _CommitCheckRun check) =>
                    DioHubLegacyCheckData(
                      name: check.name,
                      kind: 'check_run',
                      status: check.status.toJson(),
                      conclusion: check.conclusion?.toJson(),
                      detailsUrl: check.detailsUrl,
                      appName: check.checkSuite.app?.name,
                      appLogoUrl: check.checkSuite.app?.logoUrl,
                      startedAt: check.startedAt,
                      completedAt: check.completedAt,
                    ),
                statusContext: (final _CommitStatusContext status) =>
                    DioHubLegacyCheckData(
                      name: status.context,
                      kind: 'status_context',
                      status: status.state.toJson(),
                      detailsUrl: status.targetUrl,
                    ),
                orElse: () => null,
              ),
        )
        .whereType<DioHubLegacyCheckData>()
        .toList(growable: false);
  }

  Future<List<DioHubLegacyPullRequestData>> _listPullRequestsByBranch(
    final GitHubRepositoryRef repository, {
    required final String? branch,
    required final String? headOwner,
    required final bool refresh,
  }) async {
    final String? normalizedBranch = branch?.trim();
    if (normalizedBranch == null || normalizedBranch.isEmpty) {
      return const <DioHubLegacyPullRequestData>[];
    }
    final Response<List<dynamic>> response = await _apiClient.rest
        .get<List<dynamic>>(
          '/repos/${repository.owner}/${repository.name}/pulls',
          refreshCache: refresh,
          queryParameters: <String, dynamic>{
            'state': 'all',
            'head': '${headOwner ?? repository.owner}:$normalizedBranch',
            'per_page': 10,
          },
        );
    final List<DioHubLegacyPullRequestData> result =
        <DioHubLegacyPullRequestData>[];
    for (final Object? item in response.data ?? const <dynamic>[]) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final Object? number = item['number'];
      final Object? title = item['title'];
      final Object? htmlUrl = item['html_url'];
      if (number is! int || title is! String || htmlUrl is! String) {
        continue;
      }
      final Uri? parsedUrl = Uri.tryParse(htmlUrl);
      if (parsedUrl == null) {
        continue;
      }
      result.add(
        DioHubLegacyPullRequestData(
          number: number,
          title: title,
          htmlUrl: parsedUrl,
          state: item['merged_at'] == null
              ? item['state']?.toString() ?? 'unknown'
              : 'merged',
          isDraft: item['draft'] == true,
        ),
      );
    }
    return result;
  }

  RepoRef _repoRef(final GitHubRepositoryRef repository) {
    if (repository.host.toLowerCase() != 'github.com') {
      throw UnsupportedError(
        'The DioHub legacy gateway currently supports github.com only: '
        '${repository.host}',
      );
    }
    return RepoRef(owner: repository.owner, name: repository.name);
  }
}
