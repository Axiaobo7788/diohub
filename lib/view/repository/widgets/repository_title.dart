import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Reusable widget for displaying owner and repository name in a column layout
class RepositoryTitle extends StatelessWidget {
  const RepositoryTitle({
    required this.repo,
    this.ownerTextStyle,
    this.repoTextStyle,
    this.avatarSize = 20,
    this.spacing = 8,
    this.compact = false,
    this.onOwnerTap,
    this.onRepoTap,
    super.key,
  });

  final GrepositoryInfoData_repository repo;
  final TextStyle? ownerTextStyle;
  final TextStyle? repoTextStyle;
  final double avatarSize;
  final double spacing;
  final bool compact;
  final VoidCallback? onOwnerTap;
  final VoidCallback? onRepoTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    if (compact) {
      return _buildCompactLayout(
        context,
        theme,
        colorScheme,
        ownerLogin,
        ownerAvatarUrl,
      );
    }

    return _buildExpandedLayout(
      context,
      theme,
      colorScheme,
      ownerLogin,
      ownerAvatarUrl,
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String? ownerLogin,
    String? ownerAvatarUrl,
  ) {
    return Row(
      children: [
        if (ownerAvatarUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: ownerAvatarUrl,
              width: avatarSize,
              height: avatarSize,
              fit: BoxFit.cover,
              placeholder: (final _, final __) => Container(
                width: avatarSize,
                height: avatarSize,
                color: colorScheme.surfaceVariant,
              ),
              errorWidget: (final _, final __, final ___) => Container(
                width: avatarSize,
                height: avatarSize,
                color: colorScheme.surfaceVariant,
                child: Icon(
                  Octicons.repo,
                  size: avatarSize * 0.6,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (ownerAvatarUrl != null) SizedBox(width: spacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ownerLogin != null)
                GestureDetector(
                  onTap: onOwnerTap,
                  child: Text(
                    ownerLogin,
                    style: ownerTextStyle ??
                        theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (ownerLogin != null) const SizedBox(height: 2),
              Text(
                repo.name,
                style: repoTextStyle ??
                    theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedLayout(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String? ownerLogin,
    String? ownerAvatarUrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Repository name on top
        GestureDetector(
          onTap: onRepoTap,
          child: Text(
            repo.name,
            style: repoTextStyle ??
                theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  height: 1.3,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Avatar + owner below
        if (ownerLogin != null && ownerAvatarUrl != null) ...[
          SizedBox(height: spacing),
          GestureDetector(
            onTap: onOwnerTap,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: ownerAvatarUrl,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    placeholder: (final _, final __) => Container(
                      width: avatarSize,
                      height: avatarSize,
                      color: colorScheme.surfaceVariant,
                    ),
                    errorWidget: (final _, final __, final ___) => Container(
                      width: avatarSize,
                      height: avatarSize,
                      color: colorScheme.surfaceVariant,
                      child: Icon(
                        Octicons.repo,
                        size: avatarSize * 0.6,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Text(
                    ownerLogin,
                    style: ownerTextStyle ??
                        theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

