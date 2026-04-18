import 'package:diohub/common/cards/chip_priority.dart';
import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_models/models/search/topic_search_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Card for a topic search result.
class TopicCard extends StatelessWidget {
  const TopicCard(this.data, {super.key});
  final TopicSearchResult data;

  @override
  Widget build(final BuildContext context) {
    final String title = data.displayName ?? data.name;

    // Build titlePrefix: hash icon
    final Widget titlePrefix = Icon(
      Octicons.hash,
      size: 18,
      color: Theme.of(context).colorScheme.primary,
    );

    // Build title: topic name
    final Widget titleWidget = Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      overflow: TextOverflow.ellipsis,
    );

    // Build chips: score + curated + featured + createdBy
    final List<PrioritizedChip> allChips = [];
    if (data.score != null) {
      allChips.add(
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: TintedChip(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            icon: Octicons.star,
            label: 'Score: ${data.score!.toStringAsFixed(1)}',
          ),
        ),
      );
    }
    if (data.curated) {
      allChips.add(
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: TintedChip(
            icon: Octicons.verified,
            color: Theme.of(context).colorScheme.primary,
            label: 'Curated',
          ),
        ),
      );
    }
    if (data.featured) {
      allChips.add(
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: TintedChip(
            icon: Octicons.star,
            color: Theme.of(context).colorScheme.primary,
            label: 'Featured',
          ),
        ),
      );
    }
    if (data.createdBy != null) {
      allChips.add(
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: MetadataChip(label: data.createdBy),
        ),
      );
    }

    final chips = buildChipSection(
      chips: allChips,
      maxVisible: 4,
    );

    // Build supplementary: description
    Widget? supplementary;
    if (data.shortDescription != null && data.shortDescription!.isNotEmpty) {
      supplementary = Text(
        data.shortDescription!,
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return EntityCardLayout(
      titlePrefix: titlePrefix,
      title: titleWidget,
      chips: chips.isNotEmpty ? chips : null,
      supplementary: supplementary,
    );
  }
}

/// Skeleton for [TopicCard].
class TopicCardSkeleton extends StatelessWidget {
  const TopicCardSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    return const EntityCardLayoutSkeleton(
      showPrefix: true,
      showMetadataLine: false,
      showTrailing: false,
      showChips: 2,
      showSupplementary: true,
    );
  }
}
