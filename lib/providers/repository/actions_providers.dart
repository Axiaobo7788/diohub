import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/code/github_log_annotations.dart';
import 'package:diohub_models/models/download/download_item.dart';
import 'package:diohub_models/models/download/download_metadata.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/workflow.dart';
import 'package:diohub_models/models/repositories/workflow_run.dart';
import 'package:diohub/providers/settings/terminal_settings_provider.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// Refresh trigger for the Actions paginated list.
/// Increment to force the PaginationController to reset and re-fetch.
final actionsRefreshTriggerProvider = Provider.autoDispose
    .family<ValueNotifier<int>, RepoRef>((ref, repoRef) {
      final notifier = ValueNotifier<int>(0);
      ref.onDispose(notifier.dispose);
      return notifier;
    });

class _SelectedWorkflowNotifier extends Notifier<Workflow?> {
  _SelectedWorkflowNotifier(this._arg);
  // ignore: unused_field
  final RepoRef _arg;

  @override
  Workflow? build() => null;

  void setWorkflow(Workflow? workflow) {
    state = workflow;
  }
}

/// Selected workflow for filtering runs; null = all workflows.
final selectedWorkflowProvider =
    NotifierProvider.family<_SelectedWorkflowNotifier, Workflow?, RepoRef>(
      _SelectedWorkflowNotifier.new,
    );

/// Cancel a workflow run. After mutation, increments [actionsRefreshTriggerProvider] to reload the list.
Future<void> cancelWorkflowRun(
  WidgetRef ref,
  RepoRef repoRef,
  int runId,
) async {
  await repoRef
      .workflows(ref.read(apiClientProvider))
      .cancelWorkflowRun(runId: runId);
  ref.read(actionsRefreshTriggerProvider(repoRef)).value++;
}

/// Re-run a workflow run. After mutation, increments [actionsRefreshTriggerProvider] to reload the list.
Future<void> rerunWorkflowRun(WidgetRef ref, RepoRef repoRef, int runId) async {
  await repoRef
      .workflows(ref.read(apiClientProvider))
      .rerunWorkflowRun(runId: runId);
  ref.read(actionsRefreshTriggerProvider(repoRef)).value++;
}

/// Re-run failed jobs of a workflow run. After mutation, increments [actionsRefreshTriggerProvider] to reload the list.
Future<void> rerunFailedJobs(WidgetRef ref, RepoRef repoRef, int runId) async {
  await repoRef
      .workflows(ref.read(apiClientProvider))
      .rerunFailedJobs(runId: runId);
  ref.read(actionsRefreshTriggerProvider(repoRef)).value++;
}

/// Re-run a single job. After mutation, increments [actionsRefreshTriggerProvider] to reload the list.
Future<void> rerunJob(WidgetRef ref, RepoRef repoRef, int jobId) async {
  await repoRef.workflows(ref.read(apiClientProvider)).rerunJob(jobId: jobId);
  ref.read(actionsRefreshTriggerProvider(repoRef)).value++;
}

/// Dispatches a workflow and refreshes the runs list.
Future<void> dispatchWorkflow(
  WidgetRef ref,
  RepoRef repoRef, {
  required int workflowId,
  required String branchRef,
  Map<String, String>? inputs,
}) async {
  await repoRef
      .workflows(ref.read(apiClientProvider))
      .dispatchWorkflow(
        workflowId: workflowId,
        branchRef: branchRef,
        inputs: inputs,
      );
  await Future<void>.delayed(const Duration(seconds: 2));
  ref.read(actionsRefreshTriggerProvider(repoRef)).value++;
}

/// Resolve logs URL and enqueue download of workflow run logs zip.
Future<void> downloadLogs(
  WidgetRef ref,
  RepoRef repoRef,
  int runId,
  String runName,
  BuildContext context,
) async {
  final String url = await repoRef
      .workflows(ref.read(apiClientProvider))
      .getWorkflowRunLogsUrl(runId: runId);
  final DownloadItem item = DownloadItem(
    id: 'workflow-logs-$runId',
    displayName: '$runName logs',
    fileName: 'workflow-run-$runId-logs.zip',
    downloadUrl: url,
    totalBytes: null,
    type: DownloadType.singleFile,
    contentType: 'application/zip',
    createdAt: DateTime.now(),
    metadata: DownloadMetadata.singleFile(
      repoRef: repoRef,
      branch: 'actions',
      fullPath: 'runs/$runId/logs',
    ),
  );
  await ref.read(premiumActionsProvider).enqueueDownload(context, ref, item);
}

/// Single workflow run (for status and "Notify me" button).
final workflowRunDetailProvider =
    FutureProvider.family<WorkflowRunItem, ({RepoRef repo, int runId})>((
      ref,
      args,
    ) async {
      return args.repo
          .workflows(ref.read(apiClientProvider))
          .getWorkflowRun(runId: args.runId);
    });

/// Job logs (plain text with ANSI). Processed for GitHub annotations.
final jobLogsProvider = FutureProvider.autoDispose
    .family<String?, ({String owner, String repoName, int jobId})>((
      ref,
      params,
    ) async {
      final repoRef = RepoRef(owner: params.owner, name: params.repoName);
      final raw = await repoRef
          .workflows(ref.read(apiClientProvider))
          .getJobLogs(jobId: params.jobId);
      if (raw == null) return null;
      return processGitHubAnnotations(raw);
    });

