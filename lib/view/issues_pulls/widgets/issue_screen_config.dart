import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/nav_center/dock/bookmark_dock_pill.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub/view/issues_pulls/widgets/config/issue_metadata_builders.dart';
import 'package:diohub/view/issues_pulls/widgets/config/issue_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Extension to build NavCenter [ScreenConfig] from issue GQL data.
extension IssueScreenConfigX on IssueInfo {
  ScreenConfig toScreenConfig(
    BuildContext context,
    WidgetRef ref, {
    required IssueRef issueRef,
    required VoidCallback onRefresh,
    List<Widget> Function(BuildContext)? linkedPRsSliverBuilder,
    DateTime? commentsSince,
    String? scrollToCommentId,
  }) {
    final data = this;
    
    // Build expanded zone content with parent breadcrumb if present
    final List<ExpandedZoneDetail> expandedZoneContent = [];
    
    // Add parent issue breadcrumb if present
    final parentIssue = data.parent;
    if (parentIssue != null && parentIssue.repository?.nameWithOwner != null) {
      final parentRepo = parentIssue.repository!.nameWithOwner!;
      expandedZoneContent.add(
        ExpandedZoneText(
          '<span style="color: #888;">$parentRepo#${parentIssue.number}</span>',
        ),
      );
    }
    
    // Add issue title
    if (data.titleHTML.isNotEmpty) {
      expandedZoneContent.add(ExpandedZoneText(data.titleHTML));
    }
    
    // Add status flags
    if (data.statusFlags.isNotEmpty) {
      expandedZoneContent.add(FlagSummary(data.statusFlags));
    }
    
    return ScreenConfig(
      entity: data.toEntityConfig(context, ref),
      tabs: data.tabs(
        context,
        ref,
        linkedPRsSliverBuilder: linkedPRsSliverBuilder,
        commentsSince: commentsSince,
        scrollToCommentId: scrollToCommentId,
      ),
      onRefresh: () async => onRefresh(),
      expandedZoneContent: expandedZoneContent,
      screenInlineControls: (ctx, r) => [
        bookmarkDockPill(
          ref: r,
          entityRef: issueRef,
          snapshot: data.toSnapshot(),
          contextRepo: issueRef.repo,
        ),
      ],
    );
  }
}
