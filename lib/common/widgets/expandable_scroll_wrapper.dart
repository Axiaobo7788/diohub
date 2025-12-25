import 'package:diohub/graphql/queries/repositories/__generated__/repo_info.data.gql.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ExpandableScrollBuilder = Widget Function(
  BuildContext context,
  Widget expandOnScrollWidget,
);

typedef PullToExpandCollapsedWidgetBuilder = Widget Function(
  BuildContext context,
  double pullProgress,
  bool isReadyToExpand,
);

typedef PullToExpandExpandedWidgetBuilder = Widget Function(
  BuildContext context,
  VoidCallback onCollapse,
);

typedef PullToExpandTransitionBuilder = Widget Function(
  Widget child,
  Animation<double> animation,
);

/// Indicator widget shown when collapsed, displaying "Pull for details" with a chevron.
/// The text and chevron animate based on pull progress with rotation, scale, and opacity.
/// Shows a background pill that reveals as pull progress increases, with a visual effect
/// when ready to expand.
class PullToExpandIndicator extends StatefulWidget {
  const PullToExpandIndicator({
    required this.pullProgress,
    required this.isReadyToExpand,
    this.text = 'More Details',
    super.key,
  });

  /// Pull progress from 0.0 (not pulling) to 1.0 (at threshold).
  final double pullProgress;

  /// Whether the pull distance has reached the threshold and is ready to expand.
  final bool isReadyToExpand;

  /// Text to display. Defaults to "Pull for details".
  final String text;

  @override
  State<PullToExpandIndicator> createState() => _PullToExpandIndicatorState();
}

