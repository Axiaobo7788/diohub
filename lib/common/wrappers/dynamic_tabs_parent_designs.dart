import 'package:flutter/material.dart';
import 'package:flutter_dynamic_tabs/flutter_dynamic_tabs.dart';

/// Design Option 1: Subtle Underline Indicator
/// 
/// A thin, subtle underline that complements the PullToExpandIndicator's minimal aesthetic.
/// Uses primary color with reduced opacity for a cohesive look.
/// 
/// Best for: Clean, minimal interfaces where the indicator and tabs should feel unified.
DynamicTabSettings _designOption1_SubtleUnderline(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colorScheme = theme.colorScheme;
  
  return DynamicTabSettings(
    // Thin underline indicator matching PullToExpandIndicator's subtlety
    indicator: UnderlineTabIndicator(
      borderSide: BorderSide(
        color: colorScheme.primary.withOpacity(0.7),
        width: 2.0,
      ),
      insets: const EdgeInsets.symmetric(horizontal: 12),
    ),
    indicatorSize: TabBarIndicatorSize.label,
    indicatorPadding: EdgeInsets.zero,
    dividerColor: Colors.transparent,
    tabAlignment: TabAlignment.center,
    labelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 0.1,
    ),
    unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      letterSpacing: 0.05,
    ),
    labelColor: colorScheme.primary.withOpacity(0.9),
    unselectedLabelColor: colorScheme.onSurfaceVariant.withOpacity(0.5),
    labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    childPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    physics: const BouncingScrollPhysics(),
  );
}

/// Design Option 2: Pill Background Indicator
/// 
/// A rounded pill background for the selected tab, creating a clear visual distinction
/// while maintaining a modern, cohesive look with the PullToExpandIndicator.
/// 
/// Best for: When you want stronger visual hierarchy without being too bold.
DynamicTabSettings _designOption2_PillBackground(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colorScheme = theme.colorScheme;
  final bool isDark = colorScheme.brightness == Brightness.dark;
  
  return DynamicTabSettings(
    // Rounded pill background for selected tab
    indicator: BoxDecoration(
      color: colorScheme.primaryContainer.withOpacity(isDark ? 0.3 : 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    indicatorSize: TabBarIndicatorSize.tab,
    indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    dividerColor: Colors.transparent,
    tabAlignment: TabAlignment.center,
    labelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 0.1,
    ),
    unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      letterSpacing: 0.05,
    ),
    labelColor: colorScheme.onPrimaryContainer,
    unselectedLabelColor: colorScheme.onSurfaceVariant.withOpacity(0.6),
    labelPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    childPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    physics: const BouncingScrollPhysics(),
  );
}

/// Design Option 3: Minimal Dot Indicator
/// 
/// A small dot below the selected tab, extremely subtle and non-intrusive.
/// Works perfectly with the PullToExpandIndicator's minimal design language.
/// 
/// Best for: Maximum subtlety while still providing clear tab selection feedback.
DynamicTabSettings _designOption3_MinimalDot(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colorScheme = theme.colorScheme;
  
  return DynamicTabSettings(
    // Custom dot indicator
    indicator: BoxDecoration(
      shape: BoxShape.circle,
      color: colorScheme.primary.withOpacity(0.8),
    ),
    indicatorSize: TabBarIndicatorSize.label,
    indicatorPadding: const EdgeInsets.only(bottom: 8),
    dividerColor: Colors.transparent,
    tabAlignment: TabAlignment.center,
    labelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 0.1,
    ),
    unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      letterSpacing: 0.05,
    ),
    labelColor: colorScheme.primary.withOpacity(0.9),
    unselectedLabelColor: colorScheme.onSurfaceVariant.withOpacity(0.5),
    labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    childPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    physics: const BouncingScrollPhysics(),
  );
}

/// Design Option 4: Segmented Control Style
/// 
/// A segmented control-inspired design with subtle borders and background.
/// Creates clear separation between tabs while maintaining elegance.
/// 
/// Best for: When tabs represent distinct sections that benefit from clear boundaries.
DynamicTabSettings _designOption4_SegmentedControl(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colorScheme = theme.colorScheme;
  
  return DynamicTabSettings(
    // Segmented control style with background
    indicator: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: colorScheme.outlineVariant.withOpacity(0.2),
        width: 1,
      ),
    ),
    indicatorSize: TabBarIndicatorSize.tab,
    indicatorPadding: const EdgeInsets.all(2),
    dividerColor: Colors.transparent,
    tabAlignment: TabAlignment.fill,
    labelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 0.1,
    ),
    unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      letterSpacing: 0.05,
    ),
    labelColor: colorScheme.onSurface,
    unselectedLabelColor: colorScheme.onSurfaceVariant.withOpacity(0.6),
    labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    childPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    physics: const BouncingScrollPhysics(),
  );
}

