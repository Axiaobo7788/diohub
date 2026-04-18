import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/cards/popups/popup_chip_template.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/mutation_action_card.dart';
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/common/cards/issue_pull_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/profile_card.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' as gql;
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/users/profile_card_input.dart'
    show FragmentUser, ProfileCardInputUser;
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

Widget buildLabelsPopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final List<CardLabel> labels,
}) {
  final AppSpacing spacing = context.spacing;
  return PopupContentTemplate(
    context,
    children: <Widget>[
      Wrap(
        spacing: spacing.tightSpacing,
        runSpacing: spacing.tightSpacing,
        children: labels
            .map(
              (final CardLabel label) => InkWell(
                onTap: () {
                  ProviderScope.containerOf(
                    context,
                  ).read(clipboardServiceProvider).copy(label.name);
                  onDismiss();
                },
                borderRadius: context.radius(RadiusSize.small),
                child: IssueLabel.fromNameColor(label.name, label.color),
              ),
            )
            .toList(),
      ),
    ],
    onDismiss: onDismiss,
  );
}

/// Builds popup content for checks status: enlarged icon + descriptive text; optional "View Checks" action.

Widget buildChecksPopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final CardChecksState state,
  final VoidCallback? onViewChecks,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final Color color;
  final IconData icon;
  final String text;
  switch (state) {
    case CardChecksState.success:
      color = DiffColors.addition;
      icon = Octicons.check_circle;
      text = 'All checks have passed';
      break;
    case CardChecksState.failure:
      color = DiffColors.deletion;
      icon = Octicons.x_circle;
      text = 'Some checks were not successful';
      break;
    case CardChecksState.error:
      color = DiffColors.deletion;
      icon = Octicons.alert;
      text = 'There was an error running checks';
      break;
    case CardChecksState.pending:
      color = DiffColors.modified;
      icon = Octicons.clock;
      text = 'Checks are still running';
      break;
    case CardChecksState.expected:
      color = DiffColors.modified;
      icon = Octicons.clock;
      text = 'Checks are expected';
      break;
  }
  return PopupContentTemplate(
    context,
    children: <Widget>[
      Row(
        children: <Widget>[
          Icon(icon, size: 20, color: color),
          spacing.compactGap,
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.strong,
              ),
            ),
          ),
        ],
      ),
    ],
    actionLabel: 'View Checks',
    onAction: onViewChecks,
    onDismiss: onDismiss,
  );
}

/// Shows the assignees bottom sheet from [assigneeNodes] (issue/PR card fragment).
/// Renders [ProfileCard] for User/Org and a minimal row for Bot/Mannequin.

void showAssigneesSheet(
  final BuildContext context, {
  required final Iterable<Object?> assigneeNodes,
}) {
  final AppSpacing spacing = context.spacing;
  final List<Object?> list = assigneeNodes.toList();
  AppSheet.scrollable<void>(
    context,
    header: AppSheetHeader.text('Assignees'),
    bodyBuilder:
        (
          final BuildContext context,
          final StateSetter setState,
          final ScrollController scrollController,
        ) => Consumer(
          builder: (final BuildContext context, final WidgetRef ref, final _) =>
              ListView.builder(
                padding: spacing.cardContentPadding,
                controller: scrollController,
                itemCount: list.length,
                itemBuilder: (final BuildContext context, final int index) {
                  final Object? node = list[index];
                  if (node == null) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.tightSpacing),
                    child: _assigneeTileFromNode(context, node),
                  );
                },
              ),
        ),
  );
}

/// Renders one assignee node. Assignees are always User; show ProfileCard or minimal row.
Widget _assigneeTileFromNode(final BuildContext context, final Object node) {
  if (node is gql.UserCardData) {
    return BorderedContainer(
      ref: UserRef(login: node.login),
      child: ProfileCard(ProfileCardInputUser(FragmentUser(node))),
    );
  }
  return const SizedBox.shrink();
}

/// One list item for the tracked issues sheet: loads issue via [issueDetailProvider] and shows [IssuePullCard] or [IssuePullLoadingCard].

class _TrackedIssueCardItem extends ConsumerWidget {
  const _TrackedIssueCardItem({required this.item});

