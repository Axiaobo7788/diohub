import 'package:diohub/common/misc/repository_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

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
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Deleted ref info - only show for non-branch deletions
        if (refType != 'branch') ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Octicons.tag,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    refName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                Icon(
                  Octicons.trash,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Repository card
        RepoCardLoading(
          repoUrl,
          repoName,
          branch: refName.isNotEmpty ? refName : null,
          branchColor: refType == 'branch'
              ? const Color(0xFFE57373) // Lighter red for deleted branches
              : null,
          branchStrikethrough: refType == 'branch',
          refresh: false,
        ),
      ],
    );
  }
}

