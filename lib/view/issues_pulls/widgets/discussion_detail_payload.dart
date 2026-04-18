import 'package:diohub_graphql/fragments/fragment_typedefs.dart'
    show ReactionGroupData;
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';

/// Single payload for the discussion content slivers (issue or PR).
///
/// Built from [IssueInfo] or [PullInfo] by [IssueContentView] / [PullDiscussionView].
/// Author, timestamp, comment count, labels, and branch refs are in metadata slivers only.
/// [createdAt] is used by the timeline widget only.
class DiscussionDetailPayload {
  const DiscussionDetailPayload({
    required this.title,
    required this.bodyHTML,
    required this.reactionGroups,
    required this.viewerCanReact,
    required this.repo,
    required this.number,
    required this.isPull,
    this.nodeID,
    this.isLocked,
    this.commentsSince,
    this.createdAt,
    this.scrollToCommentId,
    this.subIssuesSummary,
    this.subIssuesTabIndex,
  });

  final String title;
  final String bodyHTML;
  final List<ReactionGroupData> reactionGroups;
  final bool viewerCanReact;
  final RepoRef repo;
  final int number;
  final bool isPull;
  final String? nodeID;
  final bool? isLocked;
  final DateTime? commentsSince;
  final DateTime? createdAt;

  /// When set (e.g. from issueRef.fragment / pullRef.fragment), timeline will scroll to this comment (e.g. issuecomment-123).
  final String? scrollToCommentId;
  
  /// Sub-issues summary (completed, total, percentCompleted) for issues.
  final ({int completed, int total, int percentCompleted})? subIssuesSummary;
  
  /// Index of the sub-issues tab for programmatic navigation.
  final int? subIssuesTabIndex;
}
