import 'package:diohub_graphql/queries/issues_pulls/pr_review_comments.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pr_review_threads.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/pr_review_checks.graphql.dart';

export 'package:diohub_graphql/queries/issues_pulls/pr_review_checks.graphql.dart';

typedef ReviewCommentEdge = Query$getPRReviewComments$node$$PullRequestReview$comments$edges;
typedef ReviewCommentNode = Fragment$pullRequestReviewComment;

typedef ReviewThreadsData = Query$getPullRequestReviewThreads;
typedef ReviewThreadEdge = Query$getPullRequestReviewThreads$repository$pullRequest$reviewThreads$edges;
typedef ThreadReplyEdge = Query$reviewThreadCommentsQuery$node$$PullRequestReviewThread$comments$edges;
typedef ThreadReplyNode = Fragment$pullRequestReviewComment;

typedef ViewerPendingReviewData = Query$getViewerPendingReview;
typedef PendingReviewNode = Query$getViewerPendingReview$node$$PullRequest$reviews$nodes;
