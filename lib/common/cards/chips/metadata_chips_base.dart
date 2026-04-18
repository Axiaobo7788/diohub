import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/cards/mini_avatar_stack.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/diff_colors.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/get_date.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// A base metadata chip used across cards
class MetadataChip extends StatelessWidget {
  const MetadataChip({
    this.leading,
    this.label,
    this.accentColor,
    this.backgroundOpacity = Opacities.tint,
    this.textStyle,
    this.showChevron = false,
    super.key,
  });

  final Widget? leading;
  final String? label;
  final Color? accentColor;
  final double backgroundOpacity;
  final TextStyle? textStyle;
  final bool showChevron;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final Color baseColor = accentColor ?? context.colorScheme.onSurfaceVariant;
    final Color mutedColor = context.colorScheme.onSurfaceVariant.muted;
    final TextStyle defaultStyle =
        Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.secondary,
                  fontWeight: FontWeight.w500,
                ) ??
            const TextStyle(fontWeight: FontWeight.w500);

    return Container(
      padding: spacing.chipPadding,
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: backgroundOpacity),
        borderRadius: context.radius(RadiusSize.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leading != null)
            IconTheme(
              data: IconThemeData(
                color: baseColor,
                size: 12,
              ),
              child: leading!,
            ),
          if (leading != null && label != null) spacing.tightGap,
          if (label != null)
            Text(
              label!,
              style: defaultStyle.merge(textStyle),
            ),
          if (showChevron && label != null) spacing.tightGap,
          if (showChevron)
            Icon(
              Icons.expand_more_rounded,
              size: 10,
              color: mutedColor,
            ),
        ],
      ),
    );
  }
}

/// Reusable chip-style pill for "show more" truncation: "+ N more" with expand icon.
/// Matches [MetadataChip] visual language; use in Wrap flows and entity card lists.
class ShowMoreChip extends StatelessWidget {
  const ShowMoreChip({
    required this.remainingCount,
    required this.onTap,
    this.entityLabel,
    super.key,
  });

  final int remainingCount;
  final VoidCallback onTap;

  /// Optional label, e.g. "repositories" → "+ 5 more repositories".
  final String? entityLabel;

  @override
  Widget build(final BuildContext context) {
    final Color accent = context.colorScheme.primary;
    final String label = entityLabel != null && entityLabel!.isNotEmpty
        ? '+ $remainingCount more $entityLabel'
        : '+ $remainingCount more';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.radius(RadiusSize.small),
        child: MetadataChip(
          label: label,
          accentColor: accent,
          showChevron: true,
        ),
      ),
    );
  }
}

/// A metadata chip that displays a key-value pair with different styling
class KeyValueMetadataChip extends StatelessWidget {
  const KeyValueMetadataChip({
    required this.filterKey,
    required this.value,
    this.leading,
    // this.accentColor,
    // this.backgroundOpacity = 0.15,
    super.key,
  });

  final String filterKey;
  final String value;
  final Widget? leading;

