import 'package:diohub/common/animations/animated_chevron.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/widgets/inline_control_chip.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/animations/pressable_scale.dart';
import 'package:diohub/common/charts/mini_sparkline.dart';
import 'package:diohub/utils/hex_color.dart';
import 'package:diohub/common/nav_center/models/ambient_indicator.dart';
import 'package:diohub/common/nav_center/models/tab_config.dart';
import 'package:diohub/common/nav_center/models/trailing_indicator.dart';
import 'package:diohub/common/nav_center/overlays/tab_switcher_overlay.dart';
import 'package:diohub/common/popup/popup_button.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full pill for tab switching: tab switcher zone, optional divider and
/// inline controls (from current tab's [TabConfig.inlineControls]), and
/// overflow chip. Content only; parent wraps in [GlassPill] as needed.
class ContextPill extends ConsumerWidget {
  const ContextPill({
    required this.tabs,
    required this.tabIndex,
    required this.switchTab,
    this.maxInlineControls = 3,
    super.key,
  });

  final List<TabConfig> tabs;
  final ValueNotifier<int> tabIndex;
  final void Function(int) switchTab;
  final int maxInlineControls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<int>(
      valueListenable: tabIndex,
      builder: (context, index, _) {
        if (tabs.isEmpty) return const SizedBox.shrink();
        final tab = tabs[index];
        final controls = tab.inlineControls?.call(context, ref) ?? [];
        final theme = Theme.of(context);
        final labelStyle = theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        );

        Widget tabSwitcherButton(bool isOpen) => PressableScale(
              haptic: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 16,
                      color:
                          tab.tint ?? theme.colorScheme.onSurfaceVariant,
                    ),
                    context.spacing.itemGap,
                    Text(
                      tab.label,
                      style: labelStyle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (tab.trailing != null ||
                        tab.ambientIndicator != null) ...[
                      context.spacing.compactGap,
                      CompactTabMetadata(tab: tab),
                    ],
                    context.spacing.tightGap,
                    AnimatedChevron(isOpen: isOpen),
                  ],
                ),
              ),
            );

        return Row(
          children: [
            Expanded(
              child: PopupButton(
                buttonBuilder: (context, open) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: open,
                  child: tabSwitcherButton(false),
                ),
                animatedButtonBuilder: (context, open, isOpen) =>
                    GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: open,
                  child: tabSwitcherButton(isOpen),
                ),
                popupBuilder: (context, close) => TabSwitcherOverlay(
                  tabs: tabs,
                  currentIndex: tabIndex.value,
                  onSelect: (i) {
                    switchTab(i);
                    close();
                  },
                  onDismiss: close,
                ),
              ),
            ),
            if (controls.isNotEmpty) _InlineDivider(),
            for (final pill in controls.take(maxInlineControls))
              InlineControlChip(pill: pill),
            if (controls.length > maxInlineControls)
              _OverflowChip(
                controls: controls.skip(maxInlineControls).toList(),
              ),
          ],
        );
      },
    );
  }
}

/// Thin vertical divider between tab switcher and inline controls (~30% opacity, ~16px height).
class _InlineDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 1,
        height: 16,
        color: color.withOpacity(0.3),
      ),
    );
  }
}

