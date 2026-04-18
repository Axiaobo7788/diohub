import 'package:auto_route/annotations.dart';
import 'package:diohub/common/misc/scaffold_body.dart';
import 'package:diohub/common/misc/scoped_image_theme.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/shell/nav_center_shell_widgets.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/profile/about/widgets/tabbed_contribution_section.dart';
import 'package:diohub/view/profile/widgets/profile_screen_config.dart';
import 'package:diohub/view/profile/widgets/user_profile_screen_skeleton.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen(this.userRef, {super.key});

  final UserRef userRef;

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  late ContributionQueryKey _contributionQueryKey;
  ContributionTab _contributionTab = TabbedContributionSection.defaultTab;

  @override
  void initState() {
    super.initState();
    _contributionQueryKey = ContributionQueryKey.lastYear(widget.userRef.login);
    if (kDebugMode) {
      final (from, to) = _contributionQueryKey.dateRange.dates;
      debugPrint('Contribution range initialized: $from → $to');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onYearChanged(int year) {
    setState(() {
      _contributionQueryKey =
          ContributionQueryKey.year(widget.userRef.login, year);
    });
  }

  void _onCustomRangeChanged(DateTime? from, DateTime? to) {
    setState(() {
      if (from == null && to == null) {
        _contributionQueryKey =
            ContributionQueryKey.lastYear(widget.userRef.login);
      } else if (from != null && to != null) {
        _contributionQueryKey = ContributionQueryKey.customRange(
          userName: widget.userRef.login,
          from: from,
          to: to,
        );
      }
    });
  }

  void _onContributionTabChanged(ContributionTab tab) {
    setState(() {
      _contributionTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider(widget.userRef));

    return Scaffold(
      body: ScaffoldBody(
        child: userAsync.maybeWhen(
          loading: () => const UserProfileScreenSkeleton(),
          error: (Object e, StackTrace _) => Center(child: Text('Error: $e')),
          orElse: () => const SizedBox.shrink(),
          data: (UserProfileData data) {
            final userData = data.owner;
            final Widget content = ScopedImageTheme(
              imageUrl: userData.avatarUrl.toString(),
              child: _ProfileShellContent(
                userData: userData,
                repoCount: data.repoCount,
                hasProfileReadme: data.hasProfileReadme,
                initialTabParam: widget.userRef.tab,
                contributionQueryKey: _contributionQueryKey,
                contributionTab: _contributionTab,
                onYearChanged: _onYearChanged,
                onCustomRangeChanged: _onCustomRangeChanged,
                onContributionTabChanged: _onContributionTabChanged,
                onToggleFollow: ({required bool follow}) async {
                  await ref
                      .read(userProvider(widget.userRef).notifier)
                      .changeFollowStatus(
                        userData.maybeWhen(
                          user: (u) => u.id,
                          organization: (o) => o.id,
                          orElse: () => '',
                        ),
                        follow: follow,
                        isOrg: userData.maybeWhen(
                          organization: (_) => true,
                          orElse: () => false,
                        ),
                      );
                },
                userRef: widget.userRef,
              ),
            );
            return userData.maybeWhen(
              organization: (OrgProfile org) =>
                  _OrgAnnouncementWrapper(org: org, child: content),
              orElse: () => content,
            );
          },
        ),
      ),
    );
  }
}

/// Builds config in didChangeDependencies / didUpdateWidget so we don't
/// allocate the full config tree on every build.
class _ProfileShellContent extends ConsumerStatefulWidget {
  const _ProfileShellContent({
    required this.userData,
    required this.repoCount,
    required this.hasProfileReadme,
    required this.initialTabParam,
    required this.contributionQueryKey,
    required this.contributionTab,
    required this.onYearChanged,
    required this.onCustomRangeChanged,
    required this.onContributionTabChanged,
    required this.onToggleFollow,
    required this.userRef,
  });

  final UserProfileOwner userData;
  final int repoCount;
  final bool hasProfileReadme;
  final String? initialTabParam;
  final ContributionQueryKey contributionQueryKey;
  final ContributionTab contributionTab;
  final void Function(int) onYearChanged;
  final void Function(DateTime?, DateTime?) onCustomRangeChanged;
  final void Function(ContributionTab) onContributionTabChanged;
  final Future<void> Function({required bool follow}) onToggleFollow;
  final UserRef userRef;

  @override
  ConsumerState<_ProfileShellContent> createState() =>
      _ProfileShellContentState();
}

class _ProfileShellContentState extends ConsumerState<_ProfileShellContent> {
  ScreenConfig? _config;

  void _buildConfig() {
    _config = widget.userData.toScreenConfig(
      context,
      ref,
      repoCount: widget.repoCount,
      hasProfileReadme: widget.hasProfileReadme,
      initialTabParam: widget.initialTabParam,
      contributionQueryKey: widget.contributionQueryKey,
      contributionTab: widget.contributionTab,
      onYearChanged: widget.onYearChanged,
      onCustomRangeChanged: widget.onCustomRangeChanged,
      onContributionTabChanged: widget.onContributionTabChanged,
      onToggleFollow: widget.onToggleFollow,
      userRef: widget.userRef,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_config == null) _buildConfig();
  }

  @override
  void didUpdateWidget(covariant _ProfileShellContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData ||
        widget.repoCount != oldWidget.repoCount ||
        widget.hasProfileReadme != oldWidget.hasProfileReadme ||
        widget.contributionQueryKey != oldWidget.contributionQueryKey ||
        widget.contributionTab != oldWidget.contributionTab ||
        widget.initialTabParam != oldWidget.initialTabParam) {
      _buildConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleTabs = _config!.visibleTabs;
    final idx = visibleTabs.indexWhere(
      (TabConfig p) => p.deeplinkPath == _config!.initialTabPath,
    );
    final initialIndex = idx >= 0 ? idx : 0;
    return NavCenterShell(
      config: _config!,
      initialTabIndex: initialIndex,
    );
  }
}

/// Wraps org profile content with an optional MaterialBanner when [org] has a non-expired announcement.
class _OrgAnnouncementWrapper extends StatefulWidget {
  const _OrgAnnouncementWrapper({
    required this.org,
    required this.child,
  });

  final OrgProfile org;
  final Widget child;

  @override
  State<_OrgAnnouncementWrapper> createState() =>
      _OrgAnnouncementWrapperState();
}

class _OrgAnnouncementWrapperState extends State<_OrgAnnouncementWrapper> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final banner = widget.org.announcementBanner;
    final announcement = banner?.message;
    final expiresAt = banner?.expiresAt?.toIso8601String();
    final isExpired = expiresAt != null &&
        DateTime.tryParse(expiresAt)?.isBefore(DateTime.now()) == true;
    if (_dismissed ||
        announcement == null ||
        announcement.trim().isEmpty ||
        isExpired) {
      return widget.child;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MaterialBanner(
          content: Text(announcement),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          actions: banner?.isUserDismissible == true
              ? <Widget>[
                  TextButton(
                    onPressed: () => setState(() => _dismissed = true),
                    child: const Text('Dismiss'),
                  ),
                ]
              : const <Widget>[],
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
