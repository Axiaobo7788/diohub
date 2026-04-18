// Domain types and adapters for issue/PR cards. UI depends on these types so
// other git providers (e.g. GitLab) can reuse the same cards via their own
// constructors (e.g. fromGitLabRest).

import 'package:diohub/common/misc/reaction_bar.dart';
import 'package:diohub/common/utils/github_visual_styles.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' as gql;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

// ---------------------------------------------------------------------------
// Domain value types (provider-agnostic)
// ---------------------------------------------------------------------------

/// Label display for cards (name + color + optional description for popup).
class CardLabel {
  const CardLabel({required this.name, required this.color, this.description});
  final String name;
  final String color;

  /// Optional description shown in label popup (max 2 lines).
  final String? description;
}

/// Single reaction group: emoji, count, and whether the viewer reacted.
class CardReactionGroup {
  const CardReactionGroup({
    required this.emoji,
    required this.count,
    this.viewerHasReacted = false,
  });
  final String emoji;
  final int count;
  final bool viewerHasReacted;
}

/// Project item for project chips (title + optional link).
class CardProjectItem {
  const CardProjectItem({required this.title, this.url});
  final String title;
  final Uri? url;
}

/// Milestone info for milestone chip and popup.
class CardMilestoneInfo {
  const CardMilestoneInfo({
    required this.title,
    this.dueOn,
    this.description,
    this.progress,
    this.openIssues,
    this.closedIssues,
  });
  final String title;
  final String? dueOn; // ISO8601
  final String? description;
  final double? progress; // 0..1
  final int? openIssues;
  final int? closedIssues;
}

/// One tracked issue row (state names for VisualState.fromNames).
class CardTrackedIssue {
  const CardTrackedIssue({
    required this.number,
    required this.title,
    required this.stateName,
    this.stateReasonName,
    required this.repoOwner,
    required this.repoName,
  });
  final int number;
  final String title;
  final String stateName;
  final String? stateReasonName;
  final String repoOwner;
  final String repoName;
}

/// Sub-issues summary (tasklist progress).
class CardSubIssuesSummary {
  const CardSubIssuesSummary({
    required this.completed,
    required this.total,
    required this.percentCompleted,
  });
  final int completed;
  final int total;
  final double percentCompleted; // 0..1
}

/// Author for author chip.
class CardAuthor {
  const CardAuthor({required this.login, this.avatarUrl});
  final String login;
  final String? avatarUrl;
}

/// Parent issue reference (e.g. for sub-issues).
class CardParentIssue {
  const CardParentIssue({
    required this.repoNameWithOwner,
    required this.number,
    required this.title,
  });
  final String repoNameWithOwner;
  final int number;
  final String title;
}

// ---------------------------------------------------------------------------
// Domain enums (replace GQL enums so other providers can map to them)
// ---------------------------------------------------------------------------

/// PR merge state for branch row and merge badge.
enum CardMergeStateStatus {
  clean,
  blocked,
  dirty,
  behind,
  unstable,
  draft,
  hasHooks,
  unknown,
}

/// PR review decision: Approved, Changes Requested, Review Required.
enum CardReviewDecision {
  approved,
  changesRequested,
  reviewRequired,
}

/// CI/checks status for status chip and popup.
enum CardChecksState {
  success,
  failure,
  error,
  pending,
  expected,
}

/// One reviewer row for review chip and popup: avatar, login, state, optional body/time/comments/url.
class ReviewReviewerRow {
  const ReviewReviewerRow({
    required this.avatarUrl,
    required this.login,
    required this.stateIcon,
    this.stateColor,
    this.stateName,
    this.bodyText,
    this.submittedAt,
    this.inlineCommentCount = 0,
    this.url,
    this.authorAssociation,
    this.teamName,
    this.teamAvatarUrl,
  });

  final String? avatarUrl;
  final String login;
  final IconData stateIcon;
  final Color? stateColor;

  /// Raw review state name (e.g. APPROVED, CHANGES_REQUESTED) for aggregation.
  final String? stateName;

  /// First line of review body (plain text), truncated in popup.
  final String? bodyText;

  /// ISO8601 when the review was submitted.
  final String? submittedAt;

  /// Inline/thread comment count for this review.
  final int inlineCommentCount;

  /// Direct link to the review.
  final Uri? url;

  /// Author association (e.g. MEMBER, COLLABORATOR, OWNER). Shown as badge when notable.
  final String? authorAssociation;

