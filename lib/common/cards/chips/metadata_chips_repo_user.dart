import 'package:diohub/common/cards/chips/metadata_chips_base.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// A label that displays a repository name.
class RepoNameLabel extends StatelessWidget {
  const RepoNameLabel({required this.repo, super.key});

  final RepoRef repo;

  @override
  Widget build(final BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Text(
              repo.fullName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant.secondary,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}

/// A label that displays an author's login name with optional avatar
class AuthorLabel extends StatelessWidget {
  const AuthorLabel({
    required this.login,
    this.avatarUrl,
    super.key,
  });

  final String login;
  final String? avatarUrl;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (avatarUrl != null) ...<Widget>[
          UserAvatar(
            avatarUrl: avatarUrl,
            size: 16,
          ),
          spacing.compactGap,
        ],
        Flexible(
          child: Text(
            login,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.secondary,
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Security alerts badge when vulnerabilityAlerts.totalCount > 0.
class SecurityAlertBadge extends StatelessWidget {
  const SecurityAlertBadge({
    required this.count,
    super.key,
  });

  final int count;

  @override
  Widget build(final BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return TintedChip(
      color: context.colorScheme.error,
      icon: Icons.shield_rounded,
      label: '$count ${count == 1 ? 'alert' : 'alerts'}',
      iconSize: 12,
    );
  }
}

/// Monospace abbreviated SHA (7 chars), tappable to copy.
class BranchSHAPill extends StatelessWidget {
  const BranchSHAPill({
    required this.sha,
    super.key,
  });

  final String sha;

  String get _abbrev => sha.length >= 7 ? sha.substring(0, 7) : sha;

  @override
  Widget build(final BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Caller can wrap with copy callback if needed
        },
        borderRadius: context.radius(RadiusSize.small),
        child: MetadataChip(
          label: _abbrev,
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
          backgroundOpacity: Opacities.border,
        ),
      ),
    );
  }
}

/// Repo settings indicators: merge strategies, delete-branch-on-merge, auto-merge, web-commit-signoff.
/// Only shown when viewer has ADMIN or MAINTAIN permission.
class RepoSettingsIndicators extends StatelessWidget {
  const RepoSettingsIndicators({
    this.mergeCommitAllowed,
    this.squashMergeAllowed,
    this.rebaseMergeAllowed,
    this.autoMergeAllowed,
    this.deleteBranchOnMerge,
    this.webCommitSignoffRequired,
    super.key,
  });

  final bool? mergeCommitAllowed;
  final bool? squashMergeAllowed;
  final bool? rebaseMergeAllowed;
  final bool? autoMergeAllowed;
  final bool? deleteBranchOnMerge;
  final bool? webCommitSignoffRequired;

  @override
  Widget build(final BuildContext context) {
    final List<Widget> chips = <Widget>[];
    if (mergeCommitAllowed == true) {
      chips.add(TintedChip(
        color: context.colorScheme.primary,
        icon: Octicons.git_merge,
        label: 'Merge commit',
        iconSize: 12,
      ));
    }
    if (squashMergeAllowed == true) {
      chips.add(TintedChip(
        color: context.colorScheme.primary,
        icon: Icons.compress_rounded,
        label: 'Squash merge',
        iconSize: 12,
      ));
    }
    if (rebaseMergeAllowed == true) {
      chips.add(TintedChip(
        color: context.colorScheme.primary,
        icon: Octicons.git_pull_request,
        label: 'Rebase merge',
        iconSize: 12,
      ));
    }
    if (autoMergeAllowed == true) {
      chips.add(TintedChip(
        color: DiffColors.addition,
        icon: Octicons.git_merge,
        label: 'Auto-merge',
        iconSize: 12,
      ));
    }
    if (deleteBranchOnMerge == true) {
      chips.add(TintedChip(
        color: context.colorScheme.onSurfaceVariant,
        icon: Octicons.trash,
        label: 'Delete branch on merge',
        iconSize: 12,
      ));
    }
    if (webCommitSignoffRequired == true) {
      chips.add(TintedChip(
        color: context.colorScheme.tertiary,
        icon: Icons.edit_rounded,
        label: 'Web commit signoff',
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

/// Row of GitHub achievement badges (Star, Campus Expert, Dev Program, Employee, Bug Bounty).
/// Each boolean when true renders a [TintedChip].
class GitHubBadges extends StatelessWidget {
  const GitHubBadges({
    this.isStar = false,
    this.isCampusExpert = false,
    this.isDeveloperProgramMember = false,
    this.isEmployee = false,
    this.isBugBountyHunter = false,
    super.key,
  });

  final bool isStar;
  final bool isCampusExpert;
  final bool isDeveloperProgramMember;
  final bool isEmployee;
  final bool isBugBountyHunter;

  @override
  Widget build(final BuildContext context) {
    final List<Widget> chips = <Widget>[];
    if (isStar) {
      chips.add(TintedChip(
        color: context.colorScheme.tertiary,
        icon: Octicons.star,
        label: 'GitHub Star',
        iconSize: 12,
      ));
    }
    if (isCampusExpert) {
      chips.add(TintedChip(
        color: context.colorScheme.primary,
        icon: Octicons.mortar_board,
        label: 'Campus Expert',
        iconSize: 12,
      ));
    }
    if (isDeveloperProgramMember) {
      chips.add(TintedChip(
        color: context.colorScheme.primary,
        icon: Octicons.code_square,
        label: 'Developer Program',
        iconSize: 12,
      ));
    }
    if (isEmployee) {
      chips.add(TintedChip(
        color: context.colorScheme.primary,
        icon: Icons.business_rounded,
        label: 'Employee',
        iconSize: 12,
      ));
    }
    if (isBugBountyHunter) {
      chips.add(TintedChip(
        color: context.colorScheme.error,
        icon: Octicons.bug,
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

/// Single social account entry for [SocialAccountsRow].
class SocialAccountChipData {
  const SocialAccountChipData({required this.provider, required this.url});
  final String provider; // e.g. TWITTER, LINKEDIN, BLUESKY
  final Uri url;
}

/// Row of social account chips with platform icons. Dedupe Twitter/X when [skipTwitter] is true.
class SocialAccountsRow extends StatelessWidget {
  const SocialAccountsRow({
    required this.accounts,
    this.skipTwitter = false,
    super.key,
  });

  final List<SocialAccountChipData> accounts;
  final bool skipTwitter;

  static IconData _iconForProvider(final String provider) {
    return switch (provider.toUpperCase()) {
      'TWITTER' || 'X' => Icons.alternate_email,
      'LINKEDIN' => Icons.business_center_rounded,
      'BLUESKY' => Icons.cloud_rounded,
      'YOUTUBE' => Icons.play_circle_filled_rounded,
      'TWITCH' => Icons.videocam_rounded,
      'MASTODON' => Icons.public_rounded,
      _ => Icons.link_rounded,
    };
  }

  @override
  Widget build(final BuildContext context) {
    final List<SocialAccountChipData> filtered = skipTwitter
        ? accounts
            .where((final SocialAccountChipData a) =>
                a.provider.toUpperCase() != 'TWITTER' &&
                a.provider.toUpperCase() != 'X')
            .toList()
        : accounts;
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: filtered
          .map(
            (final SocialAccountChipData a) => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => launchUrl(a.url),
                borderRadius: context.radius(RadiusSize.small),
                child: TintedChip(
                  color: context.colorScheme.primary,
                  icon: _iconForProvider(a.provider),
                  label: a.provider,
                  iconSize: 12,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// "Via Web" commit indicator.
class WebCommitIndicator extends StatelessWidget {
  const WebCommitIndicator({super.key});

  @override
  Widget build(final BuildContext context) {
    return TintedChip(
      color: context.colorScheme.onSurfaceVariant,
      icon: Icons.public_rounded,
      label: 'via Web',
      iconSize: 12,
    );
  }
}
