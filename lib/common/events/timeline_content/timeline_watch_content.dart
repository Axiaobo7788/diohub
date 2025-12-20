import 'package:diohub/common/misc/repository_card.dart';
import 'package:flutter/material.dart';

/// Simple timeline content for WatchEvent (star)
class TimelineWatchContent extends StatelessWidget {
  const TimelineWatchContent({
    required this.repoName,
    required this.repoUrl,
    super.key,
  });

  final String repoName;
  final String repoUrl;

  @override
  Widget build(BuildContext context) {
    return RepoCardLoading(
      repoUrl,
      repoName,
      refresh: false,
    );
  }
}