  @override
  Widget build(final BuildContext context) {
    final AppSpacing spacing = context.spacing;
    final Color baseColor = context.colorScheme.primaryContainer;

    return Container(
      padding: spacing.chipPadding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: context.radius(RadiusSize.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leading != null)
            IconTheme(
              data: IconThemeData(
                color: baseColor,
                size: 12,
              ),
              child: leading!,
            ),
          if (leading != null) spacing.tightGap,
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onPrimaryContainer,
                  ),
              children: <InlineSpan>[
                TextSpan(
                  text: '$filterKey ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A label that displays a timestamp in relative format
class TimestampLabel extends StatelessWidget {
  const TimestampLabel({
    required this.date,
    this.shorten = true,
    super.key,
  });

  final String date;
  final bool shorten;

  @override
  Widget build(final BuildContext context) => Text(
        DateTime.parse(date).toRelativeDate(shorten: shorten),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant.hinted,
            ),
      );
}

/// Reaction summary: top 3 emojis + total count. Uses [reactionGroups]; returns [SizedBox.shrink] if no reactions.
class ReactionSummaryChip extends StatelessWidget {
  const ReactionSummaryChip({
    required this.reactionGroups,
    this.showChevron = false,
    super.key,
  });

  final List<CardReactionGroup> reactionGroups;
  final bool showChevron;

  @override
  Widget build(final BuildContext context) {
    final List<CardReactionGroup> nonZero = reactionGroups
        .where((final CardReactionGroup g) => g.count > 0)
        .toList();
    if (nonZero.isEmpty) return const SizedBox.shrink();
    nonZero.sort(
      (final CardReactionGroup a, final CardReactionGroup b) =>
          b.count.compareTo(a.count),
    );
    final List<CardReactionGroup> top3 = nonZero.take(3).toList();
    final int total = nonZero.fold<int>(
        0, (final int s, final CardReactionGroup g) => s + g.count);
    final String emojiString =
        top3.map((final CardReactionGroup g) => g.emoji).join();
    return MetadataChip(
      leading: Text(emojiString),
      label: '$total',
      accentColor: null,
      showChevron: showChevron,
    );
  }
}

/// "Edited" indicator with relative date; optional "by @editor" when [editorLogin] is set.
class EditedIndicator extends StatelessWidget {
  const EditedIndicator({
    required this.editedAt,
    this.editorLogin,
    this.editorAvatarUrl,
    super.key,
  });

  final DateTime editedAt;
  final String? editorLogin;
  final String? editorAvatarUrl;

  @override
  Widget build(final BuildContext context) {
    final String date = editedAt.toRelativeDate(shorten: true);
    final String label = editorLogin != null && editorLogin!.isNotEmpty
        ? 'Edited $date by @${editorLogin!}'
        : 'Edited $date';
    return TintedChip(
      color: context.colorScheme.onSurfaceVariant,
      icon: Icons.edit_rounded,
      label: label,
      iconSize: 12,
    );
  }
}

/// Viewer context badges: "You authored this", "Review requested", "Your review: APPROVED".
class ViewerContextBadges extends StatelessWidget {
  const ViewerContextBadges({
    this.viewerDidAuthor = false,
    this.reviewRequested = false,
    this.reviewState,
    super.key,
  });

  final bool viewerDidAuthor;
  final bool reviewRequested;
  final String? reviewState;

  @override
  Widget build(final BuildContext context) {
    final List<Widget> chips = <Widget>[];
    if (viewerDidAuthor) {
      chips.add(
        TintedChip(
          color: context.colorScheme.primary,
          icon: Icons.person_rounded,
          label: 'You authored this',
          iconSize: 12,
        ),
      );
    }
    if (reviewRequested) {
      chips.add(
        TintedChip(
          color: context.colorScheme.tertiary,
          icon: Octicons.person_add,
          label: 'Review requested',
          iconSize: 12,
        ),
      );
    }
    if (reviewState != null && reviewState!.isNotEmpty) {
      chips.add(
        TintedChip(
          color: context.colorScheme.primary,
          icon: Octicons.check,
          label: 'Your review: $reviewState',
          iconSize: 12,
        ),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }
}

/// Subscription state chip: SUBSCRIBED (primary), UNSUBSCRIBED (muted), IGNORED (warning).

class SubscriptionChip extends StatelessWidget {
  const SubscriptionChip({
    required this.state,
    super.key,
  });

  final String state;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = context.colorScheme;
    final Color color = state == 'SUBSCRIBED'
        ? cs.primary
        : state == 'IGNORED'
            ? cs.error
            : cs.onSurfaceVariant;
    return TintedChip(
      color: color,
      icon: Icons.notifications_rounded,
      label: state == 'SUBSCRIBED'
          ? 'Watching'
          : state == 'IGNORED'
              ? 'Ignored'
              : 'Not watching',
      iconSize: 12,
    );
  }
}

/// 6px primary dot overlay for unread state on cards.

class UnreadDot extends StatelessWidget {
  const UnreadDot({super.key});

  @override
  Widget build(final BuildContext context) {
    return Positioned(
      top: 2,
      right: 2,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: context.colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Centered stub for tabs not implemented in-app: icon + "View on GitHub" + launchUrl button.
class NotAvailableTab extends StatelessWidget {
  const NotAvailableTab({
    required this.entityType,
    required this.url,
    super.key,
  });

  final String entityType;
  final Uri url;

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Padding(
        padding: context.spacing.cardContentPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.open_in_browser_rounded,
              size: 48,
              color: context.colorScheme.onSurfaceVariant.muted,
            ),
            context.spacing.itemGap,
            Text(
              '$entityType are only available on GitHub.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant.secondary,
                  ),
              textAlign: TextAlign.center,
            ),
            context.spacing.itemGap,
            FilledButton.icon(
              onPressed: () => launchUrl(url),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('View on GitHub'),
            ),
          ],
        ),
      ),
    );
  }
}
