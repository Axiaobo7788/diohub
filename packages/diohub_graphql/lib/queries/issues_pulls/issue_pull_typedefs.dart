import 'package:diohub_graphql/queries/issues_pulls/issue_info_only.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/sub_issues.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pull_info_only.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pull_files.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pull_commits_list.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pr_merge_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_mutations.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pull_mutations.graphql.dart';
import 'package:diohub_graphql/fragments/actor.graphql.dart';
import 'package:diohub_graphql/fragments/issue_detail_fields.graphql.dart';
import 'package:diohub_graphql/fragments/pull_detail_fields.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/timeline.graphql.dart';
import 'package:diohub_graphql/fragments/label.graphql.dart';
import 'package:diohub_graphql/fragments/project_item_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/pull_card_fields.graphql.dart';
import 'package:diohub_graphql/fragments/issue_card_fields.graphql.dart';

export 'package:diohub_graphql/queries/issues_pulls/issue_info_only.graphql.dart';
export 'package:diohub_graphql/queries/issues_pulls/pull_info_only.graphql.dart';
export 'package:diohub_graphql/queries/issues_pulls/timeline.graphql.dart';
export 'package:diohub_graphql/queries/issues_pulls/pr_merge_mutations.graphql.dart';
export 'package:diohub_graphql/queries/issues_pulls/issue_mutations.graphql.dart';
export 'package:diohub_graphql/queries/issues_pulls/pull_mutations.graphql.dart';

// Issue typedefs
typedef IssueInfo = Fragment$issueDetailFields;
typedef IssueAssignees = Fragment$issueDetailFields$assignees;
typedef IssueAssigneeNode = Fragment$issueDetailFields$assignees$nodes;
typedef IssueLabels = Fragment$issueDetailFields$labels;
typedef IssueLabelNode = Fragment$label;
typedef IssueMilestone = Fragment$issueDetailFields$milestone;
typedef IssueParticipantNode = Fragment$issueDetailFields$participants$nodes;
typedef IssueProjectItems = Fragment$issueDetailFields$projectItems;
typedef IssueProjectItemNode = Fragment$projectItemCardFields;
typedef IssueProjectItemProject = Fragment$projectItemCardFields$project;
typedef IssueRepository = Fragment$issueDetailFields$repository;
typedef IssueClosedByPRNode = Fragment$pullCardFields;

typedef IssueTrackedIssues = Fragment$issueDetailFields$trackedIssues;
typedef IssueTrackedInIssues = Fragment$issueDetailFields$trackedInIssues;
typedef IssueTrackedIssueNode = Fragment$issueDetailFields$trackedIssues$nodes;
typedef IssueTrackedInIssueNode = Fragment$issueDetailFields$trackedInIssues$nodes;
typedef IssueInfoParticipantNode = Fragment$issueDetailFields$participants$nodes;
typedef IssueLinkedBranchEdge = Fragment$issueDetailFields$linkedBranches$edges;

// Pull typedefs
typedef PullClosingIssuesRefs = Fragment$pullDetailFields$closingIssuesReferences;
typedef PullClosingIssueRefNode = Fragment$issueCardFields;
typedef PullInfoReviewRequestNode = Fragment$pullDetailFields$reviewRequests$nodes;
typedef PullInfoParticipantNode = Fragment$pullDetailFields$participants$nodes;

// Create-issue mutation (used by IssueCreationService on RepoRef)
typedef CreateIssueData = Mutation$createIssue;

// Create-pull-request mutation (used by PullCreationService on RepoRef)
typedef CreatePullRequestData = Mutation$createPullRequest;

typedef SubIssueNode = Fragment$issueCardFields;

typedef PullInfo = Fragment$pullDetailFields;
typedef PullAssignees = Fragment$pullDetailFields$assignees;
typedef PullAssigneeNode = Fragment$pullDetailFields$assignees$nodes;
typedef PullLabels = Fragment$pullDetailFields$labels;
typedef PullLabelNode = Fragment$label;
typedef PullLatestReviewNode = Fragment$pullDetailFields$latestReviews$nodes;
typedef PullLatestReviewAuthor = Fragment$actor;
typedef PullMergedByActor = Fragment$pullDetailFields$mergedBy;
typedef PullMilestone = Fragment$pullDetailFields$milestone;
typedef PullParticipantNode = Fragment$pullDetailFields$participants$nodes;
typedef PullProjectItems = Fragment$pullDetailFields$projectItems;
typedef PullProjectItemNode = Fragment$projectItemCardFields;
typedef PullProjectItemProject = Fragment$projectItemCardFields$project;
typedef PullRepository = Fragment$pullDetailFields$repository;
typedef PullReviewRequestNode = Fragment$pullDetailFields$reviewRequests$nodes;
typedef PullStatusCheckRollup = Fragment$pullDetailFields$statusCheckRollup;
typedef PullStatusCheckNode = Fragment$pullDetailFields$statusCheckRollup$contexts$nodes;
typedef PullClosingIssueNode = Fragment$issueCardFields;
typedef PullAutoMergeRequest = Fragment$pullDetailFields$autoMergeRequest;

typedef PullFileEdge = Query$pullFiles$repository$pullRequest$files$edges;
typedef PullFileNode = Query$pullFiles$repository$pullRequest$files$edges$node;

typedef PullCommitEdge = Query$pullCommitsList$repository$pullRequest$commits$edges;
typedef PullCommitNode = Fragment$commitListItem;