/// Overflow chip (⋯) that opens a popup with remaining [DockPill] controls.
class _OverflowChip extends ConsumerWidget {
  const _OverflowChip({required this.controls});
  final List<DockPill> controls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupButton(
      buttonBuilder: (_, open) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Icon(
            Icons.more_horiz,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      popupBuilder: (_, close) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final pill in controls)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InlineControlChip(pill: pill),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact trailing/ambient display for a tab. Used by [ContextPill].
/// Renders trailing and ambient side-by-side when both exist.
class CompactTabMetadata extends ConsumerWidget {
  const CompactTabMetadata({required this.tab, super.key});
  final TabConfig tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final trailing = tab.trailing;
    final ambient = tab.ambientIndicator;
    final children = <Widget>[];

    if (trailing != null) {
      children.add(_TrailingWidget(indicator: trailing));
    }
    if (trailing != null && ambient != null) {
      children.add(context.spacing.tightGap);
    }
    if (ambient != null) {
      children.add(
        switch (ambient) {
          CIStatusAmbient(:final state) => _StatusDot(state: state),
          DiffStatAmbient(:final additions, :final deletions) => Text(
              '+$additions −$deletions',
              style: captionStyle,
            ),
          ProgressAmbient(:final completed, :final total) => Text(
              '$completed/$total',
              style: captionStyle,
            ),
          BranchAmbient(:final ref) => Text(
              ref.length > 12 ? '${ref.substring(0, 12)}…' : ref,
              style: captionStyle,
            ),
          ReviewDecisionAmbient(:final decision) =>
            _ReviewDot(decision: decision),
          FilterChipAmbient(:final label) => Text(
              label,
              style: captionStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          LicenseAmbient(:final name) => Text(
              name,
              style: captionStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          TagAmbient(:final tagName, :final isPrerelease) => Text(
              isPrerelease ? '$tagName (pre)' : tagName,
              style: captionStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          LanguageBarAmbient(:final segments) =>
            _CompactLanguageBar(segments: segments, theme: theme),
          AvatarStackAmbient(:final avatarUrls) =>
            _CompactAvatarStack(avatarUrls: avatarUrls),
          SparklineAmbient(:final values) =>
            _CompactSparkline(values: values, theme: theme),
        },
      );
    }
    if (trailing == null && ambient == null) {
      children.add(
        Icon(
          tab.icon,
          size: 18,
          color: theme.colorScheme.onSurface,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _TrailingWidget extends StatelessWidget {
  const _TrailingWidget({
    required this.indicator,
    this.animateCount = true,
  });
  final TrailingIndicator indicator;
  final bool animateCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return switch (indicator) {
      CountTrailing(:final count) => _CountBadge(
          count: count(),
          style: captionStyle,
        ),
      LoadingTrailing() => SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      CompoundTrailing(:final children) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in children)
              _TrailingWidget(indicator: c, animateCount: animateCount),
          ],
        ),
      IconTrailing(:final icon) => Icon(
          icon,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
    };
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, this.style});
  final int? count;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (count == null || count! <= 0) return const SizedBox.shrink();
    return Text('${count!}', style: style);
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.state});
  final StatusState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      StatusState.SUCCESS => Colors.green,
      StatusState.FAILURE || StatusState.ERROR => Colors.red,
      StatusState.PENDING || StatusState.EXPECTED => Colors.amber,
      _ => Colors.grey,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _ReviewDot extends StatelessWidget {
  const _ReviewDot({required this.decision});
  final PullRequestReviewDecision decision;

  @override
  Widget build(BuildContext context) {
    final color = switch (decision) {
      PullRequestReviewDecision.APPROVED => Colors.green,
      PullRequestReviewDecision.CHANGES_REQUESTED => Colors.red,
      PullRequestReviewDecision.REVIEW_REQUIRED => Colors.amber,
      _ => Colors.grey,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

/// Compact language bar (segments only, no legend) for [LanguageBarAmbient].
class _CompactLanguageBar extends StatelessWidget {
  const _CompactLanguageBar({
    required this.segments,
    required this.theme,
  });
  final List<LanguageBarSegment> segments;
  final ThemeData theme;

  static Color _parseColor(String hex, ColorScheme scheme) {
    return tryParseHexColor(hex, fallback: scheme.primary) ?? scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final total = segments.fold<int>(0, (s, e) => s + e.size);
    if (total <= 0) return const SizedBox.shrink();
    final scheme = theme.colorScheme;
    const double barHeight = 6;
    const double barWidth = 28;
    final list = segments.take(5).toList();
    return SizedBox(
      width: barWidth,
      height: barHeight,
      child: Row(
        children: list.map((e) {
          final w = (e.size / total * barWidth).clamp(1.0, barWidth);
          return Container(
            width: w,
            height: barHeight,
            decoration: BoxDecoration(
              color: _parseColor(e.color, scheme),
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Compact avatar stack (2–3 circles) for [AvatarStackAmbient].
class _CompactAvatarStack extends StatelessWidget {
  const _CompactAvatarStack({required this.avatarUrls});
  final List<String> avatarUrls;

  @override
  Widget build(BuildContext context) {
    final urls = avatarUrls.take(3).toList();
    if (urls.isEmpty) return const SizedBox.shrink();
    const double size = 14;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size + (urls.length - 1) * (size * 0.6),
      height: size,
      child: Stack(
        children: List.generate(urls.length, (i) {
          return Positioned(
            left: i * (size * 0.6),
            child: UserAvatar(
              avatarUrl: urls[i],
              size: size,
            ),
          );
        }),
      ),
    );
  }
}

/// Compact sparkline for [SparklineAmbient]. Uses [MiniSparkline].
class _CompactSparkline extends StatelessWidget {
  const _CompactSparkline({
    required this.values,
    required this.theme,
  });
  final List<double> values;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    return MiniSparkline(
      values: values,
      width: 40,
      height: 16,
      color: theme.colorScheme.primary,
    );
  }
}
