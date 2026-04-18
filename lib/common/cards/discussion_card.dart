import 'package:diohub/common/cards/card_body_preview.dart';
import 'package:diohub/common/cards/chip_priority.dart';
import 'package:diohub/common/cards/chips/metadata_chips_repo_user.dart';
import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/popups/popup_chip_template.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
// ignore: no_view_import_in_common
import 'package:diohub/view/discussions/widgets/discussion_poll_card.dart';
// ignore: no_view_import_in_common
import 'package:diohub/view/discussions/widgets/discussion_upvote_button.dart';
import 'package:diohub/common/issues/lock_reason_display_name.dart';
import 'package:diohub/common/cards/chips/time_to_resolution_chip.dart';
import 'package:diohub/common/cards/popup_chip_builders.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub_models/models/discussions/discussion_resolution_reason.dart';
import 'package:diohub/providers/repository/release_discussion_providers.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/app/settings/card_display.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart' show Placement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

ColorScheme _colorScheme(BuildContext context) => Theme.of(context).colorScheme;

/// Card for a discussion search result.
class DiscussionCard extends ConsumerWidget {
  const DiscussionCard(this.data, {this.compact = false, super.key});
  final DiscussionCardData data;
  
  /// When true, shows only title + metadataLine + top 2 chips (answered, labels).
  /// No supplementary (no body preview, no poll card). Trailing (upvote button) is hidden.
  final bool compact;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settings = ref.watch(cardDisplayProvider);
    final RepoRef repo = RepoRef.fromFullName(data.repository.nameWithOwner);
    final cs = _colorScheme(context);
    final Color stateColor = data.closed ? cs.onSurfaceVariant : cs.primary;
    final spacing = context.spacing;

