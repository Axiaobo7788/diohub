part of 'repository_security_md3.dart';

class _SecurityPolicyCard extends StatelessWidget {
  const _SecurityPolicyCard({
    required this.value,
    required this.waitingForRepository,
  });

  final AsyncValue<RepositoryDocumentArtifact?>? value;
  final bool waitingForRepository;

  @override
  Widget build(final BuildContext context) {
    final Widget subtitle;
    final Widget trailing;
    if (waitingForRepository || value?.isLoading == true) {
      subtitle = Text(context.l10n.repoSecurityPolicyChecking);
      trailing = const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (value?.hasError == true) {
      subtitle = Text(context.l10n.repoSecurityPolicyUnavailable);
      trailing = Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
      );
    } else {
      final RepositoryDocument? document = value?.value?.document;
      subtitle = Text(
        document == null
            ? context.l10n.repoSecurityPolicyMissing
            : context.l10n.repoSecurityPolicyFound(
                document.path ?? context.l10n.repoSecurityPolicy,
              ),
      );
      trailing = Icon(
        document == null ? Icons.policy_outlined : Icons.verified_user_outlined,
        color: document == null
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Colors.green.shade700,
      );
    }
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.policy_outlined),
        title: Text(
          context.l10n.repoSecurityPolicy,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: subtitle,
        trailing: trailing,
      ),
    );
  }
}

class _SecuritySummaryCard extends StatelessWidget {
  const _SecuritySummaryCard({
    required this.controller,
    required this.requested,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final PaginationController<dynamic, dynamic> controller;
  final bool requested;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<PaginationState<dynamic>>(
      valueListenable: controller.state,
      builder:
          (
            final BuildContext context,
            final PaginationState<dynamic> state,
            final Widget? child,
          ) {
            final Object? error = switch (state.phase) {
              Failed(:final Object error) => error,
              _ => null,
            };
            return Card.outlined(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: onTap,
                leading: Icon(icon),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  !requested
                      ? context.l10n.repoSecurityAlertsNotLoaded
                      : error == null
                      ? context.l10n.repoSecurityAlertsLoaded(
                          state.items.length,
                        )
                      : context.l10n.repoSecurityDataUnavailable,
                ),
                trailing: error == null
                    ? const Icon(Icons.chevron_right)
                    : Icon(
                        Icons.lock_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
              ),
            );
          },
    );
  }
}

class _SecurityAlertRow extends StatelessWidget {
  const _SecurityAlertRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.state,
    required this.url,
    required this.first,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String severity;
  final String? state;
  final String? url;
  final bool first;

  @override
  Widget build(final BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.only(top: first ? 0 : RepositoryMd3Layout.space8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: url == null || url!.isEmpty
            ? null
            : () => unawaited(launchUrl(Uri.parse(url!))),
        leading: Icon(icon),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Wrap(
          spacing: RepositoryMd3Layout.space4,
          children: <Widget>[
            Chip(label: Text(severity), visualDensity: VisualDensity.compact),
            if (state != null)
              Chip(label: Text(state!), visualDensity: VisualDensity.compact),
          ],
        ),
      ),
    );
  }
}
