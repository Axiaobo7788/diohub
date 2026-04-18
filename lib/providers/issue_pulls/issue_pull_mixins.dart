library;

import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/common/riverpod/mutation_error.dart';
import 'package:diohub/common/riverpod/optimistic_notifier.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart'
    show
        IssueCommentUpdate,
        IssuePullMutationResult,
        subjectMutationResultFromPayload,
        TitleBodyEditResult;
import 'package:diohub_models/models/issues/subject_mutation_payload.dart';
import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub/providers/pagination/patch_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/services/issues/issue_service.dart' show IssueService;
import 'package:diohub/services/pulls/pull_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/async_notifier.dart';

import 'package:diohub/providers/issue_pulls/models/issue_pull_mutations.dart';

Future<IssuePullMutationResult?> executeIssuePullOp(
  final Ref ref,
  final EntityRef entityRef,
  final IssuePullMutation op,
  final String nodeId, {
  final PullRequestRef? pullRef,
}) async {
  final IssueRef issueRef = entityRef is IssueRef
      ? entityRef as IssueRef
      : IssueRef(
          repo: (entityRef as PullRequestRef).repo,
          number: (entityRef as PullRequestRef).number,
        );
  final IssueService issuesService = IssueService(
    ref.read(apiClientProvider),
    issueRef,
  );
  final PullService? pullsService = pullRef != null
      ? pullRef.copyWith(nodeId: nodeId).services(ref.read(apiClientProvider))
      : null;
  switch (op) {
    case AddLabels(:final List<String> labelIds):
      return await issuesService.labelable.addLabels(labelIds);
    case RemoveLabels(:final List<String> labelIds):
      return await issuesService.labelable.removeLabels(labelIds);
    case AddAssignees(:final List<String> assigneeIds):
      return await issuesService.assignable.addAssignees(assigneeIds);
    case RemoveAssignees(:final List<String> assigneeIds):
      return await issuesService.assignable.removeAssignees(assigneeIds);
    case CloseIssue(:final IssueClosedStateReason? reason):
      final SubjectMutationPayload? payload = await issuesService.closeIssue(
        reason: reason,
      );
      return payload != null ? subjectMutationResultFromPayload(payload) : null;
    case ReopenIssue():
      final SubjectMutationPayload? payload = await issuesService.reopenIssue();
      return payload != null ? subjectMutationResultFromPayload(payload) : null;
    case ClosePullRequest():
      final SubjectMutationPayload? payload = await pullsService!
          .closePullRequest();
      return payload != null ? subjectMutationResultFromPayload(payload) : null;
    case ReopenPullRequest():
      final SubjectMutationPayload? payload = await pullsService!
          .reopenPullRequest();
      return payload != null ? subjectMutationResultFromPayload(payload) : null;
    case AddComment(:final String body):
      return await issuesService.commentable.addComment(body: body);
    case SetIssueMilestone(:final String? milestoneId):
      return await issuesService.setMilestone(milestoneId: milestoneId);
    case SetPullRequestMilestone(:final String? milestoneId):
      return await pullsService!.setMilestone(milestoneId: milestoneId);
    case UpdateIssue(
      :final title,
      :final body,
      :final state,
      :final assigneeIds,
      :final labelIds,
      :final milestoneId,
    ):
      final bool titleBodyOnly =
          state == null &&
          assigneeIds == null &&
          labelIds == null &&
          milestoneId == null;
      if (titleBodyOnly) {
        final TitleBodyEditResult? result = await issuesService
            .editIssueContent(title: title, body: body);
        return result;
      }
      final SubjectMutationPayload? payload = await issuesService.updateIssue(
        title: title,
        body: body,
        state: state,
        assigneeIds: assigneeIds,
        labelIds: labelIds,
        milestoneId: milestoneId,
      );
      return payload != null ? subjectMutationResultFromPayload(payload) : null;
    case UpdatePullRequest(
      :final title,
      :final body,
      :final assigneeIds,
      :final labelIds,
      :final milestoneId,
      :final baseRefName,
      :final state,
    ):
      final bool titleBodyOnly =
          assigneeIds == null &&
          labelIds == null &&
          milestoneId == null &&
          baseRefName == null &&
          state == null;
      if (titleBodyOnly) {
        final TitleBodyEditResult? result = await pullsService!
            .editPullRequestContent(title: title, body: body);
        return result;
      }
      final SubjectMutationPayload? payload = await pullsService!
          .updatePullRequest(
            title: title,
            body: body,
            assigneeIds: assigneeIds,
            labelIds: labelIds,
            milestoneId: milestoneId,
            baseRefName: baseRefName,
            state: state,
          );
      return payload != null ? subjectMutationResultFromPayload(payload) : null;
  }
}

