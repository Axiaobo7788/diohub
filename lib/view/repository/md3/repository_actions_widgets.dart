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

class _WorkflowRunRow extends StatelessWidget {
  const _WorkflowRunRow({required this.run, required this.first});

  final WorkflowRunItem run;
  final bool first;

  @override
  Widget build(final BuildContext context) {
    final _RunPresentation presentation = _RunPresentation.from(run);
    final DateTime? created = DateTime.tryParse(run.createdAt ?? '');
    final String title =
        run.displayTitle ??
        run.headCommit?.message?.split('\n').first ??
        run.name ??
        context.l10n.repoWorkflowRun;
    final String? url = run.htmlUrl;
    return Card.outlined(
      margin: EdgeInsets.only(top: first ? 0 : RepositoryMd3Layout.space4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: url == null || url.isEmpty
            ? null
            : () => unawaited(launchUrl(Uri.parse(url))),
        child: Padding(
          padding: const EdgeInsets.all(RepositoryMd3Layout.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(presentation.icon, color: presentation.color(context)),
              const SizedBox(width: RepositoryMd3Layout.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: RepositoryMd3Layout.space4),
                    Wrap(
                      spacing: RepositoryMd3Layout.space8,
                      runSpacing: RepositoryMd3Layout.space4,
                      children: <Widget>[
                        Text(run.name ?? context.l10n.repoWorkflow),
                        if (run.runNumber != null) Text('#${run.runNumber}'),
                        if (run.event != null) Text(run.event!),
                        if (run.triggeringActor?.login != null)
                          Text(run.triggeringActor!.login!),
                        if (created != null)
                          Text(formatRelativeTime(context, created.toLocal())),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: RepositoryMd3Layout.space8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  if (run.headBranch != null)
                    Chip(
                      avatar: const Icon(Icons.call_split, size: 16),
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 168),
                        child: Text(
                          run.headBranch!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (run.headSha != null)
                    Text(
                      run.headSha!.substring(
                        0,
                        run.headSha!.length.clamp(0, 7),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunPresentation {
  const _RunPresentation(this.icon, this._kind);

  final IconData icon;
  final String _kind;

  factory _RunPresentation.from(final WorkflowRunItem run) {
    final String state = run.conclusion ?? run.status ?? 'unknown';
    return switch (state) {
      'success' => const _RunPresentation(Icons.check_circle, 'success'),
      'failure' ||
      'timed_out' ||
      'cancelled' => const _RunPresentation(Icons.cancel, 'error'),
      'in_progress' => const _RunPresentation(Icons.sync, 'progress'),
      'queued' ||
      'waiting' ||
      'pending' => const _RunPresentation(Icons.schedule, 'pending'),
      _ => const _RunPresentation(Icons.help_outline, 'unknown'),
    };
  }

  Color color(final BuildContext context) => switch (_kind) {
    'success' => Colors.green.shade700,
    'error' => Theme.of(context).colorScheme.error,
    'progress' => Theme.of(context).colorScheme.primary,
    _ => Theme.of(context).colorScheme.onSurfaceVariant,
  };
}
