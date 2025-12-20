import 'package:diohub/common/misc/repository_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
          if (refType != 'repository' && refName != null) ...[
            // Show ref info for branch/tag
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    refType == 'branch' ? Octicons.git_branch : Octicons.tag,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      refName!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Repository card - pass branch so it shows in the card
          RepoCardLoading(
            repoUrl,
            repoName,
            branch: refType != 'repository' && refName != null ? refName : null,
            refresh: false,
          ),
        ],
    );
  }
}
