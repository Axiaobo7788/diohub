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
import 'package:diohub/models/events/events_model.dart' hide Key, State;
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

  // Spacing constants for consistent user group separation
  static const double itemSpacing = 8.0; // Between items from same user
  static const double groupSpacing = 8.0; // Between user groups

  @override
  Widget build(final BuildContext context) {
    final CurrentUserProvider user = Provider.of<CurrentUserProvider>(context);
    // Add bottom padding to account for SafeArea/system UI
    final bottomPadding = MediaQuery.of(context).padding.bottom;
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
      padding: EdgeInsets.only(
        top: 16,
        bottom: 16 + bottomPadding, // Add SafeArea bottom padding
      ),
      firstPageLoadingBuilder: (final BuildContext context) => _KeepAlive(
        child: TimelineShimmerList(
          itemCount: 5,
          showAvatar: false,
          showUserHeaders: true,
          padding: EdgeInsets.only(
            top: 16,
            bottom: 16 + bottomPadding,
          ),
        ),
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
        final bool shouldShowUserHeader = specificUser == null;

        final isFirstInUserGroup =
            previousUser != currentUser || data.index == 0;
        final isLastInUserGroup =
            nextUser != currentUser || data.isCurrentlyLast;

        return Column(
          children: [
            // Divider between groups (not for first item)
            // if (isFirstInUserGroup && data.index > 0)
            //   Padding(
            //     padding: EdgeInsets.symmetric(
            //       horizontal: MediaQuery.of(context).size.width * 0.05,
            //       // vertical: groupSpacing / 2,
            //     ).copyWith(top: 16),
            //     child: Divider(
            //       height: 1,
            //       thickness: 1,
            //       color: context.colorScheme.outlineVariant.withOpacity(0.2),
            //     ),
            //   ),
            // User group header (only show for first item in group)
            if (shouldShowUserHeader && isFirstInUserGroup)
              _buildUserGroupHeader(
                context,
                item.actor,
                isFirst: data.index == 0,
              ),
            // Timeline event
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
        actionText = 'pushed commits';
        final commitData = CommitCardDataModel.fromPushEvent(item);
        // Extract branch name from ref (e.g., "refs/heads/main" -> "main")
        // for RepoCardLoading which shows it in the card
        final branchName = item.payload?.ref?.split('/').last;
        // Pass commit SHA (head) as ref - this is the latest commit SHA
        final commitSha = item.payload?.head;
        content = _KeepAlive(
          child: TimelineCommitContent(
            commitData: commitData,
            branchName: branchName,
            ref: commitSha, // Commit SHA, not branch ref
          ),
        );

      case EventsType.WatchEvent:
        actionText = 'starred repository';
        content = _KeepAlive(
          child: TimelineWatchContent(
            repoName: item.repo?.name ?? '',
            repoUrl: item.repo?.url ?? '',
          ),
        );

      case EventsType.ForkEvent:
        final forkee = item.payload?.forkee;
        actionText = 'forked repository';
        content = _KeepAlive(
          child: TimelineForkContent(
            sourceRepoName: item.repo?.name ?? '',
            sourceRepoUrl: item.repo?.url ?? '',
            forkRepoName: forkee?.fullName ?? forkee?.name ?? '',
            forkRepoUrl: forkee?.url ?? '',
          ),
        );

      case EventsType.CreateEvent:
        final refType = item.payload?.refType;
        final ref = item.payload?.ref;

        if (refType == RefType.REPOSITORY) {
          actionText = 'created a repository';
          content = _KeepAlive(
            child: TimelineCreateContent(
              refType: 'repository',
              repoName: item.repo?.name ?? '',
              repoUrl: item.repo?.url ?? '',
            ),
          );
        } else if (refType == RefType.BRANCH) {
          actionText = 'created a branch';
          content = _KeepAlive(
            child: TimelineCreateContent(
              refType: 'branch',
              repoName: item.repo?.name ?? '',
              repoUrl: item.repo?.url ?? '',
              refName: ref,
            ),
          );
        } else {
          final refTypeName = refTypeValues.reverse![refType] ?? 'tag';
          actionText = 'created a $refTypeName';
          content = _KeepAlive(
            child: TimelineCreateContent(
              refType: refTypeName,
              repoName: item.repo?.name ?? '',
              repoUrl: item.repo?.url ?? '',
              refName: ref,
            ),
          );
        }

      case EventsType.DeleteEvent:
        final refType = item.payload?.refType;
        final ref = item.payload?.ref;
        final refTypeName = refTypeValues.reverse![refType] ?? 'branch';
        final refName = ref?.split('/').last ?? '';

        actionText = 'deleted a $refTypeName';

        content = _KeepAlive(
          child: TimelineDeleteContent(
            refType: refTypeName,
            refName: refName,
            repoName: item.repo?.name ?? '',
            repoUrl: item.repo?.url ?? '',
          ),
        );

      case EventsType.PublicEvent:
        actionText = 'made repository public';
        content = _KeepAlive(
          child: TimelinePublicContent(
            repoName: item.repo?.name ?? '',
            repoUrl: item.repo?.url ?? '',
          ),
        );

      case EventsType.MemberEvent:
        final member = item.payload?.member;
        final action = item.payload?.action ?? 'added';
        actionText = '$action a member';
        content = _KeepAlive(
          child: TimelineMemberContent(
            member: member!,
            action: action,
            repoName: item.repo?.name ?? '',
            repoUrl: item.repo?.url ?? '',
          ),
        );

      case EventsType.IssuesEvent:
        final issue = item.payload?.issue;
        final action = item.payload?.action ?? 'opened';
        actionText = '$action an issue';
        content = TimelineIssueContent(
          issueData: IssueCardDataModel.fromIssueModel(issue!),
        );

      case EventsType.IssueCommentEvent:
        final issue = item.payload?.issue;
        final comment = item.payload?.comment;
        actionText = 'commented on issue';
        content = TimelineIssueContent(
          issueData: IssueCardDataModel.fromIssueModel(issue!),
          commentBody: comment?.body,
          commentsSince: item.createdAt,
        );

      case EventsType.PullRequestEvent:
        final pr = item.payload?.pullRequest;
        final action = item.payload?.action ?? 'opened';
        final bool isMergedAction = action
            .toLowerCase()
            .contains('merged'); // payload can be "merged a pull request"
        final bool isMerged =
            isMergedAction || pr?.merged == true || pr?.mergedAt != null;
        // Use "merged" action text if PR is merged, otherwise use the action from payload
        if (isMerged) {
          actionText = 'merged a pull request';
        } else {
          actionText = '$action a pull request';
        }
        // Extract head (from) and base (to) branch refs
        final fromRef = pr?.head?.ref; // Source branch
        final toRef = pr?.base?.ref; // Target/base branch
        // Use PR URL to fetch full data via SimplePullLoadingCard
        final prUrl = pr?.htmlUrl ?? pr?.url ?? '';
        content = _KeepAlive(
          child: TimelinePullRequestContent(
            prUrl: prUrl,
            from: fromRef,
            to: toRef,
          ),
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
      eventIcon: _getEventIcon(eventType, item, actionText),
      eventIconColor: _getEventIconColor(context, eventType, item, actionText),
      actionText: actionText,
      date: date,
      highlighted: true,
      isFirst: isFirstInUserGroup,
      isLast: isLastInUserGroup,
      actionHeaderTopPadding: isFirstInUserGroup ? 0.0 : 16.0,
      child: content,
    );
  }

  IconData _getEventIcon(
      EventsType? type, EventsModel item, String actionText) {
    switch (type) {
      case EventsType.PushEvent:
        return Octicons.git_commit;
      case EventsType.PullRequestEvent:
        final actionLower = actionText.toLowerCase();
        // Icon based on action text only (not current state)
        if (actionLower.contains('merged')) {
          return Octicons.git_merge;
        } else if (actionLower.contains('closed')) {
          return Octicons.git_pull_request_closed;
        } else if (actionLower.contains('draft')) {
          return Octicons.git_pull_request_draft;
        } else {
          return Octicons.git_pull_request;
        }
      case EventsType.IssuesEvent:
        final actionLower = actionText.toLowerCase();
        // Icon based on action text only (not current state)
        if (actionLower.contains('closed')) {
          return Octicons.issue_closed;
        } else {
          return Octicons.issue_opened;
        }
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

  Color _getEventIconColor(BuildContext context, EventsType? type,
      EventsModel item, String actionText) {
    final colorScheme = context.colorScheme;
    switch (type) {
      case EventsType.PushEvent:
        return const Color(0xFF2196F3); // Blue
      case EventsType.PullRequestEvent:
        final actionLower = actionText.toLowerCase();
        // Color based on action text only (not current state)
        if (actionLower.contains('merged')) {
          return Colors.deepPurple; // Purple for merged
        } else if (actionLower.contains('closed')) {
          return Colors.red; // Red for closed
        } else if (actionLower.contains('draft')) {
          return Colors.grey; // Grey for draft
        } else {
          return Colors.green; // Green for open
        }
      case EventsType.IssuesEvent:
        final actionLower = actionText.toLowerCase();
        // Color based on action text only (not current state)
        if (actionLower.contains('closed')) {
          return Colors.red; // Red for closed
        } else {
          return Colors.green; // Green for open
        }
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

    return Container(
      margin: EdgeInsets.only(
        top: isFirst ? 0 : groupSpacing,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            navigateToProfile(
              context: context,
              login: actor.login!,
            );
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              0,
            ),
            child: Row(
              children: [
                UserAvatar(
                  avatarUrl: actor.avatarUrl,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      actor.login!,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // keep loading cards alive while scrolling

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
