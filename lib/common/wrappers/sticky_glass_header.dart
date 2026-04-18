import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/auto_sized_sliver_persistent_header.dart';
import 'package:diohub/common/misc/floating_glass_pill.dart';
import 'package:diohub/providers/settings/layout_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:sliver_tools/sliver_tools.dart';

class StickyGlassHeader extends ConsumerWidget {
  const StickyGlassHeader({
    required this.child,
    this.style,
    this.useSticky,
    super.key,
  });

  final Widget child;

  /// Glass pill styling. Defaults to [GlassPillStyle.section] when null.
  final GlassPillStyle? style;

  /// When non-null, overrides [layoutProvider].stickyHeaders for this widget.
  final bool? useSticky;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final bool stickyHeaders =
        useSticky ?? ref.watch(layoutProvider).stickyHeaders;
    if (!stickyHeaders) {
      return SliverToBoxAdapter(child: child);
    }
    final GlassPillStyle effectiveStyle =
        style ?? GlassPillStyle.section(context);
    return SliverPinnedHeader(
      child: ScrollUnderGlass(
        style: effectiveStyle,
        child: child,
      ),
    );
  }
}

/// Resting state for non-sticky path: not pinned, no scroll.
const SliverStickyHeaderState _kRestingStickyState =
    SliverStickyHeaderState(0.0, false);

class PinnedGlassHeader extends ConsumerWidget {
  const PinnedGlassHeader({
    required this.headerBuilder,
    required this.sliver,
    this.style,
    this.useSticky,
    super.key,
  });

  final Widget Function(BuildContext context, SliverStickyHeaderState state)
      headerBuilder;
  final Widget sliver;

  /// Glass pill styling. Defaults to [GlassPillStyle.section] when null.
  final GlassPillStyle? style;

  /// When non-null, overrides [layoutProvider].stickyHeaders for this widget.
  final bool? useSticky;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final bool stickyHeaders =
        useSticky ?? ref.watch(layoutProvider).stickyHeaders;
    if (!stickyHeaders) {
      final Widget headerContent = headerBuilder(context, _kRestingStickyState);
      return MultiSliver(
        children: <Widget>[
          SliverToBoxAdapter(child: headerContent),
          sliver,
        ],
      );
    }
    final GlassPillStyle effectiveStyle =
        style ?? GlassPillStyle.section(context);
    return SliverStickyHeader.builder(
      builder:
          (final BuildContext context, final SliverStickyHeaderState state) =>
              Transform.scale(
        scale: (1.0 - state.scrollPercentage).clamp(0.0, 1.0),
        alignment: Alignment.topCenter,
        child: GlassPill(
          style: effectiveStyle,
          isFloating: state.isPinned,
          child: headerBuilder(context, state),
        ),
      ),
      sliver: sliver,
    );
  }
}

/// Reusable sliver that combines a sticky header with [GlassPill].
///
/// Use [headerBuilder] to build arbitrary header content (e.g. blend level
/// slider, directory path, icon + title). For the common icon + title row, use
/// [StickyGlassSection.withTitle].
class StickyGlassSection extends StatelessWidget {
  const StickyGlassSection({
    required this.headerBuilder,
    required this.sliver,
    this.style,
    this.useSticky,
    super.key,
  });

  /// Convenience constructor for the common "icon + title" header row.
  factory StickyGlassSection.withTitle({
    required final String title,
    required final Widget sliver,
    final IconData? icon,
    final Widget? trailing,
    final GlassPillStyle? style,
    final bool? useSticky,
    final Key? key,
  }) =>
      StickyGlassSection(
        key: key,
        style: style,
        useSticky: useSticky,
        sliver: sliver,
        headerBuilder:
            (final BuildContext context, final SliverStickyHeaderState state) {
          final ThemeData theme = Theme.of(context);
          final ColorScheme colorScheme = theme.colorScheme;
          final AppSpacing spacing = context.spacing;
          return Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                spacing.itemGap,
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...<Widget>[
                spacing.itemGap,
                trailing,
              ],
            ],
          );
        },
      );

  final Widget Function(BuildContext context, SliverStickyHeaderState state)
      headerBuilder;
  final Widget sliver;

  /// Glass pill styling. Defaults to [GlassPillStyle.section] when null.
  final GlassPillStyle? style;

  /// When non-null, overrides [layoutProvider].stickyHeaders for this widget.
  final bool? useSticky;

  @override
  Widget build(final BuildContext context) => PinnedGlassHeader(
        headerBuilder: headerBuilder,
        sliver: sliver,
        style: style,
        useSticky: useSticky,
      );
}

