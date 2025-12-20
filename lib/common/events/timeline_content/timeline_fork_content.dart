import 'package:diohub/common/misc/repository_card.dart';
import 'package:flutter/material.dart';

/// Simple timeline content for ForkEvent
class TimelineForkContent extends StatelessWidget {
  const TimelineForkContent({
    required this.sourceRepoName,
    required this.sourceRepoUrl,
    required this.forkRepoName,
    required this.forkRepoUrl,
    super.key,
  });

  final String sourceRepoName;
  final String sourceRepoUrl;
  final String forkRepoName;
  final String forkRepoUrl;

  @override
  Widget build(BuildContext context) {
    return RepoCardLoading(
      forkRepoUrl,
      forkRepoName,
      refresh: false,
    );
  }
}
