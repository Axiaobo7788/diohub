import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:diohub_models/models/repositories/code/directory_last_commit.dart';
import 'package:diohub/providers/code_browser/directory_last_commit_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/common/extensions/async_value_logging.dart';

class DirectoryEntryTile extends ConsumerWidget {
  const DirectoryEntryTile({
    required this.entry,
    required this.repoRef,
    required this.branch,
    required this.showLastCommit,
    required this.showMetadata,
    required this.onDirectoryTap,
    required this.onFileTap,
    required this.onSubmoduleTap,
    super.key,
  });

  final CodeTreeNode entry;
  final RepoRef repoRef;
  final String branch;
  final bool showLastCommit;
  final bool showMetadata;
  final ValueChanged<CodeTreeNode> onDirectoryTap;
  final ValueChanged<CodeTreeNode> onFileTap;
  final ValueChanged<CodeTreeNode> onSubmoduleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: context.spacing.screenPadding.copyWith(top: 10, bottom: 10),
          child: Row(
            children: <Widget>[
              _buildIcon(context),
              context.spacing.itemGap,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildPrimaryRow(context),
                    if (showLastCommit) _buildLastCommitRow(context, ref),
                  ],
                ),
              ),
              if (entry.kind == CodeEntryKind.directory)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    switch (entry.kind) {
      case CodeEntryKind.directory:
        onDirectoryTap(entry);
        break;
      case CodeEntryKind.file:
      case CodeEntryKind.symlink:
        onFileTap(entry);
        break;
      case CodeEntryKind.submodule:
        onSubmoduleTap(entry);
        break;
    }
  }

  Widget _buildIcon(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color) = switch (entry.kind) {
      CodeEntryKind.directory => (
          Octicons.file_directory,
          scheme.primary.withOpacity(0.8),
        ),
      CodeEntryKind.submodule => (
          Octicons.repo,
          scheme.tertiary,
        ),
      CodeEntryKind.symlink => (
          Octicons.file_symlink_file,
          scheme.onSurfaceVariant,
        ),
      CodeEntryKind.file => (
          Octicons.file,
          entry.languageColor != null
              ? tryParseHexColor(entry.languageColor!, fallback: scheme.onSurfaceVariant)!
              : scheme.onSurfaceVariant,
        ),
    };
    return Icon(icon, size: 20, color: color);
  }

  Widget _buildPrimaryRow(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final AppSpacing spacing = context.spacing;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            entry.name,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showMetadata) ...<Widget>[
          if (entry.languageName != null) ...[
            spacing.tightGap,
            Text(
              entry.languageName!,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (entry.kind == CodeEntryKind.file && entry.lineCount > 0) ...[
            spacing.tightGap,
            Text(
              '${entry.lineCount} lines',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.outline,
              ),
            ),
          ],
          if (entry.isGenerated) ...[
            spacing.tightGap,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Generated',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLastCommitRow(BuildContext context, WidgetRef ref) {
    final LastCommitKey key = (
      repo: repoRef,
      branch: branch,
      path: entry.path,
    );
    final AsyncValue<DirectoryLastCommit?> lastCommit =
        ref.watch(directoryLastCommitProvider(key));
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme scheme = theme.colorScheme;

    return lastCommit.whenOrShrink(
      debugLabel: 'directoryLastCommit',
      data: (DirectoryLastCommit? commit) {
        if (commit == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${_truncateMessage(commit.message)} · ${commit.committedDate.toRelativeDate()}',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.outline,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  static String _truncateMessage(String msg) {
    const int max = 50;
    if (msg.length <= max) return msg;
    return '${msg.substring(0, max)}…';
  }
}