    // Build title
    final Widget title = Text(
      data.title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    // Build titlePrefix: TintedChip for #number + lock TintedChip
    Widget titlePrefix = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TintedChip(
          icon: Octicons.comment_discussion,
          color: stateColor,
          label: '#${data.number}',
        ),
        if (data.locked) ...[
          SizedBox(width: spacing.tightSpacing),
          data.activeLockReason != null
              ? TintedChip(
                  icon: Octicons.lock,
                  label: 'Locked: ${lockReasonDisplayName(data.activeLockReason!)}',
                  iconSize: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                )
              : Icon(
                  Octicons.lock,
                  size: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: Opacities.hint),
                ),
        ],
      ],
    );

    // Build metadataLine: InteractiveAuthorLabel + RepoNameLabel
    final Widget metadataLine = Row(
      children: [
        if (data.author case final author?) ...[
          InteractiveAuthorLabel(
            login: author.login,
            avatarUrl: author.avatarUrl.toString(),
          ),
          SizedBox(width: spacing.itemSpacing),
        ],
        RepoNameLabel(repo: repo),
      ],
    );

    // Build trailing: upvote button + timestamp (upvote hidden in compact mode)
    Widget? trailing = compact
        ? TimestampLabel(
            date: data.createdAt.toIso8601String(),
            shorten: true,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DiscussionUpvoteButton(
                discussionId: data.id,
                upvoteCount: data.upvoteCount,
                viewerHasUpvoted: data.viewerHasUpvoted,
                repoRef: repo,
                discussionNumber: data.number,
              ),
              SizedBox(width: context.spacing.tightSpacing),
              TimestampLabel(
                date: data.createdAt.toIso8601String(),
                shorten: true,
              ),
            ],
          );

    // Build chips with priority
    final allChips = _buildPrioritizedChips(context, ref, settings, cs);
    final maxVisible = compact ? 2 : settings.effectiveMaxChips;
    final chips = buildChipSection(
      chips: allChips,
      maxVisible: maxVisible,
    );

    // Build supplementary: body + poll (hidden in compact mode)
    Widget? supplementary;
    if (!compact) {
      final hasBody = settings.showBodyPreview && data.bodyText.isNotEmpty;
      final hasPoll = data.poll != null &&
          data.poll!.options?.nodes != null &&
          (data.poll!.options!.nodes?.isNotEmpty ?? false);

      if (hasBody || hasPoll) {
        supplementary = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBody) ...[
              CardBodyPreview(
                body: data.bodyText,
                repoName: data.repository.nameWithOwner,
              ),
              if (hasPoll) SizedBox(height: context.spacing.itemSpacing),
            ],
            if (hasPoll)
              DiscussionPollCard(
                poll: data.poll!,
                discussionId: data.id,
                repoRef: repo,
                discussionNumber: data.number,
              ),
          ],
        );
      }
    }

    return EntityCardLayout(
      titlePrefix: titlePrefix,
      title: title,
      metadataLine: metadataLine,
      trailing: trailing,
      chips: chips.isNotEmpty ? chips : null,
      supplementary: supplementary,
    );
  }

  List<PrioritizedChip> _buildPrioritizedChips(
    BuildContext context,
    WidgetRef ref,
    CardDisplaySettings settings,
    ColorScheme cs,
  ) {
    return [
      // Critical: Time to resolution
      if (settings.showTimeToResolution)
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: TimeToResolutionChip(
            createdAt: data.createdAt,
            closedAt: data.closedAt,
            mergedAt: null,
            isMerged: false,
          ),
        ),

      // High: Category
      if (data.category case final cat)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: MetadataChip(
            leading: Text(cat.emoji),
            label: cat.name,
          ),
        ),

      // High: Answered
      if (data.answer != null)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: _AnsweredChip(
            answerAuthor: data.answer!.author,
            answerChosenAt: data.answerChosenAt,
          ),
        ),

      // Medium: Poll votes
      if (data.poll != null && (data.poll?.totalVoteCount ?? 0) > 0)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: TintedChip(
            icon: Octicons.graph,
            color: cs.onSurfaceVariant,
            label: (data.poll?.totalVoteCount ?? 0) == 1
                ? '1 vote'
                : '${data.poll?.totalVoteCount ?? 0} votes',
            iconSize: 12,
          ),
        ),

      // Medium: Upvotes
      if (data.upvoteCount > 0)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: MetadataChip(
            leading: Icon(
              Octicons.arrow_up,
              size: 12,
              color: data.viewerHasUpvoted ? cs.primary : null,
            ),
            label: '${data.upvoteCount}',
          ),
        ),

      // Medium: State reason
      if (data.closed) ...[
        if (data.stateReason != null) ...[
          () {
            final stateReason = data.stateReason!;
            return PrioritizedChip(
              priority: ChipPriority.medium,
              widget: TintedChip(
                color: _stateReasonColor(context, stateReason.name),
                icon: _stateReasonIcon(stateReason.name),
                label: stateReason.name.replaceAll('_', ' ').toLowerCase(),
                iconSize: 12,
              ),
            );
          }(),
        ],
      ],

      // Low: Reactions
      if (settings.showReactions && data.reactions.totalCount > 0)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: MetadataChip(
            leading: const Icon(Octicons.smiley, size: 12),
            label: '${data.reactions.totalCount}',
          ),
        ),

      // Low: Labels
      if (settings.showLabels && (data.labels?.nodes?.length ?? 0) > 0)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: PopupButton(
            placement: Placement.bottom,
            buttonBuilder: (c, show) => GestureDetector(
              onTap: show,
              child: LabelsSummaryChip(
                labels: (data.labels?.nodes ?? <DiscussionCardLabelNode?>[])
                    .whereType<DiscussionCardLabelNode>()
                    .map((l) => CardLabel(name: l.name, color: l.color))
                    .toList(),
                showChevron: true,
              ),
            ),
            popupBuilder: (c, onDismiss) => buildLabelsPopupContent(
              context,
              onDismiss: onDismiss,
              labels: (data.labels?.nodes ?? <DiscussionCardLabelNode?>[])
                  .whereType<DiscussionCardLabelNode>()
                  .map((l) => CardLabel(name: l.name, color: l.color))
                  .toList(),
            ),
          ),
        ),

      // Low: Comments
      if (settings.showCommentCount)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: CommentsChip(count: data.comments.totalCount),
        ),
    ];
  }

  static Color _stateReasonColor(final BuildContext context, final String r) {
    final cs = _colorScheme(context);
    final reason = DiscussionResolutionReason.fromString(r);
    switch (reason) {
      case DiscussionResolutionReason.resolved:
        return DiffColors.addition;
      case DiscussionResolutionReason.outdated:
        return DiffColors.modified;
      case DiscussionResolutionReason.duplicate:
        return cs.onSurfaceVariant;
      default:
        return cs.onSurfaceVariant;
    }
  }

  static IconData _stateReasonIcon(final String r) {
    final reason = DiscussionResolutionReason.fromString(r);
    switch (reason) {
      case DiscussionResolutionReason.resolved:
        return Octicons.check_circle;
      case DiscussionResolutionReason.outdated:
        return Octicons.clock;
      case DiscussionResolutionReason.duplicate:
        return Octicons.duplicate;
      default:
        return Octicons.circle;
    }
  }
}

