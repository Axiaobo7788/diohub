import 'package:diohub/common/misc/shimmer_scope.dart' show ShimmerScope;
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// The shape type for a shimmer bone.
enum ShimmerShape {
  /// Uses the app's surface shape system (squircle by default).
  surface,

  /// Perfect circle (for avatars).
  circle,

  /// Fully rounded pill (for chips/badges).
  pill,
}

/// A single shimmer placeholder shape.
///
/// Use inside a [ShimmerScope]. The bone itself is just a colored
/// rectangle clipped to the specified shape. The shimmer animation
/// comes from an ancestor [ShimmerScope].
class ShimmerBone extends StatelessWidget {
  /// Creates a shimmer bone with explicit dimensions and shape.
  const ShimmerBone({
    required this.height,
    this.width,
    this.radiusSize = RadiusSize.soft,
    this.shape = ShimmerShape.surface,
    super.key,
  });

  /// Single line of body text. Height ≈14, soft radius.
  const ShimmerBone.text({
    this.width,
    super.key,
  })  : height = 14,
        radiusSize = RadiusSize.soft,
        shape = ShimmerShape.surface;

  /// Title / heading text. Height ≈20, soft radius.
  const ShimmerBone.title({
    this.width,
    super.key,
  })  : height = 20,
        radiusSize = RadiusSize.soft,
        shape = ShimmerShape.surface;

  /// Subtitle / label text. Height ≈12, soft radius.
  const ShimmerBone.label({
    this.width,
    super.key,
  })  : height = 12,
        radiusSize = RadiusSize.soft,
        shape = ShimmerShape.surface;

  /// Circular avatar. Uses [ShimmerShape.circle].
  const ShimmerBone.avatar({
    required final double size,
    super.key,
  })  : height = size,
        width = size,
        radiusSize = RadiusSize.medium,
        shape = ShimmerShape.circle;

  /// Small square icon placeholder.
  const ShimmerBone.icon({
    final double size = 20,
    super.key,
  })  : height = size,
        width = size,
        radiusSize = RadiusSize.soft,
        shape = ShimmerShape.surface;

  /// Chip / pill / badge. Fully rounded (half-height radius).
  const ShimmerBone.chip({
    this.width = 60,
    this.height = 24,
    super.key,
  })  : radiusSize = RadiusSize.xl,
        shape = ShimmerShape.pill;

  /// Card / block area (readme placeholder, image area, chart, etc.).
  const ShimmerBone.block({
    required this.height,
    this.width,
    this.radiusSize = RadiusSize.medium,
    super.key,
  }) : shape = ShimmerShape.surface;

  final double height;
  final double? width;
  final RadiusSize radiusSize;
  final ShimmerShape shape;

  /// A column of text-line bones with automatic spacing.
  ///
  /// Useful for paragraph placeholders.
  ///
  /// Example:
  /// ```dart
  /// ShimmerBone.lines(
  ///   count: 3,
  ///   widths: [null, null, 180], // varying last line width
  /// )
  /// ```
  static Widget lines({
    final int count = 3,
    final double spacing = 4,
    final List<double?>? widths,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (final int i) {
          final double? w =
              widths != null && i < widths.length ? widths[i] : null;
          return Padding(
            padding: EdgeInsets.only(top: i > 0 ? spacing : 0),
            child: ShimmerBone.text(width: w),
          );
        }),
      );

  @override
  Widget build(final BuildContext context) {
    if (width != null) {
      return SizedBox(
        height: height,
        width: width,
        child: DecoratedBox(
          decoration: _resolveDecoration(context),
        ),
      );
    }
    // SizedBox supports intrinsic dimension queries; LayoutBuilder does not.
    // Use infinite width so we fill parent constraints when bounded (e.g. in
    // Row/Expanded); intrinsic height queries still get [height].
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: _resolveDecoration(context),
      ),
    );
  }

  Decoration _resolveDecoration(final BuildContext context) {
    // Use a moderate opacity so the FadeTransition breathe pulse (0.4–1.0)
    // produces a visible swing: effective range ≈ 16%–40% alpha.
    final Color color =
        context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.40);

    switch (shape) {
      case ShimmerShape.circle:
        return BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        );

      case ShimmerShape.pill:
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        );

      case ShimmerShape.surface:
        // Delegates to the app's squircle/rounded system
        return context.surfaceDecoration(
          radiusSize,
          color: color,
        );
    }
  }
}
