import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/search/package_search_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Card for a package search result.
class PackageCard extends StatelessWidget {
  const PackageCard(this.data, {super.key});
  final PackageSearchResult data;

  @override
  Widget build(final BuildContext context) {
    final String? ownerAvatarUrl = data.repository?.owner?.avatarUrl;

    // Build titlePrefix: owner avatar or package icon
    Widget titlePrefix;
    if (ownerAvatarUrl != null) {
      titlePrefix = UserAvatar(
        avatarUrl: ownerAvatarUrl,
        size: 20,
      );
    } else {
      titlePrefix = Icon(
        Octicons.package,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    // Build title: package name
    final Widget title = Text(
      data.name,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    // Build trailing: package type chip
    final Widget trailing = MetadataChip(label: data.packageType);

    // Build supplementary: description followed by RepoNameLabel
    Widget? supplementary;
    final hasDescription = data.description != null && data.description!.isNotEmpty;
    final hasRepo = data.repository != null;
    
    if (hasDescription || hasRepo) {
      supplementary = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDescription)
            Text(
              data.description!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (hasRepo) ...[
            if (hasDescription) SizedBox(height: Theme.of(context).extension<AppSpacing>()?.tightSpacing ?? 4),
            RepoNameLabel(
              repo: RepoRef.fromFullName(data.repository!.fullName),
            ),
          ],
        ],
      );
    }

    return EntityCardLayout(
      titlePrefix: titlePrefix,
      title: title,
      trailing: trailing,
      supplementary: supplementary,
    );
  }
}

/// Skeleton for [PackageCard].
class PackageCardSkeleton extends StatelessWidget {
  const PackageCardSkeleton({super.key});

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
