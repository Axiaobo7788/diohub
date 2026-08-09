part of '../notifications_md3_screen.dart';

class _NotificationsAccountLoadingState extends StatelessWidget {
  const _NotificationsAccountLoadingState();

  @override
  Widget build(final BuildContext context) => const _NotificationsAccountShell(
    body: Center(
      key: ValueKey<String>('notifications-account-loading'),
      child: SizedBox.square(
        dimension: 32,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    ),
  );
}

class _NotificationsAccountErrorState extends StatelessWidget {
  const _NotificationsAccountErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) => _NotificationsAccountShell(
    body: Center(
      key: const ValueKey<String>('notifications-account-error'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                context.l10n.repoAccountStateLoadError,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey<String>('notifications-account-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Preserves the final Notifications content column while the local account
/// boundary resolves. At desktop width it reserves the same sidebar width as
/// the real inbox, so account completion does not shift the primary column.
class _NotificationsAccountShell extends StatelessWidget {
  const _NotificationsAccountShell({required this.body});

  final Widget body;

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    builder: (final BuildContext context, final BoxConstraints constraints) {
      final NotificationsWindowClass windowClass =
          NotificationsMd3Layout.windowClassFor(constraints.maxWidth);
      final Widget content = windowClass == NotificationsWindowClass.expanded
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(
                  key: ValueKey<String>(
                    'notifications-account-sidebar-placeholder',
                  ),
                  width: NotificationsMd3Layout.sidebarWidth,
                ),
                const VerticalDivider(width: 1, indent: 0, endIndent: 0),
                Expanded(child: body),
              ],
            )
          : body;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: NotificationsMd3Layout.contentMaxWidth,
          ),
          child: content,
        ),
      );
    },
  );
}
