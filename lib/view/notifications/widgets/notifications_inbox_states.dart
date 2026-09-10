part of '../notifications_md3_screen.dart';

class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading();

  @override
  Widget build(final BuildContext context) {
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    final double rowMinHeight = 78 + (textScale.clamp(1, 2) - 1) * 28;
    return ShimmerScope(
      key: const ValueKey<String>('notifications-loading'),
      child: LayoutBuilder(
        builder:
            (final BuildContext context, final BoxConstraints constraints) {
              final bool showActions = constraints.maxWidth >= 680;
              return Column(
                children: <Widget>[
                  for (int index = 0; index < 5; index++)
                    Container(
                      constraints: BoxConstraints(minHeight: rowMinHeight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: _stateSurfaceDecoration(context),
                      child: Row(
                        children: <Widget>[
                          const SizedBox(
                            width: 12,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ShimmerBone.avatar(size: 8),
                            ),
                          ),
                          const SizedBox(
                            width: kMinInteractiveDimension,
                            child: Center(child: ShimmerBone.icon(size: 18)),
                          ),
                          const ShimmerBone.avatar(size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                FractionallySizedBox(
                                  widthFactor: index.isEven ? 0.42 : 0.32,
                                  child: const ShimmerBone.label(),
                                ),
                                const SizedBox(height: 8),
                                const ShimmerBone.title(),
                                const SizedBox(height: 7),
                                const FractionallySizedBox(
                                  widthFactor: 0.52,
                                  child: ShimmerBone.label(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (showActions) ...<Widget>[
                            const SizedBox(
                              width: kMinInteractiveDimension,
                              child: Center(child: ShimmerBone.icon(size: 18)),
                            ),
                            const SizedBox(
                              width: kMinInteractiveDimension,
                              child: Center(child: ShimmerBone.icon(size: 18)),
                            ),
                          ] else
                            const SizedBox(
                              width: kMinInteractiveDimension,
                              child: Center(child: ShimmerBone.icon(size: 18)),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
      ),
    );
  }
}

class _NotificationsLoadingMore extends StatelessWidget {
  const _NotificationsLoadingMore();

  @override
  Widget build(final BuildContext context) {
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: context.l10n.notificationsSyncing,
      child: SizedBox(
        height: 64,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              value: reducedMotion ? 0.5 : null,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  const _NotificationsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
    decoration: _stateSurfaceDecoration(context),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.cloud_off_outlined, size: 48),
        const SizedBox(height: 16),
        Text(
          context.l10n.notificationsLoadError,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.commonRetry),
        ),
      ],
    ),
  );
}

class _NotificationsRefreshError extends StatelessWidget {
  const _NotificationsRefreshError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    builder: (final BuildContext context, final BoxConstraints constraints) {
      final bool stacked =
          constraints.maxWidth < 520 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final Widget message = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.sync_problem_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(context.l10n.notificationsRefreshError)),
        ],
      );
      return Container(
        key: const ValueKey<String>('notifications-refresh-error'),
        padding: const EdgeInsets.all(12),
        decoration: _stateSurfaceDecoration(context),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  message,
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: onRetry,
                      child: Text(context.l10n.commonRetry),
                    ),
                  ),
                ],
              )
            : Row(
                children: <Widget>[
                  Expanded(child: message),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(context.l10n.commonRetry),
                  ),
                ],
              ),
      );
    },
  );
}

class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty({required this.filters});

  final NotificationsFiltersState filters;

  @override
  Widget build(final BuildContext context) {
    final String body = filters.showOnlyReasons.isNotEmpty
        ? context.l10n.notificationsNoResults
        : filters.onlyUnread
        ? context.l10n.notificationsNoUnread
        : context.l10n.notificationsCaughtUp;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 24),
      decoration: _stateSurfaceDecoration(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.notifications_none_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.notificationsCaughtUp,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          if (body != context.l10n.notificationsCaughtUp) ...<Widget>[
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

BoxDecoration _stateSurfaceDecoration(final BuildContext context) =>
    BoxDecoration(
      border: Border(
        left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
