import 'package:diohub_graphql/schema.graphql.dart';

// Issue and Pull Request state enums
typedef IssueState = Enum$IssueState;
typedef IssueStateReason = Enum$IssueStateReason;
typedef IssueClosedStateReason = Enum$IssueClosedStateReason;
typedef PullRequestState = Enum$PullRequestState;
typedef PullRequestUpdateState = Enum$PullRequestUpdateState;
typedef MergeStateStatus = Enum$MergeStateStatus;
typedef MergeableState = Enum$MergeableState;
typedef MilestoneState = Enum$MilestoneState;
typedef SubscriptionState = Enum$SubscriptionState;
typedef StatusState = Enum$StatusState;

// Pull Request review and reaction enums
typedef PullRequestMergeMethod = Enum$PullRequestMergeMethod;
typedef PullRequestReviewDecision = Enum$PullRequestReviewDecision;
typedef PullRequestReviewState = Enum$PullRequestReviewState;
typedef PullRequestReviewEvent = Enum$PullRequestReviewEvent;
typedef ReactionContent = Enum$ReactionContent;
typedef LockReason = Enum$LockReason;
typedef DiffSide = Enum$DiffSide;
typedef CommentAuthorAssociation = Enum$CommentAuthorAssociation;
typedef CommentCannotUpdateReason = Enum$CommentCannotUpdateReason;
typedef ReportedContentClassifiers = Enum$ReportedContentClassifiers;
typedef ContributionLevel = Enum$ContributionLevel;
typedef IssueTypeColor = Enum$IssueTypeColor;

// Order types and their fields
typedef OrderDirection = Enum$OrderDirection;
typedef RefOrder = Input$RefOrder;
typedef RefOrderField = Enum$RefOrderField;
typedef ReleaseOrder = Input$ReleaseOrder;
typedef ReleaseOrderField = Enum$ReleaseOrderField;
typedef DiscussionOrder = Input$DiscussionOrder;
typedef DiscussionOrderField = Enum$DiscussionOrderField;
typedef ProjectV2Order = Input$ProjectV2Order;
typedef ProjectV2OrderField = Enum$ProjectV2OrderField;

// Repository types
typedef RepositoryPermission = Enum$RepositoryPermission;
typedef RepositoryOrder = Input$RepositoryOrder;
typedef RepositoryOrderField = Enum$RepositoryOrderField;
typedef RepositoryVisibility = Enum$RepositoryVisibility;

// Merge commit message types
typedef SquashMergeCommitMessage = Enum$SquashMergeCommitMessage;
typedef SquashMergeCommitTitle = Enum$SquashMergeCommitTitle;
typedef MergeCommitMessage = Enum$MergeCommitMessage;
typedef MergeCommitTitle = Enum$MergeCommitTitle;

// Team and sponsorship privacy
typedef TeamPrivacy = Enum$TeamPrivacy;
typedef SponsorshipPrivacy = Enum$SponsorshipPrivacy;
