part of '../notifications_md3_screen.dart';

class _NotificationGroupHeader extends StatelessWidget {
  const _NotificationGroupHeader({required this.groupKey, required this.label});

  final String groupKey;
  final String label;

  @override
  Widget build(final BuildContext context) => Container(
    key: ValueKey<String>('notifications-group-$groupKey'),
    padding: const EdgeInsets.fromLTRB(
      NotificationsMd3Layout.space16,
      NotificationsMd3Layout.space12,
      NotificationsMd3Layout.space16,
      NotificationsMd3Layout.space8,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border(
        left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _NotificationInboxRow extends StatelessWidget {
  const _NotificationInboxRow({
    required this.thread,
    required this.selected,
    required this.pending,
    required this.compact,
    required this.showRepository,
    required this.onSelected,
    required this.onOpen,
    required this.onMarkRead,
    required this.onMarkDone,
  });

  final Thread thread;
  final bool selected;
  final bool pending;
  final bool compact;
  final bool showRepository;
  final ValueChanged<bool> onSelected;
  final VoidCallback onOpen;
  final VoidCallback? onMarkRead;
  final VoidCallback onMarkDone;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Widget content = InkWell(
      onTap: pending ? null : onOpen,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 10 : 6,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 12,
              child: thread.unread
                  ? Semantics(
                      label: context.l10n.notificationsUnread,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            Checkbox(
              key: ValueKey<String>('notifications-row-checkbox-${thread.id}'),
              value: selected,
              onChanged: pending
                  ? null
                  : (final bool? value) => onSelected(value ?? false),
            ),
            ExcludeSemantics(
              child: CircleAvatar(
                key: ValueKey<String>(
                  'notifications-subject-icon-${thread.id}',
                ),
                radius: 14,
                backgroundColor: colors.surfaceContainerHighest,
                child: Icon(
                  _subjectIcon(thread.subject.type),
                  size: 17,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (showRepository) ...<Widget>[
                    Text(
                      thread.repository.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    thread.subject.title,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (compact
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.bodyLarge)
                            ?.copyWith(
                              fontWeight: thread.unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        _reasonLabel(context, thread.reason),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (thread.updatedAt case final DateTime updatedAt)
                        Text(
                          formatRelativeTime(context, updatedAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (pending)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (!compact)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (onMarkRead != null)
                    IconButton(
                      onPressed: onMarkRead,
                      tooltip: context.l10n.notificationsMarkRead,
                      icon: const Icon(Icons.mark_email_read_outlined),
                    ),
                  IconButton(
                    onPressed: onMarkDone,
                    tooltip: context.l10n.notificationsMarkDone,
                    icon: const Icon(Icons.done),
                  ),
                ],
              )
            else
              PopupMenuButton<_NotificationRowAction>(
                tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                onSelected: (final _NotificationRowAction value) {
                  switch (value) {
                    case _NotificationRowAction.read:
                      onMarkRead?.call();
                    case _NotificationRowAction.done:
                      onMarkDone();
                    case _NotificationRowAction.open:
                      onOpen();
                  }
                },
                itemBuilder: (final BuildContext context) =>
                    <PopupMenuEntry<_NotificationRowAction>>[
                      PopupMenuItem<_NotificationRowAction>(
                        value: _NotificationRowAction.open,
                        child: Text(context.l10n.notificationsOpen),
                      ),
                      if (onMarkRead != null)
                        PopupMenuItem<_NotificationRowAction>(
                          value: _NotificationRowAction.read,
                          child: Text(context.l10n.notificationsMarkRead),
                        ),
                      PopupMenuItem<_NotificationRowAction>(
                        value: _NotificationRowAction.done,
                        child: Text(context.l10n.notificationsMarkDone),
                      ),
                    ],
              ),
          ],
        ),
      ),
    );
    return Material(
      color: selected
          ? colors.secondaryContainer
          : thread.unread
          ? colors.surfaceContainerLow
          : colors.surface,
      shape: Border(
        left: BorderSide(color: colors.outlineVariant),
        right: BorderSide(color: colors.outlineVariant),
        bottom: BorderSide(color: colors.outlineVariant),
      ),
      child: content,
    );
  }
}

enum _NotificationRowAction { open, read, done }

class _NotificationsSignInState extends StatelessWidget {
  const _NotificationsSignInState();

  @override
  Widget build(final BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.notifications_none_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                context.l10n.notificationsSignInTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.notificationsSignInBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.router.push<void>(const AuthRoute()),
                child: Text(context.l10n.commonSignIn),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AutoMarkNotificationRead extends StatefulWidget {
  const _AutoMarkNotificationRead({
    required this.threadId,
    required this.onMarkRead,
    required this.child,
  });

  final String threadId;
  final VoidCallback onMarkRead;
  final Widget child;

  @override
  State<_AutoMarkNotificationRead> createState() =>
      _AutoMarkNotificationReadState();
}

class _AutoMarkNotificationReadState extends State<_AutoMarkNotificationRead> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant final _AutoMarkNotificationRead oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.threadId != widget.threadId) {
      _timer?.cancel();
      _schedule();
    }
  }

  void _schedule() {
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onMarkRead();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}

IconData _subjectIcon(final NotificationSubjectType? type) => switch (type) {
  NotificationSubjectType.issue => Icons.adjust,
  NotificationSubjectType.pullRequest => Icons.call_split,
  NotificationSubjectType.release => Icons.sell_outlined,
  NotificationSubjectType.discussion => Icons.forum_outlined,
  NotificationSubjectType.commit => Icons.commit,
  NotificationSubjectType.checkSuite => Icons.play_circle_outline,
  null => Icons.notifications_none_outlined,
};

String _reasonLabel(final BuildContext context, final String reason) =>
    switch (reason) {
      'assign' => context.l10n.notificationsAssigned,
      'participating' => context.l10n.notificationsParticipating,
      'author' => context.l10n.notificationsAuthor,
      'comment' => context.l10n.notificationsComment,
      'invitation' => context.l10n.notificationsInvitation,
      'manual' => context.l10n.notificationsFollowing,
      'mention' => context.l10n.notificationsMentioned,
      'review_requested' => context.l10n.notificationsReviewRequested,
      'security_alert' => context.l10n.notificationsSecurityAlert,
      'state_change' => context.l10n.notificationsStateChange,
      'subscribed' => context.l10n.notificationsSubscribed,
      'team_mention' => context.l10n.notificationsTeamMention,
      'ci_activity' => context.l10n.notificationsCiActivity,
      _ => reason.replaceAll('_', ' '),
    };

String _notificationDateGroupKey(final DateTime? value) {
  if (value == null) {
    return 'unknown';
  }
  final DateTime local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String _notificationDateGroupLabel(
  final BuildContext context,
  final DateTime? value,
) {
  if (value == null) {
    return context.l10n.notificationsDateUnknown;
  }
  return MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
}
