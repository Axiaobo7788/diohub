import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single card primitive for the app.
///
/// Wraps a child with a themed background, border radius, optional shadow,
/// and optional tap interaction with visible InkWell splash feedback.
///
/// When [onTap] or [onLongPress] is provided, uses `Material` + `InkWell`
/// so the splash paints **on top of** the background. When non-tappable,
/// uses a plain `Container` with `BoxDecoration` (no gesture overhead).
///
/// Replaces the old `TappableSurface -> BorderedContainer` sandwich pattern
/// that produced invisible splashes.
class BorderedContainer extends ConsumerWidget {
  const BorderedContainer({
    required this.child,
    this.borderColor,
    this.borderSide = BorderSideType.left,
    this.borderWidth = 1.2,
    this.size = RadiusSize.medium,
    this.backgroundColor,
    this.padding,
    this.elevation = 1.0,
    this.onTap,
    this.onLongPress,
    this.ref,
    super.key,
  });

  /// The widget to wrap.
  final Widget child;

  /// Color of the border.
  final Color? borderColor;

  /// Which side to show the border on.
  final BorderSideType borderSide;

  /// Width of the border.
  final double borderWidth;

  /// Border radius size (standardized).
  final RadiusSize size;

  /// Background color of the container. If null, uses surfaceVariant from theme.
  final Color? backgroundColor;

  /// Padding around the child content.
  /// If null, defaults to context.spacing.cardContentPadding.
  final EdgeInsetsGeometry? padding;

  /// Elevation of the container (creates shadow). Default is 1.0.
  final double elevation;

  /// Callback when tapped. If provided, enables Material + InkWell feedback.
  final VoidCallback? onTap;

  /// Callback when long pressed.
  final VoidCallback? onLongPress;

  /// When non-null, tap navigates via [ref]. Takes precedence over [onTap].
  final EntityRef? ref;

  bool get _isTappable => onTap != null || onLongPress != null || ref != null;

  @override
  Widget build(final BuildContext context, final WidgetRef widgetRef) {
    final VoidCallback? effectiveOnTap =
        ref != null ? () => ref!.navigate(context, widgetRef) : onTap;
    final BorderRadius borderRadius = context.radius(size);
    final EdgeInsetsGeometry effectivePadding =
        padding ?? context.spacing.cardContentPadding;
    final Color effectiveBgColor =
        backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerLow;

    Widget content = Padding(
      padding: effectivePadding,
      child: child,
    );

    if (_isTappable) {
      return _buildTappable(
        context,
        borderRadius,
        effectiveBgColor,
        content,
        effectiveOnTap,
      );
    }
    return _buildStatic(context, borderRadius, effectiveBgColor, content);
  }

  /// Paints an accent bar on the side given by [borderSide] when [borderColor] is set.
  Widget _applyBorderAccent(
    final Widget child,
    final BorderRadius borderRadius,
  ) {
    if (borderColor == null) return child;
    final bool isVertical =
        borderSide == BorderSideType.left || borderSide == BorderSideType.right;
    final Widget accent = Container(
      width: isVertical ? borderWidth : null,
      height: isVertical ? null : borderWidth,
      decoration: BoxDecoration(
        color: borderColor,
        borderRadius: _accentBorderRadius(borderRadius),
      ),
    );
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: <Widget>[
        child,
        Positioned(
          top: borderSide == BorderSideType.top ? 0 : null,
          bottom: borderSide == BorderSideType.bottom ? 0 : null,
          left: borderSide == BorderSideType.left ? 0 : null,
          right: borderSide == BorderSideType.right ? 0 : null,
          child: accent,
        ),
      ],
    );
  }

  BorderRadius _accentBorderRadius(final BorderRadius r) {
    switch (borderSide) {
      case BorderSideType.top:
        return BorderRadius.only(
          topLeft: r.topLeft,
          topRight: r.topRight,
        );
      case BorderSideType.bottom:
        return BorderRadius.only(
          bottomLeft: r.bottomLeft,
          bottomRight: r.bottomRight,
        );
      case BorderSideType.left:
        return BorderRadius.only(
          topLeft: r.topLeft,
          bottomLeft: r.bottomLeft,
        );
      case BorderSideType.right:
        return BorderRadius.only(
          topRight: r.topRight,
          bottomRight: r.bottomRight,
        );
    }
  }

  /// Tappable path: Material -> InkWell -> (optional accent) -> child.
  /// The Material IS the background, so the InkWell splash paints on top.
  Widget _buildTappable(
    final BuildContext context,
    final BorderRadius borderRadius,
    final Color bgColor,
    final Widget paddedChild,
    final VoidCallback? effectiveOnTap,
  ) {
    final ShapeBorder shape = context.surfaceShape(size);
    final Widget innerChild = _applyBorderAccent(paddedChild, borderRadius);

    Widget result = Material(
      color: bgColor,
      shape: shape,
      child: InkWell(
        onTap: effectiveOnTap,
        onLongPress: onLongPress,
        customBorder: shape,
        child: innerChild,
      ),
    );

    // Material doesn't support boxShadow directly; wrap with DecoratedBox
    // for shadow when elevation > 0.
    if (elevation > 0) {
      result = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.subtle,
              blurRadius: elevation * 2,
              offset: Offset(0, elevation),
            ),
          ],
        ),
        child: result,
      );
    }

    return result;
  }

  /// Static (non-tappable) path: Container with BoxDecoration.
  Widget _buildStatic(
    final BuildContext context,
    final BorderRadius borderRadius,
    final Color bgColor,
    final Widget paddedChild,
  ) {
    // Get base decoration from theme API
    final Decoration baseDecoration = context.surfaceDecoration(
      size,
      color: bgColor,
    );

    // Ensure we have a BoxDecoration for shadow support
    final BoxDecoration decoration;
    if (baseDecoration is BoxDecoration) {
      decoration = baseDecoration.copyWith(
        boxShadow: elevation > 0
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.subtle,
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      );
    } else {
      // Fallback if it's a ShapeDecoration (shouldn't happen for rounded)
      decoration = BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        boxShadow: elevation > 0
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.subtle,
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      );
    }

    final Widget innerChild = _applyBorderAccent(paddedChild, borderRadius);
    return DecoratedBox(
      decoration: decoration,
      child: innerChild,
    );
  }
}
