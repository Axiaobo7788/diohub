import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Data for one suggested reviewer (from [suggestedReviewers] on PullRequest).
class SuggestedReviewerData {
  const SuggestedReviewerData({
    required this.id,
    required this.login,
    required this.avatarUrl,
    this.name,
    this.isAuthor = false,
    this.isCommenter = false,
  });

  final String id;
  final String login;
  final String avatarUrl;
  final String? name;
  final bool isAuthor;
  final bool isCommenter;
}

/// "Suggested" section for the review request sheet: avatars + names,
/// tappable to add the reviewer to the selection.
class SuggestedReviewersSection extends StatelessWidget {
  const SuggestedReviewersSection({
    super.key,
    required this.suggested,
    required this.selectedNodeIds,
    required this.onToggle,
  });

  final List<SuggestedReviewerData> suggested;
  final Set<String> selectedNodeIds;
  final void Function(String nodeId) onToggle;

  @override
  Widget build(final BuildContext context) {
    if (suggested.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Suggested',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.compactSpacing),
          Wrap(
            spacing: spacing.compactSpacing,
            runSpacing: spacing.compactSpacing,
            children: suggested.map((s) {
              final isSelected = selectedNodeIds.contains(s.id);
              return GestureDetector(
                onTap: () => onToggle(s.id),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.chipPadding.horizontal,
                    vertical: spacing.chipPadding.vertical,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      UserAvatar(
                        avatarUrl: s.avatarUrl,
                        size: 24,
                      ),
                      SizedBox(width: spacing.tightSpacing),
                      Text(
                        s.name ?? s.login,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
