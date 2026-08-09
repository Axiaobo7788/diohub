import 'dart:async';

import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/utils/markdown_emoji.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_section.dart';
import 'package:diohub/view/profile/about/widgets/contribution_calendar_section.dart';
import 'package:diohub/view/profile/md3/profile_md3_layout.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileOverviewMd3 extends ConsumerWidget {
  const ProfileOverviewMd3({
    required this.profile,
    required this.windowClass,
    required this.readmeAsync,
    required this.contributionQueryKey,
    required this.onEditProfile,
    required this.onToggleFollow,
    required this.onRetryContributions,
    super.key,
  });

  final UserProfileData profile;
  final ProfileWindowClass windowClass;
  final AsyncValue<String?>? readmeAsync;
  final ContributionQueryKey contributionQueryKey;
  final VoidCallback onEditProfile;
  final Future<void> Function({required bool follow}) onToggleFollow;
  final VoidCallback onRetryContributions;

  bool get _showInlineIdentity => windowClass != ProfileWindowClass.expanded;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final UserProfileOwner owner = profile.owner;
    final UserProfile? user = owner.maybeWhen(
      user: (final UserProfile value) => value,
      orElse: () => null,
    );
    final List<RepoCardData> pinned = owner.maybeWhen(
      user: (final UserProfile value) =>
          value.pinnedItems.edges
              ?.map((final edge) => edge?.node)
              .whereType<RepoCardData>()
              .toList() ??
          <RepoCardData>[],
      organization: (final OrgProfile value) =>
          value.pinnedItems.edges
              ?.map((final edge) => edge?.node)
              .whereType<RepoCardData>()
              .toList() ??
          <RepoCardData>[],
      orElse: () => <RepoCardData>[],
    );
    final AsyncValue<ContributionCollectionResult>? contributions = user == null
        ? null
        : ref.watch(userContributionsProvider(contributionQueryKey));
    final String readmeRepoFullName = owner.maybeWhen(
      user: (final UserProfile value) => '${value.login}/${value.login}',
      organization: (final OrgProfile value) => '${value.login}/.github',
      orElse: () => '${owner.login}/${owner.login}',
    );
    final double inset = ProfileMd3Layout.pageInsetFor(windowClass);

    return CustomScrollView(
      key: const PageStorageKey<String>('profile-overview-scroll'),
      slivers: <Widget>[
        if (_showInlineIdentity)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(inset, 24, inset, 8),
              child: ProfileIdentityPanel(
                profile: profile,
                windowClass: windowClass,
                onEditProfile: onEditProfile,
                onToggleFollow: onToggleFollow,
              ),
            ),
          ),
        if (readmeAsync != null) ...<Widget>[
          SliverToBoxAdapter(
            child: _ProfileSectionHeading(
              title: '${owner.login}/README.md',
              icon: Icons.book_outlined,
              margin: EdgeInsets.fromLTRB(inset, 24, inset, 0),
            ),
          ),
          RepositoryReadmeSliver(
            readmeAsync: readmeAsync!,
            repoFullName: readmeRepoFullName,
            contentPadding: EdgeInsets.fromLTRB(inset, 20, inset, 24),
          ),
        ],
        if (pinned.isNotEmpty) ...<Widget>[
          SliverToBoxAdapter(
            child: _ProfileSectionHeading(
              title: context.l10n.profilePinned,
              icon: Icons.push_pin_outlined,
              margin: EdgeInsets.fromLTRB(inset, 24, inset, 12),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            sliver: SliverLayoutBuilder(
              builder:
                  (
                    final BuildContext context,
                    final SliverConstraints constraints,
                  ) {
                    final int columns = constraints.crossAxisExtent >= 720
                        ? 2
                        : 1;
                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (final BuildContext context, final int index) =>
                            _PinnedRepositoryCard(repository: pinned[index]),
                        childCount: pinned.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 150,
                      ),
                    );
                  },
            ),
          ),
        ],
        if (contributions != null) ...<Widget>[
          SliverToBoxAdapter(
            child: _ProfileSectionHeading(
              title: context.l10n.profileContributions,
              icon: Icons.grid_view_outlined,
              margin: EdgeInsets.fromLTRB(inset, 28, inset, 12),
            ),
          ),
          SliverAsyncValueBuilder<ContributionCollectionResult>(
            value: contributions,
            data: (final ContributionCollectionResult result) {
              final ContributionViewModel data = result.viewModel;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                child: Card.outlined(
                  margin: EdgeInsets.zero,
                  child: ContributionCalendarSection(
                    weeks: data.weeks,
                    totalContributions: data.totalContributions,
                    colors: data.colors,
                    providerKey: contributionQueryKey,
                    createdAt: user?.createdAt,
                    commits: data.totalCommitContributions,
                    pullRequests: data.totalPullRequestContributions,
                    issues: data.totalIssueContributions,
                    reviews: data.totalPullRequestReviewContributions,
                    contributionResult: result,
                    userRef: UserRef(login: owner.login),
                  ),
                ),
              );
            },
            loading: (final BuildContext context) => Padding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: const _ContributionSkeleton(),
            ),
            error: (final Object error, final StackTrace stack) => Padding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              child: _ProfileSectionError(
                message: context.l10n.profileContributionsLoadError,
                onRetry: onRetryContributions,
              ),
            ),
          ),
          if (contributions.hasValue) ...<Widget>[
            SliverToBoxAdapter(
              child: _ProfileSectionHeading(
                title: context.l10n.profileContributionActivity,
                icon: Icons.timeline_outlined,
                margin: EdgeInsets.fromLTRB(inset, 28, inset, 8),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 0, inset, 32),
              sliver: ActivityTimelineSection(
                providerKey: contributionQueryKey,
              ),
            ),
          ],
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class ProfileIdentityPanel extends StatelessWidget {
  const ProfileIdentityPanel({
    required this.profile,
    required this.windowClass,
    required this.onEditProfile,
    required this.onToggleFollow,
    super.key,
  });

  final UserProfileData profile;
  final ProfileWindowClass windowClass;
  final VoidCallback onEditProfile;
  final Future<void> Function({required bool follow}) onToggleFollow;

  @override
  Widget build(final BuildContext context) {
    final UserProfileOwner owner = profile.owner;
    final UserProfile? user = owner.maybeWhen(
      user: (final UserProfile value) => value,
      orElse: () => null,
    );
    final OrgProfile? organization = owner.maybeWhen(
      organization: (final OrgProfile value) => value,
      orElse: () => null,
    );
    final String displayName = user?.name ?? organization?.name ?? owner.login;
    final String? description = user?.bio ?? organization?.description;
    final double avatarSize = ProfileMd3Layout.avatarSizeFor(windowClass);
    final bool compact = windowClass != ProfileWindowClass.expanded;

    return Column(
      key: const ValueKey<String>('profile-identity-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (compact)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              UserAvatar(
                avatarUrl: owner.avatarUrl.toString(),
                fallbackText: owner.login,
                size: avatarSize,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _ProfileNames(
                  displayName: displayName,
                  login: owner.login,
                  pronouns: user?.pronouns,
                ),
              ),
            ],
          )
        else ...<Widget>[
          UserAvatar(
            avatarUrl: owner.avatarUrl.toString(),
            fallbackText: owner.login,
            size: avatarSize,
          ),
          const SizedBox(height: 16),
          _ProfileNames(
            displayName: displayName,
            login: owner.login,
            pronouns: user?.pronouns,
          ),
        ],
        if (user?.status?.message case final String statusMessage) ...<Widget>[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: user!.isViewer ? onEditProfile : null,
            icon: Text(
              user.status?.emoji == null
                  ? '🙂'
                  : emoteText(user.status!.emoji!),
            ),
            label: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                emoteText(statusMessage),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        if (description != null && description.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text(
            emoteText(description),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: 16),
        if (user != null)
          SizedBox(
            width: double.infinity,
            child: user.isViewer
                ? OutlinedButton(
                    onPressed: onEditProfile,
                    child: Text(context.l10n.profileEdit),
                  )
                : FilledButton.tonal(
                    onPressed: user.viewerCanFollow
                        ? () => onToggleFollow(follow: !user.viewerIsFollowing)
                        : null,
                    child: Text(
                      user.viewerIsFollowing
                          ? context.l10n.profileUnfollow
                          : context.l10n.profileFollow,
                    ),
                  ),
          ),
        if (user != null) ...<Widget>[
          const SizedBox(height: 16),
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              const Icon(Icons.people_outline, size: 18),
              Text(
                context.l10n.profileFollowersCount(user.followers.totalCount),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text('·', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                context.l10n.profileFollowingCount(user.following.totalCount),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        ..._metadataRows(context, user, organization),
      ],
    );
  }

  List<Widget> _metadataRows(
    final BuildContext context,
    final UserProfile? user,
    final OrgProfile? organization,
  ) {
    final List<Widget> rows = <Widget>[];
    void add(
      final IconData icon,
      final String? value, {
      final VoidCallback? onTap,
    }) {
      final String normalized = value?.trim() ?? '';
      if (normalized.isEmpty) return;
      final Widget row = Row(
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              normalized,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: onTap == null
                  ? null
                  : TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: Theme.of(context).colorScheme.primary,
                    ),
            ),
          ),
        ],
      );
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: onTap == null ? 8 : 4),
          child: onTap == null
              ? ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 32),
                  child: Center(child: row),
                )
              : Semantics(
                  container: true,
                  link: true,
                  label: normalized,
                  onTap: onTap,
                  child: ExcludeSemantics(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(6),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Center(child: row),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      );
    }

    add(Icons.business_outlined, user?.company);
    add(Icons.location_on_outlined, user?.location ?? organization?.location);
    final Uri? website = user?.websiteUrl ?? organization?.websiteUrl;
    add(
      Icons.link,
      website?.toString(),
      onTap: website == null
          ? null
          : () => unawaited(
              launchUrl(website, mode: LaunchMode.externalApplication),
            ),
    );
    add(Icons.mail_outline, user?.email ?? organization?.orgEmail);
    if (user != null) {
      for (final Query$userInfo$repositoryOwner$$User$socialAccounts$nodes
          account
          in user.socialAccounts.nodes
                  ?.whereType<
                    Query$userInfo$repositoryOwner$$User$socialAccounts$nodes
                  >() ??
              const <
                Query$userInfo$repositoryOwner$$User$socialAccounts$nodes
              >[]) {
        add(
          Icons.alternate_email,
          account.displayName,
          onTap: () => unawaited(
            launchUrl(account.url, mode: LaunchMode.externalApplication),
          ),
        );
      }
    }
    return rows;
  }
}

