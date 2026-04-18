import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/lock_unlock_mutations.graphql.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart';
import 'package:diohub/services/base/node_service.dart';

/// Service for the GraphQL `Lockable` interface (issues and PRs).
class LockableService extends NodeService {
  const LockableService(super.apiClient, super.nodeId);

  Future<LockStateResult?> lock({final Enum$LockReason? reason}) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationlockLockable,
      Variables$Mutation$lockLockable(
        lockableId: nodeId,
        lockReason: reason,
      ).toJson(),
    );
    final Mutation$lockLockable? data = Mutation$lockLockable.fromJson(res.data!);
    final Mutation$lockLockable$lockLockable$lockedRecord? record =
        data?.lockLockable?.lockedRecord;
    if (record == null) return null;
    return record.maybeWhen(
      issue: (final Mutation$lockLockable$lockLockable$lockedRecord$$Issue i) =>
          LockStateResult(
        locked: i.locked,
        activeLockReason: i.activeLockReason,
      ),
      pullRequest:
          (final Mutation$lockLockable$lockLockable$lockedRecord$$PullRequest
                  p) =>
              LockStateResult(
        locked: p.locked,
        activeLockReason: p.activeLockReason,
      ),
      orElse: () => null,
    );
  }

  Future<LockStateResult?> unlock() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationunlockLockable,
      Variables$Mutation$unlockLockable(lockableId: nodeId).toJson(),
    );
    final Mutation$unlockLockable? data = Mutation$unlockLockable.fromJson(res.data!);
    final Mutation$unlockLockable$unlockLockable$unlockedRecord? record =
        data?.unlockLockable?.unlockedRecord;
    if (record == null) return null;
    return record.maybeWhen(
      issue: (final Mutation$unlockLockable$unlockLockable$unlockedRecord$$Issue
              i) =>
          LockStateResult(
        locked: i.locked,
        activeLockReason: i.activeLockReason,
      ),
      pullRequest:
          (final Mutation$unlockLockable$unlockLockable$unlockedRecord$$PullRequest
                  p) =>
              LockStateResult(
        locked: p.locked,
        activeLockReason: p.activeLockReason,
      ),
      orElse: () => null,
    );
  }
}
