import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/widgets/rows/metadata_rows_base.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';


class MetadataUserRow extends StatelessWidget {
  const MetadataUserRow({
    required this.avatarUrl,
    required this.login,
    this.label,
    this.labelWidth = 80,
    this.association,
    this.trailing,
    this.padding,
    this.onTap,
    super.key,
  });

  final String avatarUrl;
  final String login;

  /// Row label (e.g. "Author", "Committer").
  final String? label;

  /// Width of the label column when [label] is non-null.
  final double labelWidth;

  /// Association badge text (e.g. "MEMBER", "OWNER").
  final String? association;

  /// Optional trailing widget (e.g. timestamp, state icon). Rendered after login with itemGap.
  final Widget? trailing;

  /// Tap callback for navigation.
  final VoidCallback? onTap;

  /// When null, uses [AppSpacing.metadataRowPadding].
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? spacing.metadataRowPadding;

    final Padding content = Padding(
      padding: effectivePadding,
      child: Row(
        children: <Widget>[
          if (label != null) ...<Widget>[
            SizedBox(
              width: labelWidth,
              child: Text(
                label!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.strong,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
            spacing.itemGap,
          ],
          UserAvatar(avatarUrl: avatarUrl, size: 20),
          spacing.itemGap,
          Flexible(
            child: Text(
              login,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (association != null &&
              association != 'NONE' &&
              association != 'FIRST_TIMER' &&
              association != 'FIRST_TIME_CONTRIBUTOR') ...<Widget>[
            spacing.compactGap,
            Container(
              padding: spacing.badgePadding,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                association!.toLowerCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                  fontSize: 9,
                ),
              ),
            ),
          ],
          if (trailing != null) ...<Widget>[
            const Spacer(),
            spacing.itemGap,
            trailing!
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }
}

/// Displays a row of overlapping avatars with optional "+N" overflow count.
class MetadataAvatarStack extends StatelessWidget {
  const MetadataAvatarStack({
    required this.avatars,
    required this.totalCount,
    this.label,
    this.labelWidth = 80,
    this.avatarSize = 20,
    this.maxVisible = 5,
    this.padding,
    this.onTap,
    super.key,
  });

  final List<String> avatars;
  final int totalCount;
  final String? label;

  /// Width of the label column when [label] is non-null.
  final double labelWidth;

  final double avatarSize;
  final int maxVisible;

  /// When null, uses [AppSpacing.metadataRowPadding].
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final List<String> visible = avatars.take(maxVisible).toList();
    final int overflow = totalCount - visible.length;

    final AppSpacing spacing = context.spacing;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? spacing.metadataRowPadding;
    final Padding content = Padding(
      padding: effectivePadding,
      child: Row(
        children: <Widget>[
          if (label != null) ...<Widget>[
            SizedBox(
              width: labelWidth,
              child: Text(
                label!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.strong,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
            spacing.itemGap,
          ],
          // Stacked avatars
          SizedBox(
            height: avatarSize,
            width: avatarSize + (visible.length - 1) * (avatarSize * 0.65),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                for (int i = 0; i < visible.length; i++)
                  Positioned(
                    left: i * (avatarSize * 0.65),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                      child: UserAvatar(
                        avatarUrl: visible[i],
                        size: avatarSize - 3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (overflow > 0) ...<Widget>[
            spacing.compactGap,
            Text(
              '+$overflow',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.secondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }
}

/// Data for a single chip.
class MetadataChipData {
  const MetadataChipData({
    required this.label,
    this.color,
    this.onTap,
  });

  final String label;
  final Color? color;
  final VoidCallback? onTap;
}

/// A flowing wrap of colored chips for labels, topics, linked issues, etc.
class MetadataChipWrap extends StatelessWidget {
  const MetadataChipWrap({
    required this.chips,
    this.padding,
    super.key,
  });

  final List<MetadataChipData> chips;

  /// When null, uses [AppSpacing.metadataRowPadding].
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(final BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? spacing.metadataRowPadding;

    return Padding(
      padding: effectivePadding,
      child: Wrap(
        spacing: spacing.compactSpacing,
        runSpacing: spacing.compactSpacing,
        children: chips.map((final MetadataChipData chip) {
          final Color chipColor = chip.color ?? colorScheme.primary;
          final Container widget = Container(
            padding: spacing.chipPadding,
            decoration: BoxDecoration(
              color: chipColor.subtle,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: chipColor.tint,
                width: 0.5,
              ),
            ),
            child: Text(
              chip.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          );

          if (chip.onTap != null) {
            return GestureDetector(onTap: chip.onTap, child: widget);
          }
          return widget;
        }).toList(),
      ),
    );
  }
}

/// "Merged by" attribution row: merge icon + avatar + login + relative timestamp.
class MergedByAttribution extends StatelessWidget {
  const MergedByAttribution({
    required this.login,
    required this.avatarUrl,
    required this.mergedAt,
    this.onTap,
    super.key,
  });

  final String login;
  final String avatarUrl;
  final DateTime mergedAt;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final Color mergeColor = context.colorScheme.tertiary;
    final String date = mergedAt.toRelativeDate(shorten: true);
    final Widget row = Padding(
      padding: spacing.metadataRowPadding,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.merge_rounded,
            size: 16,
            color: mergeColor,
          ),
          spacing.itemGap,
          Text(
            'Merged by',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.strong,
                ),
          ),
          spacing.itemGap,
          UserAvatar(avatarUrl: avatarUrl, size: 20),
          spacing.itemGap,
          Flexible(
            child: Text(
              login,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          spacing.compactGap,
          Text(
            date,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.muted,
                ),
          ),
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, child: row);
    }
    return row;
  }
}

/// Stacked avatars + "& N co-authors" for commits with multiple authors.
class CoAuthorRow extends StatelessWidget {
  const CoAuthorRow({
    required this.avatarUrls,
    super.key,
  });

  final List<String> avatarUrls;

  @override
  Widget build(final BuildContext context) {
    if (avatarUrls.isEmpty) return const SizedBox.shrink();
    final AppSpacing spacing = context.spacing;
    final int n = avatarUrls.length;
    return Padding(
      padding: spacing.metadataRowPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 20.0 + (n - 1) * 12.0,
            height: 20,
            child: Stack(
              children: List.generate(
                n.clamp(0, 5),
                (final int i) => Positioned(
                  left: i * 12.0,
                  child: UserAvatar(
                    avatarUrl: avatarUrls[i],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          spacing.compactGap,
          Text(
            n == 1 ? '1 co-author' : '& $n co-authors',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.secondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// GitHub profile badges: GitHub Star, Campus Expert, Developer Program, Employee, Bug Bounty.
class GitHubBadges extends StatelessWidget {
  const GitHubBadges({
    this.isGitHubStar = false,
    this.isCampusExpert = false,
    this.isDeveloperProgramMember = false,
    this.isEmployee = false,
    this.isBountyHunter = false,
    super.key,
  });

  final bool isGitHubStar;
  final bool isCampusExpert;
  final bool isDeveloperProgramMember;
  final bool isEmployee;
  final bool isBountyHunter;

  @override
  Widget build(final BuildContext context) {
    final List<Widget> chips = <Widget>[];
    final ColorScheme cs = context.colorScheme;
    if (isGitHubStar) {
      chips.add(TintedChip(
        color: const Color(0xFFFFD700),
        icon: Icons.star_rounded,
        label: 'GitHub Star',
        iconSize: 12,
      ));
    }
    if (isCampusExpert) {
      chips.add(TintedChip(
        color: cs.primary,
        icon: Icons.school_rounded,
        label: 'Campus Expert',
        iconSize: 12,
      ));
    }
    if (isDeveloperProgramMember) {
      chips.add(TintedChip(
        color: Colors.green,
        icon: Icons.code_rounded,
        label: 'Developer Program',
        iconSize: 12,
      ));
    }
    if (isEmployee) {
      chips.add(TintedChip(
        color: Colors.purple,
        icon: Icons.badge_rounded,
        label: 'Employee',
        iconSize: 12,
      ));
    }
    if (isBountyHunter) {
      chips.add(TintedChip(
        color: Colors.orange,
        icon: Icons.security_rounded,
        label: 'Bug Bounty',
        iconSize: 12,
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }
}
