import 'package:flutter/material.dart';

/// 3px-wide left-edge colored stripe on notification cards encoding priority.
///
/// Wraps [child] in a [Row] with the stripe. Priority from [reason] and optional
/// [enrichedState] (e.g. failing CI boosts to high).
class NotificationPriorityStripe extends StatelessWidget {
  const NotificationPriorityStripe({
    required this.reason,
    required this.child,
    this.enrichedState,
    super.key,
  });

  final String reason;
  final Widget child;

  /// Optional enriched state (e.g. 'ci_activity' + failing → high).
  final String? enrichedState;

  static const double _stripeWidth = 3;

  @override
  Widget build(final BuildContext context) {
    final Color color = _colorForPriority(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          width: _stripeWidth,
          decoration: BoxDecoration(
            color: color,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Color _colorForPriority(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    if (_isHighPriority) {
      return cs.error;
    }
    if (_isMediumPriority) {
      return Colors.amber;
    }
    return cs.onSurfaceVariant.withValues(alpha: 0.4);
  }

  bool get _isHighPriority {
    const Set<String> high = <String>{
      'review_requested',
      'assign',
      'security_alert',
      'ci_activity',
    };
    if (high.contains(reason)) {
      if (reason == 'ci_activity' && enrichedState != null) {
        final String s = enrichedState!.toLowerCase();
        if (s.contains('fail') || s.contains('error')) {
          return true;
        }
      } else {
        return true;
      }
    }
    return false;
  }

  bool get _isMediumPriority {
    const Set<String> medium = <String>{
      'mention',
      'author',
      'comment',
      'approval_requested',
    };
    return medium.contains(reason);
  }
}
