import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/cards/branch_refs.dart';
import 'package:diohub/common/cards/chip_priority.dart';
import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/inline_metadata_line.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/providers/repository/release_discussion_providers.dart';
import 'package:diohub/common/cards/chips/release_scope_chip.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/common/cards/popup_chip_builders.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/reaction_bar.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/html_utils.dart';
import 'package:diohub/app/settings/card_display.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart' show Placement;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Callback to show release assets sheet (provided by view layer).
typedef ShowReleaseAssetsCallback = void Function({
  required BuildContext context,
  required WidgetRef ref,
  required RepoRef repoRef,
  required String releaseNodeId,
  required String releaseTag,
  required String releaseName,
});

/// Shows a bottom sheet with release description (MarkdownBody), tag/badges, and a button to open assets.
void _showReleaseDetailSheet(
  BuildContext context, {
  required RepoRef repoRef,
  required ReleaseListItemData release,
  required String releaseName,
  required WidgetRef ref,
  String? previousTagName,
  ShowReleaseAssetsCallback? onShowAssets,
}) {
  final descriptionHTML = release.descriptionHTML;
  final hasDescription =
      descriptionHTML != null && descriptionHTML.trim().isNotEmpty;

  AppSheet.scrollable<void>(
    context,
    header: AppSheetHeader.text(
      releaseName,
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            release.tagName,
            style: context.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          Wrap(
            spacing: context.spacing.tightSpacing,
            runSpacing: context.spacing.tightSpacing,
            children: <Widget>[
              if (release.isLatest)
                TintedChip(
                  color: context.colorScheme.primary,
                  icon: Octicons.tag,
                  label: 'Latest',
                  iconSize: 12,
                ),
              if (release.isPrerelease)
                TintedChip(
                  color: context.colorScheme.secondary,
                  icon: Octicons.tag,
                  label: 'Pre-release',
                  iconSize: 12,
                ),
              if (release.isDraft)
                TintedChip(
                  color: context.colorScheme.outline,
                  icon: Octicons.tag,
                  label: 'Draft',
                  iconSize: 12,
                ),
            ],
          ),
        ],
      ),
    ),
    bodyBuilder: (
      BuildContext ctx,
      StateSetter setState,
      ScrollController scrollController,
    ) {
      return ListView(
        controller: scrollController,
        shrinkWrap: true,
        padding: EdgeInsets.only(
          left: context.spacing.pagePadding.left,
          right: context.spacing.pagePadding.right,
          bottom: context.spacing.pagePadding.bottom,
        ),
        children: <Widget>[
          if (hasDescription) ...[
            if (descriptionHTML.length > 500)
              Padding(
                padding: EdgeInsets.only(bottom: context.spacing.itemSpacing),
                child: ref.read(premiumAiProvider).buildAiSummaryChip(
                  context,
                  ref,
                  content: htmlToPlain(descriptionHTML),
                  label: 'TL;DR',
                ) ?? const SizedBox.shrink(),
              ),
            MarkdownBody(descriptionHTML),
            context.spacing.sectionGap,
          ],
          if (previousTagName != null) ...[
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.router.push(CompareViewRoute(
                  repoRef: repoRef,
                  base: previousTagName,
                  head: release.tagName,
                ));
              },
              icon: const Icon(Octicons.git_compare, size: 18),
              label: const Text('Changes since previous release'),
            ),
            context.spacing.sectionGap,
          ],
          FilledButton.icon(
            onPressed: onShowAssets != null
                ? () {
                    Navigator.of(context).pop();
                    onShowAssets(
                      context: context,
                      ref: ref,
                      repoRef: repoRef,
                      releaseNodeId: release.id,
                      releaseTag: release.tagName,
                      releaseName: releaseName,
                    );
                  }
                : null,
            icon: const Icon(Octicons.download, size: 18),
            label: const Text('Release assets'),
          ),
        ],
      );
    },
  );
}

/// REST release id (Release.databaseId). From [release.toJson()] so it works
/// before/after GraphQL codegen. Returns null if not available.
int? releaseDatabaseId(ReleaseListItemData release) {
  try {
    final v = release.toJson()['databaseId'];
    if (v is int) return v;
    return null;
  } catch (e, st) {
    AppLogger.warning(
      'releaseDatabaseId: failed to read databaseId',
      error: e,
      stackTrace: st,
      tag: 'release_card',
    );
    return null;
  }
}

