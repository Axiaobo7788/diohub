import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/workflow.dart';
import 'package:diohub_models/models/repositories/pending_deployment.dart';
import 'package:diohub_models/models/repositories/workflow_artifact.dart';
import 'package:diohub_models/models/repositories/workflow_job.dart';
import 'package:diohub_models/models/repositories/workflow_run.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:lens_annotations/lens_annotations.dart';

/// CI/CD workflows and runs for a repository.
@LensService(group: 'workflows')
class RepoWorkflowsService extends EntityService<RepoRef> {
  RepoWorkflowsService(super.apiClient, super.ref);

  /// List workflow definitions. REST GET /repos/{owner}/{repo}/actions/workflows.
  @Lens(
    'list_workflows',
    'List all GitHub Actions workflow definitions for the repository',
    category: ToolCategory.workflow,
  )
  Future<WorkflowsResponse> listWorkflows({
    @Desc('Page number') final int page = 1,
    @Desc('Results per page') final int perPage = 30,
  }) async {
    final Response<Map<String, dynamic>> res =
        await rest.get<Map<String, dynamic>>(
      '${ref.apiPath}/actions/workflows',
      queryParameters: <String, dynamic>{
        'page': page,
        'per_page': perPage,
      },
    );
    return WorkflowsResponse.fromJson(res.data ?? <String, dynamic>{});
  }

  /// List workflow runs. REST GET .../actions/runs or .../actions/workflows/{id}/runs.
  @Lens(
    'list_workflow_runs',
    'List all workflow runs for a repository or specific workflow',
    category: ToolCategory.workflow,
  )
  Future<WorkflowRunsResponse> listWorkflowRuns({
    @Desc('Optional workflow ID to filter by') final int? workflowId,
    @Desc('Results per page') final int perPage = 20,
    @Desc('Page number') final int page = 1,
    @Desc('Filter by branch name') final String? branch,
    @Skip() final bool refresh = false,
  }) async {
    final String path = workflowId != null
        ? '${ref.apiPath}/actions/workflows/$workflowId/runs'
        : '${ref.apiPath}/actions/runs';
    final Response<Map<String, dynamic>> res =
        await rest.get<Map<String, dynamic>>(
      path,
      queryParameters: <String, dynamic>{
        'per_page': perPage,
        'page': page,
        if (branch != null) 'branch': branch,
      },
      refreshCache: refresh,
    );
    return WorkflowRunsResponse.fromJson(res.data ?? <String, dynamic>{});
  }

  /// Fetch latest runs for multiple workflows for overview dashboard.
  /// Makes parallel calls to list runs for each workflow.
  Future<Map<int, List<WorkflowRunItem>>> listWorkflowRunsMulti({
    required final List<Workflow> workflows,
    final int runsPerWorkflow = 10,
  }) async {
    final Map<int, List<WorkflowRunItem>> result = {};
    
    await Future.wait(
      workflows.map((workflow) async {
        try {
          final response = await listWorkflowRuns(
            workflowId: workflow.id,
            perPage: runsPerWorkflow,
          );
          result[workflow.id] = response.workflowRuns;
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Failed to fetch workflow runs for workflow ${workflow.id}',
            error: e,
            stackTrace: stackTrace,
            tag: 'RepoWorkflowsService',
          );
          result[workflow.id] = [];
        }
      }),
    );
    
