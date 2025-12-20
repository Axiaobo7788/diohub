import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/timeline/timeline_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

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
    final theme = Theme.of(context);
    
    return TimelineContainer(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Public notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Octicons.globe,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Repository is now public',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Repository card
        RepoCardLoading(
          repoUrl,
          repoName,
          refresh: false,
        ),
      ],
      ),
    );
  }
}

