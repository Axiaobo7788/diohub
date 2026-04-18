import 'package:diohub/common/cards/state_chip.dart' show StateChip;
import 'package:diohub/common/misc/repository_card.dart' show RepoStarChip;
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Reusable header row: [avatar] [title / subtitle] ... [trailing]
///
/// Used across the app wherever an entity needs to be displayed with an
/// avatar and contextual text, e.g.:
/// - Repository CollapseBar (owner avatar + repo name / owner login)
/// - Issue/Pull CollapseBar (repo owner avatar + repo name / owner login)
/// - RepositoryCard header (owner avatar + repo name / owner login)
///
/// Subtitle is rendered above title (owner above repo name) to match the
/// GitHub convention and the existing RepositoryCard layout.
class EntityHeader extends StatelessWidget {
  const EntityHeader({
    required this.avatarUrl,
    required this.title,
    this.subtitle,
    this.avatarSize = 24,
    this.onTap,
    this.trailing,
    this.titleStyle,
    this.subtitleStyle,
    this.showAvatar = true,
    super.key,
  });

  /// URL for the avatar image.
  final String? avatarUrl;

  /// Primary text (e.g., repo name). Shown bold below subtitle.
  final String title;

  /// Secondary text (e.g., owner login). Shown small and muted above title.
  final String? subtitle;

  /// Avatar size in logical pixels.
  final double avatarSize;

  /// Called when the header is tapped (e.g., navigate to profile).
  final VoidCallback? onTap;

  /// Optional trailing widget (e.g., [StateChip], [RepoStarChip]).
  final Widget? trailing;

  /// Override the default title text style.
  final TextStyle? titleStyle;

  /// Override the default subtitle text style.
  final TextStyle? subtitleStyle;

  /// Whether to show the avatar. Defaults to true.
  final bool showAvatar;

  @override
  Widget build(final BuildContext context) {
    final TextStyle? effectiveTitleStyle = titleStyle ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.onSurface,
            );

    final TextStyle? effectiveSubtitleStyle = subtitleStyle ??
        Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant.secondary,
              fontWeight: FontWeight.w500,
            );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showAvatar) ...<Widget>[
          UserAvatar(
            avatarUrl: avatarUrl,
            size: avatarSize,
          ),
          context.spacing.itemGap,
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: effectiveSubtitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                title,
                style: effectiveTitleStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          context.spacing.compactGap,
          trailing!,
        ],
      ],
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
