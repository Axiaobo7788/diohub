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
import 'package:diohub/common/wrappers/infinite_pagination.dart';
import 'package:diohub/common/wrappers/infinite_scroll_wrapper.dart';
import 'package:diohub/models/commits/commit_card_data_model.dart';
import 'package:diohub/models/events/events_model.dart' hide Key, State;
import 'package:diohub/models/issues/issue_card_data_model.dart';
import 'package:diohub/models/issues/issue_model.dart';
import 'package:diohub/models/pull_requests/pull_request_model.dart';
import 'package:diohub/models/repositories/repository_model.dart';
import 'package:diohub/models/users/user_info_model.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/services/activity/events_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

class Events extends StatefulWidget {
   Events({
    this.privateEvents = true,
    this.specificUser,
    super.key,
  });

  final bool privateEvents;
  final String? specificUser;

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  // Spacing constants for consistent user group separation
  Future<List<EventsModel>> _fetchEvents(
    final BuildContext context,
    final ScrollWrapperFutureArguments<EventsModel> data,
  ) async {
    if (widget.specificUser != null) {
      return EventsService.getUserEvents(
        widget.specificUser,
        page: data.pageNumber,
        perPage: data.pageSize,
        refresh: data.refresh,
      );
    } else if (widget.privateEvents) {
      return EventsService.getReceivedEvents(
        context.read<CurrentUserProvider>().data.login,
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
  }

  List<EventsModel> _filterEvents(final List<EventsModel> items) {
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
  }

  Widget _buildEventItem(
    final BuildContext context,
    final ScrollWrapperBuilderData<EventsModel> data,
  ) {
    final EventsModel item = data.item;

    // Determine if timeline should break based on user changes
    final String? currentUser = item.actor?.login;
    final String? previousUser = data.previousItem?.actor?.login;
    final String? nextUser = data.nextItem?.actor?.login;
    final bool shouldShowUserHeader = widget.specificUser == null;

    final bool isFirstInUserGroup = previousUser != currentUser || data.index == 0;
    final bool isLastInUserGroup = nextUser != currentUser || data.isCurrentlyLast;

    return Column(
      children: <Widget>[
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
  }

late final InfinitePaginationController<EventsModel> infinitePaginationController =InfinitePaginationController<EventsModel>(
        future: (final ScrollWrapperFutureArguments<EventsModel> data) => _fetchEvents(context, data),
        builder: _buildEventItem,
        filterFn: _filterEvents,
        // Calculate padding dynamically with SafeArea support
        paddingBuilder: (final BuildContext context) {
          final double bottomPadding = MediaQuery.of(context).padding.bottom;
          return EdgeInsets.only(
            // top: 8,
            bottom: 16 + bottomPadding,
          );
        },
        firstPageLoadingBuilder: (final BuildContext context) {
          // Calculate bottom padding at build time when context is available
          final double bottomPadding = MediaQuery.of(context).padding.bottom;
          return _KeepAlive(
            child: TimelineShimmerList(
              itemCount: 5,
              showAvatar: false,
              showUserHeaders: true,
              padding: EdgeInsets.only(
                top: 16,
                bottom: 16 + bottomPadding,
              ),
            ),
          );
        },
      );

  @override
  Widget build(final BuildContext context) =>
     infinitePaginationController .buildSliverList(context);

  Widget buildTimelineEvent(
    final EventsModel item,
    final ScrollWrapperBuilderData<EventsModel> data,
    final BuildContext context, {
    required final bool isFirstInUserGroup,
    required final bool isLastInUserGroup,
  }) {
    final DateTime? date = item.createdAt;
    final EventsType? eventType = item.type;

    String actionText;
    Widget content;

    switch (item.type) {
      case EventsType.PushEvent:
        actionText = 'pushed commits';
        final CommitCardDataModel commitData = CommitCardDataModel.fromPushEvent(item);
        // Extract branch name from ref (e.g., "refs/heads/main" -> "main")
        // for RepoCardLoading which shows it in the card
        final String? branchName = item.payload?.ref?.split('/').last;
        // Pass commit SHA (head) as ref - this is the latest commit SHA
        final String? commitSha = item.payload?.head;
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
        final RepositoryModel? forkee = item.payload?.forkee;
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
        final RefType? refType = item.payload?.refType;
        final String? ref = item.payload?.ref;

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
          final String refTypeName = refTypeValues.reverse![refType] ?? 'tag';
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
        final RefType? refType = item.payload?.refType;
        final String? ref = item.payload?.ref;
        final String refTypeName = refTypeValues.reverse![refType] ?? 'branch';
        final String refName = ref?.split('/').last ?? '';

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
        final UserInfoModel? member = item.payload?.member;
        final String action = item.payload?.action ?? 'added';
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
        final IssueModel? issue = item.payload?.issue;
        final String action = item.payload?.action ?? 'opened';
        actionText = '$action an issue';
        content = TimelineIssueContent(
          issueData: IssueCardDataModel.fromIssueModel(issue!),
        );

      case EventsType.IssueCommentEvent:
        final IssueModel? issue = item.payload?.issue;
        final Comment? comment = item.payload?.comment;
        actionText = 'commented on issue';
        content = TimelineIssueContent(
          issueData: IssueCardDataModel.fromIssueModel(issue!),
          commentBody: comment?.body,
          commentsSince: item.createdAt,
        );

      case EventsType.PullRequestEvent:
        final PullRequestModel? pr = item.payload?.pullRequest;
        final String action = item.payload?.action ?? 'opened';
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
        final String? fromRef = pr?.head?.ref; // Source branch
        final String? toRef = pr?.base?.ref; // Target/base branch
        // Use PR URL to fetch full data via SimplePullLoadingCard
        final String prUrl = pr?.htmlUrl ?? pr?.url ?? '';
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
      final EventsType? type, final EventsModel item, final String actionText) {
    switch (type) {
      case EventsType.PushEvent:
        return Octicons.git_commit;
      case EventsType.PullRequestEvent:
        final String actionLower = actionText.toLowerCase();
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
        final String actionLower = actionText.toLowerCase();
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

  Color _getEventIconColor(final BuildContext context, final EventsType? type,
      final EventsModel item, final String actionText) {
    final ColorScheme colorScheme = context.colorScheme;
    switch (type) {
      case EventsType.PushEvent:
        return const Color(0xFF2196F3); // Blue
      case EventsType.PullRequestEvent:
        final String actionLower = actionText.toLowerCase();
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
        final String actionLower = actionText.toLowerCase();
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
    final BuildContext context,
    final Actor? actor, {
    required final bool isFirst,
  }) {
    if (actor == null || actor.login == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(
        top: isFirst ? 0 : 8,
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
              children: <Widget>[
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