  /// Team name when review was submitted on behalf of a team.
  final String? teamName;

  /// Team avatar URL when onBehalfOf is present.
  final String? teamAvatarUrl;
}

// ---------------------------------------------------------------------------
// Issue card data (all fields the issue card uses)
// ---------------------------------------------------------------------------

class IssueCardData {
  const IssueCardData({
    required this.repo,
    required this.id,
    required this.number,
    required this.state,
    required this.title,
    required this.url,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    required this.commentsCount,
    this.author,
    required this.labels,
    required this.assigneeNodes,
    required this.milestone,
    required this.locked,
    this.activeLockReason,
    this.isPinned = false,
    this.isReadByViewer,
    this.authorAssociation,
    required this.trackedIssuesCount,
    required this.trackedIssues,
    required this.subIssuesSummary,
    this.parent,
    required this.projectItems,
    required this.reactionGroups,
    this.linkedPRCount = 0,
  });

  final RepoRef repo;
  final String id;
  final int number;
  final VisualState state;
  final String title;
  final Uri url;
  final String body;
  final String createdAt; // ISO8601
  final String updatedAt;
  final String? closedAt;
  final int commentsCount;
  final CardAuthor? author;
  final List<CardLabel> labels;

  /// Assignee nodes (User/Org/Bot/Mannequin) for assignees sheet and avatar stack.
  final List<gql.IssueCardAssigneeNode?> assigneeNodes;
  final CardMilestoneInfo? milestone;
  final bool locked;

  /// When locked, the reason (e.g. TOO_HEATED, SPAM). Display as "Locked: too heated".
  final String? activeLockReason;
  final bool isPinned;

  /// When false, show unread styling (e.g. bolder title). Null when not available.
  final bool? isReadByViewer;

  /// Author association (e.g. MEMBER, CONTRIBUTOR). Shown as badge when not NONE/MANNEQUIN.
  final String? authorAssociation;
  final int trackedIssuesCount;
  final List<CardTrackedIssue> trackedIssues;
  final CardSubIssuesSummary subIssuesSummary;
  final CardParentIssue? parent;
  final List<CardProjectItem> projectItems;
  final List<CardReactionGroup> reactionGroups;

  /// Number of pull requests that close this issue (from closedByPullRequestsReferences).
  final int linkedPRCount;

  List<String> get assigneeAvatarUrls =>
      _avatarUrlsFromAssigneeNodes(assigneeNodes);

