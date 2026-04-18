import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Builds the pinned issues section for the README/overview tab.
Widget? buildPinnedIssuesSection(
  BuildContext context,
  WidgetRef ref,
  RepoPinnedIssues pinnedIssues,
  RepoRef repoRef,
) {
  final nodes = pinnedIssues.nodes;
  if (nodes == null || nodes.isEmpty) return null;
  final spacing = context.spacing;
  final theme = Theme.of(context);
  return Padding(
    padding: EdgeInsets.fromLTRB(
      spacing.pagePadding.left,
      spacing.listInset.top,
      spacing.pagePadding.right,
      spacing.compactSpacing,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Pinned',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.compactSpacing),
        ...nodes.whereType<RepoPinnedIssueNode>().map(
          (node) {
            final issue = node.issue;
            final issueRef = IssueRef(
              repo: repoRef,
              number: issue.number,
            );
            return Padding(
              padding: EdgeInsets.only(bottom: spacing.compactSpacing),
              child: InkWell(
                onTap: () => issueRef.navigate(context, ref),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: spacing.metadataRowPadding,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        issue.state.name == 'OPEN'
                            ? Octicons.issue_opened
                            : Octicons.issue_closed,
                        size: 16,
                        color: issue.state.name == 'OPEN'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                      ),
                      SizedBox(width: spacing.tightSpacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '#${issue.number}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              issue.title,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}
