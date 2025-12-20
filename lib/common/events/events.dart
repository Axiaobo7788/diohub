import 'package:diohub/common/events/timeline_content/timeline_create_content.dart';
import 'package:diohub/common/events/timeline_content/timeline_delete_content.dart';
import 'package:diohub/common/events/timeline_content/timeline_fork_content.dart';
import 'package:diohub/common/events/timeline_content/timeline_member_content.dart';
import 'package:diohub/common/events/timeline_content/timeline_public_content.dart';
import 'package:diohub/common/events/timeline_content/timeline_watch_content.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/timeline/timeline_shimmer_item.dart';
import 'package:diohub/common/timeline/unified_timeline_item.dart';
import 'package:diohub/common/timeline_content/timeline_commit_content.dart';
import 'package:diohub/common/timeline_content/timeline_issue_content.dart';
import 'package:diohub/common/timeline_content/timeline_pull_request_content.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/models/commits/commit_card_data_model.dart';
import 'package:diohub/models/events/events_model.dart' hide Key;
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/services/activity/events_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

class Events extends StatelessWidget {
  const Events({
    this.privateEvents = true,
    this.specificUser,
    super.key,
  });

  final bool privateEvents;
  final String? specificUser;

  @override
  Widget build(final BuildContext context) {
    final CurrentUserProvider user = Provider.of<CurrentUserProvider>(context);
    return InfiniteScrollWrapper<EventsModel>(
      // header: (final BuildContext context) => Padding(
      //   padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      //   child: Text(
      //     'Feed',
      //     style: context.textTheme.headlineSmall?.copyWith(
      //       fontWeight: FontWeight.bold,
      //     ),
      //   ),
      // ),
      firstPageLoadingBuilder: (final BuildContext context) =>
          const TimelineShimmerList(
        itemCount: 5,
        showAvatar: true,
      ),
      filterFn: (final List<EventsModel> items) {
        final List<EventsModel> temp = <EventsModel>[];
        for (final EventsModel item in items) {
          if (<EventsType>{
            // EventsType.CommitCommentEvent,
            EventsType.CreateEvent,
            EventsType.DeleteEvent,
            EventsType.ForkEvent,
            // EventsType.GollumEvent,
            EventsType.IssueCommentEvent,
            EventsType.IssuesEvent,
            EventsType.MemberEvent,
            EventsType.PublicEvent,
            EventsType.PullRequestEvent,
            // EventsType.PullRequestReviewCommentEvent,
            EventsType.PushEvent,
            // EventsType.ReleaseEvent,
            // EventsType.SponsorshipEvent,
            EventsType.WatchEvent,
          }.contains(item.type)) {
            temp.add(item);
          }
        }

        return temp;
      },
      future: (
        final ScrollWrapperFutureArguments<EventsModel> data,
      ) async {
        if (specificUser != null) {
          return EventsService.getUserEvents(
            specificUser,
            page: data.pageNumber,
            perPage: data.pageSize,
            refresh: data.refresh,
          );
        } else if (privateEvents) {
          return EventsService.getReceivedEvents(
            user.data.login,
            page: data.pageNumber,
            perPage: data.pageSize,
            refresh: data.refresh,
          );
        } else {
          return EventsService.getPublicEvents(
            page: data.pageNumber,
            perPage: data.pageSize,
            refresh: data.refresh,
          );
        }
      },
      builder: (
        final BuildContext context,
        final ScrollWrapperBuilderData<EventsModel> data,
      ) {
        final EventsModel item = data.item;

        // Determine if timeline should break based on user changes
        final currentUser = item.actor?.login;
        final previousUser = data.previousItem?.actor?.login;
        final nextUser = data.nextItem?.actor?.login;

        final isFirstInUserGroup =
            previousUser != currentUser || data.index == 0;
        final isLastInUserGroup =
            nextUser != currentUser || data.isCurrentlyLast;

        return Column(
          children: [
            // User group header (only show for first item in group)
            if (isFirstInUserGroup)
              _buildUserGroupHeader(
                context,
                item.actor,
                isFirst: data.index == 0,
              ),
            // Timeline event
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: buildTimelineEvent(
                item,
                data,
                context,
                isFirstInUserGroup: isFirstInUserGroup,
                isLastInUserGroup: isLastInUserGroup,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildTimelineEvent(
    final EventsModel item,
    final ScrollWrapperBuilderData<EventsModel> data,
    final BuildContext context, {
    required bool isFirstInUserGroup,
    required bool isLastInUserGroup,
  }) {
    final date = item.createdAt;
    final eventType = item.type;

    String actionText;
    Widget content;

    switch (item.type) {
      case EventsType.PushEvent:
        actionText = 'pushed';
        final commitData = CommitCardDataModel.fromPushEvent(item);
        // Extract branch name from ref (e.g., "refs/heads/main" -> "main")
        // for RepoCardLoading which shows it in the card
        final branchName = item.payload?.ref?.split('/').last;
        // Pass full ref string for display in commit count text
        final ref = item.payload?.ref;
        content = TimelineCommitContent(
          commitData: commitData,
          branchName: branchName,
          ref: ref,
        );

      case EventsType.WatchEvent:
        actionText = 'starred';
        content = TimelineWatchContent(
          repoName: item.repo?.name ?? '',
          repoUrl: item.repo?.url ?? '',
        );

      case EventsType.ForkEvent:
        final forkee = item.payload?.forkee;
        actionText = 'forked';
        content = TimelineForkContent(
          sourceRepoName: item.repo?.name ?? '',
          sourceRepoUrl: item.repo?.url ?? '',
          forkRepoName: forkee?.fullName ?? forkee?.name ?? '',
          forkRepoUrl: forkee?.url ?? '',
        );

      case EventsType.CreateEvent:
        final refType = item.payload?.refType;
        final ref = item.payload?.ref;

        actionText = 'created';
        if (refType == RefType.REPOSITORY) {
          content = TimelineCreateContent(
            refType: 'repository',
            repoName: item.repo?.name ?? '',
            repoUrl: item.repo?.url ?? '',
          );
        } else if (refType == RefType.BRANCH) {
          content = TimelineCreateContent(
            refType: 'branch',
            repoName: item.repo?.name ?? '',
            repoUrl: item.repo?.url ?? '',
            refName: ref,
          );
        } else {
          content = TimelineCreateContent(
            refType: refTypeValues.reverse![refType] ?? 'tag',
            repoName: item.repo?.name ?? '',
            repoUrl: item.repo?.url ?? '',
            refName: ref,
          );
        }

      case EventsType.DeleteEvent:
        final refType = item.payload?.refType;
        final ref = item.payload?.ref;
        final refTypeName = refTypeValues.reverse![refType] ?? 'branch';
        final refName = ref?.split('/').last ?? '';

        // Restore action text: "deleted branch 'name'" or "deleted tag 'name'"
        if (refName.isNotEmpty) {
          actionText = 'deleted $refTypeName \'$refName\'';
        } else {
          actionText = 'deleted $refTypeName';
        }

        content = TimelineDeleteContent(
          refType: refTypeName,
          refName: refName,
          repoName: item.repo?.name ?? '',
          repoUrl: item.repo?.url ?? '',
        );

      case EventsType.PublicEvent:
        actionText = 'made public';
        content = TimelinePublicContent(
          repoName: item.repo?.name ?? '',
          repoUrl: item.repo?.url ?? '',
        );

      case EventsType.MemberEvent:
        final member = item.payload?.member;
        final action = item.payload?.action ?? 'added';
        actionText = action;
        content = TimelineMemberContent(
          member: member!,
          action: action,
          repoName: item.repo?.name ?? '',
          repoUrl: item.repo?.url ?? '',
        );

      case EventsType.IssuesEvent:
        final issue = item.payload?.issue;
        final action = item.payload?.action ?? 'opened';
        actionText = action;
        content = TimelineIssueContent(
          issueData: IssueCardDataModel.fromIssueModel(issue!),
        );

      case EventsType.IssueCommentEvent:
        final issue = item.payload?.issue;
        final comment = item.payload?.comment;
        actionText = 'commented';
        content = TimelineIssueContent(
          issueData: IssueCardDataModel.fromIssueModel(issue!),
          commentBody: comment?.body,
          commentsSince: item.createdAt,
        );

      case EventsType.PullRequestEvent:
        final pr = item.payload?.pullRequest;
        final action = item.payload?.action ?? 'opened';
        // Use "merged" action text if PR is merged, otherwise use the action from payload
        actionText = (pr?.merged == true) ? 'merged' : action;
        // Extract head (from) and base (to) branch refs
        final fromRef = pr?.head?.ref; // Source branch
        final toRef = pr?.base?.ref; // Target/base branch
        // Use PR URL to fetch full data via SimplePullLoadingCard
        final prUrl = pr?.htmlUrl ?? pr?.url ?? '';
        content = TimelinePullRequestContent(
          prUrl: prUrl,
          from: fromRef,
          to: toRef,
        );

      default:
        actionText = '${eventsValues.reverse![item.type]}';
        content = Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text('Unimplemented: ${eventsValues.reverse![item.type]}'),
          ),
        );
    }

    return UnifiedTimelineItem(
      eventIcon: _getEventIcon(eventType),
      eventIconColor: _getEventIconColor(context, eventType),
      actionText: actionText,
      date: date,
      highlighted: true,
      isFirst: isFirstInUserGroup,
      isLast: isLastInUserGroup,
      actionHeaderTopPadding: isFirstInUserGroup ? 4.0 : 16.0,
      child: content,
    );
  }

  IconData _getEventIcon(EventsType? type) {
    switch (type) {
      case EventsType.PushEvent:
        return Octicons.git_commit;
      case EventsType.PullRequestEvent:
        return Octicons.git_pull_request;
      case EventsType.IssuesEvent:
        return Octicons.issue_opened;
      case EventsType.IssueCommentEvent:
        return Octicons.comment;
      case EventsType.WatchEvent:
        return Octicons.star;
      case EventsType.ForkEvent:
        return Octicons.repo_forked;
      case EventsType.CreateEvent:
        return Octicons.plus;
      case EventsType.DeleteEvent:
        return Octicons.trash;
      case EventsType.PublicEvent:
        return Octicons.globe;
      case EventsType.MemberEvent:
        return Octicons.person_add;
      default:
        return Octicons.circle;
    }
  }

  Color _getEventIconColor(BuildContext context, EventsType? type) {
    final colorScheme = context.colorScheme;
    switch (type) {
      case EventsType.PushEvent:
        return const Color(0xFF2196F3); // Blue
      case EventsType.PullRequestEvent:
        return const Color(0xFF9C27B0); // Purple
      case EventsType.IssuesEvent:
        return const Color(0xFF4CAF50); // Green
      case EventsType.IssueCommentEvent:
        return const Color(0xFF00ACC1); // Cyan/Teal for comments
      case EventsType.WatchEvent:
        return const Color(0xFFFFC107); // Amber/Yellow
      case EventsType.ForkEvent:
        return const Color(0xFF00BCD4); // Cyan
      case EventsType.CreateEvent:
        return const Color(0xFF009688); // Teal
      case EventsType.DeleteEvent:
        return const Color(0xFFF44336); // Red
      case EventsType.PublicEvent:
        return const Color(0xFF3F51B5); // Indigo
      case EventsType.MemberEvent:
        return const Color(0xFFFF9800); // Orange
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildUserGroupHeader(
    BuildContext context,
    Actor? actor, {
    required bool isFirst,
  }) {
    if (actor == null || actor.login == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        navigateToProfile(
          context: context,
          login: actor.login!,
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          isFirst ? 8 : 32, // More space from previous group
          16,
          4, // Less space to own group
        ),
        child: Row(
          children: [
            UserAvatar(
              avatarUrl: actor.avatarUrl,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                actor.login!,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
