import 'package:diohub/common/overlay/modal_barrier_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_anchor/flutter_anchor.dart' show Anchor;

/// Reusable modal barrier for anchor-based overlays (popup, peek).
///
/// Opaque tap target that calls [onDismiss] when tapped. Uses [modalBarrierColor]
/// when [color] is null. Pass to [Anchor.backdropBuilder].
class AnchorBarrier extends StatelessWidget {
  const AnchorBarrier({
    required this.onDismiss,
    this.color,
    super.key,
  });

  final VoidCallback onDismiss;
  final Color? color;

  @override
  Widget build(final BuildContext context) {
    final Color effectiveColor = color ?? modalBarrierColor(context);

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: effectiveColor,
      ),
    );
  }
}
