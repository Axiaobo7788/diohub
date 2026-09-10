import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub_graphql/schema.graphql.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/services/repositories/gql_order_helpers.dart';
import 'package:diohub_models/models/pagination/page_slice.dart'
    show CursorPage;
import 'package:diohub/services/base/base_service.dart';
import 'package:lens_annotations/lens_annotations.dart';
import 'package:diohub_graphql/queries/users/user_info.graphql.dart';
import 'package:diohub_graphql/queries/users/user_repositories_list.graphql.dart';
import 'package:diohub_graphql/queries/users/user_lists.graphql.dart';
import 'package:diohub_graphql/queries/users/user_public_keys.graphql.dart';
import 'package:diohub_graphql/queries/users/follow_status.graphql.dart';
import 'package:diohub_graphql/queries/users/follow_mutations.graphql.dart';
import 'package:diohub_graphql/queries/users/user_contributions.graphql.dart';
import 'package:diohub_graphql/queries/users/user_card_by_login.graphql.dart';
import 'package:diohub_graphql/queries/users/get_saved_replies.graphql.dart';
import 'package:diohub_graphql/queries/users/user_repos.graphql.dart';
import 'package:diohub_graphql/queries/users/user_packages.graphql.dart';
import 'package:diohub_graphql/queries/users/user_projects_v2.graphql.dart';
import 'package:diohub_graphql/queries/users/user_sponsors.graphql.dart';
import 'package:diohub_graphql/queries/users/get_user_watching.graphql.dart';
import 'package:diohub_graphql/queries/users/get_org_members.graphql.dart';
import 'package:diohub_graphql/queries/users/get_org_teams.graphql.dart';
import 'package:diohub_graphql/queries/users/get_org_pending_members.graphql.dart';
import 'package:diohub_graphql/queries/viewer/viewer.query.graphql.dart';
import 'package:diohub_graphql/queries/viewer/dashboard.query.graphql.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart' as gq;

/// Resolved profile data returned by [UserInfoService.getUserInfoGraphQL] (via [userInfoServiceProvider]).
///
/// Encapsulates the owner, a resolved repo count (prefers the full count from
/// the `ownerStats` alias, falls back to the public-only count from the main
/// `repositoryOwner` block), and the profile README flag.
class UserProfileData {
  const UserProfileData({
    required this.owner,
    required this.repoCount,
    required this.hasProfileReadme,
  });
  final Query$userInfo$repositoryOwner owner;
  final int repoCount;
  final bool hasProfileReadme;
}

/// User and viewer info API. Use [userInfoServiceProvider] to obtain an instance.
@LensService(scope: Scope.global, group: 'user')
class UserInfoService extends BaseService {
  const UserInfoService(super.apiClient);

  // Ref: https://docs.github.com/en/rest/reference/users#get-the-authenticated-user
  Future<ViewerInfo> getViewerInfo({final String? explicitToken}) async {
    final Map<String, dynamic>? headers = explicitToken != null
        ? <String, dynamic>{'Authorization': 'token $explicitToken'}
        : null;
    final GQLResponse response = await gql.query(
      documentNodeQueryviewerInfo,
      <String, dynamic>{},
      requestHeaders: headers,
    );
    return ViewerInfoData.fromJson(response.data!).viewer;
  }

  @Lens(
    'get_user_repositories',
    'Get user repositories with optional filters and pagination.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<UserRepositories> getUserRepositories(
    @Desc('Username') final String user,
    @Desc('Number of results') final int first, {
    @Skip() final bool refresh = false,
    @Desc('Pagination cursor') final String? after,
    @Desc('Order field for sorting') final RepositoryOrderField? orderField,
    @Desc('Order direction') final OrderDirection? orderDirection,
    @Desc('Repository visibility filter')
    final RepositoryVisibility? visibility,
  }) async {
    final order = buildRepositoryOrder(
      field: orderField,
      direction: orderDirection,
    );
    final GQLResponse response = await gql.query(
      documentNodeQuerygetUserRepositories,
      Variables$Query$getUserRepositories(
        user: user,
        first: first,
        after: after,
        orderBy: Input$RepositoryOrder(
          field: order.field,
          direction: order.direction,
        ),
        visibility: visibility,
      ).toJson(),
      refreshCache: refresh,
    );
    return GetUserRepositoriesData.fromJson(response.data!).user!.repositories;
  }

