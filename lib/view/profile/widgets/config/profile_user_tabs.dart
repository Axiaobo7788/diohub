import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/context_dock/pills/basic_dock_pill.dart';
import 'package:diohub/providers/dock/inline_search_query_provider.dart';
import 'package:diohub/common/nav_center/builders/common_metadata_builders.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/tab_action.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/common/nav_center/settings/settings_section.dart';
import 'package:diohub/common/nav_center/settings/settings_sheet_action_row.dart';
import 'package:diohub/common/nav_center/settings/settings_text_field_row.dart';
import 'package:diohub/common/nav_center/settings/settings_toggle_row.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/common/widgets/expandable_option_list_widget.dart'
    as option_list;
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub/common/widgets/metadata_rows.dart';
import 'package:diohub/common/widgets/metadata_section_sliver.dart';
import 'package:diohub/common/widgets/scope_gated_widget.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/common/widgets/user_status_pill.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/contribution_query_utils.dart';
import 'package:diohub/utils/markdown_emoji.dart';
import 'package:diohub/view/profile/about/user_about_screen.dart';
import 'package:diohub/view/profile/about/widgets/tabbed_contribution_section.dart';
import 'package:diohub/view/profile/followers/profile_followers_tab.dart';
import 'package:diohub/view/profile/following/profile_following_tab.dart';
import 'package:diohub/view/profile/gists/profile_gists_tab.dart';
import 'package:diohub/view/profile/members/profile_members_tab.dart';
import 'package:diohub/view/profile/teams/profile_teams_tab.dart';
import 'package:diohub/view/profile/organizations/profile_organizations_tab.dart';
import 'package:diohub/view/profile/widgets/create_gist_sheet.dart';
import 'package:diohub/view/profile/widgets/email_management_sheet.dart';
import 'package:diohub/view/profile/packages/profile_packages_tab.dart';
import 'package:diohub/view/profile/projects/profile_projects_tab.dart';
import 'package:diohub/view/profile/sponsors/profile_sponsors_tab.dart';
import 'package:diohub/view/profile/stars/profile_stars_tab.dart';
import 'package:diohub/view/profile/watching/profile_watching_tab.dart';
import 'package:diohub/providers/users/keys_refresh_trigger_provider.dart';
import 'package:diohub/providers/profile/keys_tab_index_provider.dart';
import 'package:diohub/view/profile/keys/profile_keys_tab.dart';
import 'package:diohub/view/profile/widgets/gpg_key_sheet.dart';
import 'package:diohub/view/profile/widgets/key_cards.dart';
import 'package:diohub/view/profile/widgets/profile_popup_sections.dart';
import 'package:diohub/view/profile/widgets/config/profile_org_tabs.dart';
import 'package:diohub/view/profile/widgets/config/profile_settings_and_sheets.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:diohub/common/events/events.dart';

