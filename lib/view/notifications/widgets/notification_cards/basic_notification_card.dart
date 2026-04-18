import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/cards/branch_refs.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub_models/models/notifications/notification_card_data.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub/providers/notifications/notifications_service_provider.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/providers/notifications/thread_subscription_provider.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_priority_stripe.dart';
import 'package:diohub/view/notifications/widgets/notification_cards/notification_reason_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Pure renderer for notification cards.
///
/// Takes a [NotificationCardData] and renders the full card including:
/// - Subject-type-aware icon (with enrichment-driven state)
/// - Title, repo name, timestamp
/// - Reason badge
/// - Footer (comment preview, diff stats, branch info)
/// - Swipe-to-mark-as-read
///
/// This widget has zero response model imports -- it operates solely on
/// [NotificationCardData].
class BasicNotificationCard extends ConsumerStatefulWidget {
  const BasicNotificationCard({
    required this.data,
    this.onTap,
    this.onMarkDone,
    super.key,
  });

  final NotificationCardData data;
  final VoidCallback? onTap;

  /// Called after "Mark as done"; list applies PatchDeleted so the item is removed without refetch.
  final VoidCallback? onMarkDone;

  @override
  ConsumerState<BasicNotificationCard> createState() =>
      BasicNotificationCardState();
}

class BasicNotificationCardState extends ConsumerState<BasicNotificationCard> {
  bool _unread = false;

  @override
  void initState() {
    super.initState();
    _unread = widget.data.unread;
  }

