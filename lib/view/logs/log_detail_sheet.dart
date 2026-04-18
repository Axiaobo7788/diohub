import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/logging/structured_log_entry.dart';
import 'package:diohub/utils/log_issue_reporter.dart';
import 'package:diohub/view/log_report_navigation.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet showing full details of a [StructuredLogEntry].
class LogDetailSheet extends ConsumerWidget {
  const LogDetailSheet({required this.entry, super.key});

  final StructuredLogEntry entry;

  static Future<void> show(BuildContext context, StructuredLogEntry entry) {
    return AppSheet.scrollable<void>(
      context,
      header: AppSheetHeader.text('Log details'),
      bodyBuilder: (BuildContext ctx, _, ScrollController scrollController) =>
          Consumer(
        builder: (BuildContext ctx, WidgetRef ref, _) => _LogDetailBody(
            entry: entry, ref: ref, scrollController: scrollController),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clipboard = ref.read(clipboardServiceProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Log details', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _Section(
            title: 'Level',
            child: Text(entry.level),
          ),
          _Section(
            title: 'Time',
            child: Text(entry.createdAt.toIso8601String()),
          ),
          _Section(
            title: 'Message',
            child: SelectableText(entry.message),
          ),
          if (entry.entityPath != null)
            _Section(
              title: 'Entity',
              child: SelectableText(entry.entityPath!),
            ),
          if (entry.httpMethod != null) ...[
            _Section(
              title: 'Request',
              child: Text(
                '${entry.httpMethod} ${entry.httpPath ?? ''}'
                '${entry.httpStatusCode != null ? ' → ${entry.httpStatusCode}' : ''}'
                '${entry.responseTimeMs != null ? ' (${entry.responseTimeMs}ms)' : ''}',
              ),
            ),
          ],
          if (entry.errorMessage != null)
            _Section(
              title: 'Error',
              child: SelectableText(entry.errorMessage!),
            ),
          if (entry.stackTrace != null)
            _Section(
              title: 'Stack trace',
              child: SelectableText(
                entry.stackTrace!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (entry.detailJson != null)
            _Section(
              title: 'Detail',
              child: SelectableText(
                entry.detailJson!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          context.spacing.spaciousGap,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final text = StringBuffer()
                      ..writeln(entry.message)
                      ..writeln()
                      ..writeln('Level: ${entry.level}')
                      ..writeln('Time: ${entry.createdAt.toIso8601String()}');
                    if (entry.entityPath != null) {
                      text.writeln('Entity: ${entry.entityPath}');
                    }
                    if (entry.errorMessage != null) {
                      text.writeln('Error: ${entry.errorMessage}');
                    }
                    if (entry.stackTrace != null) {
                      text.writeln('Stack: ${entry.stackTrace}');
                    }
                    await clipboard.copy(text.toString());
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy'),
                ),
              ),
              context.spacing.contentGap,
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final targets =
                        LogIssueReporter.getTargetsFromStructured(entry);
                    if (targets.isEmpty) return;
                    final target = targets.first;
                    final title =
                        LogIssueReporter.buildIssueTitleFromStructured(entry);
                    final body =
                        await LogIssueReporter.buildIssueBodyFromStructured(
                            entry);
                    if (context.mounted) {
                      navigateToCreateIssueFromLog(
                          context, ref, target.repo, title, body);
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.bug_report_rounded),
                  label: const Text('Report as issue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogDetailBody extends StatelessWidget {
  const _LogDetailBody({
    required this.entry,
    required this.ref,
    required this.scrollController,
  });

  final StructuredLogEntry entry;
  final WidgetRef ref;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clipboard = ref.read(clipboardServiceProvider);
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Section(title: 'Level', child: Text(entry.level)),
          _Section(
            title: 'Time',
            child: Text(entry.createdAt.toIso8601String()),
          ),
          _Section(
            title: 'Message',
            child: SelectableText(entry.message),
          ),
          if (entry.entityPath != null)
            _Section(
              title: 'Entity',
              child: SelectableText(entry.entityPath!),
            ),
          if (entry.httpMethod != null)
            _Section(
              title: 'Request',
              child: Text(
                '${entry.httpMethod} ${entry.httpPath ?? ''}'
                '${entry.httpStatusCode != null ? ' → ${entry.httpStatusCode}' : ''}'
                '${entry.responseTimeMs != null ? ' (${entry.responseTimeMs}ms)' : ''}',
              ),
            ),
          if (entry.errorMessage != null)
            _Section(
              title: 'Error',
              child: SelectableText(entry.errorMessage!),
            ),
          if (entry.stackTrace != null)
            _Section(
              title: 'Stack trace',
              child: SelectableText(
                entry.stackTrace!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (entry.detailJson != null)
            _Section(
              title: 'Detail',
              child: SelectableText(
                entry.detailJson!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          context.spacing.spaciousGap,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final text = StringBuffer()
                      ..writeln(entry.message)
                      ..writeln()
                      ..writeln('Level: ${entry.level}')
                      ..writeln('Time: ${entry.createdAt.toIso8601String()}');
                    if (entry.entityPath != null) {
                      text.writeln('Entity: ${entry.entityPath}');
                    }
                    if (entry.errorMessage != null) {
                      text.writeln('Error: ${entry.errorMessage}');
                    }
                    if (entry.stackTrace != null) {
                      text.writeln('Stack: ${entry.stackTrace}');
                    }
                    await clipboard.copy(text.toString());
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy'),
                ),
              ),
              context.spacing.contentGap,
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final targets =
                        LogIssueReporter.getTargetsFromStructured(entry);
                    if (targets.isEmpty) return;
                    final target = targets.first;
                    final title =
                        LogIssueReporter.buildIssueTitleFromStructured(entry);
                    final body =
                        await LogIssueReporter.buildIssueBodyFromStructured(
                            entry);
                    if (context.mounted) {
                      navigateToCreateIssueFromLog(
                          context, ref, target.repo, title, body);
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.bug_report_rounded),
                  label: const Text('Report as issue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          context.spacing.tightGap,
          child,
        ],
      ),
    );
  }
}