/// Minimum height for the info banner so single-line messages stay tappable.
const double _kInfoBannerMinHeight = 48;

/// Sticky glass info banner: icon + message + optional dismiss.
///
/// When [onDismiss] is non-null and [dismissible] is true, shows a close button.
/// On dismiss tap, the banner animates away (collapse to 0 height) then calls
/// [onDismiss]; the parent should then stop including this sliver (e.g. setState).
class StickyGlassInfoBanner extends StatefulWidget {
  const StickyGlassInfoBanner({
    required this.message,
    this.icon,
    this.style,
    this.dismissible = true,
    this.onDismiss,
    super.key,
  });

  final String message;
  final IconData? icon;
  final GlassPillStyle? style;
  final bool dismissible;
  final VoidCallback? onDismiss;

  @override
  State<StickyGlassInfoBanner> createState() => _StickyGlassInfoBannerState();
}

class _StickyGlassInfoBannerState extends State<StickyGlassInfoBanner>
    with TickerProviderStateMixin {
  late AnimationController _exitController;
  late Animation<double> _exitAnimation;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      vsync: this,
      duration: kMicroDuration,
    );
    _exitAnimation = CurvedAnimation(
      parent: _exitController,
      curve: kMicroCurve,
    );
    _exitController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    // ignore: prefer_async_await
    if (widget.onDismiss == null) return;
    // ignore: prefer_async_await
    _exitController.forward().then((final _) {
      if (mounted) widget.onDismiss?.call();
    });
  }

  Widget _buildBannerContent(
    final BuildContext context,
    final GlassPillStyle effectiveStyle,
  ) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return ScrollUnderGlass(
      style: effectiveStyle,
      child: Row(
        children: <Widget>[
          if (widget.icon != null) ...<Widget>[
            Icon(
              widget.icon,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              widget.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.dismissible && widget.onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: _handleDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final GlassPillStyle effectiveStyle =
        widget.style ?? GlassPillStyle.section(context);
    final Widget bannerContent = _buildBannerContent(context, effectiveStyle);
    return AutoSizedSliverPersistentHeader(
      pinned: true,
      minExtent: _kInfoBannerMinHeight,
      child: bannerContent,
      delegateBuilder: (final double measuredHeight) => _InfoBannerDelegate(
        contentHeight: measuredHeight >= _kInfoBannerMinHeight
            ? measuredHeight
            : _kInfoBannerMinHeight,
        animationValue: _exitAnimation.value,
        message: widget.message,
        icon: widget.icon,
        style: effectiveStyle,
        dismissible: widget.dismissible && widget.onDismiss != null,
        onDismiss: _handleDismiss,
      ),
    );
  }
}

class _InfoBannerDelegate extends SliverPersistentHeaderDelegate {
  _InfoBannerDelegate({
    required this.contentHeight,
    required this.animationValue,
    required this.message,
    required this.icon,
    required this.style,
    required this.dismissible,
    required this.onDismiss,
  });

  final double contentHeight;
  final double animationValue;
  final String message;
  final IconData? icon;
  final GlassPillStyle style;
  final bool dismissible;
  final VoidCallback onDismiss;

  double get _extent =>
      (contentHeight * (1.0 - animationValue)).clamp(0.0, contentHeight);

  @override
  double get maxExtent => _extent;

  @override
  double get minExtent => _extent;

  @override
  Widget build(
    final BuildContext context,
    final double shrinkOffset,
    final bool overlapsContent,
  ) {
    if (_extent <= 0) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Widget content = ScrollUnderGlass(
      style: style,
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (dismissible)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
    return SizedBox(
      height: _extent,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: contentHeight,
          maxHeight: contentHeight,
          child: content,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant final _InfoBannerDelegate oldDelegate) =>
      contentHeight != oldDelegate.contentHeight ||
      animationValue != oldDelegate.animationValue ||
      message != oldDelegate.message ||
      icon != oldDelegate.icon ||
      dismissible != oldDelegate.dismissible;
}