  @override
  void didUpdateWidget(covariant final BasicNotificationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.id != widget.data.id) {
      _unread = widget.data.unread;
    }
  }

  Future<void> markAsRead() async {
    await ref
        .read(notificationsServiceProvider)
        .markThreadAsRead(widget.data.id);
    if (mounted) {
      setState(() {
        _unread = false;
      });
    }
    await ref.read(hapticServiceProvider).lightImpact();
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final NotificationCardData data = widget.data;
    final bool loading = data.supportsEnrichment && !data.enriched;
    final bool showPriorityStripe =
        ref.watch(cardDisplayProvider).showNotificationPriority;

    final Widget cardContent = Material(
        color: _unread
            ? colorScheme.primaryContainer.withValues(alpha: 0.25)
            : colorScheme.surface,
        child: InkWell(
          borderRadius: context.radius(RadiusSize.medium),
          onTap: () async {
            if (_unread) {
              await markAsRead();
            }
            widget.onTap?.call();
          },
          child: Container(
            decoration: _unread
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: colorScheme.primary,
                        width: 4,
                      ),
                    ),
                  )
                : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.screenPadding.left,
                context.spacing.contentPadding.top,
                context.spacing.screenPadding.right,
                context.spacing.contentPadding.bottom,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Icon column + unread dot
                  Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: _buildIcon(context, data, loading: loading),
                      ),
                      if (_unread)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  context.spacing.contentGap,
                  // Content
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Repo name + timestamp row
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                data.repoFullName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            context.spacing.itemGap,
                            Text(
                              _formatTime(data.updatedAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        context.spacing.tightGap,
                        // Title
                        Text(
                          data.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: _unread ? FontWeight.w600 : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Reason badge
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: NotificationReasonBadge(reason: data.reason),
                        ),
                        // Footer (state-dependent)
                        if (!loading && data.enriched)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildFooter(
                              data,
                              showBranchRefs:
                                  ref.watch(cardDisplayProvider).showBranchRefs,
                            ),
                          ),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: _FooterLoading(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      
    );

    return Dismissible(
      key: ValueKey('notif-${data.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (final DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          await ref
              .read(threadSubscriptionProvider(data.id).notifier)
              .toggleMute();
        } else {
          await markAsRead();
        }
        return false;
      },
      background: Container(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(
          left: context.spacing.spaciousPadding.left,
          right: context.spacing.spaciousPadding.right,
          top: 0,
          bottom: 0,
        ),
        child: Icon(
          Icons.notifications_off_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.green.withValues(alpha: 0.2),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(
          left: context.spacing.spaciousPadding.left,
          right: context.spacing.spaciousPadding.right,
          top: 0,
          bottom: 0,
        ),
        child: const Icon(Octicons.check, color: Colors.green),
      ),
      child: showPriorityStripe
          ? NotificationPriorityStripe(
              reason: data.reason,
              child: cardContent,
            )
          : cardContent,
    );
  }

  static const double _iconSize = 20;

  static Widget _buildIcon(
    final BuildContext context,
    final NotificationCardData data, {
    required final bool loading,
  }) {
    if (data.isIssue) return _buildIssueIcon(context, data, loading: loading);
    if (data.isPullRequest) {
      return _buildPrIcon(context, data, loading: loading);
    }
    // Generic subject types
    return Icon(
      _iconForSubjectType(data.subjectType),
      size: _iconSize,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static Widget _buildIssueIcon(
    final BuildContext context,
    final NotificationCardData data, {
    required final bool loading,
  }) {
    if (loading) {
      return Icon(
        Octicons.issue_opened,
        size: _iconSize,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }

    if (data.isClosed) {
      if (data.isNotPlanned) {
        return const Icon(Octicons.skip, color: Colors.grey, size: _iconSize);
      }
      return const Icon(
        Octicons.issue_closed,
        color: Colors.purple,
        size: _iconSize,
      );
    }

    return const Icon(
      Octicons.issue_opened,
      color: Colors.green,
      size: _iconSize,
    );
  }

  static Widget _buildPrIcon(
    final BuildContext context,
    final NotificationCardData data, {
    required final bool loading,
  }) {
    if (loading) {
      return Icon(
        Octicons.git_pull_request,
        size: _iconSize,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }

    final VisualState? vs = data.visualState;
    if (vs is PrVisualState) {
      return switch (vs) {
        PrVisualState.draft => const Icon(
            Octicons.git_pull_request_draft,
            color: Colors.grey,
            size: _iconSize,
          ),
        PrVisualState.merged => const Icon(
            Octicons.git_merge,
            color: Colors.deepPurpleAccent,
            size: _iconSize,
          ),
        PrVisualState.closed => const Icon(
            Octicons.git_pull_request_closed,
            color: Colors.red,
            size: _iconSize,
          ),
        PrVisualState.open => const Icon(
            Octicons.git_pull_request,
            color: Colors.green,
            size: _iconSize,
          ),
      };
    }

    return const Icon(
      Octicons.git_pull_request,
      color: Colors.green,
      size: _iconSize,
    );
  }

  static IconData _iconForSubjectType(final NotificationSubjectType? type) =>
      switch (type) {
        NotificationSubjectType.release => Octicons.tag,
        NotificationSubjectType.discussion => Octicons.comment_discussion,
        NotificationSubjectType.commit => Octicons.git_commit,
        NotificationSubjectType.checkSuite => Octicons.check_circle,
        _ => Octicons.bell,
      };

  static Widget _buildFooter(
    final NotificationCardData data, {
    final bool showBranchRefs = true,
  }) {
    if (data.isIssue) return _buildIssueFooter(data);
    if (data.isPullRequest)
      return _buildPrFooter(data, showBranchRefs: showBranchRefs);
    return const SizedBox.shrink();
  }

  static Widget _buildIssueFooter(final NotificationCardData data) {
    // Latest comment takes priority
    if (data.latestCommentBody != null) {
      return CardFooter(
        data.latestCommentAuthorAvatar,
        data.latestCommentBody,
        unread: data.unread,
      );
    }
    // Fallback: comment count
    if (data.commentCount != null) {
      final int count = data.commentCount!;
      return CardFooter(
        data.authorAvatarUrl,
        '$count comment${count == 1 ? '' : 's'}',
        unread: data.unread,
      );
    }
    return const SizedBox.shrink();
  }

  static Widget _buildPrFooter(
    final NotificationCardData data, {
    final bool showBranchRefs = true,
  }) {
    final List<String> parts = <String>[];

    // Diff stats (branch info shown via BranchRefsRow below when showBranchRefs)
    final int additions = data.additions ?? 0;
    final int deletions = data.deletions ?? 0;
    final int changed = data.changedFiles ?? 0;
    if (additions > 0 || deletions > 0) {
      parts.add(
        '+$additions -$deletions ($changed file${changed == 1 ? '' : 's'})',
      );
    }

    final bool hasBranchRefs = data.headRef != null && data.baseRef != null;
    if (showBranchRefs && hasBranchRefs && parts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BranchRefsRow(from: data.headRef, to: data.baseRef),
        ],
      );
    }
    if (showBranchRefs && hasBranchRefs) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BranchRefsRow(from: data.headRef, to: data.baseRef),
          const SizedBox(height: 6),
          CardFooter(
            data.authorAvatarUrl,
            parts.join(' \u00b7 '),
            unread: data.unread,
          ),
        ],
      );
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return CardFooter(
      data.authorAvatarUrl,
      parts.join(' \u00b7 '),
      unread: data.unread,
    );
  }

  static String _formatTime(final DateTime? updatedAt) {
    if (updatedAt == null) return '';
    try {
      return updatedAt.toRelativeDate();
    } catch (e, _) {
      AppLogger.info(
        'Failed to format notification time',
        tag: 'Notifications',
      );
      return '';
    }
  }
}

/// Footer row for notification cards showing an avatar and text.
class CardFooter extends StatelessWidget {
  const CardFooter(
    this.avatarUrl,
    this.text, {
    this.unread = false,
    super.key,
  });

  final String? avatarUrl;
  final String? text;
  final bool unread;

  @override
  Widget build(final BuildContext context) => Row(
        children: <Widget>[
          Opacity(
            opacity: unread ? 1 : 0.7,
            child: ProfileTile.avatar(
              avatarUrl: avatarUrl,
              size: 18,
              padding: EdgeInsets.zero,
            ),
          ),
          context.spacing.itemGap,
          Flexible(
            child: Text(
              text ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
}

class _FooterLoading extends StatelessWidget {
  const _FooterLoading();

  @override
  Widget build(final BuildContext context) => Row(
        children: <Widget>[
          Container(
            height: 16,
            width: 16,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
          context.spacing.itemGap,
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      );
}
