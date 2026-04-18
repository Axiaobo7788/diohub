import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Overlapping mini avatars with optional "+N" overflow.
///
/// [avatarUrls] in order; [maxVisible] (default 3) shown; [size] (default 16).
/// Overlap ~65%. Uses compactGap before "+N" when overflow.
/// Returns [SizedBox.shrink] when [avatarUrls] is empty.
class MiniAvatarStack extends StatelessWidget {
  const MiniAvatarStack({
    required this.avatarUrls,
    this.maxVisible = 3,
    this.size = 16,
    this.labelIcon,
    this.showExpandIcon = false,
    super.key,
  });

  final List<String> avatarUrls;
  final int maxVisible;
  final double size;

  /// Optional leading icon (e.g. people) to indicate what the avatars represent.
  final IconData? labelIcon;

  /// When true, shows a trailing expand icon to indicate the stack is tappable.
  final bool showExpandIcon;

  @override
  Widget build(final BuildContext context) {
    if (avatarUrls.isEmpty) {
      return const SizedBox.shrink();
    }
    final AppSpacing spacing = context.spacing;
    final int visible = avatarUrls.length.clamp(0, maxVisible);
    final int overflow = avatarUrls.length - visible;
    final double overlap = size * 0.65;

    final Widget stack = SizedBox(
      width: visible * (size - overlap) + overlap,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int i = 0; i < visible; i++)
            Positioned(
              left: i * (size - overlap),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrls[i],
                  width: size,
                  height: size,
                  memCacheWidth:
                      (size * MediaQuery.of(context).devicePixelRatio)
                          .round()
                          .clamp(1, 512),
                  memCacheHeight:
                      (size * MediaQuery.of(context).devicePixelRatio)
                          .round()
                          .clamp(1, 512),
                  fit: BoxFit.cover,
                  placeholder: (final _, final __) => Container(
                    width: size,
                    height: size,
                    color: context.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person,
                      size: size * 0.56,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  errorWidget: (final _, final __, final ___) => Container(
                    width: size,
                    height: size,
                    color: context.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person,
                      size: size * 0.56,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    Widget result;
    if (overflow > 0) {
      result = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          stack,
          spacing.compactGap,
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.compactSpacing,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: context.colorScheme.surface,
              ),
            ),
            child: Text(
              '+$overflow',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant.muted,
                    fontSize: 10,
                  ),
            ),
          ),
        ],
      );
    } else {
      result = stack;
    }

    if (labelIcon != null || showExpandIcon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (labelIcon != null) ...<Widget>[
            Icon(
              labelIcon,
              size: size * 0.75,
              color: context.colorScheme.onSurfaceVariant.secondary,
            ),
            spacing.compactGap,
          ],
          result,
          if (showExpandIcon) ...<Widget>[
            spacing.tightGap,
            Icon(
              Icons.expand_more_rounded,
              size: 10,
              color: context.colorScheme.onSurfaceVariant.muted,
            ),
          ],
        ],
      );
    }
    return result;
  }
}
