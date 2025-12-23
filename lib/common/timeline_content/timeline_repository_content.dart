import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/models/repositories/repo_card_data_model.dart';
import 'package:flutter/material.dart';

/// Unified content for repository creation events in timeline
class TimelineRepositoryContent extends StatelessWidget {
  const TimelineRepositoryContent({
    required this.repoData,
    super.key,
  });

  final RepoCardDataModel repoData;

  @override
  Widget build(BuildContext context) {
    return RepositoryCard(
      repoData,
      withBackground: false,
    );
  }
}
