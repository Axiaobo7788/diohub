import 'package:diohub/common/misc/repository_card.dart';
import 'package:flutter/material.dart';

/// Simple timeline content for DeleteEvent
class TimelineDeleteContent extends StatelessWidget {
  const TimelineDeleteContent({
    required this.refType,
    required this.refName,
    required this.repoName,
    required this.repoUrl,
    super.key,
  });

  final String refType; // 'branch', 'tag'
  final String refName;
  final String repoName;
  final String repoUrl;

  @override
  Widget build(BuildContext context) {
    return RepoCardLoading(
      repoUrl,
      repoName,
      branch: refName.isNotEmpty ? refName : null,
      branchColor: refType == 'branch'
          ? const Color(0xFFE57373) // Lighter red for deleted branches
          : null,
      branchStrikethrough: refType == 'branch',
      refresh: false,
    );
  }
}

