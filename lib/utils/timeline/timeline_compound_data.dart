import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/issues/issue_label.dart' show IssueLabel;
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/fragments/issue_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/label.graphql.dart';
import 'package:diohub_graphql/fragments/pull_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub_graphql/queries/issues_pulls/timeline.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub/utils/compound_grouping.dart';
import 'package:diohub/utils/timeline/timeline_grouping_strategy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'timeline_compound_data.freezed.dart';

// ---------------------------------------------------------------------------
// UI-agnostic context types (no G* types in UI layer)
// ---------------------------------------------------------------------------

/// Label info for timeline label chips. Use with [IssueLabel.fromNameColor].
class TimelineLabelInfo {
  const TimelineLabelInfo({required this.name, required this.color});
  final String name;
  final String color;
}

/// Extracts [TimelineLabelInfo] from label nodes (issue or PR; both implement [IssueLabelNode]).
List<TimelineLabelInfo> timelineLabelsFromNodes(
    final Iterable<dynamic>? nodes) {
  if (nodes == null) return <TimelineLabelInfo>[];
  return nodes
      .whereType<IssueLabelNode>()
      .map((final IssueLabelNode n) => TimelineLabelInfo(name: n.name, color: n.color))
      .toList();
}

/// Commit summary for timeline commit list.
class TimelineCommitSummary {
  const TimelineCommitSummary({
    required this.oid,
    required this.abbreviatedOid,
    required this.messageHeadline,
    required this.commitUrl,
    this.additions,
    this.deletions,
  });
  final String oid;
  final String abbreviatedOid;
  final String messageHeadline;
  final String commitUrl;
  final int? additions;
  final int? deletions;
}

/// Closer context for closed/merged events (commit or PR).
class TimelineCloserInfo {
  const TimelineCloserInfo.commit({
    required this.abbreviatedOid,
    required this.commitUrl,
  })  : pullRequest = null,
        mergeRefName = null,
        mergeCommitOid = null,
        mergeCommitUrl = null;

  const TimelineCloserInfo.pullRequest({
    required this.pullRequest,
    this.mergeRefName,
    this.mergeCommitOid,
    this.mergeCommitUrl,
  })  : abbreviatedOid = null,
        commitUrl = null;

  final String? abbreviatedOid;
  final String? commitUrl;
  final Fragment$pullCardFields? pullRequest;
  final String? mergeRefName;
  final String? mergeCommitOid;
  final String? mergeCommitUrl;
}

/// Review context for PR review events.
class TimelineReviewContext {
  const TimelineReviewContext({
    required this.stateLabel,
    required this.body,
    required this.commentCount,
    required this.reactionGroups,
    required this.viewerCanDelete,
    required this.viewerCanUpdate,
    required this.viewerCanReact,
    required this.viewerDidAuthor,
    required this.authorAssociation,
    this.author,
    this.bodyHTML,
    this.createdAt,
    this.lastEditedAt,
    this.viewerCannotUpdateReasons = const <String>[],
    this.nodeId,
  });
  final String stateLabel;
  final String body;
  final int commentCount;
  final List<dynamic> reactionGroups;
  final bool viewerCanDelete;
  final bool viewerCanUpdate;
  final bool viewerCanReact;
  final bool viewerDidAuthor;
  final Fragment$actor$$User? author;
  final Enum$CommentAuthorAssociation authorAssociation;
  final String? bodyHTML;
  final DateTime? createdAt;
  final DateTime? lastEditedAt;
  final List<String> viewerCannotUpdateReasons;
  final String? nodeId;
}

/// Part action data for icon/color resolution (timeline semantic action + optional state reason).
class TimelinePartActionData {
  const TimelinePartActionData({
    required this.action,
    this.stateReason,
  });
  final IssueTimelineSemanticAction action;
  final Enum$IssueStateReason? stateReason;
}

// ---------------------------------------------------------------------------
// Main DTO
// ---------------------------------------------------------------------------

