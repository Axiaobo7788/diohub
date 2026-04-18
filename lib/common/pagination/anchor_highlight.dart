import 'package:flutter/material.dart';

/// Wraps an item widget with a flash-highlight animation
/// when it's the anchor target (deep-link / scroll-to).
///
/// Fades from highlighted color to transparent over [duration].
class AnchorHighlight extends StatefulWidget {
  const AnchorHighlight({
    required this.isHighlighted,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.highlightColor,
    super.key,
  });

  final bool isHighlighted;
  final Widget child;
  final Duration duration;
  final Color? highlightColor;

  @override
  State<AnchorHighlight> createState() => _AnchorHighlightState();
}

class _AnchorHighlightState extends State<AnchorHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  GlobalKey? _key;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.isHighlighted) {
      _key = GlobalKey();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _key?.currentContext == null) return;
        Scrollable.ensureVisible(
          _key!.currentContext!,
          alignment: 0.3,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color highlight = widget.highlightColor ??
        Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3);
    final Animation<Color?> colorAnimation = ColorTween(
      begin: highlight,
      end: Colors.transparent,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    return AnimatedBuilder(
      animation: colorAnimation,
      builder: (context, child) => Container(
        key: _key,
        color: colorAnimation.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}
