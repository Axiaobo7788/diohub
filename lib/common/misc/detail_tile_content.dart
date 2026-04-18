import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:image_stack/image_stack.dart';

/// Base content widget for DetailTile with consistent styling
class DetailTileContent extends StatelessWidget {
  const DetailTileContent({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final TextStyle baseStyle =
        context.textTheme.bodyMedium ?? const TextStyle();
    // Use onSurface with reduced opacity for darker gray that fits the darker card
    final Color textColor = context.colorScheme.onSurface.strong;
    return DefaultTextStyle(
      style: baseStyle.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: textColor, // Explicitly override any theme color
        fontSize: (baseStyle.fontSize ?? 14) *
            0.9, // Slightly smaller (90% of original)
      ),
      child: child,
    );
  }
}

/// Simple text content for DetailTile
class DetailTileText extends StatelessWidget {
  const DetailTileText(
    this.text, {
    this.color,
    super.key,
  });

  final String text;
  final Color? color;

  @override
  Widget build(final BuildContext context) {
    final TextStyle themeStyle =
        context.textTheme.bodyMedium ?? const TextStyle();
    // Use onSurfaceVariant with higher opacity for better contrast on darker card
    final Color textColor = context.colorScheme.onSurfaceVariant.emphasized;
    final TextStyle baseStyle = themeStyle.copyWith(
      fontWeight: FontWeight.w500,
      height: 1.3,
      color: textColor, // Explicitly override any theme color
      fontSize: (themeStyle.fontSize ?? 14) *
          0.9, // Slightly smaller (90% of original)
    );

    return DetailTileContent(
      child: Text(
        text,
        style: color != null ? baseStyle.copyWith(color: color) : baseStyle,
      ),
    );
  }
}

/// Count display for DetailTile (e.g., "5 commits", "3 files")
class DetailTileCount extends StatelessWidget {
  const DetailTileCount(
    this.count,
    this.singularLabel,
    this.pluralLabel, {
    super.key,
  });

  final int count;
  final String singularLabel;
  final String pluralLabel;

  @override
  Widget build(final BuildContext context) => DetailTileContent(
        child: Text(
          '$count ${count == 1 ? singularLabel : pluralLabel}',
        ),
      );
}

/// Single user display for DetailTile
class DetailTileUser extends StatelessWidget {
  const DetailTileUser({
    required this.avatarUrl,
    required this.login,
    this.size = 16,
    super.key,
  });

  final String avatarUrl;
  final String login;
  final double size;

