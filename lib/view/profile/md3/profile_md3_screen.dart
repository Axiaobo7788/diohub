import 'dart:async';

import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/common/riverpod/async_value_builder.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/dashboard/home_top_repositories_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/profile/md3/profile_md3_layout.dart';
import 'package:diohub/view/profile/md3/profile_md3_shell.dart';
import 'package:diohub/view/profile/md3/profile_navigation.dart';
import 'package:diohub/view/profile/md3/profile_overview_md3.dart';
import 'package:diohub/view/profile/packages/profile_packages_tab.dart';
import 'package:diohub/view/profile/projects/profile_projects_tab.dart';
import 'package:diohub/view/profile/stars/profile_stars_tab.dart';
import 'package:diohub/view/profile/widgets/config/profile_settings_and_sheets.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileMd3Screen extends ConsumerStatefulWidget {
  const ProfileMd3Screen({
    required this.userRef,
    required this.onOpenLegacy,
    super.key,
  });

  final UserRef userRef;
  final VoidCallback onOpenLegacy;

  @override
  ConsumerState<ProfileMd3Screen> createState() => _ProfileMd3ScreenState();
}

class _ProfileMd3ScreenState extends ConsumerState<ProfileMd3Screen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _contentAnimation;
  late int _selectedIndex;
  int _motionDirection = 1;
  late final Set<int> _visitedIndexes;
  late ContributionQueryKey _contributionQueryKey;
  late final List<GlobalKey<_ProfileDataTabState>> _dataTabKeys;

  @override
  void initState() {
    super.initState();
    _selectedIndex = ProfileNavigationDestination.fromPath(
      widget.userRef.tab,
    ).index;
    _visitedIndexes = <int>{_selectedIndex};
    _contributionQueryKey = ContributionQueryKey.lastYear(widget.userRef.login);
    _dataTabKeys = List<GlobalKey<_ProfileDataTabState>>.generate(
      ProfileNavigationDestination.values.length,
      (final int index) =>
          GlobalKey<_ProfileDataTabState>(debugLabel: 'profile-tab-$index'),
    );
    _tabController = TabController(
      length: ProfileNavigationDestination.values.length,
      initialIndex: _selectedIndex,
      vsync: this,
    )..addListener(_handleTabChanged);
    _contentAnimation = AnimationController(
      vsync: this,
      duration: kTabTransitionDuration,
      value: 1,
    );
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    _contentAnimation.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    final int nextIndex = _tabController.index;
    if (!mounted || nextIndex == _selectedIndex) return;
    final int previousIndex = _selectedIndex;
    setState(() {
      _motionDirection = nextIndex > previousIndex ? 1 : -1;
      _selectedIndex = nextIndex;
      _visitedIndexes.add(nextIndex);
    });
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _contentAnimation.value = 1;
    } else {
      _contentAnimation.forward(from: 0);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(userProvider(widget.userRef));
    ref.invalidate(profileReadmeHtmlProvider(widget.userRef));
    ref.invalidate(orgProfileReadmeHtmlProvider(widget.userRef));
    ref.invalidate(userContributionsProvider(_contributionQueryKey));
    if (_selectedIndex > 0) {
      await _dataTabKeys[_selectedIndex].currentState?.refresh();
    }
  }

  Future<void> _showEditProfile() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final BuildContext sheetContext) => Consumer(
        builder:
            (
              final BuildContext context,
              final WidgetRef sheetRef,
              final Widget? child,
            ) {
              final List<Widget> sections = profileSettingsSections(
                context,
                sheetRef,
                widget.userRef,
              );
              return SafeArea(
                child: FractionallySizedBox(
                  heightFactor: 0.9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                context.l10n.profileEdit,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: context.l10n.commonCancel,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: sections.length,
                          separatorBuilder:
                              (final BuildContext context, final int index) =>
                                  const SizedBox(height: 16),
                          itemBuilder:
                              (final BuildContext context, final int index) =>
                                  sections[index],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
      ),
    );
  }

  Future<void> _toggleFollow({required final bool follow}) async {
    final UserProfileData? profile = ref
        .read(userProvider(widget.userRef))
        .value;
    final UserProfile? user = profile?.owner.maybeWhen(
      user: (final UserProfile value) => value,
      orElse: () => null,
    );
    if (user == null) return;
    await ref
        .read(userProvider(widget.userRef).notifier)
        .changeFollowStatus(user.id, follow: follow, isOrg: false);
  }

  @override
  Widget build(final BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final bool accountResolved =
        accountState.hasValue && !accountState.hasError;
    final AccountModel? account = accountResolved
        ? accountState.value?.activeAccountModel
        : null;
    final AsyncValue<List<HomeRepositoryItem>> topRepositories = account == null
        ? const AsyncData<List<HomeRepositoryItem>>(<HomeRepositoryItem>[])
        : ref.watch(
            homeTopRepositoriesProvider((
              accountKey: account.accountKey,
              login: account.username,
            )),
          );
    final AsyncValue<UserProfileData> profileAsync = ref.watch(
      userProvider(widget.userRef),
    );
    final UserProfileData? profile = profileAsync.value;
    final UserProfile? user = profile?.owner.maybeWhen(
      user: (final UserProfile value) => value,
      orElse: () => null,
    );
    final OrgProfile? organization = profile?.owner.maybeWhen(
      organization: (final OrgProfile value) => value,
      orElse: () => null,
    );

    return ProfileMd3Shell(
      login: widget.userRef.login,
      account: account,
      accountLoading: !accountResolved,
      topRepositories: topRepositories,
      onRefresh: _refresh,
      onOpenLegacy: widget.onOpenLegacy,
      navigation: ProfileNavigation(
        controller: _tabController,
        repositoryCount: profile?.repoCount,
        projectCount:
            user?.projectsV2.totalCount ?? organization?.projectsV2.totalCount,
        packageCount:
            user?.packages.totalCount ?? organization?.packages.totalCount,
        starCount: user?.starredRepositories.totalCount,
      ),
      body: LayoutBuilder(
        builder:
            (final BuildContext context, final BoxConstraints constraints) {
              final ProfileWindowClass windowClass =
                  ProfileMd3Layout.windowClassFor(constraints.maxWidth);
              return AsyncValueBuilder<UserProfileData>(
                value: profileAsync,
                data: (final UserProfileData profile) =>
                    _buildLoadedProfile(profile, windowClass),
                skeleton: (final BuildContext context) =>
                    _ProfilePageSkeleton(windowClass: windowClass),
                error: (final Object error, final StackTrace stack) =>
                    _ProfileLoadError(
                      login: widget.userRef.login,
                      error: error,
                      onRetry: () =>
                          ref.invalidate(userProvider(widget.userRef)),
                    ),
              );
            },
      ),
    );
  }

  Widget _buildLoadedProfile(
    final UserProfileData profile,
    final ProfileWindowClass windowClass,
  ) {
    final UserProfileOwner owner = profile.owner;
    final AsyncValue<String?>? readmeAsync = profile.hasProfileReadme
        ? owner.maybeWhen(
            user: (final UserProfile user) =>
                ref.watch(profileReadmeHtmlProvider(widget.userRef)),
            organization: (final OrgProfile organization) =>
                ref.watch(orgProfileReadmeHtmlProvider(widget.userRef)),
            orElse: () => null,
          )
        : null;
    final Widget tabStack = _ProfileRetainedTabTransition(
      animation: _contentAnimation,
      direction: _motionDirection,
      child: IndexedStack(
        key: const ValueKey<String>('profile-retained-tab-stack'),
        index: _selectedIndex,
        children: List<Widget>.generate(
          ProfileNavigationDestination.values.length,
          (final int index) {
            if (!_visitedIndexes.contains(index)) {
              return const SizedBox.shrink();
            }
            final ProfileNavigationDestination destination =
                ProfileNavigationDestination.values[index];
            if (destination == ProfileNavigationDestination.overview) {
              return ProfileOverviewMd3(
                profile: profile,
                windowClass: windowClass,
                readmeAsync: readmeAsync,
                contributionQueryKey: _contributionQueryKey,
                onEditProfile: _showEditProfile,
                onToggleFollow: _toggleFollow,
                onRetryContributions: () => ref.invalidate(
                  userContributionsProvider(_contributionQueryKey),
                ),
              );
            }
            return _ProfileDataTab(
              key: _dataTabKeys[index],
              destination: destination,
              userRef: widget.userRef,
              profile: profile,
              windowClass: windowClass,
              onEditProfile: _showEditProfile,
              onToggleFollow: _toggleFollow,
            );
          },
        ),
      ),
    );

    if (windowClass != ProfileWindowClass.expanded) return tabStack;
    final double inset = ProfileMd3Layout.pageInsetFor(windowClass);
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, 24, inset, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: ProfileMd3Layout.identityWidth,
            child: SingleChildScrollView(
              key: const PageStorageKey<String>('profile-identity-scroll'),
              child: ProfileIdentityPanel(
                profile: profile,
                windowClass: windowClass,
                onEditProfile: _showEditProfile,
                onToggleFollow: _toggleFollow,
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(child: tabStack),
        ],
      ),
    );
  }
}