  @Lens(
    'get_user_profile',
    'Get user or organization profile information.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<UserProfileData> getUserInfoGraphQL(
    @Desc('Username or organization login') final String login,
  ) async {
    final GQLResponse response = await gql.query(
      documentNodeQueryuserInfo,
      Variables$Query$userInfo(user: login).toJson(),
    );
    final UserInfoData parsed = UserInfoData.fromJson(response.data!);
    if (parsed.repositoryOwner == null) {
      throw Exception('User or organization "$login" not found');
    }
    // Resolve profile README: users use {login}/{login} repo,
    // orgs use {org}/.github repo with profile/README.md.
    final UserProfileOwner owner = parsed.repositoryOwner!;
    final bool hasReadme = owner.maybeWhen(
      user: (final _) => parsed.profileReadme?.object != null,
      organization: (final _) => parsed.orgProfileReadme?.object != null,
      orElse: () => false,
    );

    return UserProfileData(
      owner: owner,
      repoCount:
          parsed.ownerStats?.repositories.totalCount ??
          owner.repositories.totalCount,
      hasProfileReadme: hasReadme,
    );
  }

  Future<List<ViewerOrgEdge?>> getViewerOrgs({
    @Skip() final bool refresh = false,
    final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetViewerOrgs,
      Variables$Query$getViewerOrgs(after: after).toJson(),
      refreshCache: refresh,
    );
    return GetViewerOrgsData.fromJson(
      res.data!,
    ).viewer.organizations.edges!.toList();
  }

  /// Page size for profile list tabs (followers, following, orgs, stars).
  static const int profileListPageSize = 20;

