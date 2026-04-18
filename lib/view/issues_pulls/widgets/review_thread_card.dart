import 'package:diohub/app/app_logger.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Compact card for a single PR review thread (path, line, comment count, resolved state).
class ReviewThreadCard extends StatelessWidget {
  const ReviewThreadCard({
    required this.path,
    required this.commentCount,
    super.key,
    this.line,
    this.sideLabel,
    this.isResolved = false,
    this.snippet,
    this.onTap,
    this.firstCommentAuthorLogin,
    this.firstCommentCreatedAt,
  });

  final String path;
  final int? line;
  final String? sideLabel;
  final int commentCount;
  final bool isResolved;
  final String? snippet;
  final VoidCallback? onTap;

  /// Login of the first comment author (optional).
  final String? firstCommentAuthorLogin;

  /// ISO8601 date string of the first comment (optional).
  final String? firstCommentCreatedAt;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return Material(
      color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: context.radius(RadiusSize.small),
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radius(RadiusSize.small),
        child: Padding(
          padding: spacing.cardContentPadding,
          child: Row(
            children: <Widget>[
              Icon(
                isResolved
                    ? Icons.check_circle_outline
                    : Octicons.comment_discussion,
                size: 18,
                color: isResolved
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurfaceVariant.secondary,
              ),
              spacing.tightGap,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      path,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (line != null || commentCount > 0) ...[
                      SizedBox(height: spacing.tightSpacing),
                      Row(
                        children: <Widget>[
                          if (line != null)
                            Text(
                              sideLabel != null
                                  ? 'Line $line ($sideLabel)'
                                  : 'Line $line',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context
                                    .colorScheme.onSurfaceVariant.secondary,
                              ),
                            ),
                          if (line != null && commentCount > 0)
                            Text(
                              ' · ',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context
                                    .colorScheme.onSurfaceVariant.secondary,
                              ),
                            ),
                          if (commentCount > 0)
                            Text(
                              commentCount == 1
                                  ? '1 comment'
                                  : '$commentCount comments',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context
                                    .colorScheme.onSurfaceVariant.secondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (snippet != null && snippet!.isNotEmpty) ...[
                      SizedBox(height: spacing.tightSpacing),
                      Text(
                        snippet!,
                        style: context.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (firstCommentAuthorLogin != null ||
                        firstCommentCreatedAt != null) ...[
                      SizedBox(height: spacing.tightSpacing),
                      Text(
                        _formatAuthorDate(
                          firstCommentAuthorLogin,
                          firstCommentCreatedAt,
                        ),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatAuthorDate(
    final String? login,
    final String? isoDate,
  ) {
    if (login != null && isoDate != null) {
      try {
        final DateTime dt = DateTime.parse(isoDate);
        final String relative = _relativeTime(dt);
        return '$login · $relative';
      } catch (e, st) {
        AppLogger.warning(
          'Review thread: invalid author date',
          error: e,
          stackTrace: st,
          tag: 'review_thread_card',
        );
        return login;
      }
    }
    if (login != null) return login;
    if (isoDate != null) {
      try {
        return _relativeTime(DateTime.parse(isoDate));
      } catch (e, st) {
        AppLogger.warning(
          'Review thread: invalid iso date',
          error: e,
          stackTrace: st,
          tag: 'review_thread_card',
        );
        return isoDate;
      }
    }
    return '';
  }

  static String _relativeTime(final DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }
}