class _ProfileNames extends StatelessWidget {
  const _ProfileNames({
    required this.displayName,
    required this.login,
    this.pronouns,
  });

  final String displayName;
  final String login;
  final String? pronouns;

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      Text(
        login,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
      ),
      if (pronouns != null && pronouns!.trim().isNotEmpty)
        Text(
          pronouns!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
    ],
  );
}

class _PinnedRepositoryCard extends ConsumerWidget {
  const _PinnedRepositoryCard({required this.repository});

  final RepoCardData repository;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final RepoRef repoRef = RepoRef.fromRepoCardFields(repository);
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(repoRef.navigate(context, ref)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.book_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      repository.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _VisibilityLabel(isPrivate: repository.isPrivate),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  repository.description ?? context.l10n.repoNoDescription,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  if (repository.primaryLanguage
                      case final language?) ...<Widget>[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: language.color == null
                            ? Theme.of(context).colorScheme.outline
                            : Color(
                                int.parse(
                                      language.color!.replaceFirst('#', ''),
                                      radix: 16,
                                    ) |
                                    0xFF000000,
                              ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      language.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Icon(Icons.star_outline, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    repository.stargazerCount.toShortenedStr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.fork_right_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    repository.forkCount.toShortenedStr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityLabel extends StatelessWidget {
  const _VisibilityLabel({required this.isPrivate});

  final bool isPrivate;

  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      isPrivate ? context.l10n.repoPrivate : context.l10n.repoPublic,
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}

class _ProfileSectionHeading extends StatelessWidget {
  const _ProfileSectionHeading({
    required this.title,
    required this.icon,
    required this.margin,
  });

  final String title;
  final IconData icon;
  final EdgeInsets margin;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: margin,
    child: Row(
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _ContributionSkeleton extends StatelessWidget {
  const _ContributionSkeleton();

  @override
  Widget build(final BuildContext context) => const Card.outlined(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: ShimmerScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ShimmerBone.title(width: 180),
            SizedBox(height: 16),
            ShimmerBone.block(height: 132),
            SizedBox(height: 12),
            ShimmerBone.label(width: 120),
          ],
        ),
      ),
    ),
  );
}

class _ProfileSectionError extends StatelessWidget {
  const _ProfileSectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    ),
  );
}
