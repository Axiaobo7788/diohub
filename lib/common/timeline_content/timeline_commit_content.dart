import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/models/commits/commit_card_data_model.dart';
import 'package:flutter/material.dart';

/// Unified timeline content for commit/push events
class TimelineCommitContent extends StatelessWidget {
  const TimelineCommitContent({
    required this.commitData,
    this.branchName,
    this.ref,
    this.userLogin,
    this.userEmail,
    super.key,
  });

  final CommitCardDataModel commitData;
  final String?
      branchName; // Branch name from PushEvent payload.ref (for RepoCardLoading)
  final String? ref; // Full ref string (e.g., "refs/heads/main") for display
  final String?
      userLogin; // Optional, not currently used but kept for compatibility
  final String?
      userEmail; // Optional, not currently used but kept for compatibility

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Commit count text with ref
        if (commitData.count > 0) ...[
          Text(
            '${commitData.count} commit${commitData.count > 1 ? 's' : ''}${ref != null ? ' to $ref' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Show repository cards for each repo - use RepoCardLoading to fetch full data
        // Branch is already shown in the repo card when passed
        ...commitData.repositories.map((repoInfo) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RepoCardLoading(
              repoInfo.url,
              repoInfo.name,
              branch: branchName, // Branch name (will be shown in card)
              refresh: false,
            ),
          );
        }),
      ],
    );
  }
}
