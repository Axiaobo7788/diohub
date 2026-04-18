import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Different styles for section headers
enum SectionHeaderStyle {
  /// Large title style (titleLarge, bold, -0.5 letter spacing)
  large,

  /// Medium title style (titleMedium, semi-bold)
  medium,

  /// Small title style (titleSmall, bold)
  small,
}

/// A widget that wraps content with a consistent section header
/// Provides standardized heading styles across all screens
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    required this.child,
    this.style = SectionHeaderStyle.large,
    this.padding,
    this.titlePadding,
    this.showDivider = false,
    this.dividerPadding,
    super.key,
  });

  /// The section title text
  final String title;

  /// The content to display below the header
  final Widget child;

  /// The style of the header
  final SectionHeaderStyle style;

  /// Padding around the entire section (header + content)
  final EdgeInsetsGeometry? padding;

  /// Padding around the title text
  /// Defaults based on style: large (16, 20, 16, 12), medium/small (16, 16, 16, 8)
  final EdgeInsetsGeometry? titlePadding;

  /// Whether to show a divider above the header
  final bool showDivider;

  /// Padding around the divider if shown
  final EdgeInsetsGeometry? dividerPadding;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? titleStyle = _getTitleStyle(theme);

    final EdgeInsetsGeometry effectiveTitlePadding = titlePadding ??
        (style == SectionHeaderStyle.large
            ? context.spacing.sectionTitlePaddingLarge
            : context.spacing.sectionTitlePaddingMedium);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showDivider)
          Padding(
            padding: dividerPadding ?? EdgeInsets.zero,
            child: const Divider(),
          ),
        Padding(
          padding: effectiveTitlePadding,
          child: Text(
            title,
            style: titleStyle,
          ),
        ),
        if (padding != null)
          Padding(
            padding: padding!,
            child: child,
          )
        else
          child,
      ],
    );
  }

  TextStyle? _getTitleStyle(final ThemeData theme) {
    switch (style) {
      case SectionHeaderStyle.large:
        return theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        );
      case SectionHeaderStyle.medium:
        return theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
      case SectionHeaderStyle.small:
        return theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );
    }
  }
}

/// A simple section header widget without wrapping content
/// Useful when you want just the header without the wrapper pattern
class SectionHeaderText extends StatelessWidget {
  const SectionHeaderText({
    required this.title,
    this.style = SectionHeaderStyle.large,
    this.padding,
    super.key,
  });

  /// The section title text
  final String title;

  /// The style of the header
  final SectionHeaderStyle style;

  /// Padding around the title text
  /// Defaults based on style: large (16, 20, 16, 12), medium/small (16, 16, 16, 8)
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? titleStyle = _getTitleStyle(theme);

    final EdgeInsetsGeometry effectivePadding = padding ??
        (style == SectionHeaderStyle.large
            ? context.spacing.sectionTitlePaddingLarge
            : context.spacing.sectionTitlePaddingMedium);

    return Padding(
      padding: effectivePadding,
      child: Text(
        title,
        style: titleStyle,
      ),
    );
  }

  TextStyle? _getTitleStyle(final ThemeData theme) {
    switch (style) {
      case SectionHeaderStyle.large:
        return theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        );
      case SectionHeaderStyle.medium:
        return theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
      case SectionHeaderStyle.small:
        return theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );
    }
  }
}