/// Run status stream for live log detection. Polls until status is 'completed'.
final runStatusProvider = StreamProvider.autoDispose
    .family<String, ({String owner, String repoName, int runId})>((
      ref,
      params,
    ) async* {
      final repoRef = RepoRef(owner: params.owner, name: params.repoName);
      while (true) {
        final run = await repoRef
            .workflows(ref.read(apiClientProvider))
            .getWorkflowRun(runId: params.runId);
        yield run.status ?? 'unknown';
        if (run.status == 'completed') break;
        await Future<void>.delayed(const Duration(seconds: 10));
      }
    });

/// Live job logs stream: polls at interval and yields content (first full, then only new lines).
/// Use when run is in_progress/queued to tail logs.
final liveJobLogsProvider = StreamProvider.autoDispose
    .family<String, ({String owner, String repoName, int jobId})>(
      (ref, params) => _liveJobLogsStream(ref, params),
    );

/// Returns the raw stream for passing to [TerminalScreen.liveStream] (live tailing).
Stream<String> _liveJobLogsStream(
  Ref ref,
  ({String owner, String repoName, int jobId}) params,
) async* {
  final repoRef = RepoRef(owner: params.owner, name: params.repoName);
  final interval = Duration(
    seconds: ref.read(terminalSettingsProvider).logPollingIntervalSeconds,
  );
  int lastLineCount = 0;
  while (true) {
    final raw = await repoRef
        .workflows(ref.read(apiClientProvider))
        .getJobLogs(jobId: params.jobId);
    if (raw != null && raw.isNotEmpty) {
      final processed = processGitHubAnnotations(raw);
      final lines = processed.split('\n');
      if (lines.length > lastLineCount) {
        final chunk = lastLineCount == 0
            ? processed
            : lines.sublist(lastLineCount).join('\n');
        if (chunk.isNotEmpty) yield chunk;
        lastLineCount = lines.length;
      }
    }
    await Future<void>.delayed(interval);
  }
}

/// Provider that exposes the live log stream for [TerminalScreen.liveStream].
final liveJobLogsStreamProvider = Provider.autoDispose
    .family<Stream<String>, ({String owner, String repoName, int jobId})>(
      (ref, params) => _liveJobLogsStream(ref, params),
    );

/// Workflow dependency graph provider - parses YAML to extract job dependencies.
/// Returns a map of job names to their dependencies (needs: field).
final workflowDependencyGraphProvider = FutureProvider.autoDispose
    .family<Map<String, List<String>>, ({RepoRef repo, String workflowPath})>((
      ref,
      params,
    ) async {
      final service = params.repo.workflows(ref.read(apiClientProvider));
      final yaml = await service.getWorkflowYaml(
        workflowPath: params.workflowPath,
      );

      if (yaml == null) return {};

      // Simple YAML parsing to extract job dependencies
      // Format: jobs: { jobName: { needs: [dep1, dep2] } }
      final Map<String, List<String>> dependencies = {};

      try {
        final lines = yaml.split('\n');
        String? currentJob;
        bool inJobsSection = false;
        bool inNeedsSection = false;

        for (final line in lines) {
          final trimmed = line.trim();

          if (trimmed.startsWith('jobs:')) {
            inJobsSection = true;
            continue;
          }

          if (inJobsSection && !line.startsWith(' ')) {
            inJobsSection = false;
          }

          if (inJobsSection) {
            // Job definition (e.g., "  build:")
            if (line.startsWith('  ') &&
                line.contains(':') &&
                !line.contains('needs')) {
              currentJob = trimmed.replaceAll(':', '').trim();
              dependencies[currentJob] = [];
              inNeedsSection = false;
            }

            // Needs field
            if (currentJob != null && trimmed.startsWith('needs:')) {
              inNeedsSection = true;
              // Single line needs: [dep1, dep2]
              if (trimmed.contains('[')) {
                final match = RegExp(r'\[(.*?)\]').firstMatch(trimmed);
                if (match != null) {
                  final deps = match
                      .group(1)!
                      .split(',')
                      .map((e) => e.trim())
                      .toList();
                  dependencies[currentJob] = deps;
                  inNeedsSection = false;
                }
              } else if (!trimmed.endsWith(':')) {
                // Single dependency: needs: dep1
                final dep = trimmed.replaceAll('needs:', '').trim();
                if (dep.isNotEmpty) {
                  dependencies[currentJob] = [dep];
                }
              }
            } else if (inNeedsSection && trimmed.startsWith('- ')) {
              // Multi-line needs list
              final dep = trimmed.replaceAll('- ', '').trim();
              dependencies[currentJob!]!.add(dep);
            }
          }
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Failed to parse workflow YAML dependencies',
          error: e,
          stackTrace: stackTrace,
          tag: 'ActionsProviders',
        );
      }

      return dependencies;
    });

/// Workflow overview data: all workflows with their latest runs.
/// Used for the workflow overview dashboard screen.
final workflowOverviewProvider = FutureProvider.autoDispose
    .family<Map<Workflow, List<WorkflowRunItem>>, RepoRef>((
      ref,
      repoRef,
    ) async {
      final service = repoRef.workflows(ref.read(apiClientProvider));

      // Fetch all workflows
      final workflowsResponse = await service.listWorkflows();
      final workflows = workflowsResponse.workflows;

      // Fetch latest runs for each workflow
      final runsMap = await service.listWorkflowRunsMulti(
        workflows: workflows,
        runsPerWorkflow: 10,
      );

      // Combine into map
      final Map<Workflow, List<WorkflowRunItem>> result = {};
      for (final workflow in workflows) {
        result[workflow] = runsMap[workflow.id] ?? [];
      }

      return result;
    });