  final CardTrackedIssue item;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final IssueRef issueRef = IssueRef(
      repo: RepoRef(owner: item.repoOwner, name: item.repoName),
      number: item.number,
    );
    final AsyncValue<IssueInfo> asyncIssue = ref.watch(
      issueDetailProvider(issueRef),
    );
    return AsyncValueBuilder<IssueInfo>(
      value: asyncIssue,
      skeleton: (final _) => const IssuePullLoadingCard(),
      error: (final Object e, final StackTrace st) => Padding(
        padding: EdgeInsets.only(bottom: context.spacing.tightSpacing),
        child: TapFeedback(
          onTap: () {
            Navigator.of(context).pop();
            issueRef.navigate(context, ref);
          },
          child: Row(
            children: <Widget>[
              Icon(
                Icons.error_outline,
                color: context.colorScheme.error,
                size: 20,
              ),
              context.spacing.tightGap,
              Expanded(
                child: Text(
                  item.title,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant.secondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      data: (final IssueInfo data) => IssuePullCard.fromIssue(data),
    );
  }
}

/// Shows the tracked issues bottom sheet using domain [items].

void showTrackedIssuesSheet(
  final BuildContext context, {
  required final int totalCount,
  required final List<CardTrackedIssue> items,
  final VoidCallback? onViewAll,
}) {
  final AppSpacing spacing = context.spacing;
  AppSheet.scrollable<void>(
    context,
    header: AppSheetHeader.text('Tracked Issues ($totalCount)'),
    bodyBuilder:
        (
          final BuildContext context,
          final StateSetter setState,
          final ScrollController scrollController,
        ) => Consumer(
          builder: (final BuildContext context, final WidgetRef ref, final _) {
            final List<Widget> children = <Widget>[
              ...items.map(
                (final CardTrackedIssue item) => Padding(
                  padding: EdgeInsets.only(bottom: spacing.tightSpacing),
                  child: _TrackedIssueCardItem(item: item),
                ),
              ),
            ];
            if (totalCount > 10 && onViewAll != null) {
              children.add(spacing.itemGap);
              children.add(
                TapFeedback(
                  onTap: () {
                    Navigator.of(context).pop();
                    onViewAll.call();
                  },
                  child: Padding(
                    padding: spacing.chipPadding,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Octicons.link_external,
                          size: 14,
                          color: context.colorScheme.primary,
                        ),
                        spacing.tightGap,
                        Text(
                          'View all tracked issues',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: context.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListView(
              padding: spacing.cardContentPadding,
              controller: scrollController,
              children: children,
            );
          },
        ),
  );
}

/// Builds popup content for author: avatar 32px + login; "View Profile" action.

Widget buildSubIssuePopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final int completed,
  required final int total,
  final double? percentCompleted,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final int completedClamped = completed.clamp(0, total);
  final double progress = total > 0 ? completedClamped / total : 0.0;
  final int pct = percentCompleted != null
      ? (percentCompleted * 100).round()
      : (total > 0 ? (completedClamped * 100 / total).round() : 0);
  return PopupContentTemplate(
    context,
    children: <Widget>[
      Row(
        children: <Widget>[
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: progress,
              color: DiffColors.addition,
              backgroundColor: cs.onSurfaceVariant.subtle,
              strokeWidth: 2.5,
              strokeCap: StrokeCap.round,
            ),
          ),
          spacing.compactGap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '$completed of $total sub-issues completed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.strong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                spacing.compactGap,
                Text(
                  '$pct%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
    onDismiss: onDismiss,
  );
}

/// Builds popup content for a milestone chip: title row, progress bar, issue counts, description, "View Milestone" action.
/// Uses cardContentPadding, compactGap, itemGap from context spacing.

Widget buildMilestonePopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final String title,
  final VoidCallback? onViewMilestone,
  final String? dueDate,
  final double? progress,
  final String? description,
  final int? openIssues,
  final int? closedIssues,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;

  final List<Widget> children = <Widget>[
    Row(
      children: <Widget>[
        Icon(Octicons.milestone, size: 16, color: cs.primary),
        spacing.compactGap,
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (dueDate != null) TimestampLabel(date: dueDate),
      ],
    ),
    spacing.compactGap,
  ];
  if (progress != null) {
    children.addAll(<Widget>[
      ClipRRect(
        borderRadius: context.radius(RadiusSize.soft),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 4,
          backgroundColor: cs.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
        ),
      ),
      if (description != null && description.isNotEmpty) spacing.compactGap,
    ]);
  }
  if (openIssues != null && closedIssues != null) {
    children.addAll(<Widget>[
      if (progress != null) spacing.compactGap,
      Text(
        '$openIssues open / $closedIssues closed',
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant.secondary,
        ),
      ),
      spacing.compactGap,
    ]);
  }
  if (description != null && description.isNotEmpty) {
    children.add(
      Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant.secondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
  return PopupContentTemplate(
    context,
    children: children,
    actionLabel: 'View Milestone',
    onAction: onViewMilestone,
    onDismiss: onDismiss,
  );
}

/// Tracked issues are shown via [showTrackedIssuesSheet]; no popup content builder.

/// One language for the language distribution popup: name, optional hex color, byte size.

Widget buildDiffPopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final int additions,
  required final int deletions,
  required final int changedFiles,
  required final int commitsCount,
  final VoidCallback? onViewChanges,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final int total = additions + deletions;
  final bool hasBar = total > 0;
  final double addFrac = total > 0 ? additions / total : 0.5;
  final List<Widget> children = <Widget>[];
  if (hasBar) {
    children.add(
      Padding(
        padding: EdgeInsets.only(bottom: spacing.tightSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Additions vs deletions',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.secondary,
              ),
            ),
            spacing.tightGap,
            ClipRRect(
              borderRadius: context.radius(RadiusSize.small),
              child: SizedBox(
                height: 8,
                width: double.infinity,
                child: LinearProgressIndicator(
                  value: addFrac,
                  backgroundColor: DiffColors.deletion.withValues(
                    alpha: Opacities.secondary,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DiffColors.addition,
                  ),
                ),
              ),
            ),
            spacing.tightGap,
            Row(
              children: <Widget>[
                Text(
                  '+$additions',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DiffColors.addition,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                spacing.tightGap,
                Text(
                  '−$deletions',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DiffColors.deletion,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  children.add(
    Padding(
      padding: EdgeInsets.only(bottom: spacing.tightSpacing),
      child: Row(
        children: <Widget>[
          Icon(
            Octicons.git_commit,
            size: 14,
            color: cs.onSurfaceVariant.emphasized,
          ),
          spacing.tightGap,
          Text(
            '$commitsCount commit${commitsCount == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.strong,
            ),
          ),
        ],
      ),
    ),
  );
  children.add(
    Padding(
      padding: EdgeInsets.only(bottom: spacing.tightSpacing),
      child: Row(
        children: <Widget>[
          Icon(
            Octicons.file_diff,
            size: 14,
            color: cs.onSurfaceVariant.emphasized,
          ),
          spacing.tightGap,
          Text(
            '$changedFiles file${changedFiles == 1 ? '' : 's'} changed',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.strong,
            ),
          ),
        ],
      ),
    ),
  );
  return PopupContentTemplate(
    context,
    children: children,
    actionLabel: 'View Changes',
    onAction: onViewChanges,
    onDismiss: onDismiss,
  );
}

/// Builds popup content for comments chip: total count, review threads, "View Comments" action.

Widget buildReviewDecisionPopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final List<ReviewReviewerRow> reviewers,
  final VoidCallback? onViewReviews,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final int approvedCount = reviewers
      .where(
        (final ReviewReviewerRow r) => r.stateIcon == Octicons.check_circle,
      )
      .length;
  final int changesRequestedCount = reviewers
      .where(
        (final ReviewReviewerRow r) => r.stateIcon == Icons.edit_note_rounded,
      )
      .length;
  final int total = reviewers.length;
  final String summaryLine = total == 0
      ? 'No reviews'
      : '$approvedCount of $total approved' +
            (changesRequestedCount > 0
                ? ' · $changesRequestedCount requested changes'
                : '');
  return PopupContentTemplate(
    context,
    children: <Widget>[
      Text(
        summaryLine,
        style: theme.textTheme.labelMedium?.copyWith(
          color: cs.onSurfaceVariant.secondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      spacing.tightGap,
      ...reviewers.map((final ReviewReviewerRow r) {
        String? bodyPreview = r.bodyText != null && r.bodyText!.isNotEmpty
            ? (r.bodyText!.split('\n').first.trim())
            : null;
        if (bodyPreview != null && bodyPreview.length > 80) {
          bodyPreview = '${bodyPreview.substring(0, 80)}…';
        }
        final String? relativeTime = r.submittedAt != null
            ? () {
                try {
                  return DateTime.parse(
                    r.submittedAt!,
                  ).toRelativeDate(shorten: false);
                } catch (e, st) {
                  AppLogger.warning(
                    'Popup chip: invalid submittedAt date',
                    error: e,
                    stackTrace: st,
                    tag: 'popup_chip_builders',
                  );
                  return null;
                }
              }()
            : null;
        return Padding(
          padding: EdgeInsets.only(bottom: spacing.tightSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  UserAvatar(avatarUrl: r.avatarUrl, size: 24),
                  spacing.tightGap,
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            r.login,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.strong,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (r.authorAssociation != null &&
                            r.authorAssociation!.isNotEmpty &&
                            const {'MEMBER', 'COLLABORATOR', 'OWNER'}.contains(
                              r.authorAssociation!.toUpperCase(),
                            )) ...<Widget>[
                          spacing.tightGap,
                          AuthorAssociationBadge(
                            association: r.authorAssociation!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    r.stateIcon,
                    size: 14,
                    color: r.stateColor ?? cs.onSurfaceVariant,
                  ),
                ],
              ),
              if (r.teamName != null && r.teamName!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: spacing.tightSpacing * 0.5),
                  child: Row(
                    children: <Widget>[
                      if (r.teamAvatarUrl != null)
                        Padding(
                          padding: EdgeInsets.only(right: spacing.tightSpacing),
                          child: UserAvatar(
                            avatarUrl: r.teamAvatarUrl,
                            size: 16,
                          ),
                        ),
                      Expanded(
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant.muted,
                            ),
                            children: <TextSpan>[
                              const TextSpan(text: 'on behalf of '),
                              TextSpan(
                                text: r.teamName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (bodyPreview != null && bodyPreview.isNotEmpty) ...<Widget>[
                spacing.tightGap,
                Text(
                  bodyPreview,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.secondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (relativeTime != null) ...<Widget>[
                spacing.tightGap,
                Text(
                  relativeTime,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.muted,
                  ),
                ),
              ],
              if (r.inlineCommentCount > 0) ...<Widget>[
                spacing.tightGap,
                Row(
                  children: <Widget>[
                    Icon(
                      Octicons.comment_discussion,
                      size: 12,
                      color: cs.onSurfaceVariant.muted,
                    ),
                    spacing.tightGap,
                    Text(
                      '${r.inlineCommentCount} comment${r.inlineCommentCount == 1 ? '' : 's'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }),
    ],
    actionLabel: 'View Reviews',
    onAction: onViewReviews,
    onDismiss: onDismiss,
  );
}

/// Builds popup content for fork chip: parent repo name, owner, optional star count, description + "View Repository" action.

void buildCIChecksBottomSheet(
  final BuildContext context, {
  required final RepoRef repoRef,
  required final List<CICheckRunRowData> runs,
}) {
  final AppSpacing spacing = context.spacing;
  final Set<int> uniqueSuiteIds = runs
      .where((final CICheckRunRowData r) => r.checkSuiteDatabaseId != null)
      .map((final CICheckRunRowData r) => r.checkSuiteDatabaseId!)
      .toSet();
  AppSheet.scrollable<void>(
    context,
    header: AppSheetHeader.text('CI Checks'),
    bodyBuilder:
        (
          final BuildContext context,
          final StateSetter setState,
          final ScrollController scrollController,
        ) => ListView(
          controller: scrollController,
          padding: spacing.cardContentPadding,
          children: <Widget>[
            if (uniqueSuiteIds.isNotEmpty) ...[
              Wrap(
                spacing: spacing.compactSpacing,
                runSpacing: spacing.tightSpacing,
                children: uniqueSuiteIds
                    .map(
                      (final int suiteId) => Consumer(
                        builder:
                            (
                              final BuildContext context,
                              final WidgetRef ref,
                              final Widget? child,
                            ) => MutationActionCard(
                              action: const MinorActionButton(
                                icon: Icons.refresh_rounded,
                                label: 'Re-request',
                              ),
                              onTap: () async {
                                await repoRef
                                    .services(ref.read(apiClientProvider))
                                    .rerequestCheckSuite(checkSuiteId: suiteId);
                              },
                              confirmTitle: 'Re-request check suite?',
                              confirmExplanation:
                                  'This will trigger all check runs in this suite '
                                  'to run again.',
                            ),
                      ),
                    )
                    .toList(),
              ),
              spacing.sectionGap,
            ],
            CIChecksList(runs: runs),
          ],
        ),
  );
}

/// Bottom sheet with reviewer coverage rows; each row tappable to profile.

void buildReviewersBottomSheet(
  final BuildContext context, {
  required final List<ReviewCoverageRowData> rows,
}) {
  final AppSpacing spacing = context.spacing;
  AppSheet.scrollable<void>(
    context,
    header: AppSheetHeader.text('Reviewers'),
    bodyBuilder:
        (
          final BuildContext context,
          final StateSetter setState,
          final ScrollController scrollController,
        ) => ListView(
          controller: scrollController,
          padding: spacing.cardContentPadding,
          children: <Widget>[ReviewCoverageSummary(rows: rows)],
        ),
  );
}
