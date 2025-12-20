import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

/// Unified timeline item that works for both Events and Activity timelines
/// Supports both avatar+badge indicator (Events) and icon-only indicator (Activity)
class UnifiedTimelineItem extends StatelessWidget {
  const UnifiedTimelineItem({
    required this.child,
    required this.actionText,
    required this.date,
    // Indicator style: avatar + badge OR icon-only
    this.actorLogin, // If provided → avatar + badge indicator
    this.actorAvatarUrl, // For avatar indicator
    this.eventIcon, // Required if no actorLogin (icon-only mode)
    this.eventIconColor, // Required if no actorLogin
    // Timeline positioning
    this.isFirst = false,
    this.isLast = false,
    // Optional callbacks
    this.onAvatarTap,
    super.key,
  });

  final Widget child;
  final String actionText;
  final DateTime? date;
  final String? actorLogin;
  final String? actorAvatarUrl;
  final IconData? eventIcon;
  final Color? eventIconColor;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final hasActor = actorLogin != null;
    final indicatorSize = 30.0;
    final indicator = hasActor
        ? _buildAvatarWithBadge(context, indicatorSize)
        : _buildIconIndicator(context);

    final LineStyle lineStyle = LineStyle(
      thickness: 1,
      color: context.colorScheme.outlineVariant.withOpacity(0.5),
    );
    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      indicatorStyle: IndicatorStyle(
        width: indicatorSize,
        height: indicatorSize,
        indicatorXY: 0.5,
        drawGap: true,
        indicator: indicator,
      ),
      beforeLineStyle: lineStyle,
      afterLineStyle: lineStyle,
      endChild: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 0, hasActor ? 12 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action header (with or without username)
            Padding(
              padding: EdgeInsets.only(
                top: hasActor ? 8 : 16,
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildActionText(context, hasActor),
                  ),
                  if (date != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      hasActor
                          ? getDate(date.toString())
                          : date!.toRelativeDate(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                            fontSize: 10,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Content (always has container wrapper from content widget)
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarWithBadge(BuildContext context, double size) {
    if (eventIconColor == null || eventIcon == null) {
      throw ArgumentError(
        'eventIcon and eventIconColor are required when actorLogin is provided',
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // User avatar
        InkWell(
          onTap: onAvatarTap ??
              () {
                navigateToProfile(
                  context: context,
                  login: actorLogin!,
                );
              },
          borderRadius:
              BorderRadius.circular(size / 2), // Half of avatar size (36)
          child: UserAvatar(
            avatarUrl: actorAvatarUrl,
            size: size,
          ),
        ),
        // Event icon badge
        Positioned(
          right: -5,
          bottom: -8,
          child: Container(
            width: size * 2 / 3,
            height: size * 2 / 3,
            decoration: BoxDecoration(
              color: eventIconColor!,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colorScheme.surface,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                eventIcon!,
                size: size * 1.1 / 3,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconIndicator(BuildContext context) {
    if (eventIconColor == null || eventIcon == null) {
      throw ArgumentError(
        'eventIcon and eventIconColor are required when actorLogin is not provided',
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colorScheme.surface,
        border: Border.all(
          color: eventIconColor!.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Icon(
        eventIcon!,
        size: 12,
        color: eventIconColor!,
      ),
    );
  }

  Widget _buildActionText(BuildContext context, bool includeUsername) {
    final theme = Theme.of(context);

    if (includeUsername && actorLogin != null) {
      // Events format: "username actionText"
      return RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: actorLogin!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' $actionText'),
          ],
        ),
      );
    } else {
      // Activity format: "actionText" with optional bold name
      return _buildFormattedActionText(context, actionText);
    }
  }

  /// Build action text with proper formatting (action verb + bold name)
  Widget _buildFormattedActionText(BuildContext context, String? actionText) {
    if (actionText == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    // Format: "action verb name" (e.g., "created repository-name", "pushed")
    final words = actionText.split(' ');
    if (words.length >= 2) {
      final action = words[0];
      final name = words.sublist(1).join(' ');
      return Text.rich(
        TextSpan(
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
          children: [
            TextSpan(text: '$action '),
            TextSpan(
              text: name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // Fallback: plain text
    return Text(
      actionText,
      style: theme.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurface.withOpacity(0.6),
        fontSize: 12,
      ),
    );
  }
}
