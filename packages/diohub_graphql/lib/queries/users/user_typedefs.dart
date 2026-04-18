import 'package:diohub_graphql/queries/users/follow_mutations.graphql.dart';
import 'package:diohub_graphql/queries/users/follow_status.graphql.dart';
import 'package:diohub_graphql/queries/users/get_org_members.graphql.dart';
import 'package:diohub_graphql/queries/users/get_org_teams.graphql.dart';
import 'package:diohub_graphql/queries/users/get_user_watching.graphql.dart';
import 'package:diohub_graphql/queries/users/user_card_by_login.graphql.dart';
import 'package:diohub_graphql/queries/users/user_contributions.graphql.dart';
import 'package:diohub_graphql/queries/users/user_info.graphql.dart';
import 'package:diohub_graphql/queries/users/user_lists.graphql.dart';
import 'package:diohub_graphql/queries/users/user_packages.graphql.dart';
import 'package:diohub_graphql/queries/users/user_projects_v2.graphql.dart';
import 'package:diohub_graphql/queries/users/user_public_keys.graphql.dart';
import 'package:diohub_graphql/queries/users/user_repositories_list.graphql.dart';
import 'package:diohub_graphql/queries/users/user_repos.graphql.dart';
import 'package:diohub_graphql/queries/users/user_sponsors.graphql.dart';
import 'package:diohub_graphql/queries/users/user_status.graphql.dart';
import 'package:diohub_graphql/fragments/repo_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/user_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/organization_card_fields.graphql.dart';

export 'package:diohub_graphql/queries/users/user_info.graphql.dart';
export 'package:diohub_graphql/queries/users/user_card_by_login.graphql.dart';
export 'package:diohub_graphql/queries/users/follow_mutations.graphql.dart';
export 'package:diohub_graphql/queries/users/user_sponsors.graphql.dart';

// User profile types
typedef UserProfileOwner = Query$userInfo$repositoryOwner;
typedef UserProfile = Query$userInfo$repositoryOwner$$User;
typedef UserStatus = Query$userInfo$repositoryOwner$$User$status;
typedef UserFollowers = Query$userInfo$repositoryOwner$$User$followers;
typedef OrgProfile = Query$userInfo$repositoryOwner$$Organization;

// Follow status
typedef FollowStatusInfo = Query$followStatusInfo$user;

// User lists - followers, following, gists, packages, sponsors, watching, orgs, repos
typedef UserFollowerEdge = Query$getUserFollowers$user$followers$edges;
typedef UserFollowerNode = Fragment$userCardFields;
typedef UserFollowingEdge = Query$getUserFollowing$user$following$edges;
typedef UserFollowingNode = Fragment$userCardFields;
typedef UserGistEdge = Query$getUserGists$user$gists$edges;
typedef UserGistNode = Query$getUserGists$user$gists$edges$node;
typedef UserPackageEdge = Query$getUserPackages$user$packages$edges;
typedef UserPackageNode = Query$getUserPackages$user$packages$edges$node;
typedef UserSponsorEdge = Query$getUserSponsors$user$sponsors$edges;
typedef UserSponsorNode = Query$getUserSponsors$user$sponsors$edges$node;
typedef UserSponsorAsUser =
    Query$getUserSponsors$user$sponsors$edges$node$$User;
typedef UserSponsorAsOrg =
    Query$getUserSponsors$user$sponsors$edges$node$$Organization;
typedef UserWatchingEdge = Query$getUserWatching$user$watching$edges;
typedef UserWatchingNode = Fragment$repoCardFields;
typedef UserOrgEdge = Query$getUserOrganizations$user$organizations$edges;
typedef UserOrgNode = Fragment$organizationCardFields;
typedef UserRepoEdge = Query$getUserRepositories$user$repositories$edges;
typedef UserPublicKeyNode = Query$userPublicKeys$user$publicKeys$nodes;

// Contribution calendar types
typedef ContributionWeek =
    Query$userContributions$user$contributionsCollection$contributionCalendar$weeks;
typedef ContributionDay =
    Query$userContributions$user$contributionsCollection$contributionCalendar$weeks$contributionDays;
typedef CommitContributionsByRepo =
    Query$userContributions$user$contributionsCollection$commitContributionsByRepository;
typedef IssueContributionsByRepo =
    Query$userContributions$user$contributionsCollection$issueContributionsByRepository;
