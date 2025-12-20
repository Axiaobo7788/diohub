import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/timeline/timeline_container.dart';
import 'package:diohub/models/commits/commit_card_data_model.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:flutter/material.dart';

/// Unified timeline content for commit/push events
class TimelineCommitContent extends StatelessWidget {
  const TimelineCommitContent({
    required this.commitData,
    this.userLogin,
    this.userEmail,
    super.key,
  });

  final CommitCardDataModel commitData;
  final String?
      userLogin; // Optional, not currently used but kept for compatibility
  final String?
      userEmail; // Optional, not currently used but kept for compatibility

  @override
  Widget build(BuildContext context) {
    return TimelineContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show repository cards for each repo
          ...commitData.repositories.map((repoInfo) {
            // Use existing repoData if available, otherwise create from basic info
            final repoCardData = repoInfo.repoData ??
                RepoCardDataModel(
                  name: repoInfo.name,
                  url: repoInfo.url,
                );

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RepositoryCard(
                repoCardData,
                contributionCount: repoInfo.count, // Commit count
                withBackground: false,
              ),
            );
          }),
        ],
      ),
    );
  }
}