/// Immutable data extracted from a [TimelineCompound].
/// Single source of truth for timeline compound rendering; UI uses this only.
@freezed
abstract class TimelineCompoundData with _$TimelineCompoundData {
  const factory TimelineCompoundData({
    required final IssueTimelineSemanticAction action,
    final DateTime? createdAt,
    @Default(<TimelinePartActionData>[])
    final List<TimelinePartActionData> partActions,

    // labelChange
    @Default(<TimelineLabelInfo>[]) final List<TimelineLabelInfo> addedLabels,
    @Default(<TimelineLabelInfo>[]) final List<TimelineLabelInfo> removedLabels,

    // stateChange
    final String? stateVerb,
    final Enum$IssueStateReason? stateReason,
    final TimelineCloserInfo? closer,

    // assigned / unassigned
    @Default(<String>[]) final List<String> assigneeLogins,

    // milestoneChange
    @Default(<String>[]) final List<String> addedMilestoneTitles,
    @Default(<String>[]) final List<String> removedMilestoneTitles,

    // review
    final TimelineReviewContext? reviewContext,

    // commitPush
    @Default(<TimelineCommitSummary>[])
    final List<TimelineCommitSummary> commits,

    // crossReference
    @Default(false) final bool willCloseTarget,
    final Fragment$issueCardFields? sourceIssue,
    final Fragment$pullCardFields? sourcePullRequest,
    @Default(<TimelineLabelInfo>[]) final List<TimelineLabelInfo> sourceLabels,
    final String? sourceBody,

    // other (rename, lock, pin, duplicate, ref events)
    final String? previousTitle,
    final String? currentTitle,
    final Enum$LockReason? lockReason,
    @Default(false) final bool isPinned,
    @Default(false) final bool isUnpinned,
    final Fragment$issueCardFields? duplicateCanonicalIssue,
    final Fragment$pullCardFields? duplicateCanonicalPullRequest,
    @Default(false) final bool isUnmarkedAsDuplicate,
    final Fragment$issueCardFields? unmarkedDuplicateCanonicalIssue,
    final Fragment$pullCardFields? unmarkedDuplicateCanonicalPullRequest,
    final String? baseRefPreviousName,
    final String? baseRefCurrentName,
    final String? baseRefDeletedName,
    final String? headRefDeletedName,
    final String? forcePushRefName,
    final String? forcePushRefLabel,
    final String? forcePushBeforeOid,
    final String? forcePushAfterOid,
    @Default(false) final bool isHeadRefRestored,
    @Default(false) final bool isConvertedToDraft,
    @Default(false) final bool isReadyForReview,
  }) = _TimelineCompoundData;
}

