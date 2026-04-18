import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:diohub/common/nav_center/builders/common_metadata_builders.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub/common/widgets/metadata_rows.dart';
import 'package:diohub/common/widgets/metadata_section_sliver.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/common/widgets/user_status_pill.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/markdown_emoji.dart';

import 'package:diohub_graphql/queries/users/user_typedefs.dart';

Widget? buildStatusIndicators(UserProfileOwner userData) {
  return userData.maybeWhen(
    user: (UserProfile u) {
      final List<StatusFlag> flags = <StatusFlag>[
        if (u.status?.indicatesLimitedAvailability == true) StatusFlag.busy,
        if (u.isHireable == true) StatusFlag.hireable,
      ];
      final Widget? leading = u.status?.message != null
          ? UserStatusPill(
              emoji:
                  u.status!.emoji != null ? emoteText(u.status!.emoji!) : null,
              message: emoteText(u.status!.message!),
              indicatesLimitedAvailability:
                  u.status!.indicatesLimitedAvailability,
              compact: true,
            )
          : null;
      if (leading == null && flags.isEmpty) return null;
      return StatusIndicatorRow(leading: leading, flags: flags);
    },
    organization: (OrgProfile o) =>
        o.isVerified
            ? const StatusFlagRow(flags: <StatusFlag>[StatusFlag.verified])
            : null,
    orElse: () => null,
  );
}

String? expandedZoneText(UserProfileOwner userData) {
  return userData.maybeWhen(
    user: (UserProfile u) =>
        u.bio != null && u.bio!.isNotEmpty ? emoteText(u.bio!) : null,
    organization: (OrgProfile o) =>
        o.description != null && o.description!.isNotEmpty
            ? emoteText(o.description!)
            : null,
    orElse: () => null,
  );
}

List<ExpandedZoneDetail> expandedZoneDetails(
  UserProfileOwner userData,
) {
  return userData.maybeWhen(
    user: (UserProfile u) {
      final List<ExpandedZoneDetail> result = <ExpandedZoneDetail>[];
      if (u.status?.message != null) {
        final emoji =
            u.status!.emoji != null ? emoteText(u.status!.emoji!).trim() : '';
        final message = emoteText(u.status!.message!);
        result.add(
          StatusMessage(emoji.isNotEmpty ? '$emoji $message'.trim() : message),
        );
      }
      final List<StatusFlag> flags = <StatusFlag>[
        if (u.status?.indicatesLimitedAvailability == true) StatusFlag.busy,
        if (u.isHireable == true) StatusFlag.hireable,
      ];
      if (flags.isNotEmpty) {
        result.add(FlagSummary(flags));
      }
      return result;
    },
    organization: (OrgProfile o) {
      if (o.isVerified) {
        return <ExpandedZoneDetail>[
          FlagSummary([StatusFlag.verified])
        ];
      }
      return <ExpandedZoneDetail>[];
    },
    orElse: () => <ExpandedZoneDetail>[],
  );
}

