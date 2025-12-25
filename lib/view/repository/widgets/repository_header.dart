import 'package:diohub/common/misc/detail_tile.dart';
import 'package:diohub/common/misc/detail_tile_content.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/graphql/__generated__/schema.schema.gql.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/repository/widgets/repository_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Builds the collapsed header for the repository screen
Widget buildCollapsedHeader(
  BuildContext context,
  GrepositoryInfoData_repository repo,
) {
  final ownerLogin = repo.owner.when(
    user: (u) => u.login,
    organization: (o) => o.login,
    orElse: () => null,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: RepositoryTitle(
      repo: repo,
      compact: true,
      onOwnerTap: ownerLogin != null
          ? () {
              navigateToProfile(
                login: ownerLogin,
                context: context,
              );
            }
          : null,
    ),
  );
}

/// Builds the expanded header for the repository screen
Widget buildExpandedHeader(
  BuildContext context,
  GrepositoryInfoData_repository repo,
  ValueNotifier<String> activeTabNotifier,
  DynamicTabsController tabController,
) {
  final ownerLogin = repo.owner.when(
    user: (u) => u.login,
    organization: (o) => o.login,
    orElse: () => null,
  );

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Owner and repository name in column layout
        RepositoryTitle(
          repo: repo,
          avatarSize: 20,
          spacing: 6,
          onOwnerTap: ownerLogin != null
              ? () {
                  navigateToProfile(
                    login: ownerLogin,
                    context: context,
                  );
                }
              : null,
        ),
        const SizedBox(height: 12),
        // Description (if available)
        if (repo.description != null && repo.description!.isNotEmpty) ...[
          Text(
            repo.description!,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
        ],
        // Action buttons row (Star, Fork, Watch)
        _buildRepositoryActionButtons(context, repo),
      ],
    ),
  );
}

/// Builds action buttons for repository (Star, Fork, Watch)
Widget _buildRepositoryActionButtons(
  BuildContext context,
  GrepositoryInfoData_repository repo,
) {
  final ownerLogin = repo.owner.when(
    user: (u) => u.login,
    organization: (o) => o.login,
    orElse: () => null,
  );
  if (ownerLogin == null) return const SizedBox.shrink();

  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      // Star button
      _buildActionButton(
        context,
        icon: Octicons.star,
        label: repo.viewerHasStarred ? 'Unstar' : 'Star',
        isActive: repo.viewerHasStarred,
        onTap: () {
          // TODO: Implement star/unstar action
        },
      ),
      // Fork button
      if (repo.forkingAllowed)
        _buildActionButton(
          context,
          icon: Octicons.repo_forked,
          label: 'Fork',
          onTap: () {
            // TODO: Implement fork action
          },
        ),
      // Watch button
      if (repo.viewerCanSubscribe)
        _buildActionButton(
          context,
          icon: _getWatchIcon(repo.viewerSubscription),
          label: _getWatchLabel(repo.viewerSubscription),
          isActive: repo.viewerSubscription != null &&
              repo.viewerSubscription != GSubscriptionState.UNSUBSCRIBED,
          onTap: () {
            // TODO: Implement watch/unwatch action
          },
        ),
    ],
  );
}

Widget _buildActionButton(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  bool isActive = false,
}) {
  final colorScheme = context.colorScheme;
  return OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(
      icon,
      size: 16,
      color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
    ),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor:
          isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
      side: BorderSide(
        color: isActive
            ? colorScheme.primary
            : colorScheme.outlineVariant.withOpacity(0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  );
}

IconData _getWatchIcon(GSubscriptionState? subscription) {
  switch (subscription) {
    case GSubscriptionState.SUBSCRIBED:
      return Octicons.bell_fill;
    case GSubscriptionState.IGNORED:
      return Octicons.bell_slash;
    default:
      return Octicons.bell;
  }
}

String _getWatchLabel(GSubscriptionState? subscription) {
  switch (subscription) {
    case GSubscriptionState.SUBSCRIBED:
      return 'Unwatch';
    case GSubscriptionState.IGNORED:
      return 'Stop ignoring';
    default:
      return 'Watch';
  }
}

/// Builds metadata tiles for ExpandableMetadataContent
List<Widget> buildRepositoryMetadataTiles(
  BuildContext context,
  GrepositoryInfoData_repository repo,
  DynamicTabsController tabController,
) {
  final List<Widget> tiles = <Widget>[];

  // Owner
  final ownerLogin = repo.owner.when(
    user: (u) => u.login,
    organization: (o) => o.login,
    orElse: () => null,
  );
  final ownerAvatarUrl = repo.owner.when(
    user: (u) => u.avatarUrl.toString(),
    organization: (o) => o.avatarUrl.toString(),
    orElse: () => null,
  );
  if (ownerLogin != null) {
    tiles.add(
      DetailTile(
        title: 'Owner',
        actionType: DetailTileActionType.navigation,
        onTap: () {
          navigateToProfile(
            login: ownerLogin,
            context: context,
          );
        },
        child: DetailTileUser(
          avatarUrl: ownerAvatarUrl ?? '',
          login: ownerLogin,
        ),
      ),
    );
  }

  // Language
  if (repo.primaryLanguage != null) {
    tiles.add(
      DetailTile(
        title: 'Language',
        actionType: DetailTileActionType.tab,
        onTap: () => tabController.openTab('Code'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: repo.primaryLanguage?.color != null
                    ? Color(int.parse(
                        repo.primaryLanguage!.color!.replaceFirst('#', '0xFF')))
                    : const Color(0xFF878787),
                shape: BoxShape.circle,
              ),
              height: 12,
              width: 12,
            ),
            const SizedBox(width: 6),
            DetailTileText(repo.primaryLanguage?.name ?? ''),
          ],
        ),
      ),
    );
  }

  // Created date
  tiles.add(
    DetailTile(
      title: 'Created',
      child: DetailTileText(
        getDate(repo.createdAt.toIso8601String(), shorten: false),
      ),
    ),
  );

  // License
  if (repo.licenseInfo != null) {
    tiles.add(
      DetailTile(
        title: 'License',
        child: DetailTileText(repo.licenseInfo!.name),
      ),
    );
  }

  // Stats (Open Issues, Forks, Watchers)
  tiles.add(
    DetailTile(
      title: 'Stats',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailTileText('${repo.issues.totalCount} open issues'),
          const SizedBox(height: 4),
          DetailTileText('${repo.forkCount} forks'),
          const SizedBox(height: 4),
          DetailTileText('${repo.watchers.totalCount} watchers'),
        ],
      ),
    ),
  );

  return tiles;
}
