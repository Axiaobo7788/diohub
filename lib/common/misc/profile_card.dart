/// A widget that displays the profile card of a user.
///
/// This widget displays the user's avatar, name, bio, and number of followers.
/// It also allows the user to navigate to the profile page of the user when tapped.
///
/// The [ProfileCard] widget takes [ProfileCardInput] (GQL fragment or full owner).
///
/// The [ProfileCardLoading] widget fetches full profile and unwraps
/// [UserProfileOwner] to [ProfileCardInputUser] or [ProfileCardInputOrg].
///
/// The [actorAvatarUri] function
/// are utility functions that extract the login and avatar URL of a [Actor].
library;

import 'package:diohub/common/cards/chip_priority.dart';
import 'package:diohub/common/cards/entity_card_layout.dart';
import 'package:diohub/common/cards/inline_metadata_line.dart';
import 'package:diohub/common/cards/chips/user_activity_indicator.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/app/settings/card_display.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' as gql;
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart'
    show Actor;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/profile_card_input.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/providers/users/user_providers.dart'
    show userProvider, UserProfileData, userProfileDataToProfileCardInput;
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Extension on ProfileCardInput to extract common fields
extension ProfileCardInputX on ProfileCardInput {
  String get login => switch (this) {
        ProfileCardInputUser(:final UserCardData user) => switch (user) {
            FragmentUser(:final gql.UserCardData user) => user.login,
            FullUser(:final UserProfile user) => user.login,
          },
        ProfileCardInputOrg(:final OrgCardData org) => switch (org) {
            FragmentOrg(:final gql.OrgCardData org) => org.login,
            FullOrg(:final OrgProfile org) => org.login,
          },
      };

  Uri? get avatarUrl => switch (this) {
        ProfileCardInputUser(:final UserCardData user) => switch (user) {
            FragmentUser(:final gql.UserCardData user) => user.avatarUrl,
            FullUser(:final UserProfile user) => user.avatarUrl,
          },
        ProfileCardInputOrg(:final OrgCardData org) => switch (org) {
            FragmentOrg(:final gql.OrgCardData org) => org.avatarUrl,
            FullOrg(:final OrgProfile org) => org.avatarUrl,
          },
      };

  String? get name => switch (this) {
        ProfileCardInputUser(:final UserCardData user) => switch (user) {
            FragmentUser(:final gql.UserCardData user) => user.name,
            FullUser(:final UserProfile user) => user.name,
          },
        ProfileCardInputOrg(:final OrgCardData org) => switch (org) {
            FragmentOrg(:final gql.OrgCardData org) => org.name,
            FullOrg(:final OrgProfile org) => org.name,
          },
      };

  String? get bio => switch (this) {
        ProfileCardInputUser(:final UserCardData user) => switch (user) {
            FragmentUser(:final gql.UserCardData user) => user.bio,
            FullUser(:final UserProfile user) => user.bio,
          },
        ProfileCardInputOrg(:final OrgCardData org) => switch (org) {
            FragmentOrg(:final gql.OrgCardData org) => org.description,
            FullOrg(:final OrgProfile org) => org.description,
          },
      };

  int? get repositoryCount => switch (this) {
        ProfileCardInputUser(:final UserCardData user) => switch (user) {
            FragmentUser(:final gql.UserCardData user) =>
              user.repositories.totalCount,
            FullUser(:final UserProfile user) => user.repositories.totalCount,
          },
        ProfileCardInputOrg(:final OrgCardData org) => switch (org) {
            FragmentOrg(:final gql.OrgCardData org) =>
              org.repositories.totalCount,
            FullOrg(:final OrgProfile org) => org.repositories.totalCount,
          },
      };

  int? get followersCount => switch (this) {
        ProfileCardInputUser(:final UserCardData user) => switch (user) {
            FragmentUser(:final gql.UserCardData user) =>
              user.followers.totalCount,
            FullUser(:final UserProfile user) => user.followers.totalCount,
          },
        ProfileCardInputOrg() => null,
      };

  bool get isOrganization => this is ProfileCardInputOrg;
}

class ProfileCard extends ConsumerWidget {
  const ProfileCard(
    this.input, {
    super.key,
  });

  final ProfileCardInput input;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settings = ref.watch(cardDisplayProvider);
    