/// Converts release reaction groups to [CardReactionGroup] for chips/popup.
List<CardReactionGroup> _releaseReactionGroups(
  final List<ReleaseListItemReactionGroups?>? groups,
) {
  if (groups == null || groups.isEmpty) return const [];
  return groups
      .whereType<ReleaseListItemReactionGroups>()
      .map(
        (final ReleaseListItemReactionGroups g) => CardReactionGroup(
          emoji: g.content.emoji,
          count: g.reactors.totalCount,
          viewerHasReacted: g.viewerHasReacted,
        ),
      )
      .toList();
}

/// Rich release card: header with tag pill, badges, author popup, description, reactions.
class ReleaseCard extends ConsumerWidget {
  const ReleaseCard({
    required this.repoRef,
    required this.release,
    this.previousTagName,
    this.onShowAssets,
    super.key,
  });

  final RepoRef repoRef;
  final ReleaseListItemData release;

  /// When set, the release detail sheet shows "Changes since previous release".
  final String? previousTagName;

  /// Callback to show release assets sheet (provided by view layer).
  final ShowReleaseAssetsCallback? onShowAssets;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settings = ref.watch(cardDisplayProvider);
    final cs = context.colorScheme;
    final name = release.name ?? release.tagName;
    final reactionGroups =
        _releaseReactionGroups(release.reactionGroups?.toList());
    final description = release.shortDescriptionHTML != null &&
            release.shortDescriptionHTML!.trim().isNotEmpty
        ? release.shortDescriptionHTML!
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .trim()
        : null;

    // Build titlePrefix: Package icon
    final Widget titlePrefix = Icon(
      Octicons.package,
      size: 20,
      color: cs.primary,
    );

    // Build title
    final Widget titleWidget = Text(
      name,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      overflow: TextOverflow.ellipsis,
    );

    // Build trailing: tag pill
    final Widget trailing = InteractiveTagPill(
      tagName: release.tagName,
      repoRef: repoRef,
    );

    // Build metadataLine: author + timestamp
    final List<InlineMetadataItem> metadataItems = [];
    if (release.author != null) {
      metadataItems.add(InlineMetadataItem(
        text: release.author!.login,
      ));
    }
    if (release.publishedAt != null) {
      metadataItems.add(InlineMetadataItem(
        text: DateTime.parse(release.publishedAt!.toIso8601String())
            .toRelativeDate(shorten: false),
      ));
    }
    final Widget? metadataLine = metadataItems.isNotEmpty
        ? InlineMetadataLine(items: metadataItems)
        : null;

    // Build chips
    final allChips = _buildPrioritizedChips(context, ref, settings);
    final maxVisible = settings.effectiveMaxChips;
    final chips = buildChipSection(
      chips: allChips,
      maxVisible: maxVisible,
    );

