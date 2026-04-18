import 'dart:async';

import 'package:diohub/common/misc/action_card.dart';
import 'package:diohub/common/misc/action_card_style.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An [ActionCard] that tracks mutation state and shows visual feedback.
///
/// Shows:
/// - Idle: normal action icon
/// - Loading: trailing [ButtonSpinner]
/// - Success: [Icons.check_circle_rounded] in green, auto-resets
/// - Error: [Icons.error_rounded] in red, allow retry, auto-resets
class MutationActionCard extends ConsumerStatefulWidget {
  const MutationActionCard({
    required this.action,
    required this.onTap,
    this.style,
    this.confirmTitle,
    this.confirmExplanation,
    this.isDestructive = false,
    this.resetDuration = const Duration(seconds: 2),
    super.key,
  });

  final ActionButtonData action;
  final Future<void> Function() onTap;
  final String? confirmTitle;
  final String? confirmExplanation;
  final bool isDestructive;
  final ActionCardStyle? style;
  final Duration resetDuration;

  @override
  ConsumerState<MutationActionCard> createState() => _MutationActionCardState();
}

class _MutationActionCardState extends ConsumerState<MutationActionCard> {
  MutationState<void> _state = MutationState.idle();
  Timer? _resetTimer;

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(widget.resetDuration, () {
      if (mounted) setState(() => _state = MutationState.idle());
    });
  }

  Future<void> _execute() async {
    if (widget.confirmTitle != null) {
      final bool? confirmed = await showConfirmAction(
        context,
        title: widget.confirmTitle!,
        explanation: widget.confirmExplanation,
        isDestructive: widget.isDestructive,
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _state = MutationState.loading());
    try {
      await widget.onTap();
      if (!mounted) return;
      setState(() => _state = const MutationState.success(null));
      _scheduleReset();
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _state = MutationState.error(e, st));
      ref.read(notificationServiceProvider).error(e.toString());
      _scheduleReset();
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ActionCardStyle style = widget.style ?? ActionCardStyle.compact;
    final ThemeData theme = Theme.of(context);

    return _state.when(
      idle: () => ActionCard(
        action: widget.action,
        onTap: _execute,
        style: style,
      ),
      loading: () {
        final ActionButtonData loadingAction = widget.action.copyWithVisuals(
          trailing: const ButtonSpinner(size: 16),
        );
        return ActionCard(
          action: loadingAction,
          onTap: null,
          style: style,
        );
      },
      success: (_) {
        final ActionButtonData successAction = widget.action.copyWithVisuals(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
        );
        return ActionCard(
          action: successAction,
          onTap: null,
          style: style,
        );
      },
      error: (_, __) {
        final ActionButtonData errorAction = widget.action.copyWithVisuals(
          icon: Icons.error_rounded,
          iconColor: theme.colorScheme.error,
        );
        return ActionCard(
          action: errorAction,
          onTap: _execute,
          style: style,
        );
      },
    );
  }
}
