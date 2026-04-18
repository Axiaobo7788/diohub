import 'dart:convert';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub_database/database/database.dart';
import 'package:diohub_database/database/models/entity_type_snapshot.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/utils/json_decode_safe.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:diohub/common/extensions/async_value_logging.dart';

/// Base type for entity store entries (bookmarks or history).
sealed class EntityStoreEntry {
  const EntityStoreEntry();
  
  String get nodeId;
  EntityCacheEntry get entity;
}

/// Bookmark entry with entity data.
class BookmarkEntry extends EntityStoreEntry {
  const BookmarkEntry(this.data);
  
  final BookmarkWithEntity data;
  
  @override
  String get nodeId => data.bookmark.nodeId;
  
  @override
  EntityCacheEntry get entity => data.entity;
}

/// History entry with entity data.
class HistoryEntry extends EntityStoreEntry {
  const HistoryEntry(this.data);
  
  final HistoryWithEntity data;
  
  @override
  String get nodeId => data.visit.nodeId;
  
  @override
  EntityCacheEntry get entity => data.entity;
}

// Helper functions for backwards compatibility
String _nodeId(EntityStoreEntry entry) => entry.nodeId;

EntityCacheEntry _entity(EntityStoreEntry entry) => entry.entity;

/// Renders a bookmark or history entry as a rich card.
///
/// Accepts [BookmarkWithEntity] or [HistoryWithEntity] (entity data included).
class EntityStoreCard extends ConsumerWidget {
  const EntityStoreCard({
    required this.entry,
    this.showParentBreadcrumb = true,
    this.onTap,
    this.titleOverride,
    super.key,
  });

  /// [BookmarkWithEntity] or [HistoryWithEntity].
  final EntityStoreEntry entry;
  final bool showParentBreadcrumb;

  /// When null, tap navigates via entity subject. Set for custom tap (e.g. saved search).
  final VoidCallback? onTap;

  /// When set, used as the main title instead of entity.snapshotTitle / path.
  final String? titleOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entity = _entity(entry);
    final nodeId = _nodeId(entry);

    return BorderedContainer(
      onTap: onTap ??
          () {
            try {
              EntityRef.fromJson(
                jsonDecode(entity.subjectJson) as Map<String, dynamic>,
              ).navigate(context, ref);
            } catch (e) {
              ref
                  .read(notificationServiceProvider)
                  .error('Failed to open entity: $e');
            }
          },
      child: Padding(
        padding: context.spacing.cardContentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showParentBreadcrumb && entity.parentPath != null)
              _ParentBreadcrumb(parentPath: entity.parentPath!),
            if (showParentBreadcrumb && entity.parentPath != null)
              SizedBox(height: context.spacing.itemSpacing),
            _TitleRow(
                entity: entity,
                snapshot: switch (entry) {
                  BookmarkEntry(:final data) => data.snapshot,
                  _ => null,
                },
                titleOverride: titleOverride),
            SizedBox(height: context.spacing.itemSpacing),
            _MetadataRow(
                entity: entity,
                snapshot: switch (entry) {
                  BookmarkEntry(:final data) => data.snapshot,
                  _ => null,
                }),
            _AnnotationBadges(nodeId: nodeId),
          ],
        ),
      ),
    );
  }
}

