import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/wiki_search_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Card for a wiki search result.
class WikiCard extends StatelessWidget {
  const WikiCard(this.data, {super.key});
  final WikiSearchResult data;

  @override
  Widget build(final BuildContext context) {
    final spacing = context.spacing;
    
    final Widget titlePrefix = Icon(
      Octicons.book,
      size: 16,
      color: Theme.of(context).colorScheme.primary,
    );

    final Widget title = Text(
      data.title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      overflow: TextOverflow.ellipsis,
    );

    final Widget metadataLine = Row(
      children: [
        RepoNameLabel(
          repo: RepoRef.fromFullName(data.repository.fullName),
        ),
        if (data.sha.isNotEmpty) ...[
          SizedBox(width: spacing.compactSpacing),
          MetadataChip(
            label: data.sha.length >= 7
                ? data.sha.substring(0, 7)
                : data.sha,
          ),
        ],
      ],
    );

    Widget? supplementary;
    final String snippet = data.textMatches.isNotEmpty ? data.textMatches.first.fragment : '';
    if (snippet.isNotEmpty) {
      supplementary = Text(
        snippet,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    return EntityCardLayout(
      titlePrefix: titlePrefix,
      title: title,
      metadataLine: metadataLine,
      supplementary: supplementary,
    );
  }
}

/// Skeleton for [WikiCard].
class WikiCardSkeleton extends StatelessWidget {
  const WikiCardSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    return const EntityCardLayoutSkeleton(
      showPrefix: true,
      showMetadataLine: true,
      showTrailing: false,
      showChips: 0,
      showSupplementary: true,
    );
  }
}