    // Build titlePrefix: avatar
    final Widget titlePrefix = UserAvatar(
      avatarUrl: input.avatarUrl?.toString(),
      size: 30,
    );
    
    // Build title: name + verified badge
    final String? displayName = input.name;
    final Widget title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (displayName != null && displayName.isNotEmpty)
          Flexible(
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (input.isVerified) ...[
          SizedBox(width: context.spacing.tightSpacing),
          Icon(
            Octicons.verified,
            size: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ],
    );
    
    // Build metadataLine: @login + pronouns + location
    final List<InlineMetadataItem> metadataItems = [];
    metadataItems.add(InlineMetadataItem(text: '@${input.login}'));
    if (input.pronouns != null && input.pronouns!.isNotEmpty) {
      metadataItems.add(InlineMetadataItem(text: input.pronouns!));
    }
    if (input.location != null && input.location!.isNotEmpty) {
      metadataItems.add(InlineMetadataItem(text: input.location!));
    }
    final Widget? metadataLine = metadataItems.isNotEmpty
        ? InlineMetadataLine(items: metadataItems)
        : null;
    
    // Build trailing: follow button
    Widget? trailing;
    if (input.login.isNotEmpty &&
        input.viewerCanFollow &&
        input.id != null &&
        !input.isOrganization) {
      trailing = _ProfileFollowChip(
        login: input.login,
        userId: input.id!,
        initialIsFollowing: input.viewerIsFollowing,
      );
    }
    
    // Build chips with priority
    final allChips = _buildPrioritizedChips(context, ref, settings);
    final int maxVisible = 4;
    final chips = buildChipSection(
      chips: allChips,
      maxVisible: maxVisible,
    );
    
    // Build supplementary: StatusPill + bio + UserActivityIndicator
    Widget? supplementary;
    final String? statusMessage = input.statusMessage;
    final String? statusEmoji = input.statusEmoji;
    final String? bio = input.bio;
    final bool hasStatus = statusMessage != null && statusMessage.isNotEmpty;
    final bool hasBio = bio != null && bio.isNotEmpty;
    final bool showActivity = settings.showUserActivity && input is ProfileCardInputUser;
    
    if (hasStatus || hasBio || showActivity) {
      supplementary = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasStatus) ...[
            StatusPill(
              emoji: statusEmoji,
              message: statusMessage,
            ),
            if (hasBio || showActivity) SizedBox(height: context.spacing.compactSpacing),
          ],
          if (hasBio) ...[
            Text(
              bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (showActivity) SizedBox(height: context.spacing.compactSpacing),
          ],
          if (showActivity)
            UserActivityIndicator(
              weeklyContributions: const <int>[],
            ),
        ],
      );
    }
    
    return EntityCardLayout(
      titlePrefix: titlePrefix,
      title: title,
      metadataLine: metadataLine,
      trailing: trailing,
      chips: chips.isNotEmpty ? chips : null,
      supplementary: supplementary,
    );
  }
  
  List<PrioritizedChip> _buildPrioritizedChips(
    BuildContext context,
    WidgetRef ref,
    CardDisplaySettings settings,
  ) {
    final int? repoCount = input.repositoryCount;
    final int? followersCount = input.followersCount;
    final int? membersCount = input.membersCount;
    final String? company = input.company;
    final String? websiteUrl = input.websiteUrl?.toString();
    final DateTime? createdAt = input.createdAt;
    final int? teamsCount = input.teamsCount;
    final bool isFollowingViewer = input.isFollowingViewer;
    
    return [
      // Critical: Repository count
      if (repoCount != null)
        PrioritizedChip(
          priority: ChipPriority.critical,
          widget: MetadataChip(
            leading: const Icon(Octicons.repo, size: 12),
            label: _shortCount(repoCount),
          ),
        ),
      
      // High: Followers/Members
      if (followersCount != null)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: MetadataChip(
            leading: const Icon(Octicons.people, size: 12),
            label: _shortCount(followersCount),
          ),
        ),
      if (membersCount != null)
        PrioritizedChip(
          priority: ChipPriority.high,
          widget: MetadataChip(
            leading: const Icon(Octicons.people, size: 12),
            label: _shortCount(membersCount),
          ),
        ),
      
      // High: Organization badge
      if (input.isOrganization)
        const PrioritizedChip(
          priority: ChipPriority.high,
          widget: MetadataChip(
            leading: Icon(Octicons.organization, size: 12),
            label: 'Organization',
          ),
        ),
      
      // Medium: Company
      if (company != null && company.isNotEmpty)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: MetadataChip(
            leading: const Icon(Octicons.organization, size: 12),
            label: company,
          ),
        ),
      
      // Medium: Following viewer
      if (isFollowingViewer)
        PrioritizedChip(
          priority: ChipPriority.medium,
          widget: TintedChip(
            color: Theme.of(context).colorScheme.primary,
            icon: Octicons.person,
            label: 'Follows you',
            iconSize: 12,
          ),
        ),
      
      // Low: Website
      if (websiteUrl != null && websiteUrl.isNotEmpty)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: GestureDetector(
            onTap: () => launchUrl(Uri.parse(websiteUrl)),
            child: MetadataChip(
              leading: const Icon(Octicons.link, size: 12),
              label: _stripProtocol(websiteUrl),
              accentColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      
      // Low: Joined date
      if (createdAt != null)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: MetadataChip(
            leading: const Icon(Octicons.calendar, size: 12),
            label: 'Joined ${createdAt.toRelativeDate(shorten: true)}',
          ),
        ),
      
      // Low: Teams count
      if (teamsCount != null && teamsCount > 0)
        PrioritizedChip(
          priority: ChipPriority.low,
          widget: MetadataChip(
            leading: const Icon(Octicons.people, size: 12),
            label: '$teamsCount teams',
          ),
        ),
    ];
  }
}

