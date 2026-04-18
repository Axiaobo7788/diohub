import 'package:diohub/common/animations/animated_visibility.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';

/// Wrapper widget that adds delay to AnimatedVisibility.
///
/// This widget is useful for creating staggered entrance animations where
/// multiple elements fade in one after another.
///
/// Example:
/// ```dart
/// Column(
///   children: [
///     DelayedFadeAnimation(
///       delay: Duration(milliseconds: 100),
///       child: Logo(),
///     ),
///     DelayedFadeAnimation(
///       delay: Duration(milliseconds: 200),
///       child: Title(),
///     ),
///   ],
/// )
/// ```
class DelayedFadeAnimation extends StatefulWidget {
  const DelayedFadeAnimation({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration delay;

  @override
  State<DelayedFadeAnimation> createState() => _DelayedFadeAnimationState();
}

class _DelayedFadeAnimationState extends State<DelayedFadeAnimation> {
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _shouldShow = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((final _) {
        Future.delayed(widget.delay, () {
          if (mounted) {
            setState(() {
              _shouldShow = true;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(final BuildContext context) => AnimatedVisibility(
        visible: _shouldShow,
        transition: AnimationTransition.fade,
        child: widget.child,
      );
}
