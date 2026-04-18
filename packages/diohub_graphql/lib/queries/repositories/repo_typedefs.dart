import 'package:diohub_graphql/queries/repositories/repo_info.graphql.dart';
import 'package:diohub_graphql/queries/repositories/commit_info.graphql.dart';
import 'package:diohub_graphql/queries/repositories/branches_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/commits_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/tags_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_lists.graphql.dart';
import 'package:diohub_graphql/queries/repositories/projects_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/deployments.graphql.dart';
import 'package:diohub_graphql/queries/repositories/repo_star_watch.graphql.dart';
import 'package:diohub_graphql/queries/repositories/clone_template_repository.graphql.dart';
import 'package:diohub_graphql/queries/repositories/label_mutations.graphql.dart';
import 'package:diohub_graphql/queries/repositories/releases_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/discussions_list.graphql.dart';
import 'package:diohub_graphql/queries/repositories/release_assets.graphql.dart';
import 'package:diohub_graphql/queries/repositories/forks.graphql.dart';
import 'package:diohub_graphql/queries/repositories/stargazers.graphql.dart';
import 'package:diohub_graphql/queries/repositories/watchers.graphql.dart';
import 'package:diohub_graphql/fragments/release_asset.graphql.dart';
import 'package:diohub_graphql/fragments/release_list_item.graphql.dart';
import 'package:diohub_graphql/fragments/user_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/repo_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/label.graphql.dart';

export 'package:diohub_graphql/queries/repositories/repo_info.graphql.dart';
export 'package:diohub_graphql/queries/repositories/branches_list.graphql.dart';
export 'package:diohub_graphql/queries/repositories/tags_list.graphql.dart';
export 'package:diohub_graphql/queries/repositories/clone_template_repository.graphql.dart';

// Discussion types
typedef DiscussionEdge = Query$discussionsList$repository$discussions$edges;

// Repository info types
typedef RepoInfoData = Query$repositoryInfo;
typedef RepoInfo = Query$repositoryInfo$repository;
typedef RepoIssueTemplate = Query$repositoryInfo$repository$issueTemplates;
typedef RepoIssueTemplateAssignee = Query$repositoryInfo$repository$issueTemplates$assignees$nodes;
typedef RepoIssueTemplateLabel = Fragment$label;
typedef RepoLanguageEdge = Query$repositoryInfo$repository$languages$edges;
typedef RepoLicenseInfo = Query$repositoryInfo$repository$licenseInfo;
typedef RepoLicenseCondition = Query$repositoryInfo$repository$licenseInfo$conditions;
typedef RepoLicenseLimitation = Query$repositoryInfo$repository$licenseInfo$limitations;
typedef RepoLicensePermission = Query$repositoryInfo$repository$licenseInfo$permissions;
typedef RepoOwnerAsOrg = Query$repositoryInfo$repository$owner$$Organization;
typedef RepoOwnerAsUser = Query$repositoryInfo$repository$owner$$User;
typedef RepoPinnedIssues = Query$repositoryInfo$repository$pinnedIssues;
typedef RepoPinnedIssueNode = Query$repositoryInfo$repository$pinnedIssues$nodes;
typedef RepoTopicEdge = Query$repositoryInfo$repository$repositoryTopics$edges;
typedef RepoTopicEdgeNode = Query$repositoryInfo$repository$repositoryTopics$edges$node;
typedef RepoTopic = Query$repositoryInfo$repository$repositoryTopics$edges$node$topic;

// Commit info types
typedef CommitInfo = Query$commitInfo$repository$object$$Commit;
typedef CommitAssociatedPRs = Query$commitInfo$repository$object$$Commit$associatedPullRequests;
typedef CommitAssociatedPREdge = Query$commitInfo$repository$object$$Commit$associatedPullRequests$edges;
typedef CommitAssociatedPRNode = Query$commitInfo$repository$object$$Commit$associatedPullRequests$edges$node;
typedef CommitParentEdge = Query$commitInfo$repository$object$$Commit$parents$edges;
typedef CommitParentNode = Query$commitInfo$repository$object$$Commit$parents$edges$node;

// Branch types
typedef BranchEdge = Query$branchesList$repository$refs$edges;
typedef BranchNode = Query$branchesList$repository$refs$edges$node;
typedef BranchCommit = Query$branchesList$repository$refs$edges$node$target$$Commit;
typedef BranchCommitAuthor = Query$branchesList$repository$refs$edges$node$target$$Commit$author;

// Tag types
typedef TagEdge = Query$tagsList$repository$refs$edges;
typedef TagNode = Query$tagsList$repository$refs$edges$node;
typedef TagAsTag = Query$tagsList$repository$refs$edges$node$target$$Tag;
typedef TagAsCommit = Query$tagsList$repository$refs$edges$node$target$$Commit;
typedef TagTargetCommit = Query$tagsList$repository$refs$edges$node$target$$Tag$target$$Commit;

// Milestone, assignable users, labels, projects
typedef MilestoneEdge = Query$repositoryMilestones$repository$milestones$edges;
typedef MilestoneNode = Query$repositoryMilestones$repository$milestones$edges$node;
typedef AssignableUserEdge = Query$repoAssignableUsers$repository$assignableUsers$edges;
typedef LabelEdge = Query$repoLabels$repository$labels$edges;
typedef LabelNode = Query$repoLabels$repository$labels$edges$node;
typedef ProjectV2ListItem = Query$projectsList$repository$projectsV2;
typedef ProjectV2Edge = Query$projectsList$repository$projectsV2$edges;
typedef ProjectV2Node = Query$projectsList$repository$projectsV2$edges$node;
typedef ProjectV2PickerEdge = Query$repositoryProjectsV2$repository$projectsV2$edges;
typedef DeploymentNode = Query$repositoryDeployments$repository$deployments$nodes;

// Star/watch status
typedef HasStarredRepo = Query$hasStarred$repository;
typedef HasWatchedRepo = Query$hasWatched$repository;
typedef CloneTemplateRepositoryData = Mutation$cloneTemplateRepository;

// Releases
typedef ReleaseEdge = Query$releasesList$repository$releases$edges;
typedef ReleaseNode = Fragment$releaseListItem;
typedef ReleaseAssetNode = Fragment$releaseAssetFields;

// Forks, stargazers, watchers
typedef ForkEdge = Query$getForks$repository$forks$edges;
typedef ForkNode = Fragment$repoCardFields;
typedef StargazerEdge = Query$getStargazers$repository$stargazers$edges;
typedef StargazerNode = Fragment$userCardFields;
typedef WatcherEdge = Query$getWatchers$repository$watchers$edges;
typedef WatcherNode = Fragment$userCardFields;

// Commits list
typedef CommitHistory = Fragment$commitHistoryConnection;
typedef CommitEdge = Fragment$commitHistoryConnection$edges;
typedef CommitNode = Fragment$commitListItem;

// Label mutations
typedef CreatedLabel = Mutation$createLabel$createLabel$label;
typedef UpdatedLabel = Mutation$updateLabel$updateLabel$label;
typedef CloneTemplateResult = Mutation$cloneTemplateRepository$cloneTemplateRepository$repository;