/// Extension on [TimelineCompound] to extract [TimelineCompoundData].
extension TimelineCompoundDataExtraction on TimelineCompound {
  /// Extracts all rendering data from this compound. Call once per compound.
  TimelineCompoundData toTimelineCompoundData() {
    final ActionCluster<IssueTimelineSemanticAction, dynamic> cluster =
        firstPart;
    final IssueTimelineSemanticAction action = cluster.action;
    final List<dynamic> events = cluster.events;

    final List<TimelinePartActionData> partActions = parts
        .map(
          (final ActionCluster<IssueTimelineSemanticAction, dynamic> p) =>
              TimelinePartActionData(
            action: p.action,
            stateReason: _stateReasonFromFirstEvent(p.events),
          ),
        )
        .toList();

    DateTime? createdAt;
    final List<TimelineLabelInfo> addedLabels = <TimelineLabelInfo>[];
    final List<TimelineLabelInfo> removedLabels = <TimelineLabelInfo>[];
    String? stateVerb;
    Enum$IssueStateReason? stateReason;
    TimelineCloserInfo? closer;
    final List<String> assigneeLogins = <String>[];
    final List<String> addedMilestoneTitles = <String>[];
    final List<String> removedMilestoneTitles = <String>[];
    TimelineReviewContext? reviewContext;
    final List<TimelineCommitSummary> commits = <TimelineCommitSummary>[];
    bool willCloseTarget = false;
    Fragment$issueCardFields? sourceIssue;
    Fragment$pullCardFields? sourcePullRequest;
    final List<TimelineLabelInfo> sourceLabels = <TimelineLabelInfo>[];
    String? sourceBody;
    String? previousTitle;
    String? currentTitle;
    Enum$LockReason? lockReason;
    bool isPinned = false;
    bool isUnpinned = false;
    Fragment$issueCardFields? duplicateCanonicalIssue;
    Fragment$pullCardFields? duplicateCanonicalPullRequest;
    bool isUnmarkedAsDuplicate = false;
    Fragment$issueCardFields? unmarkedDuplicateCanonicalIssue;
    Fragment$pullCardFields? unmarkedDuplicateCanonicalPullRequest;
    String? baseRefPreviousName;
    String? baseRefCurrentName;
    String? baseRefDeletedName;
    String? headRefDeletedName;
    String? forcePushRefName;
    String? forcePushRefLabel;
    String? forcePushBeforeOid;
    String? forcePushAfterOid;
    bool isHeadRefRestored = false;
    bool isConvertedToDraft = false;
    bool isReadyForReview = false;

    for (final node in events) {
      createdAt ??= _dateFromNode(node);

      if (node is LabeledEvent) {
        addedLabels.add(
          TimelineLabelInfo(name: node.label.name, color: node.label.color),
        );
      } else if (node is UnlabeledEvent) {
        removedLabels.add(
          TimelineLabelInfo(name: node.label.name, color: node.label.color),
        );
      } else if (node is ClosedEvent) {
        stateVerb = 'closed';
        stateReason = node.stateReason;
        closer = _closerFromClosed(node);
      } else if (node is ReopenedEvent) {
        stateVerb = 'reopened';
      } else if (node is MergedEvent) {
        stateVerb = 'merged';
        closer = _closerFromMerged(node);
      } else if (node is ConvertedToDraftEvent) {
        stateVerb = 'converted to draft';
        isConvertedToDraft = true;
      } else if (node is ReadyForReviewEvent) {
        stateVerb = 'ready for review';
        isReadyForReview = true;
      } else if (node is AssignedEvent) {
        final Fragment$actor$$User? a = node.assignee as Fragment$actor$$User?;
        if (a != null) assigneeLogins.add(a.login);
      } else if (node is UnassignedEvent) {
        final Fragment$actor$$User? a = node.assignee as Fragment$actor$$User?;
        if (a != null) assigneeLogins.add(a.login);
      } else if (node is MilestonedEvent) {
        addedMilestoneTitles.add(node.milestoneTitle);
      } else if (node is DemilestonedEvent) {
        removedMilestoneTitles.add(node.milestoneTitle);
      } else if (node is TimelinePullRequestReviewEvent) {
        reviewContext = _reviewContextFromNode(node);
      } else if (node is PullRequestCommitEvent) {
        commits.add(_commitSummaryFromNode(node.commit));
      } else if (node is CrossReferenceEvent) {
        willCloseTarget = node.willCloseTarget;
        node.source.maybeWhen(
          issue: (final CrossReferenceSourceIssue i) {
            sourceIssue = i;
            sourceBody = i.body;
            sourceLabels.addAll(timelineLabelsFromNodes(i.labels?.nodes));
          },
          pullRequest: (final CrossReferenceSourcePullRequest p) {
            sourcePullRequest = p;
            sourceBody = p.body;
            sourceLabels.addAll(timelineLabelsFromNodes(p.labels?.nodes));
          },
          orElse: () {},
        );
      } else if (node is RenamedTitleEvent) {
        previousTitle = node.previousTitle;
        currentTitle = node.currentTitle;
      } else if (node is LockedEvent) {
        lockReason = node.lockReason;
      } else if (node is UnlockedEvent) {
        // no extra fields
      } else if (node is PinnedEvent) {
        isPinned = true;
      } else if (node is UnpinnedEvent) {
        isUnpinned = true;
      } else if (node is MarkedAsDuplicateEvent) {
        node.canonical?.maybeWhen(
          issue: (final MarkedAsDuplicateCanonicalIssue i) =>
              duplicateCanonicalIssue = i,
          pullRequest: (final MarkedAsDuplicateCanonicalPullRequest p) =>
              duplicateCanonicalPullRequest = p,
          orElse: () {},
        );
      } else if (node is UnmarkedAsDuplicateEvent) {
        isUnmarkedAsDuplicate = true;
        node.canonical?.maybeWhen(
          issue: (final UnmarkedAsDuplicateCanonicalIssue i) =>
              unmarkedDuplicateCanonicalIssue = i,
          pullRequest:
              (final UnmarkedAsDuplicateCanonicalPullRequest p) =>
                  unmarkedDuplicateCanonicalPullRequest = p,
          orElse: () {},
        );
      } else if (node is BaseRefChangedEvent) {
        baseRefPreviousName = node.previousRefName;
        baseRefCurrentName = node.currentRefName;
      } else if (node is BaseRefForcePushedEvent) {
        forcePushRefName = node.ref?.name;
        forcePushRefLabel = 'base ref';
        forcePushBeforeOid = node.beforeCommit?.abbreviatedOid;
        forcePushAfterOid = node.afterCommit?.abbreviatedOid;
      } else if (node is BaseRefDeletedEvent) {
        baseRefDeletedName = node.baseRefName;
      } else if (node is HeadRefForcePushedEvent) {
        forcePushRefName = node.ref?.name;
        forcePushRefLabel = 'head ref';
        forcePushBeforeOid = node.beforeCommit?.abbreviatedOid;
        forcePushAfterOid = node.afterCommit?.abbreviatedOid;
      } else if (node is HeadRefDeletedEvent) {
        headRefDeletedName = node.headRefName;
      } else if (node is HeadRefRestoredEvent) {
        isHeadRefRestored = true;
      }
    }

    return TimelineCompoundData(
      action: action,
      createdAt: createdAt,
      partActions: partActions,
      addedLabels: addedLabels,
      removedLabels: removedLabels,
      stateVerb: stateVerb,
      stateReason: stateReason,
      closer: closer,
      assigneeLogins: assigneeLogins,
      addedMilestoneTitles: addedMilestoneTitles,
      removedMilestoneTitles: removedMilestoneTitles,
      reviewContext: reviewContext,
      commits: commits,
      willCloseTarget: willCloseTarget,
      sourceIssue: sourceIssue,
      sourcePullRequest: sourcePullRequest,
      sourceLabels: sourceLabels,
      sourceBody: sourceBody,
      previousTitle: previousTitle,
      currentTitle: currentTitle,
      lockReason: lockReason,
      isPinned: isPinned,
      isUnpinned: isUnpinned,
      duplicateCanonicalIssue: duplicateCanonicalIssue,
      duplicateCanonicalPullRequest: duplicateCanonicalPullRequest,
      isUnmarkedAsDuplicate: isUnmarkedAsDuplicate,
      unmarkedDuplicateCanonicalIssue: unmarkedDuplicateCanonicalIssue,
      unmarkedDuplicateCanonicalPullRequest:
          unmarkedDuplicateCanonicalPullRequest,
      baseRefPreviousName: baseRefPreviousName,
      baseRefCurrentName: baseRefCurrentName,
      baseRefDeletedName: baseRefDeletedName,
      headRefDeletedName: headRefDeletedName,
      forcePushRefName: forcePushRefName,
      forcePushRefLabel: forcePushRefLabel,
      forcePushBeforeOid: forcePushBeforeOid,
      forcePushAfterOid: forcePushAfterOid,
      isHeadRefRestored: isHeadRefRestored,
      isConvertedToDraft: isConvertedToDraft,
      isReadyForReview: isReadyForReview,
    );
  }
}

