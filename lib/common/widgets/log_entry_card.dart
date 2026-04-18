import 'package:diohub/common/logging/structured_log_entry.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:flutter/material.dart';

/// Card for a single log entry in the log viewer list.
class LogEntryCard extends StatelessWidget {
  const LogEntryCard({
    required this.entry,
    required this.onTap,
    super.key,
  });

  final StructuredLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    return BorderedContainer(
      onTap: onTap,
      padding: spacing.cardContentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _LevelBadge(level: entry.level),
              SizedBox(width: spacing.tightSpacing * 2),
              Text(
                entry.createdAt.toRelativeDate(shorten: true),
                style: theme.textTheme.labelSmall,
              ),
              const Spacer(),
              if (entry.tag != null)
                Chip(
                  label: Text(entry.tag!),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          SizedBox(height: spacing.tightSpacing),
          Text(
            entry.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          if (entry.httpMethod != null) ...[
            SizedBox(height: spacing.tightSpacing),
            Row(
              children: [
                _HttpMethodChip(method: entry.httpMethod!),
                SizedBox(width: spacing.tightSpacing),
                Expanded(
                  child: Text(
                    entry.httpPath ?? '',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (entry.httpStatusCode != null)
                  _StatusCodeChip(code: entry.httpStatusCode!),
                if (entry.responseTimeMs != null)
                  Padding(
                    padding: EdgeInsets.only(left: spacing.tightSpacing),
                    child: Text(
                      '${entry.responseTimeMs}ms',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ],
          if (entry.entityPath != null) ...[
            SizedBox(height: spacing.tightSpacing),
            Text(
              entry.entityPath!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'error' => Theme.of(context).colorScheme.error,
      'warning' => Theme.of(context).colorScheme.errorContainer,
      _ => Theme.of(context).colorScheme.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _HttpMethodChip extends StatelessWidget {
  const _HttpMethodChip({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _StatusCodeChip extends StatelessWidget {
  const _StatusCodeChip({required this.code});

  final int code;

  @override
  Widget build(BuildContext context) {
    final isError = code >= 400;
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$code',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
