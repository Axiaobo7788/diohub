import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/dock/inline_search_query_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/view/profile/members/profile_members_tab.dart';
import 'package:diohub/view/profile/pending_members/profile_pending_members_tab.dart';
import 'package:diohub/view/profile/teams/profile_teams_tab.dart';
import 'package:diohub/view/profile/packages/profile_packages_tab.dart';
import 'package:diohub/view/profile/projects/profile_projects_tab.dart';
import 'package:diohub/view/profile/sponsors/profile_sponsors_tab.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:diohub/view/profile/activity/profile_org_activity_tab.dart';
import 'package:diohub/view/profile/pat_requests/profile_pat_requests_tab.dart';

import 'package:diohub_graphql/queries/users/user_typedefs.dart';

List<TabConfig> buildOrgTabs({
  required OrgProfile org,
  required int repoCount,
  required bool hasProfileReadme,
  required UserRef ref,
  required WidgetRef widgetRef,
}) {
  final String login = org.login;
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
                    ref.watch(orgProfileReadmeHtmlProvider(userRef));
                return RepositoryReadmeSliver(readmeAsync: readmeAsync);
              },
            ),
          ],
          refreshFuture: () => widgetRef.refresh(
              orgProfileReadmeHtmlProvider(UserRef(login: login)).future),
        )),
      ),
    );
  }

  tabs.add(
    reposPosition(login, repoCount, ref, false),
  );

  tabs.add(
    TabConfig(
      label: 'Activity',
      icon: Octicons.pulse,
      category: TabCategory.primary,
      deeplinkPath: 'activity',
      body: TabBodyPage(body: createOrgActivityBody(widgetRef, login)),
    ),
  );

  final orgSearchKey = 'org/$login';

  tabs.add(
    TabConfig(
      label: 'Members',
      icon: Octicons.people,
      category: TabCategory.primary,
      deeplinkPath: 'members',
      trailing: CountTrailing(() => org.membersWithRole.totalCount),
      body: TabBodyPage(
        body: createMembersBody(widgetRef, ref,
            queryNotifier: widgetRef.read(
                inlineSearchQueryNotifierProvider('$orgSearchKey/members'))),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef
            .read(inlineSearchQueryNotifierProvider('$orgSearchKey/members')),
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Pending',
      icon: Octicons.hourglass,
      category: TabCategory.primary,
      deeplinkPath: 'pending',
      body: TabBodyPage(
        body: createPendingMembersBody(widgetRef, ref,
            queryNotifier: widgetRef.read(
                inlineSearchQueryNotifierProvider('$orgSearchKey/pending'))),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef
            .read(inlineSearchQueryNotifierProvider('$orgSearchKey/pending')),
      ),
    ),
  );

  // PAT Requests tab (org admin feature)
  tabs.add(
    TabConfig(
      label: 'PAT Requests',
      icon: Octicons.key,
      category: TabCategory.other,
      deeplinkPath: 'pat-requests',
      body: TabBodyPage(body: createPatRequestsBody(widgetRef, ref)),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Teams',
      icon: Octicons.people,
      category: TabCategory.primary,
      deeplinkPath: 'teams',
      trailing: CountTrailing(() => org.teams.totalCount),
      body: TabBodyPage(
        body: createTeamsBody(widgetRef, ref,
            queryNotifier: widgetRef.read(
                inlineSearchQueryNotifierProvider('$orgSearchKey/teams'))),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef
            .read(inlineSearchQueryNotifierProvider('$orgSearchKey/teams')),
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Packages',
      icon: Octicons.package,
      category: TabCategory.other,
      deeplinkPath: 'packages',
      trailing: org.packages.totalCount > 0
          ? CountTrailing(() => org.packages.totalCount)
          : null,
      body: TabBodyPage(
        body: createPackagesBody(widgetRef, UserRef(login: login),
            queryNotifier: widgetRef.read(
                inlineSearchQueryNotifierProvider('$orgSearchKey/packages'))),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef.read(
            inlineSearchQueryNotifierProvider('$orgSearchKey/packages')),
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Projects',
      icon: Octicons.project,
      category: TabCategory.other,
      deeplinkPath: 'projects',
      trailing: org.projectsV2.totalCount > 0
          ? CountTrailing(() => org.projectsV2.totalCount)
          : null,
      body: TabBodyPage(
        body: createProfileProjectsBody(widgetRef, UserRef(login: login),
            queryNotifier: widgetRef.read(
                inlineSearchQueryNotifierProvider('$orgSearchKey/projects'))),
      ),
      controls: TabControls.clientList(
        searchQuery: widgetRef.read(
            inlineSearchQueryNotifierProvider('$orgSearchKey/projects')),
      ),
    ),
  );

  tabs.add(
    TabConfig(
      label: 'Sponsors',
      icon: Octicons.heart,
      category: TabCategory.other,
      deeplinkPath: 'sponsors',
      trailing: org.sponsors.totalCount > 0
          ? CountTrailing(() => org.sponsors.totalCount)
          : null,
      body: TabBodyPage(
          body: createSponsorsBody(widgetRef, UserRef(login: login))),
    ),
  );

  // TODO: Org-wide security overview tab should be injected via PremiumExtension
  // when a proper extension point for org profile tabs is added.

  return tabs;
}

TabConfig reposPosition(
  String login,
  int repoCount,
  UserRef ref,
  bool isViewer,
) {
  final scope = SearchScope.userRepos(user: UserRef(login: login));
  return TabConfig(
    label: 'Repositories',
    icon: Octicons.repo,
    category: TabCategory.primary,
    deeplinkPath: 'repositories',
    searchScope: scope,
    trailing: CountTrailing(() => repoCount),
    body: TabBodyPage(body: SearchListBody(scope: scope)),
    controls: TabControls.search(scope: scope),
  );
}
