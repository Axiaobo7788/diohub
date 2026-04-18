import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/misc/liquid_glass_wrapper.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart' show Placement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

Widget PopupContentTemplate(
  final BuildContext context, {
  required final List<Widget> children,
  final String? actionLabel,
  final VoidCallback? onAction,
  final VoidCallback? onDismiss,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final List<Widget> columnChildren = <Widget>[...children];
  if (actionLabel != null) {
    columnChildren.add(spacing.itemGap);
    columnChildren.add(
      TapFeedback(
        onTap: () {
          onAction?.call();
          onDismiss?.call();
        },
        size: RadiusSize.small,
        child: Padding(
          padding: spacing.chipPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Octicons.link_external, size: 14, color: cs.primary),
              spacing.tightGap,
              Text(
                actionLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  return LiquidGlassWrapper(
    size: RadiusSize.large,
    child: Padding(
      padding: spacing.cardContentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columnChildren,
      ),
    ),
  );
}

/// Tappable row for multi-action popups. Calls [action] then [dismiss].
Widget _popupActionRow(
  final BuildContext context, {
  required final IconData icon,
  required final String label,
  required final VoidCallback action,
  required final VoidCallback dismiss,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  return TapFeedback(
    onTap: () {
      action();
      dismiss();
    },
    size: RadiusSize.small,
    child: Padding(
      padding: spacing.chipPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: cs.primary),
          spacing.tightGap,
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds popup content for reactions: one row per reaction group (emoji 20px + count + check if viewer reacted).
Widget buildReactionPopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final List<CardReactionGroup> reactionGroups,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final List<CardReactionGroup> nonZero =
      reactionGroups.where((final CardReactionGroup g) => g.count > 0).toList();
  if (nonZero.isEmpty) {
    return PopupContentTemplate(
      context,
      children: <Widget>[
        Text(
          'No reactions',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant.secondary,
          ),
        ),
      ],
      onDismiss: onDismiss,
    );
  }
  nonZero.sort(
    (final CardReactionGroup a, final CardReactionGroup b) =>
        b.count.compareTo(a.count),
  );
  final List<Widget> rows = nonZero.map((final CardReactionGroup g) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.tightSpacing),
      child: Row(
        children: <Widget>[
          Text(
            g.emoji,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 20),
          ),
          spacing.tightGap,
          Text(
            '${g.count}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.strong,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (g.viewerHasReacted) ...<Widget>[
            spacing.tightGap,
            TintedChip(
              color: cs.primary,
              icon: Octicons.check,
              label: null,
              iconSize: 12,
              padding: spacing.badgePadding,
            ),
          ],
        ],
      ),
    );
  }).toList();
  return PopupContentTemplate(
    context,
    children: rows,
    onDismiss: onDismiss,
  );
}

/// Builds popup content for labels: Wrap of [IssueLabel] chips. Tap copies label name.

Widget buildAuthorPopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final String login,
  final String? avatarUrl,
  final VoidCallback? onViewProfile,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  return PopupContentTemplate(
    context,
    children: <Widget>[
      Row(
        children: <Widget>[
          UserAvatar(
            avatarUrl: avatarUrl,
            size: 32,
          ),
          spacing.compactGap,
          Expanded(
            child: Text(
              login,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface.strong,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ],
    actionLabel: 'View Profile',
    onAction: onViewProfile,
    onDismiss: onDismiss,
  );
}

Widget buildCommentsPopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final int commentsCount,
  required final int reviewThreadsCount,
  final VoidCallback? onViewComments,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  return PopupContentTemplate(
    context,
    children: <Widget>[
      Row(
        children: <Widget>[
          Icon(Octicons.comment,
              size: 14, color: cs.onSurfaceVariant.emphasized),
          spacing.tightGap,
          Text(
            '$commentsCount comment${commentsCount == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.strong,
            ),
          ),
        ],
      ),
      if (reviewThreadsCount > 0) ...<Widget>[
        spacing.tightGap,
        Row(
          children: <Widget>[
            Icon(Octicons.code_review,
                size: 14, color: cs.onSurfaceVariant.emphasized),
            spacing.tightGap,
            Text(
              '$reviewThreadsCount review thread${reviewThreadsCount == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.secondary,
              ),
            ),
          ],
        ),
      ],
    ],
    actionLabel: 'View Comments',
    onAction: onViewComments,
    onDismiss: onDismiss,
  );
}

/// Popup content for a branch reference: branch name + icon, with actions.
Widget buildBranchPopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final String branchName,
  required final RepoRef repoRef,
  final VoidCallback? onBrowseFiles,
  final VoidCallback? onViewCommits,
  final VoidCallback? onCompare,
  final VoidCallback? onCopy,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final List<Widget> children = <Widget>[
    Row(
      children: <Widget>[
        Icon(Octicons.git_branch, size: 16, color: cs.primary),
        spacing.compactGap,
        Expanded(
          child: Text(
            branchName,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: cs.onSurface.strong,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    spacing.itemGap,
  ];
  if (onBrowseFiles != null) {
    children.add(_popupActionRow(
      context,
      icon: Octicons.file_code,
      label: 'Browse files at branch',
      action: onBrowseFiles,
      dismiss: onDismiss,
    ));
  }
  if (onViewCommits != null) {
    children.add(_popupActionRow(
      context,
      icon: Octicons.git_commit,
      label: 'View commits',
      action: onViewCommits,
      dismiss: onDismiss,
    ));
  }
  if (onCompare != null) {
    children.add(_popupActionRow(
      context,
      icon: Octicons.git_compare,
      label: 'Compare…',
      action: onCompare,
      dismiss: onDismiss,
    ));
  }
  if (onCopy != null) {
    children.add(_popupActionRow(
      context,
      icon: Octicons.copy,
      label: 'Copy branch name',
      action: onCopy,
      dismiss: onDismiss,
    ));
  }
  return PopupContentTemplate(
    context,
    children: children,
    onDismiss: onDismiss,
  );
}

/// Popup content for a commit SHA: abbreviated OID + actions.
Widget buildCommitPopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final String abbreviatedOid,
  required final String fullOid,
  required final RepoRef repoRef,
  final VoidCallback? onViewCommit,
  final VoidCallback? onBrowseFiles,
  final VoidCallback? onCompareWithParent,
  final VoidCallback? onCopySha,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final List<Widget> children = <Widget>[
    Row(
      children: <Widget>[
        Icon(Octicons.git_commit, size: 16, color: cs.primary),
        spacing.compactGap,
        Text(
          abbreviatedOid,
          style: theme.textTheme.labelMedium?.copyWith(
            fontFamily: 'monospace',
            color: cs.onSurface.strong,
          ),
        ),
      ],
    ),
    spacing.itemGap,
  ];
  if (onViewCommit != null) {
    children.add(_popupActionRow(
      context,
      icon: Octicons.eye,
      label: 'View commit details',
      action: onViewCommit,
      dismiss: onDismiss,
    ));
  }
  if (onBrowseFiles != null) {
    children.add(_popupActionRow(
      context,
      icon: Octicons.file_code,
      label: 'Browse files at this commit',
      action: onBrowseFiles,
      dismiss: onDismiss,
    ));
  }
  if (onCompareWithParent != null) {
    children.add(_popupActionRow(
      context,
      icon: Octicons.git_compare,
      label: 'Compare with parent',
      action: onCompareWithParent,
      dismiss: onDismiss,
    ));
  }
  if (onCopySha != null) {
    children.add(_popupActionRow(
      context,
      icon: Octicons.copy,
      label: 'Copy full SHA',
      action: onCopySha,
      dismiss: onDismiss,
    ));
  }
  return PopupContentTemplate(
    context,
    children: children,
    onDismiss: onDismiss,
  );
}

/// Popup content for a tag reference: tag name + actions.
Widget buildTagPopupContent(
  final BuildContext context, {
  required final VoidCallback onDismiss,
  required final String tagName,
  required final RepoRef repoRef,
  final VoidCallback? onBrowseFiles,
  final VoidCallback? onCompareWithPrevious,
  final VoidCallback? onCopy,
}) {
  final AppSpacing spacing = context.spacing;
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = context.colorScheme;
  final List<Widget> children = <Widget>[
    Row(
      children: <Widget>[
        Icon(Octicons.tag, size: 16, color: cs.primary),
        spacing.compactGap,
        Expanded(
          child: Text(
            tagName,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: cs.onSurface.strong,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    spacing.itemGap,
  ];
  if (onBrowseFiles != null) {
    children.add(_popupActionRow(
      context,
      icon: Octicons.file_code,
      label: 'Browse files at tag',
      action: onBrowseFiles,
      dismiss: onDismiss,
    ));
  }
  if (onCompareWithPrevious != null) {
    children.add(_popupActionRow(
      context,
      icon: Octicons.git_compare,
      label: 'Compare with previous',
      action: onCompareWithPrevious,
      dismiss: onDismiss,
    ));
  }
  if (onCopy != null) {
    children.add(_popupActionRow(
      context,
      icon: Octicons.copy,
      label: 'Copy tag name',
      action: onCopy,
      dismiss: onDismiss,
    ));
  }
  return PopupContentTemplate(
    context,
    children: children,
    onDismiss: onDismiss,
  );
}

/// Self-navigating author label with popup.
/// Tap → show popup. Long-press → popup. Popup has "View Profile" → user profile.
class InteractiveAuthorLabel extends ConsumerWidget {
  const InteractiveAuthorLabel({
    required this.login,
    this.avatarUrl,
    super.key,
  });

  final String login;
  final String? avatarUrl;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return PopupButton(
      placement: Placement.bottom,
      buttonBuilder: (final BuildContext c, final VoidCallback show) =>
          GestureDetector(
        onTap: show,
        child: AuthorLabel(login: login, avatarUrl: avatarUrl),
      ),
      popupBuilder: (final BuildContext c, final VoidCallback onDismiss) =>
          buildAuthorPopupContent(
        context,
        onDismiss: onDismiss,
        login: login,
        avatarUrl: avatarUrl,
        onViewProfile: () => UserRef(login: login).navigate(context, ref),
      ),
    );
  }
}

/// Self-navigating repo label. Tap → navigate to repo.
class InteractiveRepoLabel extends ConsumerWidget {
  const InteractiveRepoLabel({required this.repo, super.key});

  final RepoRef repo;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return TapFeedback(
      onTap: () => repo.navigate(context, ref),
      child: RepoNameLabel(repo: repo),
    );
  }
}