typedef PRContributionsByRepo =
    Query$userContributions$user$contributionsCollection$pullRequestContributionsByRepository;
typedef PRReviewContributionsByRepo =
    Query$userContributions$user$contributionsCollection$pullRequestReviewContributionsByRepository;

// Contribution highlight union types (have maybeWhen)
typedef FirstIssueContribution =
    Query$userContributions$user$contributionsCollection$firstIssueContribution;
typedef FirstPRContribution =
    Query$userContributions$user$contributionsCollection$firstPullRequestContribution;
typedef FirstRepoContribution =
    Query$userContributions$user$contributionsCollection$firstRepositoryContribution;

// Concrete subtypes of the union types
typedef CreatedIssueContribution =
    Query$userContributions$user$contributionsCollection$firstIssueContribution$$CreatedIssueContribution;
typedef RestrictedIssueContribution =
    Query$userContributions$user$contributionsCollection$firstIssueContribution$$RestrictedContribution;
typedef CreatedPRContribution =
    Query$userContributions$user$contributionsCollection$firstPullRequestContribution$$CreatedPullRequestContribution;
typedef RestrictedPRContribution =
    Query$userContributions$user$contributionsCollection$firstPullRequestContribution$$RestrictedContribution;
typedef CreatedRepoContribution =
    Query$userContributions$user$contributionsCollection$firstRepositoryContribution$$CreatedRepositoryContribution;
typedef RestrictedRepoContribution =
    Query$userContributions$user$contributionsCollection$firstRepositoryContribution$$RestrictedContribution;

// Contribution highlight concrete types (no union, no maybeWhen)
typedef PopularIssueContribution =
    Query$userContributions$user$contributionsCollection$popularIssueContribution;
typedef PopularPRContribution =
    Query$userContributions$user$contributionsCollection$popularPullRequestContribution;

// User status mutation
typedef ChangedUserStatus = Mutation$changeUserStatus$changeUserStatus$status;

// Mutation types
typedef FollowOrganizationData = Mutation$followOrganization;
typedef UnfollowOrganizationData = Mutation$unfollowOrganization;
typedef FollowUserData = Mutation$followUser;
typedef UnfollowUserData = Mutation$unfollowUser;
typedef FollowUserResultUser = Mutation$followUser$followUser$user;
typedef UnfollowUserResultUser = Mutation$unfollowUser$unfollowUser$user;

// ProjectV2
typedef UserProjectV2Edge = Query$getUserProjectsV2$user$projectsV2$edges;
typedef UserProjectV2Node = Query$getUserProjectsV2$user$projectsV2$edges$node;

// Starred repos
typedef UserStarredRepoEdge =
    Query$getUserStarredRepositories$user$starredRepositories$edges;
typedef UserStarredRepoNode = Fragment$repoCardFields;

// User repositories
typedef UserRepositories = Query$getUserRepositories$user$repositories;

// Org members and teams
typedef OrgMemberEdge = Query$getOrgMembers$organization$membersWithRole$edges;
typedef OrgMemberNode = Fragment$userCardFields;
typedef GetOrgMembersData = Query$getOrgMembers;
typedef OrgTeamEdge = Query$getOrgTeams$organization$teams$edges;
typedef OrgTeamNode = Query$getOrgTeams$organization$teams$edges$node;
typedef GetOrgTeamsData = Query$getOrgTeams;

// Query data types
typedef GetUserCardByLoginData = Query$getUserCardByLogin;
typedef UserInfoData = Query$userInfo;
typedef GetUserRepositoriesData = Query$getUserRepositories;
typedef GetUserFollowersData = Query$getUserFollowers;
typedef GetUserFollowingData = Query$getUserFollowing;
typedef GetUserOrganizationsData = Query$getUserOrganizations;
typedef GetUserGistsData = Query$getUserGists;
typedef UserPublicKeysData = Query$userPublicKeys;
typedef GetUserStarredRepositoriesData = Query$getUserStarredRepositories;
typedef GetUserWatchingData = Query$getUserWatching;
typedef GetUserPackagesData = Query$getUserPackages;
typedef GetUserProjectsV2Data = Query$getUserProjectsV2;
typedef GetUserSponsorsData = Query$getUserSponsors;
typedef UserContributionsData = Query$userContributions;
typedef UserContributionsDataUser = Query$userContributions$user;
typedef FollowStatusInfoData = Query$followStatusInfo;