Enum$IssueStateReason? _stateReasonFromFirstEvent(final List<dynamic> events) {
  if (events.isEmpty) return null;
  final node = events.first;
  if (node is ClosedEvent) return node.stateReason;
  return null;
}

DateTime? _dateFromNode(final dynamic node) {
  try {
    if (node is AssignedEvent) return node.createdAt;
    if (node is ClosedEvent) return node.createdAt;
    if (node is LabeledEvent) return node.createdAt;
    if (node is UnlabeledEvent) return node.createdAt;
    if (node is ReopenedEvent) return node.createdAt;
    if (node is MergedEvent) return node.createdAt;
    if (node is TimelinePullRequestReviewEvent) return node.createdAt;
    if (node is PullRequestCommitEvent) return node.commit.authoredDate;
    if (node is UnassignedEvent) return node.createdAt;
    if (node is MilestonedEvent) return node.createdAt;
    if (node is DemilestonedEvent) return node.createdAt;
    if (node is CrossReferenceEvent) return node.createdAt;
    if (node is ConvertedToDraftEvent) return node.createdAt;
    if (node is ReadyForReviewEvent) return node.createdAt;
    if (node is LockedEvent) return node.createdAt;
    if (node is UnlockedEvent) return node.createdAt;
    if (node is PinnedEvent) return node.createdAt;
    if (node is UnpinnedEvent) return node.createdAt;
    if (node is MarkedAsDuplicateEvent) return node.createdAt;
    if (node is UnmarkedAsDuplicateEvent) return node.createdAt;
    if (node is RenamedTitleEvent) return node.createdAt;
    if (node is BaseRefChangedEvent) return node.createdAt;
    if (node is BaseRefForcePushedEvent) return node.createdAt;
    if (node is BaseRefDeletedEvent) return node.createdAt;
    if (node is HeadRefForcePushedEvent) return node.createdAt;
    if (node is HeadRefDeletedEvent) return node.createdAt;
    if (node is HeadRefRestoredEvent) return node.createdAt;
    if (node is IssueCommentEvent) return node.createdAt;
  } catch (e, st) {
    AppLogger.warning(
      'Reading createdAt from timeline node failed',
      error: e,
      stackTrace: st,
      tag: 'TimelineCompoundData',
    );
  }
  return null;
}

