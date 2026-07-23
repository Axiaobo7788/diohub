import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:flutter/widgets.dart';

/// Localizes filter metadata at the rendering boundary.
///
/// Search models deliberately keep stable English identifiers and fallback
/// labels. Values entered by the user, and values returned by GitHub such as
/// label names, logins, milestones, and branch names, must bypass this helper.
String localizedFilterSectionName(
  BuildContext context,
  FilterSectionDef section,
) {
  final l10n = context.l10n;
  return switch (section.id) {
    'status' => l10n.filterStatus,
    'assignee' => l10n.repoAssignee,
    'label' => l10n.filterLabel,
    'milestone' => l10n.filterMilestone,
    'author' => l10n.repoAuthor,
    'base' => l10n.filterBaseBranch,
    'head' => l10n.filterHeadBranch,
    'created' => l10n.filterCreated,
    'updated' => l10n.filterUpdated,
    'comments' => l10n.filterComments,
    'reactions' => l10n.filterReactions,
    'interactions' => l10n.filterInteractions,
    'draft' => l10n.filterDraft,
    'review' => l10n.filterReviewStatus,
    'reviews' => l10n.repoReviews,
    'reviewed-by' || 'reviewed_by' => l10n.filterReviewedBy,
    'review-requested' || 'review_requested' => l10n.filterReviewRequested,
    'team-requested' || 'team_requested' => l10n.filterTeamRequested,
    'linked' || 'linked-issue' || 'linked_issue' => l10n.filterLinkedIssue,
    'no' => l10n.filterExclude,
    'closed' => l10n.filterClosed,
    'merged' => l10n.filterMerged,
    'sort' => l10n.repoSort,
    _ => section.displayName,
  };
}

String localizedFilterSearchHint(
  BuildContext context,
  FilterSectionDef section,
) {
  final l10n = context.l10n;
  return switch (section.id) {
    'label' => l10n.filterSearchLabels,
    'assignee' => l10n.filterSearchAssignees,
    'base' || 'head' => l10n.repoSearchBranches,
    _ => l10n.filterSearch(localizedFilterSectionName(context, section)),
  };
}

String localizedFilterOptionLabel(
  BuildContext context,
  FilterSectionDef section,
  String value,
  String fallback,
) {
  final l10n = context.l10n;
  final String? localized = switch ('${section.id}:$value') {
    'status:open' => l10n.repoOpen,
    'status:closed' => l10n.repoClosed,
    'status:merged' => l10n.filterOptionMerged,
    'sort:best' => l10n.filterOptionBestMatch,
    'sort:created-desc' => l10n.filterOptionNewest,
    'sort:created-asc' => l10n.filterOptionOldest,
    'sort:comments-desc' => l10n.filterOptionMostComments,
    'sort:updated-desc' => l10n.filterOptionRecentlyUpdated,
    'review:none' => l10n.filterOptionNoReview,
    'review:required' => l10n.filterOptionReviewRequired,
    'review:approved' => l10n.filterOptionApproved,
    'review:changes_requested' => l10n.filterOptionChangesRequested,
    'draft:true' => l10n.filterOptionDraftOnly,
    'draft:false' => l10n.filterOptionNonDraftOnly,
    'linked:pr' => l10n.filterOptionHasLinkedPullRequest,
    'linked:issue' => l10n.filterOptionHasLinkedIssue,
    'no:label' => l10n.filterOptionNoLabels,
    'no:milestone' => l10n.filterOptionNoMilestone,
    'no:assignee' => l10n.filterOptionNoAssignee,
    _ => null,
  };
  return localized ?? (fallback.isEmpty ? value : fallback);
}