class _ProfileDataTab extends ConsumerStatefulWidget {
  const _ProfileDataTab({
    required this.destination,
    required this.userRef,
    required this.profile,
    required this.windowClass,
    required this.onEditProfile,
    required this.onToggleFollow,
    super.key,
  });

  final ProfileNavigationDestination destination;
  final UserRef userRef;
  final UserProfileData profile;
  final ProfileWindowClass windowClass;
  final VoidCallback onEditProfile;
  final Future<void> Function({required bool follow}) onToggleFollow;

  @override
  ConsumerState<_ProfileDataTab> createState() => _ProfileDataTabState();
}

class _ProfileDataTabState extends ConsumerState<_ProfileDataTab> {
  LeadingTabBody? _body;

  Future<void> refresh() async {
    await _body?.performRefresh();
  }

  @override
  Widget build(final BuildContext context) {
    _body ??= LeadingTabBody(
      leading: null,
      child: switch (widget.destination) {
        ProfileNavigationDestination.repositories => SearchListBody(
          scope: SearchScope.userRepos(user: widget.userRef),
        ),
        ProfileNavigationDestination.projects => createProfileProjectsBody(
          ref,
          widget.userRef,
        ),
        ProfileNavigationDestination.packages => createPackagesBody(
          ref,
          widget.userRef,
        ),
        ProfileNavigationDestination.stars => createStarsBody(
          ref,
          widget.userRef,
        ),
        ProfileNavigationDestination.overview => throw StateError(
          'Overview is not a data-list tab.',
        ),
      },
    );
    _body!.leading = widget.windowClass == ProfileWindowClass.expanded
        ? null
        : Padding(
            padding: EdgeInsets.fromLTRB(
              ProfileMd3Layout.pageInsetFor(widget.windowClass),
              24,
              ProfileMd3Layout.pageInsetFor(widget.windowClass),
              24,
            ),
            child: ProfileIdentityPanel(
              profile: widget.profile,
              windowClass: widget.windowClass,
              onEditProfile: widget.onEditProfile,
              onToggleFollow: widget.onToggleFollow,
            ),
          );
    return TabBodyPage(body: _body!);
  }
}