/// Answered chip with popup showing answerer and when chosen.
class _AnsweredChip extends StatelessWidget {
  const _AnsweredChip({
    required this.answerAuthor,
    this.answerChosenAt,
  });

  final DiscussionCardAuthor? answerAuthor;
  final DateTime? answerChosenAt;

  @override
  Widget build(final BuildContext context) {
    final hasDetails = answerAuthor != null || answerChosenAt != null;
    final chip = TintedChip(
      icon: Octicons.check_circle,
      color: DiffColors.addition,
      label: 'Answered',
      iconSize: 12,
    );
    if (!hasDetails) return chip;
    return PopupButton(
      placement: Placement.bottom,
      buttonBuilder: (final BuildContext c, final VoidCallback show) =>
          GestureDetector(onTap: show, child: chip),
      popupBuilder: (final BuildContext c, final VoidCallback onDismiss) {
        final theme = Theme.of(context);
        return Padding(
          padding: context.spacing.contentPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (answerAuthor != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UserAvatar(
                      avatarUrl: answerAuthor!.avatarUrl.toString(),
                      size: 32,
                    ),
                    SizedBox(width: context.spacing.itemSpacing),
                    Text(
                      answerAuthor!.login,
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                if (answerChosenAt != null)
                  SizedBox(height: context.spacing.tightSpacing),
              ],
              if (answerChosenAt != null)
                Text(
                  'Chosen ${answerChosenAt.toRelativeDate(shorten: false)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton for [DiscussionCard].
class DiscussionCardSkeleton extends StatelessWidget {
  const DiscussionCardSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    return const EntityCardLayoutSkeleton(
      showPrefix: true,
      showMetadataLine: true,
      showTrailing: true,
      showChips: 5,
      showSupplementary: false,
    );
  }
}

/// Fetches a single discussion by [repoRef] + [number] (e.g. from events feed)
/// and renders the full [DiscussionCard] when loaded. Shows skeleton while loading.
class DiscussionCardLoading extends ConsumerWidget {
  const DiscussionCardLoading({
    required this.repoRef,
    required this.number,
    super.key,
  });

  final RepoRef repoRef;
  final int number;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<DiscussionCardData?> asyncDiscussion = ref
        .watch(discussionByNumberProvider(DiscussionRef(repo: repoRef, number: number)));
    return AsyncValueBuilder<DiscussionCardData?>(
      value: asyncDiscussion,
      skeleton: (final _) => const ShimmerScope(
        child: BorderedContainer(
          child: DiscussionCardSkeleton(),
        ),
      ),
      error: (final Object err, final _) => BorderedContainer(
        child: Padding(
          padding: context.spacing.cardContentPadding,
          child: Text(
            'Failed to load discussion',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ),
      data: (final DiscussionCardData? discussion) {
        if (discussion == null) {
          return BorderedContainer(
            child: Padding(
              padding: context.spacing.cardContentPadding,
              child: Text(
                'Discussion not found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        }
        return BorderedContainer(
          child: DiscussionCard(discussion),
        );
      },
    );
  }
}