    // Build supplementary: description + reactions
    Widget? supplementary;
    if (description != null || reactionGroups.isNotEmpty) {
      supplementary = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (description != null)
            Text(
              description,
              style: context.textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (description != null && reactionGroups.isNotEmpty)
            SizedBox(height: context.spacing.itemSpacing),
          if (settings.showReactions && reactionGroups.isNotEmpty)
            PopupButton(
              placement: Placement.bottom,
              buttonBuilder: (final BuildContext c, final VoidCallback show) =>
                  GestureDetector(
                onTap: show,
                child: ReactionSummaryChip(
                  reactionGroups: reactionGroups,
                  showChevron: true,
                ),
              ),
              popupBuilder:
                  (final BuildContext c, final VoidCallback onDismiss) =>
                      buildReactionPopupContent(
                context,
                onDismiss: onDismiss,
                reactionGroups: reactionGroups,
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _showReleaseDetailSheet(
        context,
        repoRef: repoRef,
        release: release,
        releaseName: name,
        ref: ref,
        previousTagName: previousTagName,
        onShowAssets: onShowAssets,
      ),
      child: EntityCardLayout(
        titlePrefix: titlePrefix,
        title: titleWidget,
        trailing: trailing,
        metadataLine: metadataLine,
        chips: chips.isNotEmpty ? chips : null,
        supplementary: supplementary,
      ),
    );
  }

  List<PrioritizedChip> _buildPrioritizedChips(
    BuildContext context,
    WidgetRef ref,
    CardDisplaySettings settings,
  ) {
    final cs = context.colorScheme;
    final assetCount = release.releaseAssets.totalCount;

    return [
      // Critical: Latest/Prerelease/Draft badge
      if (release.isLatest)
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: TintedChip(
            color: cs.primary,
            icon: Octicons.tag,
            label: 'Latest',
            iconSize: 12,
          ),
        ),
      if (release.isPrerelease)
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: TintedChip(
            color: cs.secondary,
            icon: Octicons.tag,
            label: 'Pre-release',
            iconSize: 12,
          ),
        ),
      if (release.isDraft)
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: TintedChip(
            color: cs.outline,
            icon: Octicons.tag,
            label: 'Draft',
            iconSize: 12,
          ),
        ),

      // High: Release scope (asset count)
      if (settings.showReleaseScope && assetCount > 0)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: ReleaseScopeChip(
            assetCount: assetCount,
            totalDownloads: null,
          ),
        ),

      // Medium: Commit SHA
      if (release.tagCommit?.oid != null)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: MetadataChip(
            leading: const Icon(Octicons.git_commit, size: 12),
            label: release.tagCommit!.oid.length >= 7
                ? release.tagCommit!.oid.substring(0, 7)
                : release.tagCommit!.oid,
            textStyle: const TextStyle(fontFamily: 'monospace'),
          ),
        ),

      // Low: Compare action
      PrioritizedChip(
        priority: ChipPriority.low,
        widget: GestureDetector(
          onTap: () => context.router.push(CompareViewRoute(
            repoRef: repoRef,
            head: release.tagName,
          )),
          child: TintedChip(
            color: cs.primary.withValues(alpha: 0.15),
            icon: Octicons.git_compare,
            label: 'Compare',
            iconSize: 12,
          ),
        ),
      ),
    ];
  }
}

/// Fetches a single release by [repoRef] + [tagName] (e.g. from events feed)
/// and renders the full [ReleaseCard] when loaded. Shows skeleton while loading.
class ReleaseCardLoading extends ConsumerWidget {
  const ReleaseCardLoading({
    required this.repoRef,
    required this.tagName,
    super.key,
  });

  final RepoRef repoRef;
  final String tagName;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<ReleaseListItemData?> asyncRelease =
        ref.watch(releaseByTagProvider((repoRef: repoRef, tagName: tagName)));
    return AsyncValueBuilder<ReleaseListItemData?>(
      value: asyncRelease,
      skeleton: (final _) => const ShimmerScope(
        child: BorderedContainer(
          child: ReleaseCardSkeleton(),
        ),
      ),
      error: (final Object err, final _) => BorderedContainer(
        child: Padding(
          padding: context.spacing.pagePadding,
          child: Text(
            'Failed to load release',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ),
      data: (final ReleaseListItemData? release) {
        if (release == null) {
          return BorderedContainer(
            child: Padding(
              padding: context.spacing.pagePadding,
              child: Text(
                'Release not found',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        }
        return ReleaseCard(repoRef: repoRef, release: release);
      },
    );
  }
}

/// Skeleton placeholder for [ReleaseCard] while loading.
class ReleaseCardSkeleton extends StatelessWidget {
  const ReleaseCardSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const ShimmerBone.icon(size: 20),
              spacing.tightGap,
              const Expanded(child: ShimmerBone.title(width: 160)),
              spacing.tightGap,
              const ShimmerBone.chip(width: 60),
            ],
          ),
          spacing.tightGap,
          Wrap(
            spacing: spacing.tightSpacing,
            runSpacing: spacing.tightSpacing,
            children: const <Widget>[
              ShimmerBone.chip(width: 50),
              ShimmerBone.chip(width: 70),
            ],
          ),
          spacing.itemGap,
          const ShimmerBone.text(width: 200),
        ],
      ),
    );
  }
}