/// Inline follow/unfollow chip for profile cards. Toggles follow state on tap.
class _ProfileFollowChip extends ConsumerStatefulWidget {
  const _ProfileFollowChip({
    required this.login,
    required this.userId,
    required this.initialIsFollowing,
  });

  final String login;
  final String userId;
  final bool initialIsFollowing;

  @override
  ConsumerState<_ProfileFollowChip> createState() => _ProfileFollowChipState();
}

class _ProfileFollowChipState extends ConsumerState<_ProfileFollowChip> {
  late bool _isFollowing;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.initialIsFollowing;
  }

  @override
  void didUpdateWidget(covariant final _ProfileFollowChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIsFollowing != widget.initialIsFollowing) {
      _isFollowing = widget.initialIsFollowing;
    }
  }

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color foreground = _isFollowing
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.strong;
    return GestureDetector(
      onTap: () async {
        ref.read(hapticServiceProvider).lightImpact();
        setState(() => _isFollowing = !_isFollowing);
        await ref
            .read(userProvider(UserRef(login: widget.login)).notifier)
            .changeFollowStatus(widget.userId, follow: _isFollowing);
      },
      child: Container(
        padding: spacing.chipPadding,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(
            alpha: _isFollowing ? 0.15 : 0.08,
          ),
          borderRadius: context.radius(RadiusSize.small),
          border: Border.all(
            color: _isFollowing
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.onSurfaceVariant.tintMedium,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _isFollowing ? Octicons.person_fill : Octicons.person_add,
              size: 12,
              color: foreground,
            ),
            spacing.tightGap,
            Text(
              _isFollowing ? 'Unfollow' : 'Follow',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileCardLoading extends ConsumerWidget {
  const ProfileCardLoading(
    this.userRef, {
    super.key,
  });

  final UserRef userRef;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<UserProfileData> userAsync =
        ref.watch(userProvider(userRef));
    return AsyncValueBuilder<UserProfileData>(
      value: userAsync,
      skeleton: (final _) => Padding(
        padding: context.spacing.pagePadding,
        child: const LoadingIndicator(),
      ),
      error: (final Object e, final StackTrace st) => Padding(
        padding: context.spacing.pagePadding,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              context.spacing.itemGap,
              Text(e.toString(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (final UserProfileData data) {
        final ProfileCardInput input = userProfileDataToProfileCardInput(data);
        return BorderedContainer(
          ref: UserRef(login: input.login),
          child: ProfileCard(input),
        );
      },
    );
  }
}

String _shortCount(final int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

String _stripProtocol(final String url) {
  final u = url.trim().toLowerCase();
  if (u.startsWith('https://')) return url.substring(8).trim();
  if (u.startsWith('http://')) return url.substring(7).trim();
  return url;
}

Uri actorAvatarUri(final Actor actor) => actor.avatarUrl;