List<MetadataSectionData> buildMetadataSections(
  BuildContext context,
  UserProfileOwner userData,
  int repoCount,
) {
  return userData.maybeWhen(
    user: (UserProfile user) =>
        _buildUserMetadata(context, user),
    organization: (OrgProfile org) =>
        _buildOrgMetadata(context, org, repoCount),
    orElse: () => <MetadataSectionData>[
      MetadataSectionData(
        title: 'Info',
        icon: Icons.info_outline_rounded,
        children: <Widget>[
          MetadataRow(
            icon: Icons.person_outline_rounded,
            label: 'Login',
            child: Text(
              userData.login,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
        ],
      ),
    ],
  );
}

List<Widget> _buildSocialAccountRows(
  UserProfile user,
) {
  final nodes = user.socialAccounts.nodes;
  if (nodes == null || nodes.isEmpty) return <Widget>[];
  final List<Widget> rows = <Widget>[];
  for (final node in nodes) {
    if (node == null) continue;
    final String label = node.displayName;
    rows.add(
      MetadataContactRow(
        icon: _socialIconForProvider(node.provider.name),
        value: label,
        onTap: () => launchUrl(node.url),
      ),
    );
  }
  return rows;
}

IconData _socialIconForProvider(String providerName) {
  switch (providerName.toUpperCase()) {
    case 'TWITTER':
    case 'X':
      return Icons.tag_rounded;
    case 'LINKEDIN':
      return Icons.business_center_rounded;
    case 'YOUTUBE':
      return Icons.play_circle_rounded;
    case 'MASTODON':
    case 'BLUESKY':
    case 'HOMETOWN':
      return Icons.chat_bubble_outline_rounded;
    case 'FACEBOOK':
      return Icons.facebook_rounded;
    case 'INSTAGRAM':
      return Icons.camera_alt_outlined;
    case 'TWITCH':
      return Icons.play_circle_filled_rounded;
    case 'REDDIT':
      return Icons.forum_outlined;
    case 'NPM':
      return Icons.code_rounded;
    default:
      return Icons.link_rounded;
  }
}

Widget? _buildHonorBadges(
  BuildContext context,
  UserProfile user,
) {
  final Color color = Theme.of(context).colorScheme.onSurfaceVariant;
  final List<Widget> chips = <Widget>[];
  if (user.isGitHubStar == true) {
    chips.add(
        TintedChip(color: color, icon: Octicons.star, label: 'GitHub Star'));
  }
  if (user.isCampusExpert == true) {
    chips.add(TintedChip(
        color: color, icon: Icons.school_rounded, label: 'Campus Expert'));
  }
  if (user.isDeveloperProgramMember == true) {
    chips.add(TintedChip(
        color: color, icon: Icons.code_rounded, label: 'Developer Program'));
  }
  if (user.isEmployee == true) {
    chips.add(TintedChip(
        color: color, icon: Icons.business_rounded, label: 'GitHub Staff'));
  }
  if (user.isBountyHunter == true) {
    chips.add(TintedChip(
        color: color,
        icon: Icons.bug_report_rounded,
        label: 'Bug Bounty Hunter'));
  }
  if (chips.isEmpty) return null;
  return Wrap(
    spacing: context.spacing.compactSpacing,
    runSpacing: context.spacing.compactSpacing,
    children: chips,
  );
}

List<MetadataSectionData> _buildUserMetadata(
  BuildContext context,
  UserProfile user,
) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme cs = theme.colorScheme;
  final AppSpacing spacing = context.spacing;
  final List<Widget> detailsChildren = <Widget>[];

  TextStyle valueStyle({FontWeight? weight}) =>
      theme.textTheme.bodySmall!.copyWith(
        fontSize: 12,
        fontWeight: weight ?? FontWeight.w400,
      );

  if (user.bio != null && user.bio!.isNotEmpty) {
    detailsChildren.add(
      MetadataGroupCard(
        title: 'Bio',
        children: <Widget>[ProfileBioCard(bio: user.bio!)],
      ),
    );
    detailsChildren.add(spacing.itemGap);
  }

  final List<Widget> identityChildren = <Widget>[];
  if (user.name != null && user.name!.isNotEmpty && user.name != user.login) {
    identityChildren.add(
      Text(
        user.name!,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }
  if (user.pronouns != null && user.pronouns!.isNotEmpty) {
    if (identityChildren.isNotEmpty) identityChildren.add(spacing.tightGap);
    identityChildren.add(
      Text(
        user.pronouns!,
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant.withOpacity(0.8),
        ),
      ),
    );
  }
  if (!user.isViewer && user.isFollowingViewer == true) {
    if (identityChildren.isNotEmpty) identityChildren.add(spacing.tightGap);
    identityChildren.add(
      TintedChip(
        color: cs.onSurfaceVariant,
        icon: Icons.person_outline_rounded,
        label: 'Follows you',
        border: true,
      ),
    );
  }
  final Widget? honorBadges = _buildHonorBadges(context, user);
  if (honorBadges != null) {
    if (identityChildren.isNotEmpty) identityChildren.add(spacing.tightGap);
    identityChildren.add(honorBadges);
  }
  if (user.status != null && user.status!.message != null) {
    if (identityChildren.isNotEmpty) identityChildren.add(spacing.tightGap);
    identityChildren.add(
      UserStatusPill(
        emoji:
            user.status!.emoji != null ? emoteText(user.status!.emoji!) : null,
        message: emoteText(user.status!.message!),
        indicatesLimitedAvailability:
            user.status!.indicatesLimitedAvailability == true,
        compact: false,
      ),
    );
  }
  if (identityChildren.isNotEmpty) {
    detailsChildren.add(
      MetadataGroupCard(
        title: 'Identity',
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: identityChildren,
          ),
        ],
      ),
    );
    detailsChildren.add(spacing.itemGap);
  }

  final List<Widget> contactRows = <Widget>[
    if (user.email.isNotEmpty)
      MetadataContactRow(
        icon: Icons.email_outlined,
        value: user.email,
        onTap: () => launchUrl(Uri.parse('mailto:${user.email}')),
      ),
    ..._buildSocialAccountRows(user),
    if (_buildSocialAccountRows(user).isEmpty)
      ...buildContactRows(
        email: null,
        twitterUsername: user.twitterUsername,
        websiteUrl: user.websiteUrl?.toString(),
      ),
    if (user.isSponsoringViewer == true)
      TintedChip(
        color: Colors.pink.shade100,
        icon: Octicons.heart,
        label: 'Sponsors you',
        border: true,
      ),
    if (user.viewerIsSponsoring == true)
      TintedChip(
        color: Colors.pink.shade100,
        icon: Octicons.heart,
        label: 'You sponsor',
        border: true,
      ),
  ];
  if (user.location != null) {
    contactRows.add(
      MetadataRow(
        icon: Icons.location_on_outlined,
        label: 'Location',
        child: Text(user.location!, style: valueStyle()),
      ),
    );
  }
  if (user.company != null) {
    contactRows.add(
      MetadataRow(
        icon: Icons.business_outlined,
        label: 'Company',
        child: Text(user.company!, style: valueStyle()),
      ),
    );
  }
  final List<MetadataFlag> flagList = <MetadataFlag>[];
  if (user.isHireable == true) {
    flagList.add(
      const MetadataFlag(
        label: 'Available for hire',
        icon: Icons.work_outline_rounded,
        color: Colors.green,
      ),
    );
  }
  if (user.hasSponsorsListing == true) {
    flagList.add(
      const MetadataFlag(
        label: 'Sponsors',
        icon: Octicons.heart,
        color: Colors.pink,
      ),
    );
  }
  if (flagList.isNotEmpty) {
    contactRows.add(MetadataFlagWrap(flags: flagList));
  }
  if (contactRows.isNotEmpty) {
    detailsChildren.add(
      MetadataGroupCard(
        title: 'Contact',
        children: <Widget>[
          Column(mainAxisSize: MainAxisSize.min, children: contactRows),
        ],
      ),
    );
    detailsChildren.add(spacing.itemGap);
  }

  final List<MetadataStat> userStats = <MetadataStat>[
    MetadataStat(
      label: 'PRs',
      value: '${user.pullRequests.totalCount}',
      icon: Octicons.git_pull_request,
    ),
    MetadataStat(
      label: 'issues',
      value: '${user.issues.totalCount}',
      icon: Octicons.issue_opened,
    ),
    MetadataStat(
      label: 'stars',
      value: '${user.starredRepositories.totalCount}',
      icon: Octicons.star,
    ),
    MetadataStat(
      label: 'orgs',
      value: '${user.organizations.totalCount}',
      icon: Icons.corporate_fare_rounded,
    ),
    MetadataStat(
      label: 'gists',
      value: '${user.gists.totalCount}',
      icon: Octicons.code,
    ),
  ];
  detailsChildren.add(
    MetadataGroupCard(
      title: 'Activity',
      children: <Widget>[MetadataStatBar(stats: userStats)],
    ),
  );
  detailsChildren.add(spacing.itemGap);

  detailsChildren.add(
    buildTimestampsGroup(
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      title: 'Timeline',
    ),
  );

  return <MetadataSectionData>[
    MetadataSectionData(
      title: 'Details',
      icon: Icons.info_outline_rounded,
      variant: MetadataSectionVariant.strong,
      children: detailsChildren,
    ),
  ];
}

