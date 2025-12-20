import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/timeline/timeline_container.dart';
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
    final theme = Theme.of(context);

    return TimelineContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Source repo
          Text(
            'From',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          RepoCardLoading(
            sourceRepoUrl,
            sourceRepoName,
            refresh: false,
          ),
          const SizedBox(height: 12),
          // Fork destination
          Text(
            'To',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          RepoCardLoading(
            forkRepoUrl,
            forkRepoName,
            refresh: false,
          ),
        ],
      ),
    );
  }
}