class _ProfileRetainedTabTransition extends StatelessWidget {
  const _ProfileRetainedTabTransition({
    required this.animation,
    required this.direction,
    required this.child,
  });

  final Animation<double> animation;
  final int direction;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    final double textDirection =
        Directionality.maybeOf(context) == TextDirection.rtl ? -1 : 1;
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: kContentTransitionCurve,
    );
    return AnimatedBuilder(
      key: const ValueKey<String>('profile-tab-transition'),
      animation: curved,
      child: child,
      builder: (final BuildContext context, final Widget? child) {
        final double progress = curved.value;
        return Opacity(
          opacity:
              kTabTransitionStartOpacity +
              ((1 - kTabTransitionStartOpacity) * progress),
          child: Transform.translate(
            offset: Offset(
              kTabTransitionOffset *
                  direction.sign *
                  textDirection *
                  (1 - progress),
              0,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _ProfilePageSkeleton extends StatelessWidget {
  const _ProfilePageSkeleton({required this.windowClass});

  final ProfileWindowClass windowClass;

  @override
  Widget build(final BuildContext context) {
    final double inset = ProfileMd3Layout.pageInsetFor(windowClass);
    final Widget identity = ShimmerScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ShimmerBone.avatar(size: ProfileMd3Layout.avatarSizeFor(windowClass)),
          const SizedBox(height: 16),
          const ShimmerBone.title(width: 180),
          const SizedBox(height: 8),
          const ShimmerBone.label(width: 120),
          const SizedBox(height: 20),
          const ShimmerBone.block(height: 40),
        ],
      ),
    );
    const Widget content = ShimmerScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ShimmerBone.title(width: 160),
          SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: ShimmerBone.block(height: 150)),
              SizedBox(width: 12),
              Expanded(child: ShimmerBone.block(height: 150)),
            ],
          ),
          SizedBox(height: 28),
          ShimmerBone.title(width: 190),
          SizedBox(height: 12),
          ShimmerBone.block(height: 190),
        ],
      ),
    );
    if (windowClass == ProfileWindowClass.expanded) {
      return Padding(
        padding: EdgeInsets.fromLTRB(inset, 24, inset, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: ProfileMd3Layout.identityWidth, child: identity),
            const SizedBox(width: 32),
            const Expanded(child: content),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(inset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[identity, const SizedBox(height: 28), content],
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({
    required this.login,
    required this.error,
    required this.onRetry,
  });

  final String login;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.profileLoadError(login),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    ),
  );
}
