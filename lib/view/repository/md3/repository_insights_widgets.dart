part of 'repository_insights_md3.dart';

class _AsyncSection<T> extends StatelessWidget {
  const _AsyncSection({
    required this.value,
    required this.title,
    required this.builder,
    this.emptyTitle,
  });

  final AsyncValue<T> value;
  final String title;
  final String? emptyTitle;
  final Widget Function(T data) builder;

  @override
  Widget build(final BuildContext context) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(RepositoryMd3Layout.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: RepositoryMd3Layout.space12),
            value.when(
              data: (final T data) {
                if (data case final Iterable<dynamic> items
                    when items.isEmpty) {
                  return Text(
                    emptyTitle ?? context.l10n.repoNoInsightData,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return builder(data);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(RepositoryMd3Layout.space24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (final Object error, final StackTrace stackTrace) =>
                  RepositoryTabStateCard(
                    icon: Icons.lock_outline,
                    title: context.l10n.repoInsightsDataUnavailable,
                    message: context.l10n.repoInsightsPermissionBody('$error'),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityBars extends StatelessWidget {
  const _ActivityBars({required this.values});

  final List<int> values;

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 120,
      child: CustomPaint(
        painter: _ActivityBarsPainter(
          values: values,
          color: Theme.of(context).colorScheme.primary,
          gridColor: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _ActivityBarsPainter extends CustomPainter {
  const _ActivityBarsPainter({
    required this.values,
    required this.color,
    required this.gridColor,
  });

  final List<int> values;
  final Color color;
  final Color gridColor;

  @override
  void paint(final Canvas canvas, final Size size) {
    final Paint grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int index = 1; index <= 3; index++) {
      final double y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      grid,
    );
    if (values.isEmpty) return;
    final int maximum = values.reduce(
      (final int a, final int b) => a > b ? a : b,
    );
    if (maximum == 0) return;
    final double slot = size.width / values.length;
    final Paint paint = Paint()..color = color;
    for (int index = 0; index < values.length; index++) {
      final double height = size.height * values[index] / maximum;
      canvas.drawRect(
        Rect.fromLTWH(
          index * slot + slot * 0.14,
          size.height - height,
          slot * 0.72,
          height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(final _ActivityBarsPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor;
}

class _LanguageBreakdown extends StatelessWidget {
  const _LanguageBreakdown({required this.entries});

  final List<RepoLanguageEntry> entries;

  @override
  Widget build(final BuildContext context) {
    final int total = entries.fold<int>(
      0,
      (final int value, final RepoLanguageEntry entry) => value + entry.size,
    );
    if (total == 0) return Text(context.l10n.repoNoInsightData);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<Color> palette = <Color>[
      colors.primary,
      colors.tertiary,
      colors.secondary,
      colors.error,
      colors.primaryContainer,
      colors.tertiaryContainer,
      colors.secondaryContainer,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(RepositoryMd3Layout.space4),
          child: SizedBox(
            height: RepositoryMd3Layout.space8,
            child: Row(
              children: <Widget>[
                for (int index = 0; index < entries.length; index++)
                  Expanded(
                    flex: entries[index].size,
                    child: ColoredBox(color: palette[index % palette.length]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: RepositoryMd3Layout.space12),
        Wrap(
          spacing: RepositoryMd3Layout.space16,
          runSpacing: RepositoryMd3Layout.space8,
          children: <Widget>[
            for (int index = 0; index < entries.length; index++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: palette[index % palette.length],
                  ),
                  const SizedBox(width: RepositoryMd3Layout.space4),
                  Text(
                    '${entries[index].name} '
                    '${(entries[index].size / total * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _TrafficNumbers extends StatelessWidget {
  const _TrafficNumbers({required this.total, required this.unique});

  final int total;
  final int unique;

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _Metric(label: context.l10n.repoTotal, value: total),
        ),
        Expanded(
          child: _Metric(label: context.l10n.repoUnique, value: unique),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(label),
      ],
    );
  }
}

class _MetricRows extends StatelessWidget {
  const _MetricRows({required this.rows});

  final List<({String label, int count, int unique})> rows;

  @override
  Widget build(final BuildContext context) {
    if (rows.isEmpty) return Text(context.l10n.repoNoInsightData);
    return Column(
      children: <Widget>[
        for (int index = 0; index < rows.length; index++) ...<Widget>[
          if (index > 0) const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(rows[index].label),
            subtitle: Text(context.l10n.repoUniqueVisitors(rows[index].unique)),
            trailing: Text('${rows[index].count}'),
          ),
        ],
      ],
    );
  }
}
