part of 'repository_actions_md3.dart';

class _WorkflowPicker extends StatelessWidget {
  const _WorkflowPicker({
    required this.workflows,
    required this.selected,
    required this.loading,
    required this.onSelected,
  });

  final List<Workflow> workflows;
  final Workflow? selected;
  final bool loading;
  final ValueChanged<Workflow?> onSelected;

  @override
  Widget build(final BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: selected?.id,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: context.l10n.repoWorkflow,
        prefixIcon: const Icon(Icons.account_tree_outlined),
        suffixIcon: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      items: <DropdownMenuItem<int?>>[
        DropdownMenuItem<int?>(
          value: null,
          child: Text(context.l10n.repoAllWorkflows),
        ),
        for (final Workflow workflow in workflows)
          DropdownMenuItem<int?>(
            value: workflow.id,
            child: Text(workflow.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (final int? id) => onSelected(
        id == null
            ? null
            : workflows.firstWhere(
                (final Workflow workflow) => workflow.id == id,
              ),
      ),
    );
  }
}

/// A single GitHub Actions run in the repository run list.
///
/// Kept public so the production row can be verified with API-shaped fixtures
/// without replacing the page's authenticated service boundary in widget tests.
class RepositoryWorkflowRunRow extends StatelessWidget {
  const RepositoryWorkflowRunRow({
    required this.run,
    required this.first,
    super.key,
  });

  final WorkflowRunItem run;
  final bool first;

  @override
  Widget build(final BuildContext context) {
    final _RunPresentation presentation = _RunPresentation.from(run);
    final String statusLabel = presentation.label(context);
    final DateTime? created = DateTime.tryParse(run.createdAt ?? '');
    final String title =
        run.displayTitle ??
        run.headCommit?.message?.split('\n').first ??
        run.name ??
        context.l10n.repoWorkflowRun;
    final String? runUrl = run.htmlUrl?.trim();
    final Uri? runUri = runUrl == null || runUrl.isEmpty
        ? null
        : Uri.tryParse(runUrl);
    final VoidCallback? onOpen = runUri == null
        ? null
        : () => unawaited(launchUrl(runUri));
    final Widget card = Card.outlined(
      key: ValueKey<String>('repository-actions-run-${run.id}'),
      margin: EdgeInsets.only(top: first ? 0 : RepositoryMd3Layout.space4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(RepositoryMd3Layout.space12),
          child: LayoutBuilder(
            builder:
                (final BuildContext context, final BoxConstraints constraints) {
                  final bool compactMetadata =
                      constraints.maxWidth < 520 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3;
                  final String? shortSha = run.headSha == null
                      ? null
                      : run.headSha!.substring(
                          0,
                          run.headSha!.length.clamp(0, 7),
                        );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Tooltip(
                        message: statusLabel,
                        excludeFromSemantics: true,
                        child: ExcludeSemantics(
                          child: Icon(
                            presentation.icon,
                            color: presentation.color(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: RepositoryMd3Layout.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: RepositoryMd3Layout.space4),
                            Wrap(
                              spacing: RepositoryMd3Layout.space8,
                              runSpacing: RepositoryMd3Layout.space4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                Text(
                                  statusLabel,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(run.name ?? context.l10n.repoWorkflow),
                                if (run.runNumber != null)
                                  Text('#${run.runNumber}'),
                                if (run.event != null) Text(run.event!),
                                if (run.triggeringActor?.login != null)
                                  Text(run.triggeringActor!.login!),
                                if (created != null)
                                  Text(
                                    formatRelativeTime(
                                      context,
                                      created.toLocal(),
                                    ),
                                  ),
                                if (compactMetadata && run.headBranch != null)
                                  Chip(
                                    avatar: const Icon(
                                      Icons.call_split,
                                      size: 16,
                                    ),
                                    label: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 168,
                                      ),
                                      child: Text(
                                        run.headBranch!,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (compactMetadata && shortSha != null)
                                  Text(
                                    shortSha,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!compactMetadata) ...<Widget>[
                        const SizedBox(width: RepositoryMd3Layout.space8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            if (run.headBranch != null)
                              Chip(
                                avatar: const Icon(Icons.call_split, size: 16),
                                label: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 168,
                                  ),
                                  child: Text(
                                    run.headBranch!,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            if (shortSha != null)
                              Text(
                                shortSha,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
          ),
        ),
      ),
    );
    if (onOpen == null) {
      return card;
    }
    final List<String> semanticParts = <String>[
      title,
      statusLabel,
      if (run.name case final String name when name.trim().isNotEmpty) name,
      if (run.runNumber case final int number) '#$number',
      if (run.event case final String event when event.trim().isNotEmpty) event,
      if (run.headBranch case final String branch when branch.trim().isNotEmpty)
        branch,
      if (created != null) formatRelativeTime(context, created.toLocal()),
    ];
    return Semantics(
      container: true,
      link: true,
      label: semanticParts.join(', '),
      onTap: onOpen,
      child: ExcludeSemantics(child: card),
    );
  }
}

class _RunPresentation {
  const _RunPresentation(this.icon, this._status);

  final IconData icon;
  final String _status;

  factory _RunPresentation.from(final WorkflowRunItem run) {
    final String state = run.conclusion ?? run.status ?? 'unknown';
    return switch (state) {
      'success' => const _RunPresentation(Icons.check_circle, 'success'),
      'failure' => const _RunPresentation(Icons.cancel, 'failure'),
      'timed_out' => const _RunPresentation(Icons.timer_off, 'timed_out'),
      'cancelled' => const _RunPresentation(Icons.block, 'cancelled'),
      'in_progress' => const _RunPresentation(Icons.sync, 'in_progress'),
      'queued' => const _RunPresentation(Icons.schedule, 'queued'),
      'waiting' => const _RunPresentation(Icons.hourglass_empty, 'waiting'),
      'pending' => const _RunPresentation(Icons.schedule, 'pending'),
      _ => const _RunPresentation(Icons.help_outline, 'unknown'),
    };
  }

  Color color(final BuildContext context) => switch (_status) {
    'success' => DiffColors.addition,
    'failure' || 'timed_out' || 'cancelled' => DiffColors.deletion,
    'in_progress' => Theme.of(context).colorScheme.primary,
    'queued' || 'waiting' || 'pending' => DiffColors.modified,
    _ => Theme.of(context).colorScheme.onSurfaceVariant,
  };

  String label(final BuildContext context) => switch (_status) {
    'success' => context.l10n.repoWorkflowStatusSuccess,
    'failure' => context.l10n.repoWorkflowStatusFailure,
    'timed_out' => context.l10n.repoWorkflowStatusTimedOut,
    'cancelled' => context.l10n.repoWorkflowStatusCancelled,
    'in_progress' => context.l10n.repoWorkflowStatusInProgress,
    'queued' => context.l10n.repoWorkflowStatusQueued,
    'waiting' => context.l10n.repoWorkflowStatusWaiting,
    'pending' => context.l10n.repoWorkflowStatusPending,
    _ => context.l10n.repoWorkflowStatusUnknown,
  };
}