  /// Build [IssueCardData] from GitHub GraphQL fragment.
  /// Other providers can add e.g. [fromGitLabRest] later.
  factory IssueCardData.fromGitHubGql(final gql.IssueCardData g) {
    final RepoRef repo =
        RepoRef(owner: g.repository.owner.login, name: g.repository.name);
    final List<CardLabel> labels = _labelsFromIssueLabels(g.labels);
    final List<gql.IssueCardAssigneeNode?> assigneeNodes =
        g.assignees.nodes?.toList() ?? const [];
    final List<CardProjectItem> projectItems = _projectItemsFromIssue(g);
    final List<CardReactionGroup> reactionGroups =
        _reactionGroupsFromIssue(g.reactionGroups?.toList() ?? []);
    final CardMilestoneInfo? milestone =
        _milestoneFromIssueMilestone(g.milestone);
    final List<CardTrackedIssue> trackedIssues =
        _trackedIssuesFromGql(g.trackedIssues);
    final CardSubIssuesSummary subIssuesSummary = CardSubIssuesSummary(
      completed: g.subIssuesSummary.completed,
      total: g.subIssuesSummary.total,
      percentCompleted: g.subIssuesSummary.percentCompleted / 100,
    );
    final VisualState state = IssueVisualState.fromNames(
      g.issueState.name,
      reasonName: g.stateReason?.name,
    );
    final CardParentIssue? parent = g.parent != null
        ? CardParentIssue(
            repoNameWithOwner: g.parent!.repository.nameWithOwner,
            number: g.parent!.number,
            title: g.parent!.title,
          )
        : null;
    return IssueCardData(
      repo: repo,
      id: g.id,
      number: g.number,
      state: state,
      title: g.title,
      url: g.url,
      body: g.body,
      createdAt: g.createdAt.toIso8601String(),
      updatedAt: g.updatedAt.toIso8601String(),
      closedAt: g.closedAt?.toIso8601String(),
      commentsCount: g.comments.totalCount,
      author: g.author != null
          ? CardAuthor(
              login: g.author!.login,
              avatarUrl: g.author!.avatarUrl.toString(),
            )
          : null,
      labels: labels,
      assigneeNodes: assigneeNodes,
      milestone: milestone,
      locked: g.locked,
      activeLockReason: g.activeLockReason?.name,
      isPinned: g.isPinned == true,
      isReadByViewer: g.isReadByViewer,
      authorAssociation: g.authorAssociation.name != 'NONE' &&
              g.authorAssociation.name != 'MANNEQUIN'
          ? g.authorAssociation.name
          : null,
      trackedIssuesCount: g.trackedIssues.totalCount,
      trackedIssues: trackedIssues,
      subIssuesSummary: subIssuesSummary,
      parent: parent,
      projectItems: projectItems,
      reactionGroups: reactionGroups,
      linkedPRCount: g.closedByPRsSummary?.totalCount ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Pull request card data (issue-like fields + PR-specific)
// ---------------------------------------------------------------------------

class PullRequestCardData {
  const PullRequestCardData({
    required this.repo,
    required this.id,
    required this.number,
    required this.state,
    required this.title,
    required this.url,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.mergedAt,
    required this.merged,
    required this.isDraft,
    required this.additions,
    required this.deletions,
    required this.changedFiles,
    required this.commitsCount,
    required this.commentsCount,
    required this.reviewThreadsCount,
    this.totalCommentsCount,
    this.author,
    required this.labels,
    required this.assigneeNodes,
    required this.headRefName,
    required this.baseRefName,
    this.reviewDecision,
    this.checksState,
    this.checksTotalCount,
    this.milestone,
    required this.locked,
    this.activeLockReason,
    this.isReadByViewer,
    this.authorAssociation,
    required this.projectItems,
    required this.reactionGroups,
    required this.mergeStateStatus,
    this.autoMergeMethod,
    required this.reviewerRows,
    required this.isInMergeQueue,
    this.mergeQueuePosition,
    this.mergedByLogin,
    required this.isCrossRepository,
  });

  final RepoRef repo;
  final String id;
  final int number;
  final VisualState state;
  final String title;
  final Uri url;
  final String body;
  final String createdAt;
  final String updatedAt;
  final String? closedAt;
  final String? mergedAt;
  final bool merged;
  final bool isDraft;
  final int additions;
  final int deletions;
  final int changedFiles;
  final int commitsCount;
  final int commentsCount;
  final int reviewThreadsCount;
  final int? totalCommentsCount;
  final CardAuthor? author;
  final List<CardLabel> labels;

  /// Assignee nodes (User/Org/Bot/Mannequin) for assignees sheet and avatar stack.
  final List<gql.PullCardAssigneeNode?> assigneeNodes;
  final String headRefName;
  final String baseRefName;
  final CardReviewDecision? reviewDecision;
  final CardChecksState? checksState;

  /// Total number of CI check contexts (from statusCheckRollup.contextsSummary.totalCount).
  final int? checksTotalCount;
  final CardMilestoneInfo? milestone;
  final bool locked;
  final String? activeLockReason;
  final bool? isReadByViewer;
  final String? authorAssociation;
  final List<CardProjectItem> projectItems;
  final List<CardReactionGroup> reactionGroups;
  final CardMergeStateStatus mergeStateStatus;
  final String? autoMergeMethod;
  final List<ReviewReviewerRow> reviewerRows;
  final bool isInMergeQueue;
  final int? mergeQueuePosition;
  final String? mergedByLogin;
  final bool isCrossRepository;

  List<String> get assigneeAvatarUrls =>
      _avatarUrlsFromAssigneeNodes(assigneeNodes);

  bool get hasDiffStats => additions > 0 || deletions > 0 || changedFiles > 0;

  /// Build [PullRequestCardData] from GitHub GraphQL fragment.
  /// Other providers can add e.g. [fromGitLabRest] later.
  factory PullRequestCardData.fromGitHubGql(final gql.PullCardData g) {
    final RepoRef repo =
        RepoRef(owner: g.repository.owner.login, name: g.repository.name);
    final List<CardLabel> labels = _labelsFromPullLabels(g.labels);
    final List<gql.PullCardAssigneeNode?> assigneeNodes =
        g.assignees.nodes?.toList() ?? const [];
    final List<CardProjectItem> projectItems = _projectItemsFromPull(g);
    final List<CardReactionGroup> reactionGroups =
        _reactionGroupsFromPull(g.reactionGroups?.toList() ?? []);
    final CardMilestoneInfo? milestone =
        _milestoneFromPullMilestone(g.milestone);
    final VisualState state = PrVisualState.fromNames(
      g.pullRequestState.name,
      merged: g.merged,
      isDraft: g.isDraft,
    );
    final CardReviewDecision? reviewDecision =
        _reviewDecisionFromGql(g.reviewDecision);
    final CardChecksState? checksState = g.statusCheckRollup != null
        ? _checksStateFromGql(g.statusCheckRollup!.state)
        : null;
    final int? checksTotalCount = g.statusCheckRollup?.contextsSummary.totalCount;
    final CardMergeStateStatus mergeStateStatus =
        _mergeStateFromGql(g.mergeStateStatus);
    final List<ReviewReviewerRow> reviewerRows = _reviewerRowsFromPull(g);
    return PullRequestCardData(
      repo: repo,
      id: g.id,
      number: g.number,
      state: state,
      title: g.title,
      url: g.url,
      body: g.body,
      createdAt: g.createdAt.toIso8601String(),
      updatedAt: g.updatedAt.toIso8601String(),
      closedAt: g.closedAt?.toIso8601String(),
      mergedAt: g.mergedAt?.toIso8601String(),
      merged: g.merged,
      isDraft: g.isDraft,
      additions: g.additions,
      deletions: g.deletions,
      changedFiles: g.changedFiles,
      commitsCount: g.commits.totalCount,
      commentsCount: g.comments.totalCount,
      reviewThreadsCount: g.reviewThreads.totalCount,
      totalCommentsCount: g.totalCommentsCount,
      author: g.author != null
          ? CardAuthor(
              login: g.author!.login,
              avatarUrl: g.author!.avatarUrl.toString(),
            )
          : null,
      labels: labels,
      assigneeNodes: assigneeNodes,
      headRefName: g.headRefName,
      baseRefName: g.baseRefName,
      reviewDecision: reviewDecision,
      checksState: checksState,
      checksTotalCount: checksTotalCount,
      milestone: milestone,
      locked: g.locked,
      activeLockReason: g.activeLockReason?.name,
      isReadByViewer: g.isReadByViewer,
      authorAssociation: g.authorAssociation.name != 'NONE' &&
              g.authorAssociation.name != 'MANNEQUIN'
          ? g.authorAssociation.name
          : null,
      projectItems: projectItems,
      reactionGroups: reactionGroups,
      mergeStateStatus: mergeStateStatus,
      autoMergeMethod: g.autoMergeRequest?.mergeMethod.name,
      reviewerRows: reviewerRows,
      isInMergeQueue: g.isInMergeQueue,
      mergeQueuePosition: g.mergeQueueEntry?.position,
      mergedByLogin: g.mergedBy?.login,
      isCrossRepository: g.isCrossRepository,
    );
  }
}

// --- GitHub GQL adapter helpers (private to this library) ---

List<CardLabel> _labelsFromIssueLabels(
  final gql.IssueCardLabels? labels,
) {
  final nodes = labels?.nodes;
  if (nodes == null) return const [];
  final List<CardLabel> out = <CardLabel>[];
  for (final gql.IssueCardLabelNode? n in nodes) {
    if (n == null) continue;
    out.add(CardLabel(name: n.name, color: n.color));
  }
  return out;
}

List<CardLabel> _labelsFromPullLabels(final gql.PullCardLabels? labels) {
  final nodes = labels?.nodes;
  if (nodes == null) return const [];
  final List<CardLabel> out = <CardLabel>[];
  for (final gql.PullCardLabelNode? n in nodes) {
    if (n == null) continue;
    out.add(CardLabel(name: n.name, color: n.color));
  }
  return out;
}

List<String> _avatarUrlsFromAssigneeNodes(final Iterable<Object?>? nodes) {
  if (nodes == null) return const <String>[];
  final List<String> out = <String>[];
  for (final Object? n in nodes) {
    if (n == null) continue;
    out.add((n as gql.UserCardData).avatarUrl.toString());
  }
  return out;
}

List<CardProjectItem> _projectItemsFromIssue(final gql.IssueCardData g) {
  final nodes = g.projectItems?.nodes;
  if (nodes == null) return const [];
  final List<CardProjectItem> out = <CardProjectItem>[];
  for (final gql.IssueCardProjectItemNode? node in nodes) {
    if (node == null) continue;
    final String title = node.project.title;
    if (title.isEmpty) continue;
    out.add(CardProjectItem(title: title, url: node.project.url));
  }
  return out;
}

List<CardProjectItem> _projectItemsFromPull(final gql.PullCardData g) {
  final nodes = g.projectItems?.nodes;
  if (nodes == null) return const [];
  final List<CardProjectItem> out = <CardProjectItem>[];
  for (final gql.PullCardProjectItemNode? node in nodes) {
    if (node == null) continue;
    final String title = node.project.title;
    if (title.isEmpty) continue;
    out.add(CardProjectItem(title: title, url: node.project.url));
  }
  return out;
}

CardMilestoneInfo? _milestoneFromIssueMilestone(
  final gql.IssueCardMilestone? m,
) {
  if (m == null) return null;
  return CardMilestoneInfo(
    title: m.title,
    dueOn: m.dueOn?.toIso8601String(),
    description: m.description,
    progress: m.progressPercentage / 100,
    openIssues: m.openIssues.totalCount,
    closedIssues: m.closedIssues.totalCount,
  );
}

CardMilestoneInfo? _milestoneFromPullMilestone(
  final gql.PullCardMilestone? m,
) {
  if (m == null) return null;
  return CardMilestoneInfo(
    title: m.title,
    dueOn: m.dueOn?.toIso8601String(),
    description: m.description,
    progress: m.progressPercentage / 100,
    openIssues: m.openIssues.totalCount,
    closedIssues: m.closedIssues.totalCount,
  );
}

List<CardTrackedIssue> _trackedIssuesFromGql(
  final gql.IssueCardTrackedIssues trackedIssues,
) {
  final nodes = trackedIssues.nodes;
  if (nodes == null) return const [];
  final List<CardTrackedIssue> out = <CardTrackedIssue>[];
  for (final gql.IssueCardTrackedIssueNode? n in nodes) {
    if (n == null) continue;
    final repo = n.repository;
    out.add(CardTrackedIssue(
      number: n.number,
      title: n.title,
      stateName: n.state.name,
      stateReasonName: null,
      repoOwner: repo.owner.login,
      repoName: repo.name,
    ));
  }
  return out;
}

List<CardReactionGroup> _reactionGroupsFromIssue(
  final List<gql.IssueCardReactionGroups> list,
) {
  return list
      .where(
        (final gql.IssueCardReactionGroups g) => g.reactors.totalCount > 0,
      )
      .map(
        (final gql.IssueCardReactionGroups g) => CardReactionGroup(
          emoji: g.content.emoji,
          count: g.reactors.totalCount,
          viewerHasReacted: g.viewerHasReacted,
        ),
      )
      .toList();
}

List<CardReactionGroup> _reactionGroupsFromPull(
  final List<gql.PullCardReactionGroups> list,
) {
  return list
      .where(
        (final gql.PullCardReactionGroups g) => g.reactors.totalCount > 0,
      )
      .map(
        (final gql.PullCardReactionGroups g) => CardReactionGroup(
          emoji: g.content.emoji,
          count: g.reactors.totalCount,
          viewerHasReacted: g.viewerHasReacted,
        ),
      )
      .toList();
}

CardMergeStateStatus _mergeStateFromGql(final MergeStateStatus s) =>
    mergeStateFromGitHubGql(s);

CardChecksState _checksStateFromGql(final StatusState s) =>
    checksStateFromGitHubGql(s);

CardReviewDecision? _reviewDecisionFromGql(
        final PullRequestReviewDecision? d) =>
    reviewDecisionFromGitHubGql(d);

/// Converts GitHub GQL merge state to domain type. Use when building UI from GQL outside card adapters.
CardMergeStateStatus mergeStateFromGitHubGql(final MergeStateStatus s) {
  return switch (s) {
    MergeStateStatus.CLEAN => CardMergeStateStatus.clean,
    MergeStateStatus.BLOCKED => CardMergeStateStatus.blocked,
    MergeStateStatus.DIRTY => CardMergeStateStatus.dirty,
    MergeStateStatus.BEHIND => CardMergeStateStatus.behind,
    MergeStateStatus.UNSTABLE => CardMergeStateStatus.unstable,
    MergeStateStatus.DRAFT => CardMergeStateStatus.draft,
    MergeStateStatus.HAS_HOOKS => CardMergeStateStatus.hasHooks,
    MergeStateStatus.UNKNOWN => CardMergeStateStatus.unknown,
    _ => CardMergeStateStatus.unknown,
  };
}

/// Converts GitHub GQL checks state to domain type.
CardChecksState checksStateFromGitHubGql(final StatusState s) {
  return switch (s) {
    StatusState.SUCCESS => CardChecksState.success,
    StatusState.FAILURE => CardChecksState.failure,
    StatusState.ERROR => CardChecksState.error,
    StatusState.PENDING => CardChecksState.pending,
    StatusState.EXPECTED => CardChecksState.expected,
    _ => CardChecksState.pending,
  };
}

/// Converts GitHub GQL review decision to domain type.
CardReviewDecision? reviewDecisionFromGitHubGql(
  final PullRequestReviewDecision? d,
) {
  if (d == null) return null;
  return switch (d) {
    PullRequestReviewDecision.APPROVED => CardReviewDecision.approved,
    PullRequestReviewDecision.CHANGES_REQUESTED =>
      CardReviewDecision.changesRequested,
    PullRequestReviewDecision.REVIEW_REQUIRED =>
      CardReviewDecision.reviewRequired,
    _ => CardReviewDecision.reviewRequired,
  };
}

List<ReviewReviewerRow> _reviewerRowsFromPull(final gql.PullCardData data) {
  final reviews = data.latestOpinionatedReviews?.nodes;
  if (reviews == null) return <ReviewReviewerRow>[];
  final List<ReviewReviewerRow> out = <ReviewReviewerRow>[];
  for (final gql.PullCardLatestReviewNode? r in reviews) {
    if (r == null || r.author == null) continue;
    final String login = r.author!.login;
    final String? avatarUrl = r.author!.avatarUrl.toString();
    IconData stateIcon = Octicons.code_review;
    Color? stateColor;
    switch (r.state) {
      case PullRequestReviewState.APPROVED:
        stateIcon = Octicons.check_circle;
        stateColor = Colors.green;
        break;
      case PullRequestReviewState.CHANGES_REQUESTED:
        stateIcon = Icons.edit_note_rounded;
        stateColor = Colors.red;
        break;
      case PullRequestReviewState.COMMENTED:
        stateIcon = Octicons.comment;
        stateColor = null;
      default:
        stateIcon = Octicons.code_review;
        stateColor = null;
    }
    final String? bodyText = r.bodyText.isNotEmpty ? r.bodyText : null;
    final String? submittedAt =
        r.submittedAt != null ? r.submittedAt!.toIso8601String() : null;
    final int inlineCommentCount = r.comments.totalCount;
    final Uri? url = r.url;
    final String authorAssociationStr = r.authorAssociation.name;
    final nodes = r.onBehalfOf.nodes;
    final firstTeam = nodes != null && nodes.isNotEmpty ? nodes.first : null;
    final String? teamName = firstTeam?.name;
    final String? teamAvatarUrl = firstTeam?.avatarUrl?.toString();
    out.add(
      ReviewReviewerRow(
        avatarUrl: avatarUrl,
        login: login,
        stateIcon: stateIcon,
        stateColor: stateColor,
        stateName: r.state.name,
        bodyText: bodyText,
        submittedAt: submittedAt,
        inlineCommentCount: inlineCommentCount,
        url: url,
        authorAssociation: authorAssociationStr,
        teamName: teamName,
        teamAvatarUrl: teamAvatarUrl,
      ),
    );
  }
  return out;
}

// ---------------------------------------------------------------------------
// State color extensions
// ---------------------------------------------------------------------------

/// Extension to compute state color for IssueCardData (extracted from IssueCard.stateColor).
extension IssueCardDataStateColor on IssueCardData {
  Color? computeStateColor() {
    if (state is IssueVisualState) {
      return GitHubVisualStyles.fromIssueVisualState(state as IssueVisualState).color;
    } else if (state is PrVisualState) {
      return GitHubVisualStyles.fromPrVisualState(state as PrVisualState).color;
    }
    return null;
  }
}

/// Extension to compute state color for PullRequestCardData (extracted from PullRequestCard.stateColor).
extension PullRequestCardDataStateColor on PullRequestCardData {
  Color? computeStateColor() {
    if (state is IssueVisualState) {
      return GitHubVisualStyles.fromIssueVisualState(state as IssueVisualState).color;
    } else if (state is PrVisualState) {
      return GitHubVisualStyles.fromPrVisualState(state as PrVisualState).color;
    }
    return null;
  }
}