TimelineCloserInfo? _closerFromClosed(final ClosedEvent node) {
  final Fragment$closed$closer? c = node.closer;
  if (c == null) return null;
  return c.maybeWhen(
    commit: (final Fragment$closed$closer$$Commit commit) =>
        TimelineCloserInfo.commit(
      abbreviatedOid: commit.abbreviatedOid,
      commitUrl: commit.commitUrl.toString(),
    ),
    pullRequest: (final Fragment$closed$closer$$PullRequest pr) =>
        TimelineCloserInfo.pullRequest(
      pullRequest: pr,
    ),
    orElse: () => null,
  );
}

TimelineCloserInfo? _closerFromMerged(final MergedEvent node) =>
    TimelineCloserInfo.pullRequest(
      pullRequest: null,
      mergeRefName: node.mergeRefName,
      mergeCommitOid: node.mergeCommit?.abbreviatedOid,
      mergeCommitUrl: node.mergeCommit?.commitUrl.toString(),
    );

TimelineReviewContext _reviewContextFromNode(final TimelinePullRequestReviewEvent node) {
  String stateLabel;
  switch (node.state) {
    case Enum$PullRequestReviewState.APPROVED:
      stateLabel = 'Approved';
    case Enum$PullRequestReviewState.CHANGES_REQUESTED:
      stateLabel = 'Requested changes';
    case Enum$PullRequestReviewState.COMMENTED:
      stateLabel = 'Commented';
    case Enum$PullRequestReviewState.DISMISSED:
      stateLabel = 'Dismissed';
    case Enum$PullRequestReviewState.PENDING:
      stateLabel = 'Pending';
    default:
      stateLabel = 'Reviewed';
  }
  return TimelineReviewContext(
    stateLabel: stateLabel,
    body: node.body,
    commentCount: node.comments.totalCount,
    reactionGroups: node.reactionGroups!.toList(),
    viewerCanDelete: node.viewerCanDelete,
    viewerCanUpdate: node.viewerCanUpdate,
    viewerCanReact: node.viewerCanReact,
    viewerDidAuthor: node.viewerDidAuthor,
    author: node.author as Fragment$actor$$User?,
    authorAssociation: node.authorAssociation,
    bodyHTML: node.bodyHTML,
    createdAt: node.createdAt,
    lastEditedAt: node.lastEditedAt,
    viewerCannotUpdateReasons: node.viewerCannotUpdateReasons
        .map((final Enum$CommentCannotUpdateReason e) => e.name)
        .toList(),
    nodeId: node.id,
  );
}

TimelineCommitSummary _commitSummaryFromNode(final CommitEvent c) =>
    TimelineCommitSummary(
      oid: c.oid,
      abbreviatedOid: c.oid.isNotEmpty ? c.oid.substring(0, 7) : '',
      messageHeadline: c.messageHeadline,
      commitUrl: c.commitUrl.toString(),
      additions: c.additions,
      deletions: c.deletions,
    );