    return result;
  }

  /// Get workflow usage/timing data. REST GET .../actions/workflows/{id}/timing.
  /// Returns billable minutes and timing stats for a workflow.
  Future<Map<String, dynamic>?> getWorkflowUsage({
    required final int workflowId,
  }) async {
    try {
      final Response<Map<String, dynamic>> res =
          await rest.get<Map<String, dynamic>>(
        '${ref.apiPath}/actions/workflows/$workflowId/timing',
      );
      return res.data;
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to get workflow usage for workflow $workflowId',
        error: e,
        stackTrace: stackTrace,
        tag: 'RepoWorkflowsService',
      );
      return null;
    }
  }

  /// Fetch workflow YAML content from repository.
  /// Uses the repo contents API to get the workflow file.
  Future<String?> getWorkflowYaml({
    required final String workflowPath,
    final String? ref,
  }) async {
    try {
      final Response<Map<String, dynamic>> res =
          await rest.get<Map<String, dynamic>>(
        '${this.ref.apiPath}/contents/$workflowPath',
        queryParameters: <String, dynamic>{
          if (ref != null) 'ref': ref,
        },
      );
      final data = res.data;
      if (data == null) return null;
      
      final String? content = data['content'] as String?;
      if (content == null) return null;
      
      // GitHub returns base64 encoded content with newlines
      final String base64Clean = content.replaceAll(RegExp(r'\s'), '');
      final List<int> bytes = base64Decode(base64Clean);
      return utf8.decode(bytes);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to get workflow YAML for path $workflowPath',
        error: e,
        stackTrace: stackTrace,
        tag: 'RepoWorkflowsService',
      );
      return null;
    }
  }

  /// Single workflow run. REST GET .../actions/runs/{run_id}.
  @Lens(
    'get_workflow_run',
    'Get details of a specific workflow run',
    category: ToolCategory.workflow,
  )
  Future<WorkflowRunItem> getWorkflowRun({
    @Desc('Workflow run ID') required final int runId,
  }) async {
    final Response<Map<String, dynamic>> res =
        await rest.get<Map<String, dynamic>>(
      '${ref.apiPath}/actions/runs/$runId',
    );
    return WorkflowRunItem.fromJson(res.data ?? <String, dynamic>{});
  }

  /// List jobs for a workflow run. REST GET .../actions/runs/{runId}/jobs.
  @Lens(
    'list_workflow_run_jobs',
    'List all jobs for a specific workflow run',
    category: ToolCategory.workflow,
  )
  Future<WorkflowJobsResponse> listJobsForRun({
    @Desc('Workflow run ID') required final int runId,
    @Desc('Filter jobs by status') final String? filter,
    @Desc('Page number') final int page = 1,
    @Desc('Results per page') final int perPage = 30,
  }) async {
    final Response<Map<String, dynamic>> res =
        await rest.get<Map<String, dynamic>>(
      '${ref.apiPath}/actions/runs/$runId/jobs',
      queryParameters: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (filter != null) 'filter': filter,
      },
    );
    return WorkflowJobsResponse.fromJson(res.data ?? <String, dynamic>{});
  }

  /// Rerun a workflow run. REST POST .../actions/runs/{id}/rerun.
  Future<void> rerunWorkflowRun({required final int runId}) async {
    await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/actions/runs/$runId/rerun',
    );
  }

  /// Rerun only failed jobs. REST POST .../actions/runs/{id}/rerun-failed-jobs.
  Future<void> rerunFailedJobs({required final int runId}) async {
    await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/actions/runs/$runId/rerun-failed-jobs',
    );
  }

  /// Rerun a single job. REST POST .../actions/jobs/{job_id}/rerun.
  Future<void> rerunJob({required final int jobId}) async {
    await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/actions/jobs/$jobId/rerun',
    );
  }

  /// Cancel a workflow run. REST POST .../actions/runs/{id}/cancel.
  Future<void> cancelWorkflowRun({required final int runId}) async {
    await rest.post<Map<String, dynamic>>(
      '${ref.apiPath}/actions/runs/$runId/cancel',
    );
  }

  /// Triggers a workflow_dispatch event for a workflow.
  /// POST .../actions/workflows/{workflowId}/dispatches
  /// Body: { "ref": "main", "inputs": { "key": "value" } }
  /// Returns 204 on success.
  Future<void> dispatchWorkflow({
    required final int workflowId,
    required final String branchRef,
    final Map<String, String>? inputs,
  }) async {
    await rest.post<void>(
      '${ref.apiPath}/actions/workflows/$workflowId/dispatches',
      data: <String, dynamic>{
        'ref': branchRef,
        if (inputs != null && inputs.isNotEmpty) 'inputs': inputs,
      },
    );
  }

  /// Lists artifacts for a workflow run.
  /// GET .../actions/runs/{runId}/artifacts
  Future<WorkflowArtifactsResponse> listArtifacts({
    required final int runId,
    final int perPage = 30,
    final int page = 1,
  }) async {
    final Response<Map<String, dynamic>> res =
        await rest.get<Map<String, dynamic>>(
      '${ref.apiPath}/actions/runs/$runId/artifacts',
      queryParameters: <String, dynamic>{
        'per_page': perPage,
        'page': page,
      },
    );
    return WorkflowArtifactsResponse.fromJson(
      res.data ?? <String, dynamic>{},
    );
  }

  /// Resolves the download URL for an artifact (302 redirect).
  /// GET .../actions/artifacts/{artifactId}/zip
  /// Returns the resolved redirect URL.
  Future<String> getArtifactDownloadUrl({
    required final int artifactId,
  }) async {
    final Response<void> res = await rest.get<void>(
      '${ref.apiPath}/actions/artifacts/$artifactId/zip',
      options: Options(
        followRedirects: false,
        validateStatus: (final int? status) => status == 302,
      ),
    );
    final String? location = res.headers.value('location');
    if (location == null || location.isEmpty) {
      throw StateError(
        'Artifact download: no Location header in 302 response',
      );
    }
    return location;
  }

  /// Gets pending deployments for a workflow run that requires approval.
  /// GET .../actions/runs/{runId}/pending_deployments
  Future<List<PendingDeployment>> getPendingDeployments({
    required final int runId,
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '${ref.apiPath}/actions/runs/$runId/pending_deployments',
    );
    final List<Object?> list = extractListFromResponse<Object?>(res);
    return list
        .map((e) => PendingDeployment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Approves or rejects pending deployments for a workflow run.
  /// POST .../actions/runs/{runId}/pending_deployments
  Future<void> reviewPendingDeployments({
    required final int runId,
    required final List<int> environmentIds,
    required final String state,
    final String? comment,
  }) async {
    await rest.post<List<dynamic>>(
      '${ref.apiPath}/actions/runs/$runId/pending_deployments',
      data: <String, dynamic>{
        'environment_ids': environmentIds,
        'state': state,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }

  /// Get redirect URL for workflow run logs zip. REST GET .../actions/runs/{id}/logs
  /// returns 302 with Location header; this method returns that URL for use by download.
  Future<String> getWorkflowRunLogsUrl({required final int runId}) async {
    final Response<void> res = await rest.get<void>(
      '${ref.apiPath}/actions/runs/$runId/logs',
      options: Options(
        followRedirects: false,
        validateStatus: (final int? status) => status == 302,
      ),
    );
    final String? location = res.headers.value('location');
    if (location == null || location.isEmpty) {
      throw StateError('Workflow run logs: no Location header in 302 response');
    }
    return location;
  }

  /// Fetches plain text logs for a workflow job. REST GET .../actions/jobs/{id}/logs
  /// (GitHub redirects to the log URL). Returns raw log text including ANSI codes.
  Future<String?> getJobLogs({required final int jobId}) async {
    final Response<String> res = await rest.get<String>(
      '${ref.apiPath}/actions/jobs/$jobId/logs',
      options: Options(
        responseType: ResponseType.plain,
        followRedirects: true,
        maxRedirects: 5,
      ),
    );
    return res.data;
  }
}
