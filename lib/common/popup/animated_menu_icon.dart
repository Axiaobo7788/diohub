import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/animations/pressable_scale.dart';
import 'package:flutter/material.dart';

/// Animated menu/close icon for popup triggers using [AnimatedIcons.menu_close].
///
/// Morphs between hamburger (☰) and close (✕) based on [isOpen].
/// Use [AnimatedMenuIcon.bar] for CollapseBar actions, [AnimatedMenuIcon.compact]
/// for info cards and comment menus. Caller wraps in [TapFeedback] or
/// [GestureDetector] to provide the tap target and callback.
class AnimatedMenuIcon extends StatefulWidget {
  const AnimatedMenuIcon({
    required this.isOpen,
    this.size = 22,
    super.key,
  });

  /// Bar-style preset for CollapseBar actions (~22px).
  const AnimatedMenuIcon.bar({
    required this.isOpen,
    super.key,
  }) : size = 22;

  /// Compact preset for info cards / comment menus (16px in 32×32 box).
  const AnimatedMenuIcon.compact({
    required this.isOpen,
    super.key,
  }) : size = 16;

  /// Whether the associated popup is open (drives icon toward close ✕).
  final bool isOpen;

  /// Icon size in logical pixels.
  final double size;

  @override
  State<AnimatedMenuIcon> createState() => _AnimatedMenuIconState();
}

class _AnimatedMenuIconState extends State<AnimatedMenuIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kMicroDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: kMicroCurve,
    );
    if (widget.isOpen) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(final AnimatedMenuIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final Color? color = IconTheme.of(context).color;
    final Widget icon = AnimatedIcon(
      icon: AnimatedIcons.menu_close,
      progress: _animation,
      size: widget.size,
      color: color,
    );
    final Widget scaled = PressableScale(child: icon);

    if (widget.size == 16) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Center(child: scaled),
      );
    }
    return scaled;
  }
}