List<MetadataSectionData> _buildOrgMetadata(
  BuildContext context,
  OrgProfile org,
  int repoCount,
) {
  final AppSpacing spacing = context.spacing;
  final List<Widget> detailsChildren = <Widget>[];

  TextStyle valueStyle() => Theme.of(context).textTheme.bodySmall!.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  if (org.description != null && org.description!.isNotEmpty) {
    detailsChildren.add(
      Padding(
        padding: spacing.metadataRowPadding,
        child: Text(
          org.description!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
    detailsChildren.add(spacing.itemGap);
  }

  if (org.isVerified) {
    detailsChildren.add(
      TintedChip(
        color: Colors.blue,
        icon: Icons.verified_rounded,
        label: 'Verified',
        border: true,
      ),
    );
    detailsChildren.add(spacing.itemGap);
  }
  if (org.viewerIsAMember == true) {
    detailsChildren.add(
      TintedChip(
        color: Theme.of(context).colorScheme.primaryContainer,
        icon: Icons.person_rounded,
        label: 'Member',
        border: true,
      ),
    );
    detailsChildren.add(spacing.itemGap);
  }

  if (org.hasSponsorsListing == true) {
    detailsChildren.add(
      MetadataFlagWrap(
        flags: <MetadataFlag>[
          const MetadataFlag(
            label: 'Sponsors',
            icon: Octicons.heart,
            color: Colors.pink,
          ),
        ],
      ),
    );
    detailsChildren.add(spacing.itemGap);
  }

  final List<Widget> orgContactRows = buildContactRows(
    email:
        org.orgEmail != null && org.orgEmail!.isNotEmpty ? org.orgEmail : null,
    twitterUsername: org.twitterUsername,
    websiteUrl: org.websiteUrl?.toString(),
  );
  if (orgContactRows.isNotEmpty) {
    detailsChildren.add(
      Column(mainAxisSize: MainAxisSize.min, children: orgContactRows),
    );
    detailsChildren.add(spacing.itemGap);
  }

  if (org.location != null) {
    detailsChildren.add(
      MetadataRow(
        icon: Icons.location_on_outlined,
        label: 'Location',
        child: Text(org.location!, style: valueStyle()),
      ),
    );
    detailsChildren.add(spacing.itemGap);
  }

  final List<MetadataStat> orgStats = <MetadataStat>[
    MetadataStat(
      label: 'repos',
      value: '$repoCount',
      icon: Icons.folder,
    ),
  ];
  if (org.membersWithRole.totalCount > 0) {
    orgStats.add(
      MetadataStat(
        label: 'members',
        value: '${org.membersWithRole.totalCount}',
        icon: Icons.people,
      ),
    );
  }
  detailsChildren.add(
    MetadataGroupCard(
      title: 'Activity',
      children: <Widget>[MetadataStatBar(stats: orgStats)],
    ),
  );
  detailsChildren.add(spacing.itemGap);

  detailsChildren.add(
    buildTimestampsGroup(
      createdAt: org.createdAt,
      updatedAt: org.updatedAt,
      title: 'Timeline',
    ),
  );

  return <MetadataSectionData>[
    MetadataSectionData(
      title: 'Details',
      icon: Icons.info_outline_rounded,
      variant: MetadataSectionVariant.strong,
      children: detailsChildren,
    ),
  ];
}