  @Lens(
    'get_user_followers',
    'Get user followers list.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<List<UserFollowerEdge?>> getUserFollowers(
    @Desc('Username') final String login, {
    @Skip() final bool refresh = false,
    @Desc('Pagination cursor') final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetUserFollowers,
      Variables$Query$getUserFollowers(
        user: login,
        first: profileListPageSize,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final GetUserFollowersData data = GetUserFollowersData.fromJson(res.data!);
    return data.user?.followers.edges?.toList() ?? <UserFollowerEdge?>[];
  }

  @Lens(
    'get_user_following',
    'Get users that a user follows.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<List<UserFollowingEdge?>> getUserFollowing(
    @Desc('Username') final String login, {
    @Skip() final bool refresh = false,
    @Desc('Pagination cursor') final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetUserFollowing,
      Variables$Query$getUserFollowing(
        user: login,
        first: profileListPageSize,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final GetUserFollowingData data = GetUserFollowingData.fromJson(res.data!);
    return data.user?.following.edges?.toList() ?? <UserFollowingEdge?>[];
  }

  @Lens(
    'get_user_public_keys',
    'Get user public SSH keys.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<PaginatedResult<UserPublicKeyNode?>> getUserPublicKeys(
    @Desc('Username') final String login, {
    @Skip() final bool refresh = false,
    @Desc('Pagination cursor') final String? after,
    @Desc('Number of results') final int first = profileListPageSize,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQueryuserPublicKeys,
      Variables$Query$userPublicKeys(
        login: login,
        first: first,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final UserPublicKeysData data = UserPublicKeysData.fromJson(res.data!);
    final conn = data.user?.publicKeys;
    final nodes = conn?.nodes?.toList() ?? <UserPublicKeyNode?>[];
    final pageInfo = conn?.pageInfo;
    return PaginatedResult<UserPublicKeyNode?>(
      items: nodes,
      hasNextPage: pageInfo?.hasNextPage ?? false,
      endCursor: pageInfo?.endCursor,
      totalCount: conn?.totalCount,
    );
  }

  @Lens(
    'get_user_organizations',
    'Get user organizations list.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<List<UserOrgEdge?>> getUserOrganizations(
    @Desc('Username') final String login, {
    @Skip() final bool refresh = false,
    @Desc('Pagination cursor') final String? after,
  }) async {
    return (await getUserOrganizationsPage(
      login,
      refresh: refresh,
      after: after,
    )).items;
  }

  /// Cursor page used by Settings and other session-owned paginated views.
  ///
  /// The older list-returning method remains for existing profile consumers.
  Future<PaginatedResult<UserOrgEdge?>> getUserOrganizationsPage(
    final String login, {
    final bool refresh = false,
    final String? after,
    final int first = profileListPageSize,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetUserOrganizations,
      Variables$Query$getUserOrganizations(
        user: login,
        first: first,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final GetUserOrganizationsData data = GetUserOrganizationsData.fromJson(
      res.data!,
    );
    final connection = data.user?.organizations;
    return PaginatedResult<UserOrgEdge?>(
      items: connection?.edges?.toList() ?? <UserOrgEdge?>[],
      hasNextPage: connection?.pageInfo.hasNextPage ?? false,
      endCursor: connection?.pageInfo.endCursor,
      totalCount: connection?.totalCount,
    );
  }

  /// Organization members (paginated). Uses get_org_members.graphql (codegen).
  Future<List<OrgMemberEdge?>> getOrgMembers(
    final String org, {
    @Skip() final bool refresh = false,
    final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetOrgMembers,
      Variables$Query$getOrgMembers(
        org: org,
        first: profileListPageSize,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final GetOrgMembersData data = GetOrgMembersData.fromJson(res.data!);
    return data.organization?.membersWithRole.edges?.toList() ??
        <OrgMemberEdge?>[];
  }

  /// Organization teams (paginated).
  Future<List<OrgTeamEdge?>> getOrgTeams(
    final String orgLogin, {
    @Skip() final bool refresh = false,
    final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetOrgTeams,
      Variables$Query$getOrgTeams(
        org: orgLogin,
        first: profileListPageSize,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final GetOrgTeamsData data = GetOrgTeamsData.fromJson(res.data!);
    return data.organization?.teams.edges?.toList() ?? <OrgTeamEdge?>[];
  }

  /// Organization pending members (paginated).
  Future<List<Query$getOrgPendingMembers$organization$pendingMembers$edges?>>
  getOrgPendingMembers(
    final String org, {
    @Skip() final bool refresh = false,
    final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetOrgPendingMembers,
      Variables$Query$getOrgPendingMembers(
        org: org,
        first: profileListPageSize,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final Query$getOrgPendingMembers data = Query$getOrgPendingMembers.fromJson(
      res.data!,
    );
    return data.organization?.pendingMembers.edges?.toList() ??
        <Query$getOrgPendingMembers$organization$pendingMembers$edges?>[];
  }

  @Lens(
    'get_user_starred_repos',
    'Get repositories starred by a user.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<List<UserStarredRepoEdge?>> getUserStarredRepositories(
    @Desc('Username') final String login, {
    @Skip() final bool refresh = false,
    @Desc('Pagination cursor') final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetUserStarredRepositories,
      Variables$Query$getUserStarredRepositories(
        user: login,
        first: profileListPageSize,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final GetUserStarredRepositoriesData data =
        GetUserStarredRepositoriesData.fromJson(res.data!);
    return data.user?.starredRepositories.edges?.toList() ??
        <UserStarredRepoEdge?>[];
  }

  /// Paginated watched repositories for a user.
  @Lens(
    'get_user_watched_repos',
    'Get repositories watched by a user.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<List<UserWatchingEdge?>> getUserWatching(
    @Desc('Username') final String login, {
    @Skip() final bool refresh = false,
    @Desc('Pagination cursor') final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetUserWatching,
      Variables$Query$getUserWatching(
        user: login,
        first: profileListPageSize,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final GetUserWatchingData data = GetUserWatchingData.fromJson(res.data!);
    return data.user?.watching.edges?.toList() ?? <UserWatchingEdge?>[];
  }

  /// Fetch the viewer's saved replies (cursor-paginated). Used for inserting
  /// pre-written responses when composing comments.
  Future<CursorPage<SavedReplyEdge?>> getSavedReplies({
    required final int first,
    final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetSavedReplies,
      Variables$Query$getSavedReplies(first: first, after: after).toJson(),
    );
    final GetSavedRepliesData data = GetSavedRepliesData.fromJson(res.data!);
    final conn = data.viewer.savedReplies;
    final edges = conn?.edges?.toList() ?? <SavedReplyEdge?>[];
    final pageInfo = conn?.pageInfo;
    return CursorPage<SavedReplyEdge?>(
      items: edges,
      hasNextPage: pageInfo?.hasNextPage ?? false,
      endCursor: pageInfo?.endCursor,
      totalCount: conn?.totalCount,
    );
  }

  @Lens(
    'get_user_gists',
    'Get user gists list.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<List<UserGistEdge?>> getUserGists(
    @Desc('Username') final String login, {
    @Skip() final bool refresh = false,
    @Desc('Pagination cursor') final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetUserGists,
      Variables$Query$getUserGists(
        user: login,
        first: profileListPageSize,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final GetUserGistsData data = GetUserGistsData.fromJson(res.data!);
    return data.user?.gists.edges?.toList() ?? <UserGistEdge?>[];
  }

  @Lens(
    'get_user_packages',
    'Get user packages list.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<List<UserPackageEdge?>> getUserPackages(
    @Desc('Username') final String login, {
    @Skip() final bool refresh = false,
    @Desc('Pagination cursor') final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetUserPackages,
      Variables$Query$getUserPackages(
        user: login,
        first: profileListPageSize,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final GetUserPackagesData data = GetUserPackagesData.fromJson(res.data!);
    return data.user?.packages.edges?.toList() ?? <UserPackageEdge?>[];
  }

  @Lens(
    'get_user_projects',
    'Get user projects (v2) list.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<List<UserProjectV2Edge?>> getUserProjectsV2(
    @Desc('Username') final String login, {
    @Skip() final bool refresh = false,
    @Desc('Pagination cursor') final String? after,
  }) async {
    final PaginatedResult<UserProjectV2Edge> page = await getUserProjectsV2Page(
      login,
      profileListPageSize,
      refresh: refresh,
      after: after,
    );
    return page.items;
  }

  /// Cursor page used by account-wide ProjectV2 surfaces.
  ///
  /// Unlike the legacy profile helper, this preserves GitHub's pageInfo and
  /// totalCount and applies title search and ordering at the formal service
  /// boundary rather than filtering an incomplete page in a Widget.
  Future<PaginatedResult<UserProjectV2Edge>> getUserProjectsV2Page(
    final String login,
    final int first, {
    final bool refresh = false,
    final String? after,
    final String? query,
    final Input$ProjectV2Order? orderBy,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetUserProjectsV2,
      Variables$Query$getUserProjectsV2(
        user: login,
        first: first,
        after: after,
        query: query,
        orderBy: orderBy,
      ).toJson(),
      refreshCache: refresh,
    );
    final GetUserProjectsV2Data data = GetUserProjectsV2Data.fromJson(
      res.data!,
    );
    final Query$getUserProjectsV2$user$projectsV2? projects =
        data.user?.projectsV2;
    if (projects == null) {
      return const PaginatedResult<UserProjectV2Edge>(
        items: <UserProjectV2Edge>[],
        hasNextPage: false,
        totalCount: 0,
      );
    }
    return PaginatedResult<UserProjectV2Edge>(
      items:
          projects.edges?.whereType<UserProjectV2Edge>().toList() ??
          const <UserProjectV2Edge>[],
      hasNextPage: projects.pageInfo.hasNextPage,
      endCursor: projects.pageInfo.endCursor,
      totalCount: projects.totalCount,
    );
  }

  @Lens(
    'get_user_sponsors',
    'Get user sponsors list.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<List<UserSponsorEdge?>> getUserSponsors(
    @Desc('Username') final String login, {
    @Skip() final bool refresh = false,
    @Desc('Pagination cursor') final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQuerygetUserSponsors,
      Variables$Query$getUserSponsors(
        user: login,
        first: profileListPageSize,
        after: after,
      ).toJson(),
      refreshCache: refresh,
    );
    final GetUserSponsorsData data = GetUserSponsorsData.fromJson(res.data!);
    return data.user?.sponsors.edges?.toList() ?? <UserSponsorEdge?>[];
  }

  @Lens(
    'get_follow_info',
    'Get follow status and counts for a user.',
    category: ToolCategory.user,
    access: ToolAccess.read,
  )
  Future<FollowStatusInfo> getFollowInfo(
    @Desc('Username') final String login,
  ) async {
    final GQLResponse response = await gql.query(
      documentNodeQueryfollowStatusInfo,
      Variables$Query$followStatusInfo(user: login).toJson(),
    );
    final FollowStatusInfoData parsed = FollowStatusInfoData.fromJson(
      response.data!,
    );
    final FollowStatusInfo? user = parsed.user;
    if (user == null) {
      throw Exception('Follow info for "$login" not found');
    }
    return user;
  }

  /// Fetches user card fragment by login (for profile card from login-only context, e.g. events).
  /// Returns null if user not found. Use [userCardByLoginProvider] for UI.
  Future<gq.UserCardData?> getUserCardByLogin(final String login) async {
    final GQLResponse response = await gql.query(
      documentNodeQuerygetUserCardByLogin,
      Variables$Query$getUserCardByLogin(login: login).toJson(),
    );
    final GetUserCardByLoginData data = GetUserCardByLoginData.fromJson(
      response.data!,
    );
    return data.user;
  }

  /// Calls follow/unfollow mutation. Returns (viewerIsFollowing, followersCount)
  /// from the response so callers can update state without invalidating.
  /// When [isOrg] is true, uses organization mutations (followersCount is 0).
  @Lens(
    'follow_user',
    'Follow a user or organization.',
    category: ToolCategory.user,
    access: ToolAccess.write,
  )
  @Lens(
    'unfollow_user',
    'Unfollow a user or organization.',
    category: ToolCategory.user,
    access: ToolAccess.write,
  )
  Future<({bool viewerIsFollowing, int followersCount})?> changeFollowStatus(
    @Desc('User or organization node ID') final String id, {
    @Desc('True to follow, false to unfollow') required final bool follow,
    @Desc('Is organization (not user)') final bool isOrg = false,
  }) async {
    if (isOrg) {
      if (follow) {
        final GQLResponse res = await gql.mutation(
          documentNodeMutationfollowOrganization,
          Variables$Mutation$followOrganization(org: id).toJson(),
        );
        final FollowOrganizationData data = FollowOrganizationData.fromJson(
          res.data!,
        );
        final org = data.followOrganization?.organization;
        return org != null
            ? (viewerIsFollowing: org.viewerIsFollowing, followersCount: 0)
            : null;
      } else {
        final GQLResponse res = await gql.mutation(
          documentNodeMutationunfollowOrganization,
          Variables$Mutation$unfollowOrganization(org: id).toJson(),
        );
        final UnfollowOrganizationData data = UnfollowOrganizationData.fromJson(
          res.data!,
        );
        final org = data.unfollowOrganization?.organization;
        return org != null
            ? (viewerIsFollowing: org.viewerIsFollowing, followersCount: 0)
            : null;
      }
    }
    if (follow) {
      final GQLResponse res = await gql.mutation(
        documentNodeMutationfollowUser,
        Variables$Mutation$followUser(user: id).toJson(),
      );
      final FollowUserData data = FollowUserData.fromJson(res.data!);
      final FollowUserResultUser? user = data.followUser?.user;
      return user != null
          ? (
              viewerIsFollowing: user.viewerIsFollowing,
              followersCount: user.followers.totalCount,
            )
          : null;
    } else {
      final GQLResponse res = await gql.mutation(
        documentNodeMutationunfollowUser,
        Variables$Mutation$unfollowUser(user: id).toJson(),
      );
      final UnfollowUserData data = UnfollowUserData.fromJson(res.data!);
      final UnfollowUserResultUser? user = data.unfollowUser?.user;
      return user != null
          ? (
              viewerIsFollowing: user.viewerIsFollowing,
              followersCount: user.followers.totalCount,
            )
          : null;
    }
  }

  /// Fetches user contribution data with customizable date range.
  ///
  /// This query is separate from getUserInfoGraphQL to allow independent
  /// updates of contribution data without refetching all user info.
  ///
  /// [from] and [to] are optional. If not provided, defaults to last year.
  Future<UserContributionsDataUser> getUserContributions(
    final String login, {
    final DateTime? from,
    final DateTime? to,
    final bool refreshCache = false,
  }) async {
    // Default to last year if not specified
    final DateTime defaultTo = to ?? DateTime.now();
    final DateTime defaultFrom =
        from ?? DateTime(defaultTo.year - 1, defaultTo.month, defaultTo.day);
    final GQLResponse response = await gql.query(
      documentNodeQueryuserContributions,
      Variables$Query$userContributions(
        user: login,
        from: defaultFrom,
        to: defaultTo,
      ).toJson(),
      refreshCache: refreshCache,
    );
    final UserContributionsData parsed = UserContributionsData.fromJson(
      response.data!,
    );
    final UserContributionsDataUser? user = parsed.user;
    if (user == null) {
      throw Exception('Contribution data for "$login" not found');
    }
    return user;
  }

  /// Fetches dashboard data for the viewer: contributions (last 7 days),
  /// pinned repos, and search results (review requests, assigned issues, PRs).
  Future<DashboardData> getDashboardData({
    required String viewerLogin,
    bool refresh = false,
  }) async {
    final now = DateTime.now();
    final from = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 7));
    final response = await gql.query(
      documentNodeQuerydashboard,
      Variables$Query$dashboard(
        reviewQuery: 'is:pr is:open review-requested:$viewerLogin',
        issueQuery: 'is:issue is:open assignee:$viewerLogin sort:updated-desc',
        prQuery: 'is:pr is:open author:$viewerLogin sort:updated-desc',
        from: from,
        to: now,
      ).toJson(),
      refreshCache: refresh,
    );
    return DashboardData.fromJson(response.data!);
  }
}
