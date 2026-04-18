import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/providers/developer_mode_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract base for all NavCenter settings rows.
///
/// Provides:
/// - Consistent layout (icon + label + subtitle + trailing)
/// - Deferred feature gating (opacity 0.4 + "Coming Soon" badge)
/// - [MutationState] for loading/success/error; trailing is reactive to it
/// - [executeMutation] runs [onMutate] with centralized error handling
///
/// Subclasses implement [buildTrailing]. The base shows a spinner when
/// [MutationState] is loading; otherwise it shows [buildTrailing].
/// Subclasses may override [onMutationError] to revert local state.
abstract class SettingsRowBase<T> extends ConsumerStatefulWidget {
  const SettingsRowBase({
    required this.label,
    required this.onMutate,
    super.key,
    this.leadingIcon,
    this.subtitle,
    this.isDeferred = false,
    this.isDestructive = false,
  });

  final IconData? leadingIcon;
  final String label;
  final String? subtitle;
  final bool isDeferred;
  final bool isDestructive;
  final Future<void> Function(T value) onMutate;
}

/// Base state for [SettingsRowBase] subclasses.
abstract class SettingsRowBaseState<T, W extends SettingsRowBase<T>>
    extends ConsumerState<W> {
  MutationState<void> _mutationState = MutationState.idle();
  Timer? _resetTimer;

  bool get isDisabled => widget.isDeferred && !isDeveloperMode(ref);

  Widget buildTrailing(BuildContext context);

  void onMutationError() {}

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _mutationState = MutationState.idle());
    });
  }

  /// Runs [onMutate]; updates [MutationState] (loading → idle/success or error).
  /// Trailing UI reacts to state (base shows spinner when loading).
  Future<void> executeMutation(T value) async {
    if (_mutationState.isLoading || isDisabled) return;
    setState(() => _mutationState = MutationState.loading());
    try {
      await widget.onMutate(value);
      if (mounted) setState(() => _mutationState = MutationState.idle());
    } catch (e, st) {
      AppLogger.warning(
        'Settings row mutate failed',
        error: e,
        stackTrace: st,
        tag: 'SettingsRowBase',
      );
      onMutationError();
      if (mounted) {
        setState(() => _mutationState = MutationState.error(e, st));
        ref.read(notificationServiceProvider).error(e.toString());
        _scheduleReset();
      }
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final AppSpacing spacing = context.spacing;

    final Widget trailing;
    if (widget.isDeferred && !isDeveloperMode(ref)) {
      trailing = TintedChip(
        color: colorScheme.tertiary,
        icon: Icons.schedule_rounded,
        label: 'Coming Soon',
      );
    } else {
      trailing = _mutationState.when(
        idle: () => buildTrailing(context),
        loading: () => const CupertinoActivityIndicator(radius: 10),
        success: (_) => buildTrailing(context),
        error: (_, __) => buildTrailing(context),
      );
    }

    final Color? labelColor = widget.isDestructive ? colorScheme.error : null;
    final Color? iconColor = widget.isDestructive
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    Widget row = Padding(
      padding: spacing.contentPadding,
      child: Row(
        children: <Widget>[
          if (widget.leadingIcon != null) ...<Widget>[
            Icon(widget.leadingIcon!, size: 20, color: iconColor),
            spacing.itemGap,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (widget.subtitle != null) ...<Widget>[
                  spacing.tightGap,
                  Text(
                    widget.subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );

    if (isDisabled) {
      row = Opacity(opacity: 0.4, child: IgnorePointer(child: row));
    }

    return row;
  }
}