mixin IssuePullMutationMixin<T> on AsyncNotifier<T> {
  @override
  Ref get ref;

  /// Entity ref (IssueRef or PullRequestRef) for mutation services.
  EntityRef get entityRef;
  String get nodeId;
  Future<void> refetch();

  /// For PR notifiers, the [PullRequestRef] so mutations use ref.services(ref.read(apiClientProvider)). Null for issue notifiers.
  PullRequestRef? get pullRef => null;

  /// Patches notifier state from mutation result. Returns true if patched (skip refetch).
  bool tryPatchFromMutationResult(final IssuePullMutationResult? result) =>
      false;

  Future<void> mutate(final IssuePullMutation op) async {
    try {
      final IssuePullMutationResult? result = await executeIssuePullOp(
        ref,
        entityRef,
        op,
        nodeId,
        pullRef: pullRef,
      );
      if (tryPatchFromMutationResult(result)) {
        showMutationSuccess(op);
        return;
      }
      await refetch();
      showMutationSuccess(op);
    } catch (e, st) {
      showMutationError(ref, op.errorMessage, error: e, stackTrace: st);
    }
  }

  void showMutationSuccess(final IssuePullMutation op) {
    final String? msg = op.successMessage;
    if (msg != null) {
      ref.read(notificationServiceProvider).success(msg);
    }
  }
}

mixin FreeCommentMixin<T> on AsyncNotifier<T>, IssuePullMutationMixin<T> {
  String get timelinePatchKey;

  Future<void> addComment(final String body) => mutate(AddComment(body));

  Future<void> editComment(final String commentId, final String body) async {
    final service = entityRef.commonServices(ref.read(apiClientProvider));
    final IssueCommentUpdate? update = await service.updateComment(
      commentId,
      body,
    );
    if (update != null) {
      ref
          .read(timelinePatchesProvider(timelinePatchKey).notifier)
          .apply(
            PatchCommentEdit(
              commentId,
              body: update.body,
              bodyHTML: update.bodyHTML,
              lastEditedAt: update.lastEditedAt,
            ),
          );
    }
  }

  Future<void> deleteComment(final String commentId) async {
    final service = entityRef.commonServices(ref.read(apiClientProvider));
    await service.deleteComment(commentId);
    ref
        .read(timelinePatchesProvider(timelinePatchKey).notifier)
        .apply(PatchDeleted(commentId));
  }
}

mixin SubscribableEntityMixin<T>
    on
        AsyncNotifier<T>,
        OptimisticFamilyAsyncNotifier<T>,
        IssuePullMutationMixin<T> {
  Ref get ref;
  String get nodeId;

  T applySubscription(T current, SubscriptionState subscription);

  SubscriptionState? getCurrentSubscription();

  Future<void> toggleSubscription() async {
    final SubscriptionState current =
        getCurrentSubscription() ?? SubscriptionState.UNSUBSCRIBED;
    final SubscriptionState newState = current == SubscriptionState.SUBSCRIBED
        ? SubscriptionState.UNSUBSCRIBED
        : SubscriptionState.SUBSCRIBED;
    await setSubscription(newState);
  }

  Future<void> setSubscription(final SubscriptionState newState) async {
    final service = entityRef.commonServices(ref.read(apiClientProvider));
    await optimistic<SubscriptionState?>(
      transform: (final T current) => applySubscription(current, newState),
      mutation: () => service.subscribable.updateSubscription(newState),
      errorMessage: (_, __) => "Couldn't update subscription",
      applyResponse: (final T prev, final SubscriptionState? sub) =>
          sub != null ? applySubscription(prev, sub) : prev,
    );
  }
}