// Union type for merge mutation result's mergedBy (Actor | other)
typedef MergePullRequestMergedBy = Mutation$mergePullRequest$mergePullRequest$pullRequest$mergedBy;
typedef MergePullMergedByActor = Fragment$actor;

typedef Actor = Fragment$actor;

// Timeline event fragments
typedef AssignedEvent = Fragment$assigned;
typedef BaseRefChangedEvent = Fragment$baseRefChanged;
typedef BaseRefDeletedEvent = Fragment$baseRefDeleted;
typedef BaseRefForcePushedEvent = Fragment$baseRefForcePushed;
typedef ClosedEvent = Fragment$closed;
typedef ConvertedToDraftEvent = Fragment$convertedToDraft;
typedef CrossReferenceEvent = Fragment$crossReference;
typedef DemilestonedEvent = Fragment$deMileStoned;
typedef HeadRefDeletedEvent = Fragment$headRefDeleted;
typedef HeadRefForcePushedEvent = Fragment$headRefForcePushed;
typedef HeadRefRestoredEvent = Fragment$headRefRestored;
typedef IssueCommentEvent = Fragment$issueComment;
typedef LabeledEvent = Fragment$labeled;
typedef LockedEvent = Fragment$locked;
typedef MarkedAsDuplicateEvent = Fragment$markedAsDuplicate;
typedef MergedEvent = Fragment$merged;
typedef MilestonedEvent = Fragment$mileStoned;
typedef PinnedEvent = Fragment$pinned;
typedef PullRequestCommitEvent = Fragment$pullRequestCommit;
typedef TimelinePullRequestReviewEvent = Fragment$pullRequestReview;
typedef ReadyForReviewEvent = Fragment$readyForReview;
typedef RenamedTitleEvent = Fragment$renamedTitle;
typedef ReopenedEvent = Fragment$reopened;
typedef UnassignedEvent = Fragment$unassigned;
typedef UnlabeledEvent = Fragment$unlabeled;
typedef UnlockedEvent = Fragment$unlocked;
typedef UnmarkedAsDuplicateEvent = Fragment$unmarkedAsDuplicate;
typedef UnpinnedEvent = Fragment$unpinned;
typedef AddedToMergeQueueEvent = Fragment$addedToMergeQueue;
typedef RemovedFromMergeQueueEvent = Fragment$removedFromMergeQueue;
typedef AutoMergeEnabledEvent = Fragment$autoMergeEnabled;
typedef AutoMergeDisabledEvent = Fragment$autoMergeDisabled;
typedef SubIssueAddedEvent = Fragment$subIssueAdded;
typedef SubIssueRemovedEvent = Fragment$subIssueRemoved;
typedef ParentIssueAddedEvent = Fragment$parentIssueAdded;
typedef ParentIssueRemovedEvent = Fragment$parentIssueRemoved;
typedef IssueTypeAddedEvent = Fragment$issueTypeAdded;
typedef IssueTypeChangedEvent = Fragment$issueTypeChanged;
typedef IssueTypeRemovedEvent = Fragment$issueTypeRemoved;
typedef AddedToProjectV2Event = Fragment$addedToProjectV2;
typedef RemovedFromProjectV2Event = Fragment$removedFromProjectV2;
typedef ProjectV2ItemStatusChangedEvent = Fragment$projectV2ItemStatusChanged;
typedef DeploymentEnvironmentChangedEvent = Fragment$deploymentEnvironmentChanged;
typedef ConvertedToDiscussionEvent = Fragment$convertedToDiscussion;
typedef BlockingAddedEvent = Fragment$blockingAdded;
typedef BlockingRemovedEvent = Fragment$blockingRemoved;
typedef BlockedByAddedEvent = Fragment$blockedByAdded;
typedef BlockedByRemovedEvent = Fragment$blockedByRemoved;
typedef ConnectedEvent = Fragment$connectedEvent;
typedef DisconnectedEvent = Fragment$disconnectedEvent;
typedef CommitEvent = Fragment$commit;

// Cross-reference union types
typedef CrossReferenceSourceIssue = Fragment$crossReference$source$$Issue;
typedef CrossReferenceSourcePullRequest = Fragment$crossReference$source$$PullRequest;
typedef MarkedAsDuplicateCanonicalIssue = Fragment$markedAsDuplicate$canonical$$Issue;
typedef MarkedAsDuplicateCanonicalPullRequest = Fragment$markedAsDuplicate$canonical$$PullRequest;
typedef UnmarkedAsDuplicateCanonicalIssue = Fragment$unmarkedAsDuplicate$canonical$$Issue;
typedef UnmarkedAsDuplicateCanonicalPullRequest = Fragment$unmarkedAsDuplicate$canonical$$PullRequest;

// Timeline edges
typedef IssueTimelineEdge = Query$getTimeline$repository$issueOrPullRequest$$Issue$timelineItems$edges;
typedef PullTimelineEdge = Query$getTimeline$repository$issueOrPullRequest$$PullRequest$timelineItems$edges;
typedef TimelineReviewRequestedEvent = Query$getTimeline$repository$issueOrPullRequest$$PullRequest$timelineItems$edges$node$$ReviewRequestedEvent;
typedef TimelineReviewRequestedTeam = Query$getTimeline$repository$issueOrPullRequest$$PullRequest$timelineItems$edges$node$$ReviewRequestedEvent$requestedReviewer$$Team;
