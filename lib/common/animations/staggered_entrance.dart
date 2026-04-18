import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';

/// A widget that animates its child's entrance with a staggered delay based on index.
///
/// Use inside paginated or list builders (e.g. [ListView.builder]) for a cascading entrance effect.
///
/// The animation consists of a fade-in combined with a slide-up effect.
/// Items with higher indices start their animation later, creating a cascading effect.
///
/// Example:
/// ```dart
/// ListView.builder(
///   itemCount: items.length,
///   itemBuilder: (context, index) => StaggeredEntrance(
///     index: index,
///     shouldAnimate: true,
///     child: MyItem(items[index]),
///   ),
/// )
/// ```
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    required this.index,
    required this.child,
    this.shouldAnimate = true,
    this.staggerDelay,
    this.maxDelay,
    this.duration,
    this.slideOffset,
    super.key,
  });

  /// The index of this item in the list (used to calculate stagger delay)
  final int index;

  /// The widget to animate
  final Widget child;

  /// Whether to animate the entrance (if false, shows immediately)
  final bool shouldAnimate;

  /// Delay between each item (default: 50ms per index)
  final Duration? staggerDelay;

  /// Maximum delay for any item (default: 300ms)
  final Duration? maxDelay;

  /// Duration of the animation (default: 500ms)
  final Duration? duration;

  /// Vertical offset for the slide animation (default: Offset(0, 0.3))
  final Offset? slideOffset;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    final Duration effectiveDuration = widget.duration ?? kEntranceDuration;

    _controller = AnimationController(
      duration: effectiveDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: kEntranceCurve,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset ?? const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: kEntranceCurve,
      ),
    );

    if (widget.shouldAnimate) {
      _controller.value = 0.0;

      // Calculate stagger delay
      final int staggerMs =
          (widget.staggerDelay ?? kStaggerInterval).inMilliseconds;
      final int maxDelayMs =
          (widget.maxDelay ?? kMaxStaggerDelay).inMilliseconds;
      final int delay = (widget.index * staggerMs).clamp(0, maxDelayMs);

      // Start animation after delay
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        Future<void>.delayed(Duration(milliseconds: delay), () async {
          if (mounted && _controller.status == AnimationStatus.dismissed) {
            await _controller.forward();
          }
        });
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        ),
      );
}
