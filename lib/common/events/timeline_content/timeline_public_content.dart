import 'package:diohub/common/misc/repository_card.dart';
import 'package:flutter/material.dart';

/// Simple timeline content for PublicEvent
class TimelinePublicContent extends StatelessWidget {
  const TimelinePublicContent({
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

