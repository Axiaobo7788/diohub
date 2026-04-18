import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/cards/branch_refs.dart';
import 'package:diohub/common/cards/chip_priority.dart';
import 'package:diohub/common/cards/deployment_card_data.dart';
import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/inline_metadata_line.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/app/settings/card_display.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Rich deployment card: state chip, creator, environment, status row, commit/description.
class DeploymentCard extends ConsumerWidget {
  const DeploymentCard({
    required this.data,
    super.key,
  });

  final DeploymentCardData data;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settings = ref.watch(cardDisplayProvider);
    final textTheme = Theme.of(context).textTheme;
    final dateStr = data.latestStatusCreatedAt ?? data.createdAt ?? '';
    
    Widget? durationChip;
    if (data.createdAt != null && data.latestStatusCreatedAt != null) {
      try {
        durationChip = DurationChip(
          start: DateTime.parse(data.createdAt!),
          end: DateTime.parse(data.latestStatusCreatedAt!),
        );
      } catch (e, st) {
        AppLogger.warning(
          'Failed to parse deployment duration dates',
          error: e,
          stackTrace: st,
          tag: 'DeploymentCard',
        );
      }
    }

    // Build titlePrefix: deployment state icon
    final Widget? titlePrefix = data.state != null
        ? Icon(
            _stateIcon(data.state!, data.latestStatusState),
            size: 14,
            color: _stateColor(context, data.state!, data.latestStatusState),
          )
        : null;

    // Build title: environment name
    final Widget titleWidget = Text(
      data.environment,
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colorScheme.onSurface,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    // Build metadataLine: creator
    final Widget? metadataLine = data.creatorLogin != null
        ? InlineMetadataLine(items: [
            InlineMetadataItem(text: data.creatorLogin!),
          ])
        : null;

    // Build trailing: timestamp
    final Widget trailing = TimestampLabel(date: dateStr);

    // Build chips
    final allChips = _buildPrioritizedChips(context, ref, settings, durationChip);
    final maxVisible = settings.effectiveMaxChips;
    final chips = buildChipSection(
      chips: allChips,
      maxVisible: maxVisible,
    );

    // Build supplementary: commit message + status description
    Widget? supplementary;
    final hasCommitMessage =
        data.commitMessage != null && data.commitMessage!.trim().isNotEmpty;
    final hasStatusDescription = data.latestStatusDescription != null &&
        data.latestStatusDescription!.trim().isNotEmpty &&
        data.latestStatusDescription != data.commitMessage;

    if (hasCommitMessage || hasStatusDescription) {
      supplementary = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasCommitMessage)
            Text(
              data.commitMessage!.split('\n').first,
              style: textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant
                    .withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (hasCommitMessage && hasStatusDescription)
            SizedBox(height: context.spacing.tightSpacing),
          if (hasStatusDescription)
            Text(
              data.latestStatusDescription!,
              style: textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant
                    .withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      );
    }

    return EntityCardLayout(
      titlePrefix: titlePrefix,
      title: titleWidget,
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
    Widget? durationChip,
  ) {
    return [
      // Critical: State chip
      if (data.state != null)
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: TintedChip(
            color: _stateColor(
              context,
              data.state!,
              data.latestStatusState,
            ),
            icon: _stateIcon(data.state!, data.latestStatusState),
            label: data.state!.replaceAll('_', ' ').toLowerCase(),
            iconSize: 12,
          ),
        ),

      // High: Branch ref
      if (settings.showBranchRefs && data.refName != null)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: BranchRefPill(branchName: data.refName!),
        ),

      // Medium: Duration
      if (durationChip != null)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: durationChip,
        ),

      // Low: Commit SHA
      if (data.commitAbbreviatedOid != null)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: MetadataChip(
            leading: const Icon(Octicons.git_commit, size: 12),
            label: data.commitAbbreviatedOid!,
            textStyle: const TextStyle(fontFamily: 'monospace'),
          ),
        ),

      // Low: Logs link
      if (data.latestStatusLogUrl != null)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: GestureDetector(
            onTap: () => launchUrl(Uri.parse(data.latestStatusLogUrl!)),
            child: TintedChip(
              color: context.colorScheme.primary,
              icon: Octicons.log,
              label: 'Logs',
              iconSize: 12,
            ),
          ),
        ),
    ];
  }

  static Color _stateColor(
    final BuildContext context,
    final String state,
    final String? statusState,
  ) {
    final cs = context.colorScheme;
    if (statusState == 'SUCCESS') return DiffColors.addition;
    if (statusState == 'FAILURE') return DiffColors.deletion;
    if (state == 'ACTIVE') return cs.primary;
    if (state == 'IN_PROGRESS') return cs.tertiary;
    if (state == 'QUEUED') return DiffColors.modified;
    if (state == 'DESTROYED' || state == 'INACTIVE') return cs.onSurfaceVariant;
    return cs.onSurfaceVariant;
  }

  static IconData _stateIcon(final String state, final String? statusState) {
    if (statusState == 'SUCCESS') return Octicons.check_circle_fill;
    if (statusState == 'FAILURE') return Octicons.x_circle_fill;
    if (state == 'ACTIVE') return Octicons.rocket;
    if (state == 'IN_PROGRESS') return Icons.refresh;
    if (state == 'QUEUED') return Octicons.clock;
    if (state == 'DESTROYED') return Icons.cancel;
    if (state == 'INACTIVE') return Octicons.circle;
    return Octicons.rocket;
  }
}
