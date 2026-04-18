import 'package:diohub_graphql/queries/common/rate_limit.graphql.dart';
import 'package:diohub_graphql/queries/users/get_saved_replies.graphql.dart';
import 'package:diohub_graphql/queries/users/viewer_info.graphql.dart';
import 'package:diohub_graphql/queries/viewer/viewer.query.graphql.dart';
import 'package:diohub_graphql/queries/viewer/dashboard.query.graphql.dart';
import 'package:diohub_graphql/fragments/organization_card_fields.graphql.dart';

export 'package:diohub_graphql/queries/users/viewer_info.graphql.dart';

typedef ViewerInfoData = Query$viewerInfo;
typedef ViewerInfo = Query$viewerInfo$viewer;

typedef GetViewerOrgsData = Query$getViewerOrgs;
typedef ViewerOrgEdge = Query$getViewerOrgs$viewer$organizations$edges;
typedef ViewerOrgNode = Fragment$organizationCardFields;

typedef GetSavedRepliesData = Query$getSavedReplies;
typedef SavedReplyEdge = Query$getSavedReplies$viewer$savedReplies$edges;

typedef RateLimitData = Query$getRateLimit;

typedef DashboardData = Query$dashboard;
typedef DashboardViewer = Query$dashboard$viewer;
typedef DashboardContributions = Query$dashboard$viewer$contributionsCollection;
typedef DashboardCalendar = Query$dashboard$viewer$contributionsCollection$contributionCalendar;
typedef DashboardPinnedItem = Query$dashboard$viewer$pinnedItems$nodes;
typedef DashboardReviewSearch = Query$dashboard$reviewRequests;
typedef DashboardIssueSearch = Query$dashboard$assignedIssues;
typedef DashboardPRSearch = Query$dashboard$yourPRs;

