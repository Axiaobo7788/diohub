library;

import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/common/riverpod/mutation_error.dart';
import 'package:diohub/common/riverpod/optimistic_notifier.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_graphql/fragments/issue_detail_fields.graphql.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart'
    show
        AssigneesMutationResult,
        CommentAddedResult,
        IssuePullMutationResult,
        LabelsMutationResult,
        SetMilestoneMutationResult,
        SubjectMutationResult,
        TitleBodyEditResult;
import 'package:diohub_models/models/issues/subject_mutation_payload.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/services/issues/issue_service.dart' show IssueService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/async_notifier.dart';

import 'package:diohub/providers/issue_pulls/models/issue_pull_mutations.dart';
import 'package:diohub/providers/issue_pulls/issue_pull_mixins.dart';

final issueDetailProvider = AsyncNotifierProvider.autoDispose
    .family<IssueDetailNotifier, IssueInfo, IssueRef>(IssueDetailNotifier.new);

class IssueDetailNotifier extends AsyncNotifier<IssueInfo>
    with
        OptimisticFamilyAsyncNotifier<IssueInfo>,
        IssuePullMutationMixin<IssueInfo>,
        FreeCommentMixin<IssueInfo>,
        SubscribableEntityMixin<IssueInfo> {
  IssueDetailNotifier(this.arg);
  final IssueRef arg;

  @override
  EntityRef get entityRef => arg;

  late final IssueService _services = arg.services(ref.read(apiClientProvider));

  @override
  String get timelinePatchKey =>
      '${arg.repo.owner}/${arg.repo.name}/${arg.number}';

  @override
  IssueInfo applySubscription(
    final IssueInfo current,
    final SubscriptionState subscription,
  ) => current.copyWith(viewerSubscription: subscription);

  @override
  SubscriptionState? getCurrentSubscription() =>
      state.requireValue.viewerSubscription;

  @override
  Future<IssueInfo> build() async {
    keepAliveFor(ref);
    return _services.getIssueInfoOnly();
  }

  @override
  String get nodeId => state.requireValue.id;

  @override
  bool tryPatchFromMutationResult(final IssuePullMutationResult? result) {
    if (!state.hasValue) return false;
    final current = state.requireValue;
    switch (result) {
      case SubjectMutationResult(:final issue?) when issue != null:
        state = AsyncValue.data(issue);
        return true;
      case LabelsMutationResult(issueLabels: final issueLabels?):
        if (issueLabels != null) {
          state = AsyncValue.data(
            current.copyWith(labels: IssueLabels(nodes: issueLabels.toList())),
          );
          return true;
        }
        break;
      case AssigneesMutationResult(issueAssignees: final issueAssignees?):
        if (issueAssignees != null) {
          state = AsyncValue.data(
            current.copyWith(
              assignees: IssueAssignees(nodes: issueAssignees.toList()),
            ),
          );
          return true;
        }
        break;
      case CommentAddedResult(:final commentsTotalCount):
        state = AsyncValue.data(
          current.copyWith(
            comments: current.comments.copyWith(totalCount: commentsTotalCount),
          ),
        );
        return true;
      case TitleBodyEditResult(
        :final title,
        :final titleHTML,
        :final body,
        :final bodyHTML,
        :final lastEditedAt,
      ):
        state = AsyncValue.data(
          current.copyWith(
            title: title,
            titleHTML: titleHTML,
            body: body,
            bodyHTML: bodyHTML,
            lastEditedAt: lastEditedAt,
          ),
        );
        return true;
      case SetMilestoneMutationResult(milestone: final m?):
        state = AsyncValue.data(
          current.copyWith(
            milestone: m as Fragment$issueDetailFields$milestone,
          ),
        );
        return true;
      default:
        break;
    }
    return false;
  }

  void applyMutationPayload(final SubjectMutationPayload? payload) {
    if (payload?.issue != null) {
      state = AsyncValue.data(payload!.issue!);
    }
  }

  Future<void> close([final IssueClosedStateReason? reason]) async {
    final CloseIssue op = CloseIssue(reason);
    final IssuePullMutationResult? result =
        await optimistic<IssuePullMutationResult?>(
          transform: (final IssueInfo issue) =>
              issue.copyWith(issueState: IssueState.CLOSED),
          mutation: () => executeIssuePullOp(ref, entityRef, op, nodeId),
          onError: (final Object e, final StackTrace st) =>
              showMutationError(ref, op.errorMessage),
          applyResponse:
              (final IssueInfo prev, final IssuePullMutationResult? res) =>
                  res is SubjectMutationResult && res.issue != null
                  ? res.issue!
                  : prev,
        );
    if (result != null) showMutationSuccess(op);
  }

  Future<void> reopen() async {
    const ReopenIssue op = ReopenIssue();
    final IssuePullMutationResult? result =
        await optimistic<IssuePullMutationResult?>(
          transform: (final IssueInfo issue) =>
              issue.copyWith(issueState: IssueState.OPEN),
          mutation: () => executeIssuePullOp(ref, entityRef, op, nodeId),
          onError: (final Object e, final StackTrace st) =>
              showMutationError(ref, op.errorMessage),
          applyResponse:
              (final IssueInfo prev, final IssuePullMutationResult? res) =>
                  res is SubjectMutationResult && res.issue != null
                  ? res.issue!
                  : prev,
        );
    if (result != null) showMutationSuccess(op);
  }

  Future<void> updateTitleAndBody(final String title, final String body) async {
    await mutate(UpdateIssue(title: title, body: body));
  }

  Future<void> updateIssue({
    final String? title,
    final String? body,
    final IssueState? state,
    final List<String>? assigneeIds,
    final List<String>? labelIds,
    final String? milestoneId,
  }) async {
    await mutate(
      UpdateIssue(
        title: title,
        body: body,
        state: state,
        assigneeIds: assigneeIds,
        labelIds: labelIds,
        milestoneId: milestoneId,
      ),
    );
  }

  Future<void> addLabels(final List<String> labelIds) async {
    await mutate(AddLabels(labelIds));
  }

  Future<void> removeLabels(final List<String> labelIds) async {
    await mutate(RemoveLabels(labelIds));
  }

  Future<void> addAssignees(final List<String> assigneeIds) async {
    await mutate(AddAssignees(assigneeIds));
  }

  Future<void> removeAssignees(final List<String> assigneeIds) async {
    await mutate(RemoveAssignees(assigneeIds));
  }

  Future<void> setMilestone(final String? milestoneId) async {
    await mutate(SetIssueMilestone(milestoneId));
  }

  Future<List<dynamic>> getTimelinePage({
    required final bool refresh,
    final String? after,
    final DateTime? since,
  }) async {
    final result = await _services.getTimeline(
      refresh: refresh,
      after: after,
      since: since,
    );
    return result.edges.toList();
  }

  @override
  Future<void> refetch() async {
    state = await AsyncValue.guard(
      () => _services.getIssueInfoOnly(refresh: true),
    );
  }
}