List<TabConfig> buildUserTabs({
  required UserProfile user,
  required int repoCount,
  required bool hasProfileReadme,
  required ContributionQueryKey contributionQueryKey,
  required ContributionTab contributionTab,
  required void Function(int) onYearChanged,
  required void Function(DateTime?, DateTime?) onCustomRangeChanged,
  required void Function(ContributionTab) onContributionTabChanged,
  required UserRef ref,
  required WidgetRef widgetRef,
  required BuildContext context,
}) {
  final String login = user.login;
  final List<TabConfig> tabs = <TabConfig>[];

  if (hasProfileReadme) {
    tabs.add(
      TabConfig(
        label: 'Readme',
        icon: Octicons.book,
        category: TabCategory.primary,
        deeplinkPath: 'readme',
        body: TabBodyPage(
            body: SliverBuilderBody(
          sliverBuilder: (BuildContext ctx, WidgetRef r) => [
            Consumer(
              builder: (ctx, ref, _) {
                final userRef = UserRef(login: login);
                final readmeAsync =
                    ref.watch(profileReadmeHtmlProvider(userRef));
                return RepositoryReadmeSliver(readmeAsync: readmeAsync);
              },
            ),
          ],
          refreshFuture: () => widgetRef
              .refresh(profileReadmeHtmlProvider(UserRef(login: login)).future),
        )),
      ),
    );
  }

  tabs.add(
    TabConfig(
      label: 'Activity',
      icon: Octicons.pulse,
      category: TabCategory.primary,
      keepAlive: true,
      deeplinkPath: 'activity',
      body: TabBodyPage(
          body: SliverBuilderBody(
        sliverBuilder: (BuildContext ctx, WidgetRef r) => [
          UserAboutScreen(
            user,
            contributionQueryKey: contributionQueryKey,
            onYearChanged: onYearChanged,
            onCustomRangeChanged: onCustomRangeChanged,
            selectedTab: contributionTab,
          ),
        ],
        refreshFuture: () => widgetRef
            .refresh(userContributionsProvider(contributionQueryKey).future),
      )),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [],
    ),
  );

  final ValueNotifier<Future<void> Function()?> profileFeedRefreshRegistrar =
      ValueNotifier<Future<void> Function()?>(null);
  tabs.add(
    TabConfig(
      label: 'Feed',
      icon: Octicons.history,
      category: TabCategory.primary,
      deeplinkPath: 'feed',
      body: TabBodyPage(
          body: SliverBuilderBody(
        sliverBuilder: (BuildContext ctx, WidgetRef r) => [
          Events(
            privateEvents: false,
            specificUser: login,
            refreshRegistrar: profileFeedRefreshRegistrar,
          ),
        ],
        refreshRegistrar: profileFeedRefreshRegistrar,
      )),
    ),
  );

  tabs.add(
    reposPosition(login, repoCount, ref, user.isViewer),
  );

  final profileSearchKey = 'profile/$login';

  final ValueNotifier<Future<void> Function()?> gistsRefreshRegistrar =
      ValueNotifier<Future<void> Function()?>(null);
  tabs.add(
    TabConfig(
      label: 'Gists',
      icon: Octicons.code_square,
      category: TabCategory.content,
      deeplinkPath: 'gists',
      trailing: CountTrailing(() => user.gists.totalCount),
      body: ScopeGatedWidget(
        scopes: const [GitHubScope.gist],
        featureName: 'Gists',
        child: TabBodyPage(
          body: createGistsBody(
            widgetRef,
            ref,
            queryNotifier: widgetRef.read(
                inlineSearchQueryNotifierProvider('$profileSearchKey/gists')),
            isViewer: user.isViewer,
            refreshRegistrar: user.isViewer ? gistsRefreshRegistrar : null,
          ),
        ),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef.read(
            inlineSearchQueryNotifierProvider('$profileSearchKey/gists')),
      ),
      actions: [
        if (user.isViewer)
          TabAction.create(
            icon: Octicons.plus,
            label: 'New gist',
            onTap: (WidgetRef r) async {
              await showCreateGistSheet(context, userRef: ref, onCreated: () {
                gistsRefreshRegistrar.value?.call();
              });
            },
          ),
      ],
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Organizations',
      icon: Octicons.organization,
      category: TabCategory.content,
      deeplinkPath: 'organizations',
      trailing: CountTrailing(() => user.organizations.totalCount),
      body: ScopeGatedWidget(
        scopes: const [GitHubScope.writeOrg],
        featureName: 'Organizations',
        child: TabBodyPage(
          body: createOrganizationsBody(widgetRef, ref,
              queryNotifier: widgetRef.read(inlineSearchQueryNotifierProvider(
                  '$profileSearchKey/organizations'))),
        ),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef.read(inlineSearchQueryNotifierProvider(
            '$profileSearchKey/organizations')),
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Followers',
      icon: Octicons.people,
      category: TabCategory.social,
      deeplinkPath: 'followers',
      trailing: CountTrailing(() => user.followers.totalCount),
      body: TabBodyPage(
        body: createFollowersBody(widgetRef, ref,
            queryNotifier: widgetRef.read(inlineSearchQueryNotifierProvider(
                '$profileSearchKey/followers'))),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef.read(
            inlineSearchQueryNotifierProvider('$profileSearchKey/followers')),
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Following',
      icon: Octicons.person,
      category: TabCategory.social,
      deeplinkPath: 'following',
      trailing: CountTrailing(() => user.following.totalCount),
      body: TabBodyPage(
        body: createFollowingBody(widgetRef, ref,
            queryNotifier: widgetRef.read(inlineSearchQueryNotifierProvider(
                '$profileSearchKey/following'))),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef.read(
            inlineSearchQueryNotifierProvider('$profileSearchKey/following')),
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Stars',
      icon: Octicons.star,
      category: TabCategory.primary,
      deeplinkPath: 'stars',
      trailing: CountTrailing(() => user.starredRepositories.totalCount),
      body: TabBodyPage(
        body: createStarsBody(widgetRef, ref,
            queryNotifier: widgetRef.read(
                inlineSearchQueryNotifierProvider('$profileSearchKey/stars'))),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef.read(
            inlineSearchQueryNotifierProvider('$profileSearchKey/stars')),
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Watching',
      icon: Octicons.eye,
      category: TabCategory.primary,
      deeplinkPath: 'watching',
      trailing: CountTrailing(() => user.watching.totalCount),
      body: TabBodyPage(
        body: createWatchingBody(widgetRef, ref,
            queryNotifier: widgetRef.read(inlineSearchQueryNotifierProvider(
                '$profileSearchKey/watching'))),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef.read(
            inlineSearchQueryNotifierProvider('$profileSearchKey/watching')),
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Packages',
      icon: Octicons.package,
      category: TabCategory.other,
      deeplinkPath: 'packages',
      trailing: user.packages.totalCount > 0
          ? CountTrailing(() => user.packages.totalCount)
          : null,
      body: ScopeGatedWidget(
        scopes: const [GitHubScope.readPackages],
        featureName: 'Packages',
        child: TabBodyPage(
          body: createPackagesBody(widgetRef, UserRef(login: login),
              queryNotifier: widgetRef.read(inlineSearchQueryNotifierProvider(
                  '$profileSearchKey/packages'))),
        ),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef.read(
            inlineSearchQueryNotifierProvider('$profileSearchKey/packages')),
      ),
    ),
  );

  final UserRef userRef = UserRef(login: login);

  // Public Keys position (other users only): read-only GQL publicKeys list.
  if (!user.isViewer) {
    tabs.add(
      TabConfig(
        label: 'Public Keys',
        icon: Octicons.key,
        category: TabCategory.other,
        deeplinkPath: 'public-keys',
        body: TabBodyPage(body: createPublicKeysBody(widgetRef, userRef)),
        inlineControls: (ctx, ref) => [],
        dockActions: (ctx, ref) => [],
      ),
    );
  }

  // Keys position (viewer only): SSH / GPG / Signing tabs + add (SSH).
  if (user.isViewer) {
    tabs.add(
      TabConfig(
        label: 'Keys',
        icon: Octicons.key,
        category: TabCategory.settings,
        deeplinkPath: 'keys',
        body: TabBodyPage(
          body: TabSwitcherBody(
            tabIndexProvider: keysTabIndexProvider(userRef),
            createBodyForTab: (int index) {
              switch (index) {
                case 0:
                  return createKeysBody(userRef);
                case 1:
                  return createGpgKeysBody(userRef);
                case 2:
                  return createSSHSigningKeysBody(userRef);
                default:
                  return createKeysBody(userRef);
              }
            },
          ),
        ),
        inlineControls: (ctx, ref) => [
          BasicDockPill(
            iconData: Octicons.key,
            label: 'SSH',
            onTapAction: (r) =>
                r.read(keysTabIndexProvider(userRef).notifier).state = 0,
          ),
          BasicDockPill(
            iconData: Octicons.shield_check,
            label: 'GPG',
            onTapAction: (r) =>
                r.read(keysTabIndexProvider(userRef).notifier).state = 1,
          ),
          BasicDockPill(
            iconData: Octicons.pencil,
            label: 'Signing',
            onTapAction: (r) =>
                r.read(keysTabIndexProvider(userRef).notifier).state = 2,
          ),
        ],
        dockActions: (ctx, ref) => [
          BasicDockPill(
            iconData: Icons.add_rounded,
            label: 'Add',
            onTapAction: (r) {
              final int tab = r.read(keysTabIndexProvider(userRef));
              final void Function() onAdded = () {
                r.read(keysRefreshTriggerProvider(userRef)).value++;
              };
              if (tab == 1) {
                showAddGPGKeySheet(ctx, onAdded: onAdded);
              } else {
                showAddSSHKeySheet(ctx, userRef: userRef, onAdded: onAdded);
              }
            },
          ),
        ],
      ),
    );
  }

  final profilePullsScope = SearchScope.profilePulls(user: userRef);
  final profileIssuesScope = SearchScope.profileIssues(user: userRef);

  tabs.add(
    TabConfig(
      label: 'Pull Requests',
      icon: Octicons.git_pull_request,
      category: TabCategory.content,
      deeplinkPath: 'pulls',
      searchScope: profilePullsScope,
      presets: NavigationPresets.pulls,
      trailing: CountTrailing(() => user.pullRequests.totalCount),
      body: TabBodyPage(body: SearchListBody(scope: profilePullsScope)),
      controls: TabControls.search(
        scope: profilePullsScope,
        presets: NavigationPresets.pulls,
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Issues',
      icon: Octicons.issue_opened,
      category: TabCategory.content,
      deeplinkPath: 'issues',
      searchScope: profileIssuesScope,
      presets: NavigationPresets.issues,
      trailing: CountTrailing(() => user.issues.totalCount),
      body: TabBodyPage(body: SearchListBody(scope: profileIssuesScope)),
      controls: TabControls.search(
        scope: profileIssuesScope,
        presets: NavigationPresets.issues,
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Projects',
      icon: Octicons.project,
      category: TabCategory.other,
      deeplinkPath: 'projects',
      trailing: user.projectsV2.totalCount > 0
          ? CountTrailing(() => user.projectsV2.totalCount)
          : null,
      body: ScopeGatedWidget(
        scopes: const [GitHubScope.project],
        featureName: 'Projects',
        child: TabBodyPage(
          body: createProfileProjectsBody(widgetRef, UserRef(login: login),
              queryNotifier: widgetRef.read(inlineSearchQueryNotifierProvider(
                  '$profileSearchKey/projects'))),
        ),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef.read(
            inlineSearchQueryNotifierProvider('$profileSearchKey/projects')),
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Sponsors',
      icon: Octicons.heart,
      category: TabCategory.other,
      deeplinkPath: 'sponsors',
      trailing: user.sponsors.totalCount > 0
          ? CountTrailing(() => user.sponsors.totalCount)
          : null,
      body: TabBodyPage(
          body: createSponsorsBody(widgetRef, UserRef(login: login))),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [],
    ),
  );

  // History scoped to this user (profile visits)
  tabs.add(
    TabConfig(
      label: 'History',
      icon: Octicons.history,
      category: TabCategory.primary,
      keepAlive: false,
      deeplinkPath: 'history',
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, r) {
            final entries =
                r.watch(storeByEntityPathProvider(ref.apiPath)).asData?.value ??
                    [];
            final spacing = ctx.spacing;
            return [
              SliverPadding(
                padding: spacing.listInset,
                sliver: SliverList.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final item = entries[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing.itemSpacing),
                      child: ListTile(
                        title: Text(item.entity.snapshotTitle ??
                            item.entity.entityPath),
                        onTap: () => EntityRef.fromJson(
                                jsonDecode(item.entity.subjectJson)
                                    as Map<String, dynamic>)
                            .navigate(ctx, r),
                      ),
                    );
                  },
                ),
              ),
            ];
          },
        ),
      ),
      inlineControls: (ctx, ref) => [],
      dockActions: (ctx, ref) => [],
      trailing: null,
      ambientIndicator: null,
    ),
  );

  // Settings position (viewer only): Profile and Social sections. Not shown for other users.
  if (user.isViewer) {
    final UserRef profileUserRef = ref;
    tabs.add(
      TabConfig(
        label: 'Settings',
        icon: Octicons.gear,
        category: TabCategory.settings,
        keepAlive: false,
        deeplinkPath: 'settings',
        body: TabBodyPage(
            body: SliverBuilderBody(
          sliverBuilder: (BuildContext ctx, WidgetRef ref) => [
            Consumer(
              builder: (BuildContext ctx, WidgetRef ref, _) {
                final List<Widget> sections =
                    profileSettingsSections(ctx, ref, profileUserRef);
                final AppSpacing spacing = ctx.spacing;
                return SliverPadding(
                  padding: spacing.pagePadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        if (index.isOdd) return spacing.sectionGap;
                        return sections[index ~/ 2];
                      },
                      childCount:
                          sections.isEmpty ? 0 : sections.length * 2 - 1,
                    ),
                  ),
                );
              },
            ),
          ],
        )),
        inlineControls: (ctx, ref) => [],
        dockActions: (ctx, ref) => [],
        trailing: null,
        ambientIndicator: null,
      ),
    );
  }

  return tabs;
}
