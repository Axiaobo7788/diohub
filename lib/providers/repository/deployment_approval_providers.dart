import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/pending_deployment.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

final pendingDeploymentsProvider =
    FutureProvider.autoDispose.family<List<PendingDeployment>, ({RepoRef repo, int runId})>(
  (ref, args) async {
    return args.repo.workflows(ref.read(apiClientProvider)).getPendingDeployments(runId: args.runId);
  },
);

Future<void> approveDeployments(
  WidgetRef ref,
  RepoRef repoRef,
  int runId, {
  required List<int> environmentIds,
  String? comment,
}) async {
  await repoRef.workflows(ref.read(apiClientProvider)).reviewPendingDeployments(
    runId: runId,
    environmentIds: environmentIds,
    state: 'approved',
    comment: comment,
  );
  ref.invalidate(pendingDeploymentsProvider((repo: repoRef, runId: runId)));
}

Future<void> rejectDeployments(
  WidgetRef ref,
  RepoRef repoRef,
  int runId, {
  required List<int> environmentIds,
  String? comment,
}) async {
  await repoRef.workflows(ref.read(apiClientProvider)).reviewPendingDeployments(
    runId: runId,
    environmentIds: environmentIds,
    state: 'rejected',
    comment: comment,
  );
  ref.invalidate(pendingDeploymentsProvider((repo: repoRef, runId: runId)));
}
