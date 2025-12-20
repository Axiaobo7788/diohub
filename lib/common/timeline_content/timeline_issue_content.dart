import 'package:diohub/common/issues/issue_list_card.dart';
import 'package:diohub/common/markdown_view/trimmable_markdown_content.dart';
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:flutter/material.dart';

/// Simple card content for issue events in timeline
/// Supports optional comment body for IssueCommentEvent
class TimelineIssueContent extends StatelessWidget {
  const TimelineIssueContent({
    required this.issueData,
    this.commentBody,
    this.commentsSince,
    super.key,
  });

  final IssueCardDataModel issueData;
  final String?
      commentBody; // For IssueCommentEvent - shows comment instead of issue body
  final DateTime? commentsSince; // Used to show comment count since this time

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
          // Issue card (without description for timeline)
          IssueListCard(
            issueData,
            showRepoName: true,
            showDescription: false,
            commentsSince: commentsSince,
          ),

          // Show comment body if provided (IssueCommentEvent)
          // Otherwise show issue description
          if (commentBody != null && commentBody!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TrimmableMarkdownContent(
                text: commentBody!.trim(),
                repo: issueData.repositoryName,
              ),
            ),
          ] else if (issueData.body != null &&
              issueData.body!.trim().isNotEmpty &&
              commentsSince == null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TrimmableMarkdownContent(
                text: issueData.body!.trim(),
                repo: issueData.repositoryName,
              ),
            ),
          ],
        ],
    );
  }
}