class _PullToExpandIndicatorState extends State<PullToExpandIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.5,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(PullToExpandIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReadyToExpand && !oldWidget.isReadyToExpand) {
      // Single jump animation when becoming ready
      _pulseController.forward(from: 0.0).then((_) {
        // After animation completes, reset to 1.0 and keep it there
        _pulseController.reset();
      });
    } else if (!widget.isReadyToExpand && oldWidget.isReadyToExpand) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Scale from 0 to 1 based on pull progress - makes content 0 size at 0 state
    final double contentScale = widget.pullProgress.clamp(0.0, 1.0);

    // Animate opacity: start at 0, increase as you pull
    final double contentOpacity = widget.pullProgress.clamp(0.0, 1.0);

    // Animate text size from 11 to 12 based on progress
    final double fontSize = 11.0 + (widget.pullProgress * 1.0);

    // Animate chevron size from 14 to 16 based on progress
    final double chevronSize = 14.0 + (widget.pullProgress * 2.0);

    // Text and icon color - use onSurface color with opacity for subtle appearance
    final double colorOpacity = 0.3 + (widget.pullProgress * 0.2); // 0.3 to 0.5

    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          // Use pulse animation value during the jump, then 1.0 when ready (after jump completes)
          final double scale = widget.isReadyToExpand
              ? (_pulseController.isAnimating ? _pulseAnimation.value : 1.0)
              : 1.0;

          return Transform.scale(
            scale: scale,
            child: SizeTransition(
              sizeFactor: AlwaysStoppedAnimation(contentScale),
              axisAlignment: 0.5,
              child: Opacity(
                opacity: contentOpacity.clamp(0.0, 1.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.text,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: fontSize,
                          color: colorScheme.onSurface
                              .withOpacity(colorOpacity.clamp(0.0, 1.0)),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 14.0, end: chevronSize),
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        builder: (context, animatedSize, child) {
                          return Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: animatedSize,
                            color: colorScheme.onSurface
                                .withOpacity(colorOpacity.clamp(0.0, 1.0)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Expanded content widget that displays metadata using DetailTile components.
/// Modern floating card design with clean layout and smooth animations.
class ExpandableMetadataContent extends StatelessWidget {
  const ExpandableMetadataContent({
    required this.children,
    required this.onCollapse,
    this.title,
    super.key,
  });

  /// List of widgets (typically DetailTile widgets) to display.
  final List<Widget> children;

  /// Callback to collapse the expanded content.
  final VoidCallback onCollapse;

  /// Title to display in the header. If null, defaults to 'Details'.
  final String? title;

  BorderRadius _getTileBorderRadius(
    SurfaceStyleTheme surfaceStyle,
    int index,
    int total,
  ) {
    if (total == 1) {
      // Single tile - round bottom corners only
      return surfaceStyle.borderRadiusLarge(
        corners: [CornerSide.bottom],
      );
    } else if (index == 0) {
      // First tile - no rounded corners (connects to header)
      return BorderRadius.zero;
    } else if (index == total - 1) {
      // Last tile - round bottom corners
      return surfaceStyle.borderRadiusLarge(
        corners: [CornerSide.bottom],
      );
    } else {
      // Middle tiles - no rounded corners
      return BorderRadius.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceStyle = theme.surfaceStyle;

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use darker colors to match app bar styling
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color backgroundColor = colorScheme.surfaceContainer;

    // Header background - match app bar color
    final Color headerBackground = colorScheme.surfaceContainer;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: surfaceStyle.borderRadiusLarge(),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(isDark ? 0.12 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section with title and collapse button
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: headerBackground,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant
                      .withOpacity(isDark ? 0.2 : 0.12),
                  width: 1,
                ),
              ),
              borderRadius: surfaceStyle.borderRadiusLarge().copyWith(
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title ?? 'Details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHigh.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                            color: colorScheme.primary.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Collapse',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Metadata content section with visual separation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: surfaceStyle.borderRadiusLarge().copyWith(
                    topLeft: Radius.zero,
                    topRight: Radius.zero,
                  ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  ClipRRect(
                    borderRadius: _getTileBorderRadius(
                      surfaceStyle,
                      i,
                      children.length,
                    ),
                    child: children[i],
                  ),
                  if (i < children.length - 1)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: colorScheme.outlineVariant
                          .withOpacity(isDark ? 0.15 : 0.1),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Represents a single stat item to display in ExpandableStatsContent.
class StatItem {
  const StatItem({
    required this.icon,
    required this.label,
    required this.count,
    this.color,
    this.formatter,
  });

  /// Icon to display for this stat
  final IconData icon;

  /// Label text to display below the count
  final String label;

  /// Count value to display
  final int count;

  /// Optional color for the icon. If null, uses theme colors.
  final Color? color;

  /// Optional custom formatter for the count. If null, uses default formatting.
  final String Function(int)? formatter;
}

/// Expanded content widget that displays statistics in a grid layout.
/// Generic and reusable for any type of stats (stars, forks, watchers, etc.).
class ExpandableStatsContent extends StatelessWidget {
  const ExpandableStatsContent({
    required this.stats,
    required this.onCollapse,
    this.title,
    this.headerColor,
    super.key,
  });

  /// List of stat items to display
  final List<StatItem> stats;

  /// Callback to collapse the expanded content.
  final VoidCallback onCollapse;

  /// Title to display in the header. If null, defaults to 'Stats'.
  final String? title;

  /// Optional color for the header accent bar. If null, uses tertiary color.
  final Color? headerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceStyle = theme.surfaceStyle;

    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color backgroundColor = colorScheme.surfaceContainer;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: surfaceStyle.borderRadiusLarge(),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(isDark ? 0.12 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant
                      .withOpacity(isDark ? 0.2 : 0.12),
                  width: 1,
                ),
              ),
              borderRadius: surfaceStyle.borderRadiusLarge().copyWith(
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: (headerColor ?? colorScheme.tertiary)
                            .withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title ?? 'Stats',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHigh.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                            color: colorScheme.primary.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Collapse',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stats grid - supports multiple rows if more than 3 items
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: surfaceStyle.borderRadiusLarge().copyWith(
                    topLeft: Radius.zero,
                    topRight: Radius.zero,
                  ),
            ),
            child: _buildStatsGrid(context, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required StatItem stat,
    required ColorScheme colorScheme,
  }) {
    final theme = Theme.of(context);
    final statColor = stat.color ??
        [
          colorScheme.tertiary,
          colorScheme.secondary,
          colorScheme.primary,
        ][stats.indexOf(stat) % 3];

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              stat.icon,
              color: statColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stat.formatter?.call(stat.count) ?? _formatCount(stat.count),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, ColorScheme colorScheme) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group stats into rows of 3
    final List<List<StatItem>> rows = [];
    for (int i = 0; i < stats.length; i += 3) {
      rows.add(stats.sublist(
        i,
        i + 3 > stats.length ? stats.length : i + 3,
      ));
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: rows.indexOf(row) < rows.length - 1 ? 16 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: row
                .map(
                  (stat) => _buildStatItem(
                    context,
                    stat: stat,
                    colorScheme: colorScheme,
                  ),
                )
                .toList()
              ..addAll(
                List.generate(
                  3 - row.length,
                  (_) => const Expanded(child: SizedBox()),
                ),
              ),
          ),
        );
      }).toList(),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Expanded content widget that displays repository information
/// (language, license, size, privacy status, etc.).
class ExpandableRepositoryInfoContent extends StatelessWidget {
  const ExpandableRepositoryInfoContent({
    required this.onCollapse,
    this.primaryLanguage,
    this.licenseInfo,
    this.diskUsage,
    this.isPrivate,
    this.isArchived,
    this.hasIssuesEnabled,
    this.hasProjectsEnabled,
    this.hasWikiEnabled,
    this.hasDiscussionsEnabled,
    this.title,
    super.key,
  });

  /// Callback to collapse the expanded content.
  final VoidCallback onCollapse;

  /// Primary programming language
  final ({String name, String? color})? primaryLanguage;

  /// License information
  final ({String name, String? spdxId})? licenseInfo;

  /// Disk usage in KB
  final int? diskUsage;

  /// Whether repository is private
  final bool? isPrivate;

  /// Whether repository is archived
  final bool? isArchived;

  /// Whether issues are enabled
  final bool? hasIssuesEnabled;

  /// Whether projects are enabled
  final bool? hasProjectsEnabled;

  /// Whether wiki is enabled
  final bool? hasWikiEnabled;

  /// Whether discussions are enabled
  final bool? hasDiscussionsEnabled;

  /// Title to display in the header. If null, defaults to 'Repository Info'.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceStyle = theme.surfaceStyle;

    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color backgroundColor = colorScheme.surfaceContainer;

    final List<Widget> infoItems = [];

    // Language
    if (primaryLanguage != null) {
      infoItems.add(_buildInfoItem(
        context,
        icon: Icons.code_rounded,
        label: 'Language',
        value: primaryLanguage!.name,
        color: primaryLanguage!.color != null
            ? Color(
                int.parse(primaryLanguage!.color!.replaceFirst('#', '0xFF')))
            : colorScheme.primary,
      ));
    }

    // License
    if (licenseInfo != null) {
      infoItems.add(_buildInfoItem(
        context,
        icon: Icons.balance_rounded,
        label: 'License',
        value: licenseInfo!.name,
        color: colorScheme.secondary,
      ));
    }

    // Size
    if (diskUsage != null) {
      infoItems.add(_buildInfoItem(
        context,
        icon: Icons.storage_rounded,
        label: 'Size',
        value: _formatSize(diskUsage!),
        color: colorScheme.tertiary,
      ));
    }

    // Privacy status
    if (isPrivate != null) {
      infoItems.add(_buildInfoItem(
        context,
        icon: isPrivate! ? Icons.lock_rounded : Icons.public_rounded,
        label: 'Visibility',
        value: isPrivate! ? 'Private' : 'Public',
        color: isPrivate! ? colorScheme.error : colorScheme.primary,
      ));
    }

    // Archived status
    if (isArchived == true) {
      infoItems.add(_buildInfoItem(
        context,
        icon: Icons.archive_rounded,
        label: 'Status',
        value: 'Archived',
        color: colorScheme.onSurfaceVariant,
      ));
    }

    // Features
    final List<String> enabledFeatures = [];
    if (hasIssuesEnabled == true) enabledFeatures.add('Issues');
    if (hasProjectsEnabled == true) enabledFeatures.add('Projects');
    if (hasWikiEnabled == true) enabledFeatures.add('Wiki');
    if (hasDiscussionsEnabled == true) enabledFeatures.add('Discussions');

    if (enabledFeatures.isNotEmpty) {
      infoItems.add(_buildInfoItem(
        context,
        icon: Icons.settings_rounded,
        label: 'Features',
        value: enabledFeatures.join(', '),
        color: colorScheme.primary,
      ));
    }

    if (infoItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: surfaceStyle.borderRadiusLarge(),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(isDark ? 0.12 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant
                      .withOpacity(isDark ? 0.2 : 0.12),
                  width: 1,
                ),
              ),
              borderRadius: surfaceStyle.borderRadiusLarge().copyWith(
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title ?? 'Repository Info',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHigh.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                            color: colorScheme.primary.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Collapse',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info items
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: surfaceStyle.borderRadiusLarge().copyWith(
                    topLeft: Radius.zero,
                    topRight: Radius.zero,
                  ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: infoItems,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSize(int kb) {
    if (kb >= 1024 * 1024) {
      return '${(kb / (1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (kb >= 1024) {
      return '${(kb / 1024).toStringAsFixed(1)} MB';
    }
    return '$kb KB';
  }
}

/// Expanded content widget that displays interactive action buttons.
/// Generic and reusable for any type of actions (close/reopen, pin, lock, etc.).
class ExpandableActionsContent extends StatelessWidget {
  const ExpandableActionsContent({
    required this.actions,
    required this.onCollapse,
    this.title,
    this.headerColor,
    this.actionSpacing = 8.0,
    this.actionRunSpacing = 8.0,
    super.key,
  });

  /// List of action widgets (typically buttons)
  final List<Widget> actions;

  /// Callback to collapse the expanded content.
  final VoidCallback onCollapse;

  /// Title to display in the header. If null, defaults to 'Actions'.
  final String? title;

  /// Optional color for the header accent bar. If null, uses error color.
  final Color? headerColor;

  /// Spacing between action widgets horizontally. Defaults to 8.0.
  final double actionSpacing;

  /// Spacing between action widgets vertically. Defaults to 8.0.
  final double actionRunSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceStyle = theme.surfaceStyle;

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color backgroundColor = colorScheme.surfaceContainer;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: surfaceStyle.borderRadiusLarge(),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(isDark ? 0.12 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant
                      .withOpacity(isDark ? 0.2 : 0.12),
                  width: 1,
                ),
              ),
              borderRadius: surfaceStyle.borderRadiusLarge().copyWith(
                    bottomLeft: Radius.zero,
                    bottomRight: Radius.zero,
                  ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color:
                            (headerColor ?? colorScheme.error).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title ?? 'Actions',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHigh.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                            color: colorScheme.primary.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Collapse',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Actions content
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: surfaceStyle.borderRadiusLarge().copyWith(
                    topLeft: Radius.zero,
                    topRight: Radius.zero,
                  ),
            ),
            child: Wrap(
              spacing: actionSpacing,
              runSpacing: actionRunSpacing,
              alignment: WrapAlignment.start,
              children: actions,
            ),
          ),
        ],
      ),
    );
  }
}

/// A wrapper widget that uses NotificationListener to detect pull-to-expand gestures.
///
/// This wrapper wraps any scrollable widget and detects overscroll via ScrollNotifications,
/// making it compatible with RefreshIndicator and other scroll-based widgets.
///
/// The [builder] callback receives the expandable widget that should be placed in your
/// scrollable structure.
///
/// Example:
/// ```dart
/// ExpandOnScrollWrapper(
///   collapsedWidget: (context, progress, isReadyToExpand) => PullToExpandIndicator(
///     pullProgress: progress,
///     isReadyToExpand: isReadyToExpand,
///   ),
///   expandedWidget: (context, onCollapse) => ExpandedContentWidget(
///     onCollapse: onCollapse,
///   ),
///   builder: (context, expandOnScrollWidget) => CustomScrollView(
///     slivers: [
///       SliverToBoxAdapter(child: expandOnScrollWidget),
///       SliverList(...),
///     ],
///   ),
/// )
/// ```
class ExpandOnScrollWrapper extends StatefulWidget {
  const ExpandOnScrollWrapper({
    required this.expandedWidget,
    required this.builder,
    this.collapsedWidget,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.fastOutSlowIn,
    this.expandThreshold = 100.0,
    this.transitionBuilder,
    super.key,
  });

  /// Builder that receives pull progress (0.0 to 1.0) and isReadyToExpand flag
  /// for animating collapsed widget.
  /// progress = 0.0 when not pulling, 1.0 when at expandThreshold.
  /// isReadyToExpand = true when pull distance has reached expandThreshold.
  /// If null, nothing is shown when collapsed.
  final PullToExpandCollapsedWidgetBuilder? collapsedWidget;

  /// Builder that receives a collapse callback to programmatically collapse the widget.
  final PullToExpandExpandedWidgetBuilder expandedWidget;

  /// Duration of the expand/collapse animation.
  final Duration duration;

  /// Curve for the expand/collapse animation.
  final Curve curve;

  /// Pull distance threshold (in pixels) required to trigger expansion.
  /// Defaults to 100.0 pixels.
  final double expandThreshold;

  /// Custom transition builder for the expand/collapse animation.
  /// If null, defaults to SizeTransition.
  /// The animation parameter goes from 0.0 (collapsed) to 1.0 (expanded).
  final PullToExpandTransitionBuilder? transitionBuilder;

  /// Builder that receives the expandOnScrollWidget to place in your scrollable structure.
  ///
  /// The expandable widget should be placed as the first item in your scrollable
  /// (e.g., first sliver in CustomScrollView, first item in ListView).
  final ExpandableScrollBuilder builder;

  @override
  State<ExpandOnScrollWrapper> createState() => _ExpandOnScrollWrapperState();
}

class _ExpandOnScrollWrapperState extends State<ExpandOnScrollWrapper> {
  double _pullProgress = 0.0;
  bool _isExpanded = false;
  bool _isReadyToExpand = false;

  void _resetPullState() {
    setState(() {
      _pullProgress = 0.0;
      _isReadyToExpand = false;
    });
  }

  void _updatePullProgress(final double pullDistance) {
    final double progress =
        (pullDistance / widget.expandThreshold).clamp(0.0, 1.0);
    final bool isReady = pullDistance >= widget.expandThreshold;

    if (_pullProgress != progress || _isReadyToExpand != isReady) {
      final bool wasReady = _isReadyToExpand;
      setState(() {
        _pullProgress = progress;
        _isReadyToExpand = isReady;
      });
      // Trigger haptic feedback when becoming ready
      if (!wasReady && isReady) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  bool _handleScrollNotification(final ScrollNotification notification) {
    // Handle overscroll (pull down) - this is the key!
    if (notification is OverscrollNotification) {
      final ScrollMetrics metrics = notification.metrics;

      // Only handle vertical overscroll
      if (metrics.axis != Axis.vertical) {
        return false;
      }

      // Overscroll.overscroll is negative when pulling down
      final double overscroll = notification.overscroll;

      if (overscroll < 0) {
        final double pullDistance = overscroll.abs();
        _updatePullProgress(pullDistance);
      }
      return false; // Don't consume, let RefreshIndicator work
    }

    // Handle scroll updates to detect pull and reset
    if (notification is ScrollUpdateNotification) {
      final ScrollMetrics metrics = notification.metrics;

      // Check if we're at the top and pulling down (pixels < 0)
      if (metrics.pixels < 0) {
        final double pullDistance = metrics.pixels.abs();
        _updatePullProgress(pullDistance);
      } else if (metrics.pixels >= 0 && _pullProgress > 0 && !_isExpanded) {
        // Only reset pull progress if NOT expanded
        // If expanded, keep it expanded (only collapse via onCollapse callback)
        _resetPullState();
      }
      return false;
    }

    // Handle scroll metrics to reset state when scrolled back to top
    if (notification is ScrollMetricsNotification) {
      // Only reset pull progress if NOT expanded
      // If expanded, keep it expanded (only collapse via onCollapse callback)
      if (notification.metrics.pixels >= 0 &&
          _pullProgress > 0 &&
          !_isExpanded) {
        _resetPullState();
      }
      return false;
    }

    // Handle scroll start
    if (notification is ScrollStartNotification) {
      return false;
    }

    // Handle scroll end - expand only when user releases at threshold
    if (notification is ScrollEndNotification) {
      // Only expand if threshold was reached and user releases
      if (_isReadyToExpand && !_isExpanded) {
        setState(() {
          _isExpanded = true;
        });
      } else if (!_isReadyToExpand && _pullProgress > 0 && !_isExpanded) {
        // Reset if user released before reaching threshold
        _resetPullState();
      }
      return false;
    }

    return false;
  }

  void _collapse() {
    setState(() {
      _isExpanded = false;
    });
    _resetPullState();
  }

  @override
  Widget build(final BuildContext context) {
    // Create the expandable widget with current state
    final _ExpandOnScrollContent expandOnScrollWidget = _ExpandOnScrollContent(
      pullProgress: _pullProgress.clamp(0.0, 1.0),
      isReadyToExpand: _isReadyToExpand,
      isExpanded: _isExpanded,
      onCollapse: _collapse,
      collapsedWidget: widget.collapsedWidget,
      expandedWidget: widget.expandedWidget,
      duration: widget.duration,
      curve: widget.curve,
      transitionBuilder: widget.transitionBuilder,
    );

    // Wrap with NotificationListener and pass widget to builder
    // The NotificationListener must wrap the scrollable to catch notifications
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: widget.builder(context, expandOnScrollWidget),
    );
  }
}

class _ExpandOnScrollContent extends StatelessWidget {
  const _ExpandOnScrollContent({
    required this.pullProgress,
    required this.isReadyToExpand,
    required this.isExpanded,
    required this.onCollapse,
    this.collapsedWidget,
    required this.expandedWidget,
    required this.duration,
    required this.curve,
    this.transitionBuilder,
  });

  final double pullProgress;
  final bool isReadyToExpand;
  final bool isExpanded;
  final VoidCallback onCollapse;
  final Widget Function(
          BuildContext context, double pullProgress, bool isReadyToExpand)?
      collapsedWidget;
  final Widget Function(BuildContext context, VoidCallback onCollapse)
      expandedWidget;
  final Duration duration;
  final Curve curve;
  final Widget Function(Widget child, Animation<double> animation)?
      transitionBuilder;

  @override
  Widget build(final BuildContext context) {
    // If no collapsed widget, show expanded widget directly or nothing
    if (collapsedWidget == null) {
      return isExpanded
          ? expandedWidget(context, onCollapse)
          : const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: transitionBuilder ??
          (final Widget child, final Animation<double> animation) =>
              SizeTransition(
                sizeFactor: animation,
                axisAlignment: 1,
                child: child,
              ),
      child: isExpanded
          ? KeyedSubtree(
              key: const ValueKey('expanded'),
              child: expandedWidget(context, onCollapse),
            )
          : KeyedSubtree(
              key: const ValueKey('collapsed'),
              child: collapsedWidget!(context, pullProgress, isReadyToExpand),
            ),
    );
  }
}

/// Generic, compact expandable section widget for displaying categorized content.
/// Designed to be sleek and handle multiple sections stacked together without clutter.
///
/// Features:
/// - Modern header with title, accent bar, and collapse button
/// - Proper padding and margins matching app design
/// - Subtle dividers between sections
/// - Collapsible with smooth animations
/// - Supports any content type (DetailTiles, custom widgets, etc.)
class ExpandableSection extends StatelessWidget {
  const ExpandableSection({
    required this.title,
    required this.children,
    required this.onCollapse,
    this.headerColor,
    super.key,
  });

  /// Title to display in the header
  final String title;

  /// List of widgets to display in the content area
  final List<Widget> children;

  /// Callback to collapse the expanded content
  final VoidCallback onCollapse;

  /// Optional color for the header accent bar. If null, uses primary color.
  final Color? headerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceStyle = theme.surfaceStyle;

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color backgroundColor = colorScheme.surfaceContainer;
    final Color accentColor = headerColor ?? colorScheme.primary;

    // Use app's border radius system - large radius (18px default)
    final BorderRadius borderRadius = surfaceStyle.borderRadiusLarge();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(isDark ? 0.12 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section with title, accent bar, and collapse button
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant
                      .withOpacity(isDark ? 0.2 : 0.12),
                  width: 1,
                ),
              ),
              borderRadius: borderRadius.copyWith(
                bottomLeft: Radius.zero,
                bottomRight: Radius.zero,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHigh.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                            color: colorScheme.primary.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Collapse',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content section with proper padding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius.copyWith(
                topLeft: Radius.zero,
                topRight: Radius.zero,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  ClipRRect(
                    borderRadius: _getTileBorderRadius(
                      surfaceStyle,
                      i,
                      children.length,
                    ),
                    child: children[i],
                  ),
                  if (i < children.length - 1)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: colorScheme.outlineVariant
                          .withOpacity(isDark ? 0.15 : 0.1),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  BorderRadius _getTileBorderRadius(
    SurfaceStyleTheme surfaceStyle,
    int index,
    int total,
  ) {
    if (total == 1) {
      // Single tile - round bottom corners
      return surfaceStyle.borderRadiusLarge(corners: [CornerSide.bottom]);
    } else if (index == 0) {
      // First tile - no rounded corners (connects to header)
      return BorderRadius.zero;
    } else if (index == total - 1) {
      // Last tile - round bottom corners
      return surfaceStyle.borderRadiusLarge(corners: [CornerSide.bottom]);
    } else {
      // Middle tiles - no rounded corners
      return BorderRadius.zero;
    }
  }
}

/// Primary prominence expandable section - for most important content
/// Features: Larger shadows, more padding, bolder header, larger accent bar
class ExpandableSectionPrimary extends ExpandableSection {
  const ExpandableSectionPrimary({
    required super.title,
    required super.children,
    required super.onCollapse,
    super.headerColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceStyle = theme.surfaceStyle;

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color backgroundColor = colorScheme.surfaceContainer;
    final Color accentColor = headerColor ?? colorScheme.primary;

    final BorderRadius borderRadius = surfaceStyle.borderRadiusLarge();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(isDark ? 0.12 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant
                      .withOpacity(isDark ? 0.2 : 0.12),
                  width: 1,
                ),
              ),
              borderRadius: borderRadius.copyWith(
                bottomLeft: Radius.zero,
                bottomRight: Radius.zero,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 24,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHigh.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 20,
                            color: colorScheme.primary.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Collapse',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius.copyWith(
                topLeft: Radius.zero,
                topRight: Radius.zero,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  ClipRRect(
                    borderRadius: _getTileBorderRadius(
                      surfaceStyle,
                      i,
                      children.length,
                    ),
                    child: children[i],
                  ),
                  if (i < children.length - 1)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: colorScheme.outlineVariant
                          .withOpacity(isDark ? 0.15 : 0.1),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tertiary prominence expandable section - for less important content
/// Features: Subtle shadows, compact padding, smaller header
class ExpandableSectionTertiary extends ExpandableSection {
  const ExpandableSectionTertiary({
    required super.title,
    required super.children,
    required super.onCollapse,
    super.headerColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceStyle = theme.surfaceStyle;

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isDark = colorScheme.brightness == Brightness.dark;
    final Color backgroundColor = colorScheme.surfaceContainer;
    final Color accentColor = headerColor ?? colorScheme.primary;

    final BorderRadius borderRadius = surfaceStyle.borderRadiusLarge();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(isDark ? 0.1 : 0.06),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant
                      .withOpacity(isDark ? 0.15 : 0.1),
                  width: 0.5,
                ),
              ),
              borderRadius: borderRadius.copyWith(
                bottomLeft: Radius.zero,
                bottomRight: Radius.zero,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHigh.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.25),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 16,
                            color: colorScheme.primary.withOpacity(0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Collapse',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius.copyWith(
                topLeft: Radius.zero,
                topRight: Radius.zero,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  ClipRRect(
                    borderRadius: _getTileBorderRadius(
                      surfaceStyle,
                      i,
                      children.length,
                    ),
                    child: children[i],
                  ),
                  if (i < children.length - 1)
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: colorScheme.outlineVariant
                          .withOpacity(isDark ? 0.1 : 0.08),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