/// Design Option 5: Gradient Underline
/// 
/// A gradient underline that subtly fades, creating a soft transition effect.
/// Complements the PullToExpandIndicator's animated chevron nicely.
/// 
/// Best for: Adding a touch of visual interest while maintaining subtlety.
DynamicTabSettings _designOption5_GradientUnderline(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colorScheme = theme.colorScheme;
  
  return DynamicTabSettings(
    // Gradient underline indicator
    indicator: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          width: 2.5,
          color: colorScheme.primary,
        ),
      ),
      gradient: LinearGradient(
        colors: [
          colorScheme.primary.withOpacity(0.8),
          colorScheme.primary.withOpacity(0.4),
        ],
        stops: const [0.0, 1.0],
      ),
    ),
    indicatorSize: TabBarIndicatorSize.label,
    indicatorPadding: EdgeInsets.zero,
    dividerColor: Colors.transparent,
    tabAlignment: TabAlignment.center,
    labelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 0.1,
    ),
    unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      letterSpacing: 0.05,
    ),
    labelColor: colorScheme.primary.withOpacity(0.9),
    unselectedLabelColor: colorScheme.onSurfaceVariant.withOpacity(0.5),
    labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    childPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    physics: const BouncingScrollPhysics(),
  );
}

/// Design Option 6: Borderless with Subtle Divider
/// 
/// No indicator, but uses a subtle divider line to separate tabs from content.
/// Maximum minimalism that pairs perfectly with PullToExpandIndicator.
/// 
/// Best for: Ultra-minimal designs where color change alone is sufficient.
DynamicTabSettings _designOption6_BorderlessDivider(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colorScheme = theme.colorScheme;
  final bool isDark = colorScheme.brightness == Brightness.dark;
  
  return DynamicTabSettings(
    // No indicator, just color change
    indicator: const BoxDecoration(),
    indicatorSize: TabBarIndicatorSize.label,
    indicatorPadding: EdgeInsets.zero,
    // Subtle divider that complements PullToExpandIndicator
    dividerColor: colorScheme.outlineVariant.withOpacity(isDark ? 0.15 : 0.1),
    tabAlignment: TabAlignment.center,
    labelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 0.1,
    ),
    unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      letterSpacing: 0.05,
    ),
    labelColor: colorScheme.primary.withOpacity(0.9),
    unselectedLabelColor: colorScheme.onSurfaceVariant.withOpacity(0.5),
    labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    childPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    physics: const BouncingScrollPhysics(),
  );
}

/// Design Option 7: Top Border Indicator
/// 
/// A thin top border instead of bottom border, creating a unique visual style.
/// Works well when you want something different but still subtle.
/// 
/// Best for: Distinctive look while maintaining subtlety.
DynamicTabSettings _designOption7_TopBorder(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colorScheme = theme.colorScheme;
  
  return DynamicTabSettings(
    // Top border indicator
    indicator: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: colorScheme.primary.withOpacity(0.7),
          width: 2.0,
        ),
      ),
    ),
    indicatorSize: TabBarIndicatorSize.label,
    indicatorPadding: EdgeInsets.zero,
    dividerColor: Colors.transparent,
    tabAlignment: TabAlignment.center,
    labelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 0.1,
    ),
    unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      letterSpacing: 0.05,
    ),
    labelColor: colorScheme.primary.withOpacity(0.9),
    unselectedLabelColor: colorScheme.onSurfaceVariant.withOpacity(0.5),
    labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    childPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    physics: const BouncingScrollPhysics(),
  );
}

/// Helper function to get the recommended design
/// 
/// Currently returns Option 1 (Subtle Underline) as it best complements
/// the PullToExpandIndicator's minimal aesthetic.
DynamicTabSettings getRecommendedTabBarDesign(BuildContext context) {
  return _designOption1_SubtleUnderline(context);
}

/// Helper function to get a specific design option
DynamicTabSettings getTabBarDesign(BuildContext context, int option) {
  switch (option) {
    case 1:
      return _designOption1_SubtleUnderline(context);
    case 2:
      return _designOption2_PillBackground(context);
    case 3:
      return _designOption3_MinimalDot(context);
    case 4:
      return _designOption4_SegmentedControl(context);
    case 5:
      return _designOption5_GradientUnderline(context);
    case 6:
      return _designOption6_BorderlessDivider(context);
    case 7:
      return _designOption7_TopBorder(context);
    default:
      return getRecommendedTabBarDesign(context);
  }
}










