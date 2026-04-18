import 'package:auto_route/annotations.dart';
import 'package:diohub/app/settings/diff_settings.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/code/diff_file_view.dart';
import 'package:diohub/common/diff/diff_config.dart';
import 'package:diohub/common/diff/models.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen diff for a single PR file. Fetches patch on demand via
/// [pullFilePatchProvider]. Optional [onLineTap] for review threads;
/// [highlightedLines] and [viewedState] for PR review UI.
@RoutePage()
class FileDiffScreen extends ConsumerWidget {
  const FileDiffScreen({
    required this.pullRef,
    required this.path,
    super.key,
    this.highlightedLines,
    this.viewedState,
    this.onLineTap,
  });

  final PullRequestRef pullRef;
  final String path;
  final Set<DiffLineKey>? highlightedLines;
  final bool? viewedState;
  final ValueChanged<DiffLineTapDetails>? onLineTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<DiffEntry?> patchAsync = ref.watch(
      pullFilePatchProvider((pr: pullRef, path: path)),
    );
    final DiffSettings diffSettings = ref.watch(diffSettingsProvider);
    final DiffViewConfig config = DiffViewConfig.fromSettings(diffSettings);
    final DiffDisplayMode mode = diffSettings.defaultDiffDisplayMode;
    final pullDetail = ref.watch(pullDetailProvider(pullRef)).value;
    final bool canAddComment = pullDetail != null;

    void onAddComment(DiffLineTapDetails details, DiffSide side) {
      final int line = side == DiffSide.right
          ? (details.newLineNumber ?? details.oldLineNumber ?? 1)
          : (details.oldLineNumber ?? details.newLineNumber ?? 1);
      final sheet = ref
          .read(premiumScreensProvider)
          .buildInlineCommentSheet(
            context: context,
            ref: ref,
            pullRef: pullRef,
            pullRequestId: pullDetail!.id,
            path: path,
            line: line,
            side: side,
          );
      if (sheet == null) return;
      AppSheet.form<void>(
        context,
        bodyBuilder: (BuildContext sheetContext, StateSetter setState) => sheet,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(path)),
      body: patchAsync.when(
        data: (final DiffEntry? file) {
          if (file == null) {
            return Center(
              child: Text(
                'File not found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final String? patch = file.patch;
          if (patch == null || patch.isEmpty) {
            return Center(
              child: Text(
                'No diff content (binary or empty)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (ref
                      .read(premiumAiProvider)
                      .buildAiSummaryChip(
                        context,
                        ref,
                        content: 'Explain these changes:\n\n$patch',
                        label: 'Explain changes',
                        involvesCode: true,
                      ) !=
                  null)
                Padding(
                  padding: context.spacing.pagePadding.copyWith(
                    bottom: context.spacing.itemSpacing,
                  ),
                  child: ref
                      .read(premiumAiProvider)
                      .buildAiSummaryChip(
                        context,
                        ref,
                        content: 'Explain these changes:\n\n$patch',
                        label: 'Explain changes',
                        involvesCode: true,
                      )!,
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: context.spacing.pagePadding,
                    child: DiffFileView(
                      patch: patch,
                      config: config,
                      fileType: path.split('.').last,
                      mode: mode,
                      highlightedLines: highlightedLines,
                      viewedState: viewedState,
                      onAddComment: onLineTap != null
                          ? (final details, final _) => onLineTap!(details)
                          : canAddComment
                          ? onAddComment
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const CenteredSpinner(),
        error: (final Object err, final _) => Center(
          child: Padding(
            padding: context.spacing.pagePadding,
            child: Text(
              err.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
