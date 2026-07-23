import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Reusable user avatar widget with configurable size
/// Displays user avatar image with placeholder and error states
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.avatarUrl,
    required this.size,
    this.fallbackText,
    super.key,
  });

  final String? avatarUrl;
  final double size;
  final String? fallbackText;

  @override
  Widget build(final BuildContext context) {
    final double iconSize =
        size * 0.56; // Proportional icon size (~20 for size 36)
    final String? normalizedUrl = avatarUrl?.trim();
    final String? normalizedFallback = fallbackText?.trim();
    final Widget fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: context.colorScheme.surfaceContainerHighest,
      child: normalizedFallback != null && normalizedFallback.isNotEmpty
          ? Text(
              normalizedFallback.characters.first.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          : Icon(
              Icons.person,
              size: iconSize,
              color: context.colorScheme.onSurfaceVariant,
            ),
    );

    final int cacheSize = (size * MediaQuery.of(context).devicePixelRatio)
        .round()
        .clamp(1, 512);
    return ClipOval(
      child: normalizedUrl != null && normalizedUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: normalizedUrl,
              width: size,
              height: size,
              memCacheWidth: cacheSize,
              memCacheHeight: cacheSize,
              fit: BoxFit.cover,
              placeholder: (final BuildContext context, final String url) =>
                  ShimmerScope(child: ShimmerBone.avatar(size: size)),
              errorWidget:
                  (
                    final BuildContext context,
                    final String url,
                    final Object error,
                  ) => fallback,
            )
          : fallback,
    );
  }
}
