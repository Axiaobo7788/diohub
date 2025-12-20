import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/misc/shimmer_widget.dart';
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
  Widget build(BuildContext context) {
    final iconSize = size * 0.56; // Proportional icon size (~20 for size 36)

    return ClipOval(
      child: avatarUrl != null
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => ShimmerWidget(
                child: Container(
                  width: size,
                  height: size,
                  color: context.colorScheme.surfaceVariant,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: size,
                height: size,
                color: context.colorScheme.surfaceVariant,
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
              color: context.colorScheme.surfaceVariant,
              child: Icon(
                Icons.person,
                size: iconSize,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

