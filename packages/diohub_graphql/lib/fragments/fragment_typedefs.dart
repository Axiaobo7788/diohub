import 'package:diohub_graphql/fragments/repo_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/issue_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/pull_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/user_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/organization_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/discussion_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/release_list_item.graphql.dart';
import 'package:diohub_graphql/fragments/label.graphql.dart';
import 'package:diohub_graphql/fragments/reaction_groups.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_reactions.graphql.dart';
import 'package:diohub_graphql/queries/users/contribution_fragments.graphql.dart';
import 'package:diohub_graphql/fragments/actor.graphql.dart';
import 'package:diohub_graphql/fragments/project_item_card_fields.graphql.dart';

typedef LabelFragment = Fragment$label;

typedef RepositoryFields = Fragment$repositoryFields;

typedef RepoCardData = Fragment$repoCardFields;
typedef RepoCardLanguageEdge = Fragment$repoCardFields$languages$edges;
typedef RepoCardTopicEdge = Fragment$repoCardFields$repositoryTopics$edges;
typedef RepoCardLicenseCondition = Fragment$repoCardFields$licenseInfo$conditions;
typedef RepoCardLicenseLimitation = Fragment$repoCardFields$licenseInfo$limitations;
typedef RepoCardLicensePermission = Fragment$repoCardFields$licenseInfo$permissions;

typedef IssueCardData = Fragment$issueCardFields;
typedef IssueCardAssignees = Fragment$issueCardFields$assignees;
typedef IssueCardAssigneeNode = Fragment$issueCardFields$assignees$nodes;
typedef IssueCardLabels = Fragment$issueCardFields$labels;
typedef IssueCardLabelNode = Fragment$label;
typedef IssueCardMilestone = Fragment$issueCardFields$milestone;
typedef IssueCardProjectItemNode = Fragment$projectItemCardFields;
typedef IssueCardReactionGroups = Fragment$reactionGroups;
typedef IssueCardTrackedIssues = Fragment$issueCardFields$trackedIssues;
typedef IssueCardTrackedIssueNode = Fragment$issueCardFields$trackedIssues$nodes;

typedef PullCardData = Fragment$pullCardFields;
typedef PullCardAssignees = Fragment$pullCardFields$assignees;
typedef PullCardAssigneeNode = Fragment$pullCardFields$assignees$nodes;
typedef PullCardLabels = Fragment$pullCardFields$labels;
typedef PullCardLabelNode = Fragment$label;
typedef PullCardLatestReviewNode = Fragment$pullCardFields$latestOpinionatedReviews$nodes;
typedef PullCardMilestone = Fragment$pullCardFields$milestone;
typedef PullCardProjectItemNode = Fragment$projectItemCardFields;
typedef PullCardReactionGroups = Fragment$reactionGroups;

typedef UserCardData = Fragment$userCardFields;
typedef OrgCardData = Fragment$organizationCardFields;

typedef DiscussionCardData = Fragment$discussionCardFields;
typedef DiscussionCardAuthor = Fragment$actor;
typedef DiscussionCardLabelNode = Fragment$label;
typedef DiscussionCardPoll = Fragment$discussionCardFields$poll;
typedef DiscussionCardPollOptionNode = Fragment$discussionCardFields$poll$options$nodes;

typedef ReleaseListItemData = Fragment$releaseListItem;
typedef ReleaseListItemReactionGroups = Fragment$reactionGroups;

typedef ReactionGroupData = Fragment$reactionGroups;

typedef ReactorsGroup = Fragment$reactorsGroup;
typedef ReactorsGroupEdge = Fragment$reactorsGroup$reactors$edges;