  @override
  Widget build(final BuildContext context) => DetailTileContent(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                width: size,
                height: size,
                memCacheWidth: (size * MediaQuery.of(context).devicePixelRatio)
                    .round()
                    .clamp(1, 512),
                memCacheHeight: (size * MediaQuery.of(context).devicePixelRatio)
                    .round()
                    .clamp(1, 512),
                fit: BoxFit.cover,
                errorWidget: (final BuildContext context, final String url,
                        final Object error) =>
                    Icon(
                  Icons.person,
                  size: size,
                  color: context.colorScheme.onSurface.hinted,
                ),
              ),
            ),
            context.spacing.compactGap,
            Flexible(
              child: Text(
                login,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

/// Multiple users display with avatar stack for DetailTile
class DetailTileUserStack extends StatelessWidget {
  const DetailTileUserStack({
    required this.avatars,
    required this.totalCount,
    this.avatarSize = 18,
    super.key,
  });

  final List<String> avatars;
  final int totalCount;
  final double avatarSize;

  @override
  Widget build(final BuildContext context) {
    if (avatars.isEmpty) {
      return DetailTileContent(
        child: Text(
          'None',
          style: (context.textTheme.bodyMedium ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: context.colorScheme.onSurface.muted, // Explicitly override
            fontStyle: FontStyle.italic,
            fontSize: (context.textTheme.bodyMedium?.fontSize ?? 14) *
                0.9, // Slightly smaller
          ),
        ),
      );
    }

    return DetailTileContent(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ImageStack.widgets(
            totalCount: totalCount,
            widgetBorderColor: Colors.transparent,
            widgetBorderWidth: 0,
            children: avatars.take(3).map(
              (final String avatarUrl) {
                final int cache =
                    (avatarSize * MediaQuery.of(context).devicePixelRatio)
                        .round()
                        .clamp(1, 512);
                return ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarUrl,
                    width: avatarSize,
                    height: avatarSize,
                    memCacheWidth: cache,
                    memCacheHeight: cache,
                    fit: BoxFit.cover,
                    errorWidget: (final BuildContext context, final String url,
                            final Object error) =>
                        Icon(
                      Icons.person,
                      size: avatarSize,
                      color: context.colorScheme.onSurface.hinted,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
          if (totalCount > 3) ...<Widget>[
            const SizedBox(width: 6),
            Text(
              '+${totalCount - 3}',
              style:
                  (context.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: context
                    .colorScheme.onSurface.secondary, // Explicitly override
                fontSize: (context.textTheme.bodyMedium?.fontSize ?? 14) *
                    0.9, // Slightly smaller
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Repository display for DetailTile
class DetailTileRepository extends StatelessWidget {
  const DetailTileRepository({
    required this.ownerAvatarUrl,
    required this.ownerLogin,
    required this.repoName,
    this.avatarSize = 16,
    super.key,
  });

  final String ownerAvatarUrl;
  final String ownerLogin;
  final String repoName;
  final double avatarSize;

  @override
  Widget build(final BuildContext context) => DetailTileContent(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: ownerAvatarUrl,
                width: avatarSize,
                height: avatarSize,
                memCacheWidth:
                    (avatarSize * MediaQuery.of(context).devicePixelRatio)
                        .round()
                        .clamp(1, 512),
                memCacheHeight:
                    (avatarSize * MediaQuery.of(context).devicePixelRatio)
                        .round()
                        .clamp(1, 512),
                fit: BoxFit.cover,
                errorWidget: (final BuildContext context, final String url,
                        final Object error) =>
                    Icon(
                  Icons.folder,
                  size: avatarSize,
                  color: context.colorScheme.onSurface.hinted,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$ownerLogin/$repoName',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

/// Linked issue/PR display for DetailTile
class DetailTileLinkedIssue extends StatelessWidget {
  const DetailTileLinkedIssue({
    required this.title,
    required this.number,
    required this.repositoryName,
    required this.repositoryOwner,
    super.key,
  });

  final String title;
  final int number;
  final String repositoryName;
  final String repositoryOwner;

  @override
  Widget build(final BuildContext context) => DetailTileContent(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '#$number',
                    style: (context.textTheme.bodyMedium ?? const TextStyle())
                        .copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize:
                          (context.textTheme.bodyMedium?.fontSize ?? 14) * 0.9,
                      color: context.colorScheme.onSurface.emphasized,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (context.textTheme.bodySmall ?? const TextStyle())
                        .copyWith(
                      fontSize:
                          (context.textTheme.bodySmall?.fontSize ?? 12) * 0.9,
                      color: context.colorScheme.onSurfaceVariant.strong,
                    ),
                  ),
                  if (repositoryOwner.isNotEmpty ||
                      repositoryName.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      '$repositoryOwner/$repositoryName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (context.textTheme.bodySmall ?? const TextStyle())
                          .copyWith(
                        fontSize:
                            (context.textTheme.bodySmall?.fontSize ?? 12) *
                                0.85,
                        color: context.colorScheme.onSurfaceVariant.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

/// Multiple linked issues/PRs display for DetailTile
class DetailTileLinkedIssuesStack extends StatelessWidget {
  const DetailTileLinkedIssuesStack({
    required this.totalCount,
    super.key,
  });

  final int totalCount;

  @override
  Widget build(final BuildContext context) => DetailTileContent(
        child: Text(
          '$totalCount ${totalCount == 1 ? 'linked issue' : 'linked issues'}',
        ),
      );
}
