import 'package:diohub/common/misc/repository_card.dart';
import 'package:flutter/material.dart';

/// Simple timeline content for CreateEvent (repo/branch/tag)
class TimelineCreateContent extends StatelessWidget {
  const TimelineCreateContent({
    required this.refType,
    required this.repoName,
    required this.repoUrl,
    this.refName,
    super.key,
  });

  final String refType; // 'repository', 'branch', 'tag'
  final String repoName;
  final String repoUrl;
  final String? refName;

  @override
  Widget build(BuildContext context) {
    return RepoCardLoading(
      repoUrl,
      repoName,
      branch: refType != 'repository' && refName != null ? refName : null,
      branchColor: refType == 'branch'
          ? const Color(0xFF66BB6A) // Lighter green for created branches
          : null,
      refresh: false,
    );
  }
}
