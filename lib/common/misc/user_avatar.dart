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
    super.key,
  });

  final String? avatarUrl;
  final double size;

  @override
  Widget build(final BuildContext context) {
    final double iconSize =
        size * 0.56; // Proportional icon size (~20 for size 36)

    final int cacheSize =
        (size * MediaQuery.of(context).devicePixelRatio).round().clamp(1, 512);
    return ClipOval(
      child: avatarUrl != null
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              width: size,
              height: size,
              memCacheWidth: cacheSize,
              memCacheHeight: cacheSize,
              fit: BoxFit.cover,
              placeholder: (final BuildContext context, final String url) =>
                  ShimmerScope(
                child: ShimmerBone.avatar(size: size),
              ),
              errorWidget: (final BuildContext context, final String url,
                      final Object error) =>
                  Container(
                width: size,
                height: size,
                color: context.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  size: iconSize,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Container(
              width: size,
              height: size,
              color: context.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person,
                size: iconSize,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }
}
