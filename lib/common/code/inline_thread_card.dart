import 'package:diohub/common/diff/models.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Data for a single review thread to show inline between diff lines.
class InlineThreadData {
  const InlineThreadData({
    required this.threadId,
    required this.path,
    required this.line,
    required this.side,
    required this.firstCommentBody,
    this.authorName,
    this.resolved = false,
    this.replyCount = 0,
  });

  final String threadId;
  final String path;
  final int line;
  final DiffSide side;
  final String firstCommentBody;
  final String? authorName;
  final bool resolved;
  final int replyCount;
}

/// Inline card shown between diff lines for a review thread.
/// Collapsible; shows first comment, reply count, Reply/Resolve actions.
class InlineThreadCard extends StatelessWidget {
  const InlineThreadCard({
    required this.data,
    super.key,
    this.onReply,
    this.onResolve,
    this.onUnresolve,
    this.compact = false,
  });

  final InlineThreadData data;
  final VoidCallback? onReply;
  final VoidCallback? onResolve;
  final VoidCallback? onUnresolve;
  final bool compact;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme scheme = context.colorScheme;
    return Container(
      margin: EdgeInsets.only(
        left: context.spacing.cardContentPadding.left + 8,
        right: context.spacing.cardContentPadding.right,
        top: 4,
        bottom: 4,
      ),
      padding: context.spacing.cardContentPadding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (data.authorName != null)
                Text(
                  data.authorName!,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              if (data.resolved)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: scheme.primary,
                  ),
                ),
              const Spacer(),
              if (data.replyCount > 0)
                Text(
                  '${data.replyCount} ${data.replyCount == 1 ? 'reply' : 'replies'}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (!compact) ...<Widget>[
            context.spacing.compactGap,
            Text(
              data.firstCommentBody,
              style: context.textTheme.bodySmall,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            context.spacing.itemGap,
            Wrap(
              spacing: 8,
              children: <Widget>[
                if (onReply != null)
                  TextButton(
                    onPressed: onReply,
                    child: const Text('Reply'),
                  ),
                if (onResolve != null && !data.resolved)
                  TextButton(
                    onPressed: onResolve,
                    child: const Text('Resolve'),
                  ),
                if (onUnresolve != null && data.resolved)
                  TextButton(
                    onPressed: onUnresolve,
                    child: const Text('Unresolve'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
