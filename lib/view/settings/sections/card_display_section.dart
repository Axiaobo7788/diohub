import 'package:diohub/app/settings/card_display.dart';
import 'package:diohub/common/cards/branch_refs.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/misc/contextual_preview.dart';
import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/common/misc/settings_toggle.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Card Display section: toggles for body preview, reactions, project chips,
/// branch refs, diff distribution, and repo/timeline options. Preview shows
/// mock PR and repo cards that update live.
class CardDisplaySection extends ConsumerWidget {
  const CardDisplaySection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final cardDisplay = ref.watch(cardDisplayProvider);
    final notifier = ref.read(cardDisplayProvider.notifier);
    final AppSpacing spacing = context.spacing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ContextualPreview(child: _CardDisplayPreview(settings: cardDisplay)),
        SizedBox(height: spacing.itemSpacing),
        _densityControl(context, cardDisplay, notifier),
        SizedBox(height: spacing.itemSpacing),
        _sectionTitle(context, 'Issue & Pull Request'),
        SettingsGroup(
          children: <Widget>[
            SettingsToggle(
              title: 'Body preview',
              value: cardDisplay.showBodyPreview,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showBodyPreview: v)),
              icon: Icons.short_text,
              subtitle: 'Show issue/PR body text on cards',
            ),
            SettingsToggle(
              title: 'Reactions',
              value: cardDisplay.showReactions,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showReactions: v)),
              icon: Icons.emoji_emotions_outlined,
              subtitle: 'Show emoji reaction summary',
            ),
            SettingsToggle(
              title: 'Project chips',
              value: cardDisplay.showProjectChips,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showProjectChips: v)),
              icon: Octicons.project,
              subtitle: 'Show project board membership',
            ),
            SettingsToggle(
              title: 'Branch references',
              value: cardDisplay.showBranchRefs,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showBranchRefs: v)),
              icon: Octicons.git_branch,
              subtitle: 'Show source → target branch on PRs',
            ),
            SettingsToggle(
              title: 'Diff distribution',
              value: cardDisplay.showDiffDistribution,
              onChanged: (final bool v) => notifier
                  .update((final s) => s.copyWith(showDiffDistribution: v)),
              icon: Octicons.diff,
              subtitle: 'Show additions/deletions bar on PRs',
            ),
            SettingsToggle(
              title: 'Reviewer chip',
              value: cardDisplay.showReviewerChip,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showReviewerChip: v)),
              icon: Icons.people_outline,
              subtitle: 'Show reviewer avatars and state on PRs',
            ),
            SettingsToggle(
              title: 'Labels',
              value: cardDisplay.showLabels,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showLabels: v)),
              icon: Octicons.tag,
              subtitle: 'Show label summary on discussions/PRs',
            ),
            SettingsToggle(
              title: 'Comment count',
              value: cardDisplay.showCommentCount,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showCommentCount: v)),
              icon: Octicons.comment,
              subtitle: 'Show comment count chip',
            ),
            SettingsToggle(
              title: 'Timestamps',
              value: cardDisplay.showTimestamps,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showTimestamps: v)),
              icon: Octicons.clock,
              subtitle: 'Show relative timestamps on cards',
            ),
          ],
        ),
        SizedBox(height: spacing.itemSpacing),
        _sectionTitle(context, 'Repository'),
        SettingsGroup(
          children: <Widget>[
            SettingsToggle(
              title: 'Topics',
              value: cardDisplay.showTopics,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showTopics: v)),
              icon: Octicons.hash,
              subtitle: 'Show topic chips on repo cards',
            ),
            SettingsToggle(
              title: 'Language',
              value: cardDisplay.showRepoLanguage,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showRepoLanguage: v)),
              icon: Octicons.code,
              subtitle: 'Show primary language on repo cards',
            ),
            SettingsToggle(
              title: 'Repo stats',
              value: cardDisplay.showRepoStats,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showRepoStats: v)),
              icon: Octicons.graph,
              subtitle: 'Show forks, stars, issues, PRs on repo cards',
            ),
            SettingsToggle(
              title: 'Default branch',
              value: cardDisplay.showDefaultBranch,
              onChanged: (final bool v) => notifier
                  .update((final s) => s.copyWith(showDefaultBranch: v)),
              icon: Octicons.git_branch,
              subtitle: 'Show default branch when not main/master',
            ),
          ],
        ),
        SizedBox(height: spacing.itemSpacing),
        _sectionTitle(context, 'Indicators'),
        SettingsGroup(
          children: <Widget>[
            SettingsToggle(
              title: 'Time to resolution',
              value: cardDisplay.showTimeToResolution,
              onChanged: (final bool v) => notifier
                  .update((final s) => s.copyWith(showTimeToResolution: v)),
              icon: Octicons.clock,
              subtitle:
                  'Show how long issues/PRs have been open or took to close',
            ),
            SettingsToggle(
              title: 'Author role',
              value: cardDisplay.showAuthorAssociation,
              onChanged: (final bool v) => notifier
                  .update((final s) => s.copyWith(showAuthorAssociation: v)),
              icon: Icons.badge_outlined,
              subtitle:
                  'Show owner/member/contributor badge next to author name',
            ),
            SettingsToggle(
              title: 'Notification priority',
              value: cardDisplay.showNotificationPriority,
              onChanged: (final bool v) => notifier
                  .update((final s) => s.copyWith(showNotificationPriority: v)),
              icon: Icons.priority_high,
              subtitle: 'Color-code notification urgency on the left edge',
            ),
            SettingsToggle(
              title: 'Repository activity',
              value: cardDisplay.showActivityPulse,
              onChanged: (final bool v) => notifier
                  .update((final s) => s.copyWith(showActivityPulse: v)),
              icon: Icons.circle,
              subtitle:
                  'Show activity dot indicating when repo was last pushed',
            ),
            SettingsToggle(
              title: 'Release scope',
              value: cardDisplay.showReleaseScope,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showReleaseScope: v)),
              icon: Octicons.package,
              subtitle: 'Show asset count and downloads on release cards',
            ),
            SettingsToggle(
              title: 'User activity',
              value: cardDisplay.showUserActivity,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showUserActivity: v)),
              icon: Octicons.graph,
              subtitle:
                  'Show contribution sparkline on user cards (may slow large lists)',
            ),
          ],
        ),
        SizedBox(height: spacing.itemSpacing),
        _sectionTitle(context, 'Cross-card'),
        SettingsGroup(
          children: <Widget>[
            SettingsToggle(
              title: 'Checks status',
              value: cardDisplay.showChecksStatus,
              onChanged: (final bool v) =>
                  notifier.update((final s) => s.copyWith(showChecksStatus: v)),
              icon: Octicons.check_circle,
              subtitle: 'Show CI status on commits and PRs',
            ),
          ],
        ),
      ],
    );
  }

  static bool _matchesPreset(final CardDisplaySettings settings) {
    // If maxVisibleChips is overridden, it's custom
    if (settings.maxVisibleChips != null) return false;
    
    // Check if all toggles match the current density preset
    return switch (settings.density) {
      CardDensity.compact => settings.showBodyPreview == false &&
          settings.showReactions == false &&
          settings.showProjectChips == false &&
          settings.showBranchRefs == false &&
          settings.showTopics == false &&
          settings.showActivityPulse == false &&
          settings.showTimeToResolution == false &&
          settings.showAuthorAssociation == false,
      CardDensity.comfortable => settings.showBodyPreview == false &&
          settings.showReactions == true &&
          settings.showProjectChips == true &&
          settings.showBranchRefs == true &&
          settings.showDiffDistribution == true &&
          settings.showReviewerChip == true &&
          settings.showTopics == true &&
          settings.showRepoLanguage == true &&
          settings.showRepoStats == true &&
          settings.showDefaultBranch == true &&
          settings.showChecksStatus == true &&
          settings.showLabels == true &&
          settings.showCommentCount == true &&
          settings.showTimestamps == true &&
          settings.showTimeToResolution == true &&
          settings.showAuthorAssociation == true &&
          settings.showNotificationPriority == true &&
          settings.showActivityPulse == true &&
          settings.showReleaseScope == false &&
          settings.showUserActivity == false,
      CardDensity.detailed => settings.showBodyPreview == true &&
          settings.showReactions == true &&
          settings.showProjectChips == true &&
          settings.showBranchRefs == true &&
          settings.showTopics == true &&
          settings.showActivityPulse == true &&
          settings.showTimeToResolution == true &&
          settings.showAuthorAssociation == true,
    };
  }

  static Widget _densityControl(
    final BuildContext context,
    final CardDisplaySettings cardDisplay,
    final GenericPersistedNotifier<CardDisplaySettings> notifier,
  ) {
    final theme = Theme.of(context);
    
    // Determine if current settings match a preset
    final bool isCustom = !_matchesPreset(cardDisplay);
    final CardDensity currentDensity = cardDisplay.density;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Card Density',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SegmentedButton<CardDensity>(
          segments: const <ButtonSegment<CardDensity>>[
            ButtonSegment<CardDensity>(
              value: CardDensity.compact,
              label: Text('Compact'),
            ),
            ButtonSegment<CardDensity>(
              value: CardDensity.comfortable,
              label: Text('Comfortable'),
            ),
            ButtonSegment<CardDensity>(
              value: CardDensity.detailed,
              label: Text('Detailed'),
            ),
          ],
          selected: <CardDensity>{currentDensity},
          onSelectionChanged: (final Set<CardDensity> selection) {
            final CardDensity selected = selection.first;
            
            // Apply preset: reset toggles and maxVisibleChips based on density
            switch (selected) {
              case CardDensity.compact:
                notifier.update((final s) => s.copyWith(
                  density: CardDensity.compact,
                  maxVisibleChips: null, // Will use default for compact (3)
                  showBodyPreview: false,
                  showReactions: false,
                  showProjectChips: false,
                  showBranchRefs: false,
                  showTopics: false,
                  showActivityPulse: false,
                  showTimeToResolution: false,
                  showAuthorAssociation: false,
                ));
              case CardDensity.comfortable:
                notifier.update((final s) => s.copyWith(
                  density: CardDensity.comfortable,
                  maxVisibleChips: null, // Will use default for comfortable (5)
                  showBodyPreview: false,
                  showReactions: true,
                  showProjectChips: true,
                  showBranchRefs: true,
                  showDiffDistribution: true,
                  showReviewerChip: true,
                  showTopics: true,
                  showRepoLanguage: true,
                  showRepoStats: true,
                  showDefaultBranch: true,
                  showChecksStatus: true,
                  showLabels: true,
                  showCommentCount: true,
                  showTimestamps: true,
                  showTimeToResolution: true,
                  showAuthorAssociation: true,
                  showNotificationPriority: true,
                  showActivityPulse: true,
                  showReleaseScope: false,
                  showUserActivity: false,
                ));
              case CardDensity.detailed:
                notifier.update((final s) => s.copyWith(
                  density: CardDensity.detailed,
                  maxVisibleChips: null, // Will use default for detailed (unlimited)
                  showBodyPreview: true,
                  showReactions: true,
                  showProjectChips: true,
                  showBranchRefs: true,
                  showTopics: true,
                  showActivityPulse: true,
                  showTimeToResolution: true,
                  showAuthorAssociation: true,
                ));
            }
          },
        ),
        if (isCustom)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Custom (manual toggles override preset)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  static Widget _sectionTitle(final BuildContext context, final String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CardDisplayPreview extends StatelessWidget {
  const _CardDisplayPreview({required this.settings});

  final CardDisplaySettings settings;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    return Padding(
      padding: spacing.cardContentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _prPreview(context, theme, colorScheme, spacing),
          if (settings.showTopics ||
              settings.showRepoLanguage ||
              settings.showRepoStats ||
              settings.showDefaultBranch) ...[
            SizedBox(height: spacing.itemSpacing),
            _repoPreview(context, theme, colorScheme, spacing),
          ],
        ],
      ),
    );
  }

  Widget _prPreview(
    final BuildContext context,
    final ThemeData theme,
    final ColorScheme colorScheme,
    final AppSpacing spacing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: spacing.cardContentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: spacing.tightSpacing),
              Expanded(
                child: Text(
                  'Add dark mode support',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '#128',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.tightSpacing),
          Text(
            'octocat/Hello-World',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (settings.showBodyPreview) ...<Widget>[
            SizedBox(height: spacing.tightSpacing),
            Text(
              'Implements dark mode theming…',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: spacing.tightSpacing),
          Wrap(
            spacing: spacing.tightSpacing,
            runSpacing: spacing.tightSpacing,
            children: <Widget>[
              TintedChip(
                color: colorScheme.primary,
                label: 'enhancement',
                iconSize: 12,
              ),
              if (settings.showReactions)
                MetadataChip(
                  leading: Icon(Octicons.smiley, size: 12),
                  label: '👍 12  🎉 3',
                ),
              if (settings.showProjectChips)
                TintedChip(
                  color: colorScheme.onSurfaceVariant,
                  label: 'v2.0 Board',
                  iconSize: 12,
                ),
              if (settings.showBranchRefs)
                BranchRefsRow(from: 'feature-dark', to: 'main'),
            ],
          ),
          if (settings.showDiffDistribution) ...<Widget>[
            SizedBox(height: spacing.tightSpacing),
            DiffDistribution(
              additions: 60,
              deletions: 40,
              changedFiles: 5,
            ),
          ],
          if (settings.showReviewerChip) ...<Widget>[
            SizedBox(height: spacing.tightSpacing),
            MetadataChip(
              leading: Icon(Octicons.person, size: 12),
              label: '2 reviewers',
            ),
          ],
        ],
      ),
    );
  }

  Widget _repoPreview(
    final BuildContext context,
    final ThemeData theme,
    final ColorScheme colorScheme,
    final AppSpacing spacing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: spacing.cardContentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'octocat/Hello-World',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacing.tightSpacing),
          Wrap(
            spacing: spacing.tightSpacing,
            runSpacing: spacing.tightSpacing,
            children: <Widget>[
              if (settings.showRepoLanguage)
                TintedChip(
                  color: colorScheme.onSurfaceVariant,
                  label: 'Dart',
                  iconSize: 12,
                ),
              if (settings.showRepoStats) ...[
                MetadataChip(
                  leading: Icon(Octicons.repo_forked, size: 12),
                  label: '1.2k',
                ),
                MetadataChip(
                  leading: Icon(Octicons.issue_opened, size: 12),
                  label: '24',
                ),
                MetadataChip(
                  leading: Icon(Octicons.git_pull_request, size: 12),
                  label: '3',
                ),
              ],
              if (settings.showDefaultBranch)
                BranchRefPill(branchName: 'develop'),
            ],
          ),
          if (settings.showTopics) ...[
            SizedBox(height: spacing.tightSpacing),
            Wrap(
              spacing: spacing.tightSpacing,
              runSpacing: spacing.tightSpacing,
              children: <Widget>[
                TintedChip(
                  color: colorScheme.onSurfaceVariant,
                  icon: Octicons.hash,
                  label: 'flutter',
                  iconSize: 12,
                ),
                TintedChip(
                  color: colorScheme.onSurfaceVariant,
                  icon: Octicons.hash,
                  label: 'github-api',
                  iconSize: 12,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