class _ParentBreadcrumb extends StatelessWidget {
  const _ParentBreadcrumb({required this.parentPath});
  final String parentPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      parentPath,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.entity, this.snapshot, this.titleOverride});
  final EntityCacheEntry entity;
  final EntityTypeSnapshot? snapshot;
  final String? titleOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = titleOverride ?? entity.snapshotTitle ?? entity.entityPath;
    final isFallback = titleOverride == null &&
        (entity.snapshotTitle == null || entity.snapshotTitle!.isEmpty);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _entityTypeIcon(entity.entityType),
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: context.spacing.itemSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isFallback)
                Text(
                  '${_entityTypeLabel(entity.entityType)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (entity.snapshotState != null)
          _StateBadge(
            state: entity.snapshotState!,
            stateReason: entity.snapshotStateReason,
          ),
      ],
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state, this.stateReason});
  final String state;
  final String? stateReason;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch ((state, stateReason)) {
      ('open', _) => (Colors.green, Octicons.issue_opened),
      ('closed', 'completed') => (Colors.purple, Octicons.issue_closed),
      ('closed', 'not_planned') => (Colors.grey, Octicons.skip),
      ('closed', _) => (Colors.red, Octicons.issue_closed),
      ('merged', _) => (Colors.purple, Octicons.git_merge),
      ('draft', _) => (Colors.grey, Octicons.git_pull_request_draft),
      ('success', _) => (Colors.green, Octicons.check),
      ('failure', _) => (Colors.red, Octicons.x),
      ('cancelled', _) => (Colors.grey, Octicons.x),
      _ => (Colors.grey, Octicons.dot),
    };
    return Icon(icon, color: color, size: 16);
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.entity, this.snapshot});
  final EntityCacheEntry entity;
  final EntityTypeSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final chips = <Widget>[];

    switch (entity.entityType) {
      case 'repo':
        if (snapshot case RepoSnapshot(stars: final s?) when s > 0)
          chips.add(_Chip(label: '$s', icon: Octicons.star));
        if (snapshot case RepoSnapshot(:final language?))
          chips.add(_Chip(label: language));
        if (entity.snapshotIsPrivate == true)
          chips.add(_Chip(label: 'Private', icon: Octicons.lock));
        if (snapshot case RepoSnapshot(isArchived: true))
          chips.add(_Chip(label: 'Archived', icon: Octicons.archive));
        if (snapshot case RepoSnapshot(isFork: true))
          chips.add(_Chip(label: 'Fork', icon: Octicons.repo_forked));
        if (entity.snapshotCommentCount != null &&
            entity.snapshotCommentCount! > 0)
          chips.add(_Chip(
            label: '${entity.snapshotCommentCount}',
            icon: Octicons.comment,
          ));
        break;
      case 'issue':
      case 'pr':
        if (entity.snapshotAuthorLogin != null)
          chips.add(_Chip(label: entity.snapshotAuthorLogin!));
        if (entity.snapshotCommentCount != null &&
            entity.snapshotCommentCount! > 0)
          chips.add(_Chip(
            label: '${entity.snapshotCommentCount}',
            icon: Octicons.comment,
          ));
        if (snapshot case PRSnapshot(:final reviewDecision?))
          chips.add(_Chip(label: reviewDecision));
        if (snapshot case PRSnapshot(isDraft: true))
          chips.add(_Chip(label: 'Draft'));
        _addLabelChips(
            switch (snapshot) {
              IssueSnapshot(:final labelsJson) => labelsJson,
              PRSnapshot(:final labelsJson) => labelsJson,
              _ => null,
            },
            chips);
        if (snapshot case IssueSnapshot(:final milestone?))
          chips.add(_Chip(label: milestone));
        if (snapshot case PRSnapshot(:final milestone?))
          chips.add(_Chip(label: milestone));
        break;
      case 'commit':
        if (entity.snapshotAuthorLogin != null)
          chips.add(_Chip(label: entity.snapshotAuthorLogin!));
        final shortSha = entity.entityPath.length > 12
            ? entity.entityPath.substring(entity.entityPath.length - 12)
            : entity.entityPath;
        chips.add(_Chip(label: shortSha));
        break;
      case 'workflowRun':
        if (entity.snapshotState != null)
          chips.add(_Chip(label: entity.snapshotState!));
        break;
      default:
        break;
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: spacing.itemSpacing,
      runSpacing: spacing.itemSpacing,
      children: chips,
    );
  }

  void _addLabelChips(String? labelsJson, List<Widget> chips) {
    if (labelsJson == null || labelsJson.isEmpty) return;
    try {
      final list = tryDecodeList(labelsJson, tag: 'EntityStoreCard._labelsChips');
      if (list == null) return;
      for (final item in list.take(3)) {
        if (item is Map<String, dynamic>) {
          final name = item['name'] as String?;
          if (name != null) {
            final colorHex = item['color'] as String?;
            chips.add(_Chip(
              label: name,
              color: colorHex != null ? tryParseHexColor(colorHex) : null,
            ));
          }
        }
      }
    } catch (e, st) {
      AppLogger.warning(
        'Failed to parse label chips from entity cache',
        error: e,
        stackTrace: st,
        tag: 'EntityStoreCard',
      );
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon, this.color});
  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.surfaceContainerHighest)
            .withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
            context.spacing.tightGap,
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AnnotationBadges extends ConsumerWidget {
  const _AnnotationBadges({required this.nodeId});
  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(entityAnnotationSummaryProvider(nodeId));
    return summaryAsync.whenOrShrink(
      debugLabel: 'entityStore',
      data: (summary) {
        if (!summary.hasAny) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.spacing.itemSpacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (summary.isBookmarked)
                  _Badge(icon: Icons.bookmark_rounded, color: Colors.amber),
                if (summary.draftCount > 0)
                  _Badge(
                    icon: Octicons.pencil,
                    color: Colors.blue,
                    count: summary.draftCount,
                  ),
                if (summary.downloadCount > 0)
                  _Badge(
                    icon: Octicons.download,
                    color: Colors.green,
                    count: summary.downloadCount,
                  ),
                if (summary.watcherCount > 0)
                  _Badge(
                    icon: Octicons.eye,
                    color: Colors.orange,
                    count: summary.watcherCount,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.color,
    this.count,
  });
  final IconData icon;
  final Color color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          if (count != null && count! > 1) ...[
            const SizedBox(width: 2),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

IconData _entityTypeIcon(String type) {
  return switch (type) {
    'repo' => Octicons.repo,
    'issue' => Octicons.issue_opened,
    'pr' => Octicons.git_pull_request,
    'commit' => Octicons.git_commit,
    'release' => Octicons.tag,
    'workflowRun' => Octicons.workflow,
    'discussion' => Octicons.comment_discussion,
    'wiki' => Octicons.book,
    'codeFile' => Octicons.file_code,
    'user' => Octicons.person,
    'topic' => Octicons.hash,
    _ => Octicons.dot,
  };
}

String _entityTypeLabel(String type) {
  return switch (type) {
    'repo' => 'Repository',
    'issue' => 'Issue',
    'pr' => 'Pull request',
    'commit' => 'Commit',
    'release' => 'Release',
    'workflowRun' => 'Workflow',
    'discussion' => 'Discussion',
    'wiki' => 'Wiki',
    'codeFile' => 'File',
    'user' => 'User',
    'topic' => 'Topic',
    _ => type,
  };
}
