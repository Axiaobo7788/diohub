library;

import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/common/riverpod/mutation_error.dart';
import 'package:diohub/common/riverpod/optimistic_notifier.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_graphql/fragments/pull_detail_fields.graphql.dart';
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
import 'package:diohub/services/pulls/pull_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/async_notifier.dart';

import 'package:diohub/providers/issue_pulls/models/issue_pull_mutations.dart';
import 'package:diohub/providers/issue_pulls/issue_pull_mixins.dart';

final pullDetailProvider = AsyncNotifierProvider.autoDispose
    .family<PullDetailNotifier, PullInfo, PullRequestRef>(
      PullDetailNotifier.new,
    );

class PullDetailNotifier extends AsyncNotifier<PullInfo>
    with
        OptimisticFamilyAsyncNotifier<PullInfo>,
        IssuePullMutationMixin<PullInfo>,
        FreeCommentMixin<PullInfo>,
        SubscribableEntityMixin<PullInfo> {
  PullDetailNotifier(this.arg);
  final PullRequestRef arg;

  @override
  EntityRef get entityRef => arg;

  @override
  PullRequestRef? get pullRef => arg;

  late final IssueService _services = IssueRef(
    repo: arg.repo,
    number: arg.number,
  ).services(ref.read(apiClientProvider));

  PullService get _pullsService => arg
      .copyWith(nodeId: state.requireValue.id)
      .services(ref.read(apiClientProvider));

  @override
  String get timelinePatchKey =>
      '${arg.repo.owner}/${arg.repo.name}/${arg.number}';

  @override
  PullInfo applySubscription(
    final PullInfo current,
    final SubscriptionState subscription,
  ) => current.copyWith(viewerSubscription: subscription);

  @override
  SubscriptionState? getCurrentSubscription() =>
      state.requireValue.viewerSubscription;

  @override
  Future<PullInfo> build() async {
    keepAliveFor(ref);
    return _services.getPullInfoOnly();
  }

  @override
  String get nodeId => state.requireValue.id;

  @override
  bool tryPatchFromMutationResult(final IssuePullMutationResult? result) {
    if (!state.hasValue) return false;
    final current = state.requireValue;
    switch (result) {
      case SubjectMutationResult(:final pullRequest?) when pullRequest != null:
        state = AsyncValue.data(pullRequest);
        return true;
      case LabelsMutationResult(pullLabels: final pullLabels?):
        if (pullLabels != null) {
          state = AsyncValue.data(
            current.copyWith(labels: PullLabels(nodes: pullLabels.toList())),
          );
          return true;
        }
        break;
      case AssigneesMutationResult(pullAssignees: final pullAssignees?):
        if (pullAssignees != null) {
          state = AsyncValue.data(
            current.copyWith(
              assignees: PullAssignees(nodes: pullAssignees.toList()),
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
            titleHTMLAsString: titleHTML,
            body: body,
            bodyHTML: bodyHTML,
            lastEditedAt: lastEditedAt,
          ),
        );
        return true;
      case SetMilestoneMutationResult(milestone: final m?):
        state = AsyncValue.data(
          current.copyWith(milestone: m as Fragment$pullDetailFields$milestone),
        );
        return true;
      default:
        break;
    }
    return false;
  }

  void applyMutationPayload(final SubjectMutationPayload? payload) {
    if (payload?.pullRequest != null) {
      state = AsyncValue.data(payload!.pullRequest!);
    }
  }

  Future<void> toggleDraft() async {
    await optimistic<bool>(
      transform: (final PullInfo pr) => pr.copyWith(isDraft: !pr.isDraft),
      mutation: () async {
        if (state.requireValue.isDraft) {
          return _pullsService.markReadyForReview();
        } else {
          return _pullsService.convertToDraft();
        }
      },
      applyResponse: (final PullInfo prev, final bool ok) =>
          ok ? prev.copyWith(isDraft: !prev.isDraft) : prev,
    );
  }

  Future<void> close() async {
    const ClosePullRequest op = ClosePullRequest();
    final IssuePullMutationResult? result =
        await optimistic<IssuePullMutationResult?>(
          transform: (final PullInfo pr) =>
              pr.copyWith(pullRequestState: PullRequestState.CLOSED),
          mutation: () => executeIssuePullOp(ref, entityRef, op, nodeId),
          onError: (final Object e, final StackTrace st) =>
              showMutationError(ref, op.errorMessage),
          applyResponse:
              (final PullInfo prev, final IssuePullMutationResult? res) =>
                  res is SubjectMutationResult && res.pullRequest != null
                  ? res.pullRequest!
                  : prev,
        );
    if (result != null) showMutationSuccess(op);
  }

  Future<void> reopen() async {
    const ReopenPullRequest op = ReopenPullRequest();
    final IssuePullMutationResult? result =
        await optimistic<IssuePullMutationResult?>(
          transform: (final PullInfo pr) =>
              pr.copyWith(pullRequestState: PullRequestState.OPEN),
          mutation: () => executeIssuePullOp(ref, entityRef, op, nodeId),
          onError: (final Object e, final StackTrace st) =>
              showMutationError(ref, op.errorMessage),
          applyResponse:
              (final PullInfo prev, final IssuePullMutationResult? res) =>
                  res is SubjectMutationResult && res.pullRequest != null
                  ? res.pullRequest!
                  : prev,
        );
    if (result != null) showMutationSuccess(op);
  }

  Future<void> requestReviews(final List<String> userIds) async {
    final bool ok = await _pullsService.requestReviews(
      userIds: userIds.isEmpty ? null : userIds,
    );
    if (ok) await refetch();
  }

  Future<void> updateTitleAndBody(final String title, final String body) async {
    await mutate(UpdatePullRequest(title: title, body: body));
  }

  Future<void> updatePullRequest({
    final String? title,
    final String? body,
    final PullRequestUpdateState? state,
    final List<String>? assigneeIds,
    final List<String>? labelIds,
    final String? milestoneId,
    final String? baseRefName,
  }) async {
    await mutate(
      UpdatePullRequest(
        title: title,
        body: body,
        state: state,
        assigneeIds: assigneeIds,
        labelIds: labelIds,
        milestoneId: milestoneId,
        baseRefName: baseRefName,
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
    await mutate(SetPullRequestMilestone(milestoneId));
  }

  Future<bool> merge(
    final PullRequestMergeMethod method, {
    final String? commitHeadline,
    final String? commitBody,
  }) async {
    try {
      final res = await _pullsService.mergePullRequest(
        mergeMethod: method,
        commitHeadline: commitHeadline,
        commitBody: commitBody,
      );
      if (res == null) return false;
      final current = state.requireValue;
      final mergedByPatched = res.mergedBy?.maybeWhen(
        user: (final MergePullMergedByActor u) =>
            Fragment$pullDetailFields$mergedBy(
              login: u.login,
              avatarUrl: u.avatarUrl,
              $__typename: 'User',
            ),
        orElse: () => null,
      );
      state = AsyncValue.data(
        current.copyWith(
          merged: res.merged,
          mergedAt: res.mergedAt,
          pullRequestState: res.state,
          mergedBy: mergedByPatched ?? current.mergedBy,
        ),
      );
      return true;
    } catch (e, _) {
      showMutationError(ref, "Couldn't merge pull request");
      return false;
    }
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

  Future<PaginatedResult<PullCommitEdge?>> getPullCommitsPage({
    required final int first,
    final String? after,
    final bool refresh = false,
  }) => arg
      .services(ref.read(apiClientProvider))
      .getPullCommitsGQL(first: first, after: after, refresh: refresh);

  @override
  Future<void> refetch() async {
    state = await AsyncValue.guard(
      () => _services.getPullInfoOnly(refresh: true),
    );
  }
}
