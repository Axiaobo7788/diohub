/// Card for a single gist: name, file list with language colors, star count, public/private badge, timestamp.
///
/// Styling follows [RepositoryCard]/[ProfileCard]. Tap typically opens gist URL.
library;

import 'package:diohub/common/cards/chip_priority.dart';
import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:diohub/utils/lang_colors/get_language_color.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Data for a single gist (from getUserGists query or equivalent).
class GistCardData {
  const GistCardData({
    required this.name,
    this.description,
    required this.isPublic,
    this.isFork = false,
    required this.createdAt,
    required this.updatedAt,
    required this.starCount,
    required this.url,
    required this.files,
    this.commentCount,
    this.forkCount,
  });

  final String name;
  final String? description;
  final bool isPublic;
  final bool isFork;
  final String createdAt;
  final String updatedAt;
  final int starCount;
  final Uri url;

  /// File names with optional language name for color.
  final List<GistFileInfo> files;

  /// From GQL `comments(first: 0) { totalCount }`.
  final int? commentCount;

  /// From GQL `forks(first: 0) { totalCount }`.
  final int? forkCount;

  /// Display title: first file name or description or fallback.
  String get displayName {
    if (name.isNotEmpty) return name;
    if (description != null && description!.isNotEmpty) return description!;
    if (files.isNotEmpty) return files.first.name;
    return 'Untitled gist';
  }
}

class GistFileInfo {
  const GistFileInfo(
      {required this.name, this.languageName, this.languageColor});
  final String name;
  final String? languageName;
  final String? languageColor;
}

/// Displays gist name, file list with language colors, star count, public/private badge, relative timestamp.
/// Caller MUST wrap in BorderedContainer if needed.
class GistCard extends StatelessWidget {
  const GistCard({
    required this.data,
    super.key,
  });

  final GistCardData data;

  @override
  Widget build(final BuildContext context) {
    final String timestamp = DateTime.parse(data.updatedAt).toRelativeDate(shorten: true);

    // Build title: display name
    final Widget title = Text(
      data.displayName,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onSurface.strong,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    // Build chips: file chips (max 3) + footer chips (public/secret, stars, forks, comments, timestamp)
    final List<PrioritizedChip> allChips = [];
    
    // File chips
    final int maxVisibleFiles = 5;
    for (int i = 0; i < data.files.length && i < maxVisibleFiles; i++) {
      final GistFileInfo f = data.files[i];
      final Color langColor = f.languageColor != null && f.languageColor!.isNotEmpty
          ? tryParseHexColor(f.languageColor!, fallback: Color(getLangColor(f.languageName)))!
          : Color(getLangColor(f.languageName));
      
      allChips.add(
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: MetadataChip(
            leading: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: langColor,
                shape: BoxShape.circle,
              ),
            ),
            label: f.name,
          ),
        ),
      );
    }
    
    if (data.files.length > maxVisibleFiles) {
      allChips.add(
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: ShowMoreChip(
            remainingCount: data.files.length - maxVisibleFiles,
            entityLabel: 'files',
            onTap: () {
              // TODO: Show all files dialog or navigate
            },
          ),
        ),
      );
    }
    
    // Footer chips: public/secret, stars, forks, comments, timestamp
    allChips.add(
      PrioritizedChip(
        priority: ChipPriority.medium,
        widget: TintedChip(
          color: data.isPublic
              ? context.colorScheme.primary
              : context.colorScheme.onSurfaceVariant,
          icon: data.isPublic ? Octicons.globe : Octicons.lock,
          label: data.isPublic ? 'Public' : 'Secret',
          iconSize: 12,
        ),
      ),
    );
    
    if (data.isFork) {
      allChips.add(
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: TintedChip(
            color: context.colorScheme.onSurfaceVariant,
            icon: Octicons.repo_forked,
            label: 'Fork',
            iconSize: 12,
          ),
        ),
      );
    }
    
    if (data.starCount > 0) {
      allChips.add(
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: TintedChip(
            color: context.colorScheme.tertiary,
            icon: Octicons.star,
            label: '${data.starCount}',
            iconSize: 12,
          ),
        ),
      );
    }
    
    if (data.commentCount != null && data.commentCount! > 0) {
      allChips.add(
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: TintedChip(
            color: context.colorScheme.onSurfaceVariant,
            icon: Octicons.comment,
            label: data.commentCount! == 1
                ? '1 comment'
                : '${data.commentCount} comments',
            iconSize: 12,
          ),
        ),
      );
    }
    
    if (data.forkCount != null && data.forkCount! > 0) {
      allChips.add(
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: TintedChip(
            color: context.colorScheme.onSurfaceVariant,
            icon: Octicons.repo_forked,
            label: data.forkCount! == 1 ? '1 fork' : '${data.forkCount} forks',
            iconSize: 12,
          ),
        ),
      );
    }
    
    allChips.add(
      PrioritizedChip(
        priority: ChipPriority.low,
        widget: TintedChip(
          color: context.colorScheme.onSurfaceVariant,
          icon: Icons.schedule_rounded,
          label: timestamp,
          iconSize: 12,
        ),
      ),
    );

    final chips = buildChipSection(
      chips: allChips,
      maxVisible: 8,
    );

    // Build supplementary: description (if different from displayName)
    Widget? supplementary;
    if (data.description != null &&
        data.description!.isNotEmpty &&
        data.description != data.displayName) {
      supplementary = Text(
        data.description!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant.secondary,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return EntityCardLayout(
      title: title,
      chips: chips.isNotEmpty ? chips : null,
      supplementary: supplementary,
    );
  }
}

/// Skeleton for [GistCard].
class GistCardSkeleton extends StatelessWidget {
  const GistCardSkeleton({super.key});

  @override
  Widget build(final BuildContext context) {
    return const EntityCardLayoutSkeleton(
      showPrefix: false,
      showMetadataLine: true,
      showTrailing: true,
      showChips: 3,
      showSupplementary: false,
    );
  }
}
