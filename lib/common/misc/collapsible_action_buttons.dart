import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/nav_center/models/action_surface.dart';
import 'package:diohub/common/widgets/enum_option_list_widget.dart';
import 'package:diohub/style/opacities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Color set for action buttons
class ActionButtonColors {
  const ActionButtonColors({
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final Color badgeColor;
  final Color badgeTextColor;
}

/// Configuration for determining how many action buttons should be visible
/// based on available width.
class ActionButtonsVisibilityConfig {
  const ActionButtonsVisibilityConfig({
    this.minPerRow = 3,
    this.maxPerRow = 4,
    this.defaultVisibleCount,
  });

  /// Minimum number of buttons per row
  final int minPerRow;

  /// Maximum number of buttons per row
  final int maxPerRow;

  /// Number of primary actions visible by default
  /// If null, uses width-based calculation to show buttonsPerRow number of actions
  final int? defaultVisibleCount;

  /// Default configuration: Uses width-based calculation
  static const ActionButtonsVisibilityConfig defaultConfig =
      ActionButtonsVisibilityConfig();

  /// Configuration with fixed visible count
  /// Uses default minPerRow (3) and maxPerRow (4)
  static ActionButtonsVisibilityConfig fixedCount({
    required final int defaultVisibleCount,
  }) => ActionButtonsVisibilityConfig(defaultVisibleCount: defaultVisibleCount);
}

/// Type of action that will be performed when an ActionButton is tapped
enum ActionButtonActionType {
  /// Opens a tab within the current screen
  tab,

  /// Opens a bottom sheet
  bottomSheet,

  /// Navigates to a new screen
  navigation,

  /// Performs an action (default)
  action,
}

/// Visibility state for action buttons in collapsed toolbar state
enum ActionButtonVisibilityState {
  /// Visible only in collapsed state
  /// These buttons are hidden when the toolbar is expanded
  collapsedOnly,

  /// Visible only in expanded state
  /// These buttons are hidden when the toolbar is collapsed
  expandedOnly,

  /// Visible in both collapsed and expanded states
  /// These buttons are always shown regardless of toolbar state
  both,

  /// Never visible in either state
  /// These buttons are hidden in both collapsed and expanded states
  none,
}

/// An option that can be displayed when an expandable button is expanded
class ExpandableOption {
  const ExpandableOption({
    required this.label,
    required this.onTap,
    this.icon,
    this.customWidget,
    this.enabled = true,
  });

  /// Label text for the option
  final String label;

  /// Optional icon for the option
  final IconData? icon;

  /// Callback when the option is tapped
  final VoidCallback onTap;

  /// Optional custom widget to display instead of standard label/icon
  final Widget? customWidget;

  /// Whether the option is enabled
  final bool enabled;
}

/// Controls whether an action dismisses the entity overlay.
enum ActionDismissBehavior {
  /// Overlay stays open. Button state updates reactively.
  none,

  /// Overlay dismisses before action executes (navigation, clipboard).
  immediate,

  /// Overlay dismisses, then a sheet opens (label picker, etc.).
  afterSheet,
}

/// Base class for all action button types
///
/// Use sealed class for exhaustive pattern matching
sealed class ActionButtonData {
  const ActionButtonData({
    required this.icon,
    required this.label,
    this.subtitle,
    this.leading,
    this.trailing,
    this.iconColor,
    this.enabled = true,
    this.isDestructive = false,
    this.isPositive = false,
    this.actionType,
    this.visibilityState = ActionButtonVisibilityState.both,
    this.seedColor,
    this.category,
    this.dismissBehavior = ActionDismissBehavior.immediate,
    this.surface,
  });

  /// Where this action is intended to be shown (popup, settings, or adaptive).
  final ActionSurface? surface;

  final IconData icon;
  final String label;

  /// Whether this action dismisses the entity overlay (and when).
  final ActionDismissBehavior dismissBehavior;

  /// Optional subtitle text to display below the label
  final String? subtitle;

  /// Optional widget to display on the leading side (left) of the card
  final Widget? leading;

  /// Optional widget to display on the trailing side (right) of the card
  final Widget? trailing;
  final Color? iconColor;
  final bool enabled;
  final bool isDestructive;
  final bool isPositive;

  /// Type of action this button performs (determines trailing icon if trailing is not provided)
  final ActionButtonActionType? actionType;

  /// Visibility state that determines when this button appears
  /// Controls visibility in both collapsed and expanded toolbar states
  final ActionButtonVisibilityState visibilityState;

  /// Optional seed color used to determine button colors (for prominent action cards)
  /// When provided, this color is used as the base for generating icon, text, and background colors
  final Color? seedColor;

  /// Optional category/section identifier for grouping actions
  /// Actions with the same category will be grouped together with dividers between groups
  final String? category;

  /// Gets the display icon for this action button
  /// For CheckboxActionButton, returns checked icon when value is true
  IconData get displayIcon {
    if (this is CheckboxActionButton) {
      return (this as CheckboxActionButton).value
          ? Icons.check_box_rounded
          : Icons.check_box_outline_blank_rounded;
    }
    return icon;
  }

  /// Gets the badge text from the trailing widget if it's a Text widget
  /// Returns null if trailing is null or not a Text widget
  String? get badgeText {
    if (trailing != null && trailing is Text) {
      return (trailing! as Text).data;
    }
    return null;
  }

  /// Checks if this is a selected checkbox action button
  bool get isSelectedCheckbox =>
      this is CheckboxActionButton && (this as CheckboxActionButton).value;

  /// Checks if this action button should be visible in expanded state
  bool get isVisibleInExpanded =>
      visibilityState == ActionButtonVisibilityState.expandedOnly ||
      visibilityState == ActionButtonVisibilityState.both;

  /// Checks if this action button should be visible in collapsed state
  bool get isVisibleInCollapsed =>
      visibilityState == ActionButtonVisibilityState.collapsedOnly ||
      visibilityState == ActionButtonVisibilityState.both;

  /// Checks if this action button should be visible based on toolbar state
  ///
  /// [isExpanded] - whether the toolbar is currently expanded
  bool isVisibleWhen(final bool isExpanded) {
    if (isExpanded) {
      return isVisibleInExpanded;
    } else {
      return isVisibleInCollapsed;
    }
  }

  /// Visual-only copyWith that dispatches to the correct subtype.
  /// Used by MutationActionCard to overlay loading/success/error indicators.
  ActionButtonData copyWithVisuals({
    final IconData? icon,
    final Color? iconColor,
    final Widget? trailing,
  }) => switch (this) {
    final MinorActionButton b => b.copyWith(
      icon: icon ?? b.icon,
      iconColor: iconColor,
      trailing: trailing,
    ),
    final MajorActionButton b => b.copyWith(
      icon: icon ?? b.icon,
      iconColor: iconColor,
      trailing: trailing,
    ),
    final ExpandableActionButton b => b.copyWith(
      icon: icon ?? b.icon,
      iconColor: iconColor,
      trailing: trailing,
    ),
    final CheckboxActionButton b => b.copyWith(
      iconColor: iconColor,
      trailing: trailing,
    ),
    final SheetActionButton b => b.copyWith(
      icon: icon ?? b.icon,
      iconColor: iconColor,
      trailing: trailing,
    ),
    final ReactiveActionButton _ => this,
  };

  /// Handles the tap action and returns whether the menu/toolbar should collapse.
  ///
  /// [onDismiss] is passed so async actions (e.g. star, watch, follow) can close
  /// the menu when the action completes. When provided, actions that use
  /// [onTapWithDismiss] will call it when done instead of closing immediately.
  ///
  /// Returns `true` if the caller should dismiss (close) the menu now,
  /// `false` if the action will dismiss itself (e.g. async) or should stay open.
  bool handleTapAndShouldCollapse(final void Function()? onDismiss) {
    switch (this) {
      case MinorActionButton(
        :final void Function(void Function() dismiss)? onTapWithDismiss,
        :final VoidCallback? onTap,
      ):
        if (onTapWithDismiss != null) {
          onTapWithDismiss(onDismiss ?? () {});
          return false; // Action will call onDismiss when done
        }
        onTap?.call();
        return true;
      case MajorActionButton(
        :final void Function(void Function() dismiss)? onTapWithDismiss,
        :final VoidCallback? onTap,
      ):
        if (onTapWithDismiss != null) {
          onTapWithDismiss(onDismiss ?? () {});
          return false;
        }
        onTap?.call();
        return true;
      case CheckboxActionButton(
        :final ValueChanged<bool>? onChanged,
        :final bool value,
      ):
        onChanged?.call(!value);
        return false; // Don't collapse for checkbox - it's a toggle
      case ExpandableActionButton():
        // Expandable buttons handle their own expansion
        return false;
      case SheetActionButton():
        // Sheet buttons dismiss the popup; the sheet is opened separately by the renderer
        return true;
      case ReactiveActionButton():
        // Renderer builds the inner action with ref; tap is handled by inner
        return false;
    }
  }

  /// Generates a stable key for this action based on semantic properties
  /// Uses only stable identifiers (not object identity) so widgets persist across rebuilds
  /// Icons are not included in keys as they can change (e.g., checkbox icons based on value)
  ///
  /// [context] is only used for truly separate widget instances (e.g., checkbox AnimatedContainer)
  /// For actions visible in both collapsed/expanded states, context is ignored to preserve widget instances
  ValueKey getStableKey({
    final String?
    context, // Only used for truly separate instances (e.g., 'checkbox' for AnimatedContainer)
    final bool?
    includeEnabledState, // Whether to include enabled/disabled in key
  }) {
    // For actions visible in both states, ignore context to preserve widget instances
    // Context is only used for truly separate widget instances
    final bool shouldIncludeContext =
        context != null &&
        context != 'expanded' &&
        context != 'collapsed' &&
        context != 'prominent_expanded' &&
        context != 'prominent_collapsed';

    return ValueKey(
      Object.hash(
        shouldIncludeContext ? context : null,
        includeEnabledState ?? false
            ? (enabled ? 'enabled' : 'disabled')
            : null,
        category,
        label,
        // runtimeType,
        // Note: NOT using hashCode - only semantic properties
        // Note: NOT using icon - icons can change (e.g., checkbox icons based on value)
      ),
    );
  }

  /// Convenience method for expanded action keys
  /// For actions with visibilityState.both, this returns the same key as getCollapsedKey()
  ValueKey getExpandedKey() => getStableKey();

  /// Convenience method for collapsed action keys
  /// For actions with visibilityState.both, this returns the same key as getExpandedKey()
  ValueKey getCollapsedKey({final bool includeEnabledState = true}) =>
      getStableKey(includeEnabledState: includeEnabledState);

  /// Convenience method for prominent expanded action keys
  /// For actions with visibilityState.both, this returns the same key as getProminentCollapsedKey()
  ValueKey getProminentExpandedKey() => getStableKey();

  /// Convenience method for prominent collapsed action keys
  /// For actions with visibilityState.both, this returns the same key as getProminentExpandedKey()
  ValueKey getProminentCollapsedKey() => getStableKey();

  /// Convenience method for checkbox AnimatedContainer keys
  ValueKey getCheckboxKey() => getStableKey(context: 'checkbox');

  /// Gets the icon color for this action based on its state and type
  /// Used for simple icon buttons in collapsed toolbar
  Color getIconColor(final BuildContext context) {
    if (!enabled) {
      return Theme.of(context).colorScheme.onSurfaceVariant.borderO;
    } else if (icon == Octicons.issue_opened) {
      return Colors.green.shade600;
    } else if (icon == Octicons.git_pull_request) {
      return Colors.purple.shade600;
    } else {
      return iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  /// Calculates colors for this action button based on its state and type
  /// Returns an ActionButtonColors object with all color values
  ActionButtonColors getColors(
    final BuildContext context, {
    final bool forProminentButton = false,
    final Color? seedColor,
  }) {
    // Use seedColor from action if provided, otherwise use parameter
    final Color? effectiveSeedColor = this.seedColor ?? seedColor;

    Color backgroundColor;
    Color iconColor;
    Color textColor;
    Color badgeColor;
    Color badgeTextColor;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (!enabled) {
      final double baseOpacity = forProminentButton ? 0.2 : 0.3;
      backgroundColor = colorScheme.surfaceContainerHighest.withValues(
        alpha: baseOpacity,
      );
      iconColor = colorScheme.onSurfaceVariant.borderO;
      textColor = colorScheme.onSurfaceVariant.withValues(
        alpha: forProminentButton ? 0.4 : 0.3,
      );
      badgeColor = Colors.transparent;
      badgeTextColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    } else if (isDestructive) {
      backgroundColor = colorScheme.errorContainer.withValues(
        alpha: forProminentButton ? 0.2 : 1.0,
      );
      iconColor = colorScheme.error;
      textColor = forProminentButton
          ? colorScheme.error
          : colorScheme.onErrorContainer;
      badgeColor = colorScheme.error;
      badgeTextColor = Colors.white;
    } else if (isPositive) {
      backgroundColor = Colors.green.withValues(
        alpha: forProminentButton ? 0.15 : 0.12,
      );
      iconColor = forProminentButton
          ? Colors.green.shade600
          : Colors.green.shade700;
      textColor = forProminentButton
          ? Colors.green.shade700
          : Colors.green.shade900;
      badgeColor = forProminentButton
          ? Colors.green.shade600
          : Colors.green.shade500;
      badgeTextColor = Colors.white;
    } else if (isSelectedCheckbox) {
      // Highlight selected checkboxes with primary color
      backgroundColor = colorScheme.primaryContainer.borderO;
      iconColor = colorScheme.primary;
      textColor = forProminentButton
          ? colorScheme.onPrimaryContainer
          : colorScheme.primary;
      badgeColor = colorScheme.primary;
      badgeTextColor = Colors.white;
    } else if (effectiveSeedColor != null) {
      // Use seedColor to generate colors
      backgroundColor = effectiveSeedColor.tintMedium;
      iconColor = effectiveSeedColor;
      textColor = effectiveSeedColor;
      badgeColor = effectiveSeedColor;
      badgeTextColor = Colors.white;
    } else if (forProminentButton) {
      // Prominent actions get a subtle background
      backgroundColor = colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.25,
      );
      iconColor = this.iconColor ?? colorScheme.primary;
      textColor = colorScheme.onSurface;
      badgeColor = colorScheme.primary;
      badgeTextColor = Colors.white;
    } else {
      // Standard actions
      backgroundColor = colorScheme.surfaceContainerHigh;
      iconColor = this.iconColor ?? colorScheme.primary;
      textColor = colorScheme.onSurface;
      badgeColor = colorScheme.primary;
      badgeTextColor = Colors.white;
    }

    return ActionButtonColors(
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      textColor: textColor,
      badgeColor: badgeColor,
      badgeTextColor: badgeTextColor,
    );
  }
}

/// Small action button (replaces the previous ActionButtonData for minor actions)
class MinorActionButton extends ActionButtonData {
  const MinorActionButton({
    required super.icon,
    required super.label,
    this.onTap,
    this.onTapWithDismiss,
    super.subtitle,
    super.leading,
    super.trailing,
    super.iconColor,
    super.enabled,
    super.isDestructive,
    super.isPositive,
    super.actionType,
    super.visibilityState,
    super.seedColor,
    super.category,
    super.dismissBehavior,
    super.surface,
  });

  /// Sync tap. Menu closes immediately after.
  final VoidCallback? onTap;

  /// Async tap. Receives [dismiss]; call it when the action completes to close the menu.
  /// Use for star, watch, follow, etc. so the menu stays open until the mutation finishes.
  final void Function(void Function() dismiss)? onTapWithDismiss;

  /// Creates a copy of this MinorActionButton with updated properties
  MinorActionButton copyWith({
    final IconData? icon,
    final String? label,
    final VoidCallback? onTap,
    final void Function(void Function() dismiss)? onTapWithDismiss,
    final String? subtitle,
    final Widget? leading,
    final Widget? trailing,
    final Color? iconColor,
    final bool? enabled,
    final bool? isDestructive,
    final bool? isPositive,
    final ActionButtonActionType? actionType,
    final ActionButtonVisibilityState? visibilityState,
    final Color? seedColor,
    final String? category,
    final ActionDismissBehavior? dismissBehavior,
    final ActionSurface? surface,
  }) => MinorActionButton(
    icon: icon ?? this.icon,
    label: label ?? this.label,
    onTap: onTap ?? this.onTap,
    onTapWithDismiss: onTapWithDismiss ?? this.onTapWithDismiss,
    subtitle: subtitle ?? this.subtitle,
    leading: leading ?? this.leading,
    trailing: trailing ?? this.trailing,
    iconColor: iconColor ?? this.iconColor,
    enabled: enabled ?? this.enabled,
    isDestructive: isDestructive ?? this.isDestructive,
    isPositive: isPositive ?? this.isPositive,
    actionType: actionType ?? this.actionType,
    visibilityState: visibilityState ?? this.visibilityState,
    seedColor: seedColor ?? this.seedColor,
    category: category ?? this.category,
    dismissBehavior: dismissBehavior ?? this.dismissBehavior,
    surface: surface ?? this.surface,
  );
}

/// Major action button for prominent actions (has onTap field)
class MajorActionButton extends ActionButtonData {
  const MajorActionButton({
    required super.icon,
    required super.label,
    this.onTap,
    this.onTapWithDismiss,
    super.subtitle,
    super.leading,
    super.trailing,
    super.iconColor,
    super.enabled,
    super.isDestructive,
    super.isPositive,
    super.actionType,
    super.visibilityState,
    super.seedColor,
    super.category,
    super.dismissBehavior,
    super.surface,
  });

  /// Sync tap. Menu closes immediately after.
  final VoidCallback? onTap;

  /// Async tap. Receives [dismiss]; call it when the action completes to close the menu.
  /// Use for star, watch, follow, etc. so the menu stays open until the mutation finishes.
  final void Function(void Function() dismiss)? onTapWithDismiss;

  /// Creates a copy of this MajorActionButton with updated properties
  MajorActionButton copyWith({
    final IconData? icon,
    final String? label,
    final VoidCallback? onTap,
    final void Function(void Function() dismiss)? onTapWithDismiss,
    final String? subtitle,
    final Widget? leading,
    final Widget? trailing,
    final Color? iconColor,
    final bool? enabled,
    final bool? isDestructive,
    final bool? isPositive,
    final ActionButtonActionType? actionType,
    final ActionButtonVisibilityState? visibilityState,
    final Color? seedColor,
    final String? category,
    final ActionDismissBehavior? dismissBehavior,
    final ActionSurface? surface,
  }) => MajorActionButton(
    icon: icon ?? this.icon,
    label: label ?? this.label,
    onTap: onTap ?? this.onTap,
    onTapWithDismiss: onTapWithDismiss ?? this.onTapWithDismiss,
    subtitle: subtitle ?? this.subtitle,
    leading: leading ?? this.leading,
    trailing: trailing ?? this.trailing,
    iconColor: iconColor ?? this.iconColor,
    enabled: enabled ?? this.enabled,
    isDestructive: isDestructive ?? this.isDestructive,
    isPositive: isPositive ?? this.isPositive,
    actionType: actionType ?? this.actionType,
    visibilityState: visibilityState ?? this.visibilityState,
    seedColor: seedColor ?? this.seedColor,
    category: category ?? this.category,
    dismissBehavior: dismissBehavior ?? this.dismissBehavior,
    surface: surface ?? this.surface,
  );
}

/// Expandable action button that can expand to show additional content
class ExpandableActionButton extends ActionButtonData {
  const ExpandableActionButton({
    required super.icon,
    required super.label,
    required this.expandableWidgetBuilder,
    super.subtitle,
    super.leading,
    super.trailing,
    super.iconColor,
    super.enabled,
    super.isDestructive,
    super.isPositive,
    super.actionType,
    super.visibilityState,
    super.seedColor,
    super.category,
    super.dismissBehavior,
    super.surface,
  });

  /// Creates an [ExpandableActionButton] pre-wired to show an
  /// [EnumOptionListWidget] when expanded.
  ///
  /// The [subtitle] automatically displays the label of the current [value].
  /// Works with Dart `enum`, `built_value` `EnumClass`, or any fixed set of values.
  ///
  /// Example:
  /// ```dart
  /// ExpandableActionButton.enumSelector<SubscriptionState>(
  ///   icon: Octicons.bell,
  ///   label: 'Notifications',
  ///   value: repo.viewerSubscription ?? SubscriptionState.UNSUBSCRIBED,
  ///   values: SubscriptionState.values.toList(),
  ///   onChanged: (s) => updateSubscription(s),
  ///   labelBuilder: (s) => switch (s) { ... },
  /// )
  /// ```
  static ExpandableActionButton enumSelector<T>({
    required final IconData icon,
    required final String label,
    required final T value,
    required final List<T> values,
    required final ValueChanged<T> onChanged,
    required final String Function(T) labelBuilder,
    final IconData Function(T)? iconBuilder,
    final String? Function(T)? subtitleBuilder,
    final Widget? leading,
    final Widget? trailing,
    final Color? iconColor,
    final bool enabled = true,
    final bool isDestructive = false,
    final bool isPositive = false,
    final ActionButtonActionType? actionType,
    final ActionButtonVisibilityState visibilityState =
        ActionButtonVisibilityState.both,
    final Color? seedColor,
    final String? category,
    final ActionDismissBehavior dismissBehavior = ActionDismissBehavior.none,
    final ActionSurface? surface,
  }) => ExpandableActionButton(
    icon: icon,
    label: label,
    subtitle: labelBuilder(value),
    leading: leading,
    trailing: trailing,
    iconColor: iconColor,
    enabled: enabled,
    isDestructive: isDestructive,
    isPositive: isPositive,
    actionType: actionType,
    visibilityState: visibilityState,
    seedColor: seedColor,
    category: category,
    dismissBehavior: dismissBehavior,
    surface: surface,
    expandableWidgetBuilder: (final VoidCallback onCollapse) =>
        EnumOptionListWidget<T>(
          values: values,
          selected: value,
          onChanged: onChanged,
          labelBuilder: labelBuilder,
          iconBuilder: iconBuilder,
          subtitleBuilder: subtitleBuilder,
          onCollapse: onCollapse,
        ),
  );

  /// Builder function to create widget to show when this button is expanded
  /// The builder receives a collapse callback that can be called to collapse the expandable widget
  final Widget Function(VoidCallback onCollapse) expandableWidgetBuilder;

  /// Whether this button is expandable (always true for ExpandableActionButton)
  bool get isExpandable => true;

  /// Creates a copy of this ExpandableActionButton with updated properties
  ExpandableActionButton copyWith({
    final IconData? icon,
    final String? label,
    final Widget Function(VoidCallback onCollapse)? expandableWidgetBuilder,
    final String? subtitle,
    final Widget? leading,
    final Widget? trailing,
    final Color? iconColor,
    final bool? enabled,
    final bool? isDestructive,
    final bool? isPositive,
    final ActionButtonActionType? actionType,
    final ActionButtonVisibilityState? visibilityState,
    final Color? seedColor,
    final String? category,
    final ActionDismissBehavior? dismissBehavior,
    final ActionSurface? surface,
  }) => ExpandableActionButton(
    icon: icon ?? this.icon,
    label: label ?? this.label,
    expandableWidgetBuilder:
        expandableWidgetBuilder ?? this.expandableWidgetBuilder,
    subtitle: subtitle ?? this.subtitle,
    leading: leading ?? this.leading,
    trailing: trailing ?? this.trailing,
    iconColor: iconColor ?? this.iconColor,
    enabled: enabled ?? this.enabled,
    isDestructive: isDestructive ?? this.isDestructive,
    isPositive: isPositive ?? this.isPositive,
    actionType: actionType ?? this.actionType,
    visibilityState: visibilityState ?? this.visibilityState,
    seedColor: seedColor ?? this.seedColor,
    category: category ?? this.category,
    dismissBehavior: dismissBehavior ?? this.dismissBehavior,
    surface: surface ?? this.surface,
  );
}

/// Checkbox action button for toggleable actions
/// The icon is handled internally based on the value - no need to pass it
class CheckboxActionButton extends ActionButtonData {
  const CheckboxActionButton({
    required super.label,
    required this.value,
    required this.onChanged,
    super.subtitle,
    super.leading,
    super.trailing,
    super.iconColor,
    super.enabled,
    super.isDestructive,
    super.isPositive,
    super.actionType,
    super.visibilityState,
    super.seedColor,
    super.category,
    super.dismissBehavior,
    super.surface,
  }) : super(
         // Use a stable icon internally - displayIcon getter handles the actual display
         icon: Icons.check_box_outline_blank_rounded,
       );

  /// Current checkbox value
  final bool value;

  /// Callback when checkbox value changes
  final ValueChanged<bool>? onChanged;

  /// Creates a copy of this CheckboxActionButton with updated properties
  CheckboxActionButton copyWith({
    final String? label,
    final bool? value,
    final ValueChanged<bool>? onChanged,
    final String? subtitle,
    final Widget? leading,
    final Widget? trailing,
    final Color? iconColor,
    final bool? enabled,
    final bool? isDestructive,
    final bool? isPositive,
    final ActionButtonActionType? actionType,
    final ActionButtonVisibilityState? visibilityState,
    final Color? seedColor,
    final String? category,
    final ActionDismissBehavior? dismissBehavior,
    final ActionSurface? surface,
  }) => CheckboxActionButton(
    label: label ?? this.label,
    value: value ?? this.value,
    onChanged: onChanged ?? this.onChanged,
    subtitle: subtitle ?? this.subtitle,
    leading: leading ?? this.leading,
    trailing: trailing ?? this.trailing,
    iconColor: iconColor ?? this.iconColor,
    enabled: enabled ?? this.enabled,
    isDestructive: isDestructive ?? this.isDestructive,
    isPositive: isPositive ?? this.isPositive,
    actionType: actionType ?? this.actionType,
    visibilityState: visibilityState ?? this.visibilityState,
    seedColor: seedColor ?? this.seedColor,
    category: category ?? this.category,
    dismissBehavior: dismissBehavior ?? this.dismissBehavior,
    surface: surface ?? this.surface,
  );
}

/// Action button that dismisses the current popup/menu and opens a bottom sheet.
///
/// Used for actions that need more space than inline expansion allows:
/// labels, assignees, topics, merge confirmation, reviewers.
class SheetActionButton extends ActionButtonData {
  const SheetActionButton({
    required super.icon,
    required super.label,
    required this.sheetBuilder,
    this.headerBuilder,
    this.onResult,
    this.useScrollableSheet = true,
    super.subtitle,
    super.leading,
    super.trailing,
    super.iconColor,
    super.enabled,
    super.isDestructive,
    super.isPositive,
    super.actionType,
    super.visibilityState,
    super.seedColor,
    super.category,
    super.dismissBehavior,
    super.surface,
  });

  /// Builds the content of the sheet.
  /// Receives the sheet's own BuildContext (for Navigator.pop, setState, etc.).
  /// When [useScrollableSheet] is true, also receives the sheet's [ScrollController].
  final Widget Function(
    BuildContext context, [
    ScrollController? scrollController,
  ])
  sheetBuilder;

  /// Optional custom header builder for the sheet.
  /// If null, a default [AppSheetHeader.text] with [label] is used.
  final StatefulWidgetBuilder? headerBuilder;

  /// Called with the result value when the sheet is dismissed.
  final ValueChanged<dynamic>? onResult;

  /// Whether to use [AppSheet.scrollable] (true) or [AppSheet.simple] (false).
  final bool useScrollableSheet;

  /// Opens the sheet using the app's standard bottom sheet infrastructure.
  /// Called by renderers after the popup has been dismissed.
  Future<dynamic> openSheet(final BuildContext context) async {
    if (useScrollableSheet) {
      return AppSheet.scrollable(
        context,
        headerBuilder:
            headerBuilder ??
            (final BuildContext ctx, final StateSetter setState) =>
                AppSheetHeader.text(label),
        bodyBuilder:
            (
              final BuildContext ctx,
              final StateSetter setState,
              final ScrollController scrollController,
            ) => sheetBuilder(ctx, scrollController),
      );
    } else {
      return AppSheet.simple(
        context,
        headerBuilder:
            headerBuilder ??
            (final BuildContext ctx, final StateSetter setState) =>
                AppSheetHeader.text(label),
        bodyBuilder: (final BuildContext ctx, final StateSetter setState) =>
            sheetBuilder(ctx, null),
      );
    }
  }

  /// Creates a copy of this SheetActionButton with updated properties
  SheetActionButton copyWith({
    final IconData? icon,
    final String? label,
    final Widget Function(
      BuildContext context, [
      ScrollController? scrollController,
    ])?
    sheetBuilder,
    final StatefulWidgetBuilder? headerBuilder,
    final ValueChanged<dynamic>? onResult,
    final bool? useScrollableSheet,
    final String? subtitle,
    final Widget? leading,
    final Widget? trailing,
    final Color? iconColor,
    final bool? enabled,
    final bool? isDestructive,
    final bool? isPositive,
    final ActionButtonActionType? actionType,
    final ActionButtonVisibilityState? visibilityState,
    final Color? seedColor,
    final String? category,
    final ActionDismissBehavior? dismissBehavior,
    final ActionSurface? surface,
  }) => SheetActionButton(
    icon: icon ?? this.icon,
    label: label ?? this.label,
    sheetBuilder: sheetBuilder ?? this.sheetBuilder,
    headerBuilder: headerBuilder ?? this.headerBuilder,
    onResult: onResult ?? this.onResult,
    useScrollableSheet: useScrollableSheet ?? this.useScrollableSheet,
    subtitle: subtitle ?? this.subtitle,
    leading: leading ?? this.leading,
    trailing: trailing ?? this.trailing,
    iconColor: iconColor ?? this.iconColor,
    enabled: enabled ?? this.enabled,
    isDestructive: isDestructive ?? this.isDestructive,
    isPositive: isPositive ?? this.isPositive,
    actionType: actionType ?? this.actionType,
    visibilityState: visibilityState ?? this.visibilityState,
    seedColor: seedColor ?? this.seedColor,
    category: category ?? this.category,
    dismissBehavior: dismissBehavior ?? this.dismissBehavior,
    surface: surface ?? this.surface,
  );
}

/// Wraps an action button in reactive state: the [builder] is called with the
/// current value from [getValue](ref) so the icon/label update without
/// re-triggering the popup entrance animation.
///
/// [getValue] is called by the popup renderer with its [WidgetRef] (e.g.
/// `(ref) => ref.watch(provider)` or `(ref) => ref.watch(provider.select(...))`).
class ReactiveActionButton extends ActionButtonData {
  const ReactiveActionButton({required this.getValue, required this.builder})
    : super(
        icon: Icons.circle,
        label: '',
        dismissBehavior: ActionDismissBehavior.none,
      );

  /// Returns the current value when the action is built.
  /// Called by the renderer with its [WidgetRef].
  final Object? Function(WidgetRef ref) getValue;
  final ActionButtonData Function(Object? value) builder;
}

extension MinorActionButtonReactive on MinorActionButton {
  /// Builds a reactive action that calls [getValue](ref) and builds the
  /// inner [MinorActionButton] from [builder]. Use for toggles (star, watch,
  /// pin) so the icon updates without rebuilding the whole overlay.
  static ReactiveActionButton reactive<T>({
    required Object? Function(WidgetRef ref) getValue,
    required ActionButtonData Function(T value) builder,
  }) => ReactiveActionButton(
    getValue: getValue,
    builder: (Object? value) => builder(value as T),
  );
}

extension SheetActionButtonReactive on SheetActionButton {
  /// Builds a reactive sheet action that calls [getValue](ref) and builds
  /// the inner [SheetActionButton] from [builder].
  static ReactiveActionButton reactive<T>({
    required Object? Function(WidgetRef ref) getValue,
    required ActionButtonData Function(T value) builder,
  }) => ReactiveActionButton(
    getValue: getValue,
    builder: (Object? value) => builder(value as T),
  );
}
