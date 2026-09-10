part of '../notifications_md3_screen.dart';

class _AllUnreadControl extends StatelessWidget {
  const _AllUnreadControl({required this.onlyUnread, required this.onChanged});

  final bool onlyUnread;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey<String>('notifications-all-unread-control'),
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ScopeOption(
            label: context.l10n.notificationsAll,
            selected: !onlyUnread,
            onTap: () => onChanged(false),
          ),
          _ScopeOption(
            label: context.l10n.notificationsUnread,
            selected: onlyUnread,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 54),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? colors.surface : null,
              border: Border(
                right: BorderSide(
                  color: selected ? colors.outlineVariant : Colors.transparent,
                ),
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationQueryField extends StatefulWidget {
  const _NotificationQueryField({
    required this.value,
    required this.compact,
    required this.onChanged,
  });

  final String value;
  final bool compact;
  final ValueChanged<String> onChanged;

  @override
  State<_NotificationQueryField> createState() =>
      _NotificationQueryFieldState();
}

class _NotificationQueryFieldState extends State<_NotificationQueryField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant final _NotificationQueryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final bool expandedHitTarget = _usesExpandedHitTarget(
      context,
      compact: widget.compact,
    );
    final bool canClear = _controller.text.isNotEmpty;
    final double targetExtent = expandedHitTarget ? 48 : 40;
    return SizedBox(
      key: const ValueKey<String>('notifications-query-target'),
      height: targetExtent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Align(
            child: SizedBox(
              height: 40,
              child: TextField(
                key: const ValueKey<String>('notifications-query-field'),
                controller: _controller,
                onChanged: widget.onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.l10n.notificationsSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: canClear ? const SizedBox(width: 48) : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    maxWidth: 48,
                    maxHeight: 40,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          if (canClear)
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox.square(
                key: const ValueKey<String>('notifications-query-clear'),
                dimension: targetExtent,
                child: IconButton(
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  tooltip: context.l10n.notificationsClearSearch,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

PopupMenuItem<T> _checkedMenuItem<T>({
  required final BuildContext context,
  required final T value,
  required final bool selected,
  required final String label,
}) => PopupMenuItem<T>(
  value: value,
  child: Row(
    children: <Widget>[
      SizedBox(
        width: 24,
        child: selected ? const Icon(Icons.check, size: 18) : null,
      ),
      Expanded(child: Text(label)),
    ],
  ),
);

class _NotificationPopupControl<T> extends StatelessWidget {
  const _NotificationPopupControl({
    required this.icon,
    required this.compact,
    required this.label,
    required this.initialValue,
    required this.onSelected,
    required this.entries,
    super.key,
  });

  final IconData icon;
  final bool compact;
  final String label;
  final T initialValue;
  final ValueChanged<T> onSelected;
  final List<PopupMenuEntry<T>> entries;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool expandedHitTarget = _usesExpandedHitTarget(
      context,
      compact: compact,
    );
    final double targetExtent = expandedHitTarget ? 48 : 40;
    return PopupMenuButton<T>(
      initialValue: initialValue,
      onSelected: onSelected,
      itemBuilder: (final BuildContext context) => entries,
      tooltip: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: targetExtent,
          minHeight: targetExtent,
        ),
        child: Center(
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 18),
                if (!compact) ...<Widget>[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _NotificationsMoreAction { filters, markAllRead, refresh }

class _NotificationsNavigationButton extends StatelessWidget {
  const _NotificationsNavigationButton({
    required this.compact,
    required this.onPressed,
  });

  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(final BuildContext context) {
    final double targetExtent =
        _usesExpandedHitTarget(context, compact: compact) ? 48 : 40;
    return SizedBox.square(
      dimension: targetExtent,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: IgnorePointer(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey<String>(
              'notifications-compact-navigation-button',
            ),
            onPressed: onPressed,
            tooltip: context.l10n.homeNotifications,
            visualDensity: VisualDensity.standard,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.menu_open, size: 20),
          ),
        ],
      ),
    );
  }
}

class _NotificationsMoreMenu extends StatelessWidget {
  const _NotificationsMoreMenu({
    required this.compact,
    required this.showFilterAction,
    required this.hasReasonFilters,
    required this.busy,
    required this.refreshing,
    required this.onOpenFilters,
    required this.onMarkAllRead,
    required this.onRefresh,
  });

  final bool compact;
  final bool showFilterAction;
  final bool hasReasonFilters;
  final bool busy;
  final bool refreshing;
  final VoidCallback onOpenFilters;
  final VoidCallback onMarkAllRead;
  final Future<void> Function() onRefresh;

  @override
  Widget build(final BuildContext context) {
    final double targetExtent =
        _usesExpandedHitTarget(context, compact: compact) ? 48 : 40;
    return PopupMenuButton<_NotificationsMoreAction>(
      key: const ValueKey<String>('notifications-more-menu'),
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      enabled: !busy && !refreshing,
      onSelected: (final _NotificationsMoreAction action) {
        switch (action) {
          case _NotificationsMoreAction.filters:
            onOpenFilters();
          case _NotificationsMoreAction.markAllRead:
            onMarkAllRead();
          case _NotificationsMoreAction.refresh:
            unawaited(onRefresh());
        }
      },
      itemBuilder: (final BuildContext context) =>
          <PopupMenuEntry<_NotificationsMoreAction>>[
            if (showFilterAction)
              PopupMenuItem<_NotificationsMoreAction>(
                value: _NotificationsMoreAction.filters,
                child: Row(
                  children: <Widget>[
                    Badge(
                      isLabelVisible: hasReasonFilters,
                      child: const Icon(Icons.filter_list, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(context.l10n.notificationsFilters),
                  ],
                ),
              ),
            PopupMenuItem<_NotificationsMoreAction>(
              value: _NotificationsMoreAction.markAllRead,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.done_all_outlined, size: 18),
                  const SizedBox(width: 12),
                  Text(context.l10n.notificationsMarkAllRead),
                ],
              ),
            ),
            PopupMenuItem<_NotificationsMoreAction>(
              value: _NotificationsMoreAction.refresh,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.refresh, size: 18),
                  const SizedBox(width: 12),
                  Text(context.l10n.notificationsRefresh),
                ],
              ),
            ),
          ],
      child: SizedBox.square(
        dimension: targetExtent,
        child: Center(
          child: Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: refreshing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.more_horiz, size: 20),
          ),
        ),
      ),
    );
  }
}

bool _usesExpandedHitTarget(
  final BuildContext context, {
  required final bool compact,
}) =>
    compact ||
    switch (Theme.of(context).platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => true,
      _ => false,
    };
