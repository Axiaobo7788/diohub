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
  final String? ref; // Commit SHA from PushEvent payload.head (latest commit)
  final String?
      userLogin; // Optional, not currently used but kept for compatibility
  final String?
      userEmail; // Optional, not currently used but kept for compatibility

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show repository cards - use data if available, otherwise fetch
        // Branch name and commit SHA are passed to both RepositoryCard and RepoCardLoading
        // to display the branch and commit SHA in the repository card
        ...commitData.repositories.map((repoInfo) {
          // Construct commit SHA URL from repository URL and commit SHA
          String? commitShaUrl;
          if (ref != null && repoInfo.url.isNotEmpty) {
            // Construct commit URL: https://github.com/owner/repo/commit/{sha}
            final repoUrl = repoInfo.url;
            commitShaUrl = '$repoUrl/commit/$ref';
          }

          // If repoData is available (from GraphQL), use it directly
          // Otherwise fall back to RepoCardLoading (for REST API events)
          if (repoInfo.repoData != null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RepositoryCard(
                repoInfo.repoData,
                branch: branchName, // Branch name from PushEvent payload.ref
                commitSha: ref, // Commit SHA from PushEvent payload.head
                commitShaUrl: commitShaUrl,
                contributionCount: repoInfo.count, // Commit count for this repository
              ),
            );
          } else {
            // Fallback: fetch if data is missing (REST API events)
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RepoCardLoading(
                repoInfo.url,
                repoInfo.name,
                branch: branchName, // Branch name from PushEvent payload.ref
                commitSha: ref, // Commit SHA from PushEvent payload.head
                commitShaUrl: commitShaUrl,
                refresh: false,
              ),
            );
          }
        }),
      ],
    );
  }
}
