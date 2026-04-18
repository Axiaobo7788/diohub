import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// A button that manages its own loading state for async onPressed callbacks.
///
/// While [onSubmit] is running:
/// - The button is disabled (prevents double-tap)
/// - Icon becomes a progress indicator; [label] is called with `true`
/// - On error: calls [onError] (or rethrows)
/// - On success: calls [onSuccess]
///
/// Usage:
/// ```dart
/// SubmitButton(
///   onSubmit: () => ref.read(provider.notifier).createBranch(...),
///   onSuccess: () => Navigator.pop(context),
///   onError: (e) => setState(() => _error = e.toString()),
///   icon: Icon(Icons.add),
///   label: (isSubmitting) => Text(isSubmitting ? 'Creating…' : 'Create'),
/// )
/// ```
class SubmitButton extends StatefulWidget {
  const SubmitButton({
    required this.onSubmit,
    required this.label,
    this.onSuccess,
    this.onError,
    this.icon,
    this.variant = SubmitButtonVariant.filled,
    this.enabled = true,
    super.key,
  });

  /// Async callback. Button disables while this is running.
  final Future<void> Function() onSubmit;

  /// Called after [onSubmit] completes without error.
  final VoidCallback? onSuccess;

  /// Called with the error if [onSubmit] throws. If null, error is rethrown.
  final void Function(Object error)? onError;

  /// Builds the label. [isSubmitting] is true while [onSubmit] is running.
  final Widget Function(bool isSubmitting) label;
  final Widget? icon;
  final SubmitButtonVariant variant;

  /// External enabled/disabled (e.g. form validation).
  final bool enabled;

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  bool _submitting = false;

  Future<void> _handleTap() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit();
      if (mounted) widget.onSuccess?.call();
    } catch (e) {
      if (mounted) {
        final fn = widget.onError;
        if (fn != null) {
          fn(e);
        } else {
          rethrow;
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = widget.enabled && !_submitting;
    final icon = _submitting ? const ButtonSpinner(size: 18) : widget.icon;
    final label = widget.label(_submitting);

    final iconWidget = icon ?? const SizedBox.shrink();
    return switch (widget.variant) {
      SubmitButtonVariant.filled => FilledButton.icon(
          onPressed: effectiveEnabled ? _handleTap : null,
          icon: iconWidget,
          label: label,
        ),
      SubmitButtonVariant.text => TextButton.icon(
          onPressed: effectiveEnabled ? _handleTap : null,
          icon: iconWidget,
          label: label,
        ),
      SubmitButtonVariant.outlined => OutlinedButton.icon(
          onPressed: effectiveEnabled ? _handleTap : null,
          icon: iconWidget,
          label: label,
        ),
      SubmitButtonVariant.tonal => FilledButton.tonal(
          onPressed: effectiveEnabled ? _handleTap : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon, context.spacing.itemGap],
              label,
            ],
          ),
        ),
    };
  }
}

enum SubmitButtonVariant { filled, text, outlined, tonal }

/// A [SwitchListTile] that manages its own loading state for async onChanged.
/// Disables the tile and shows loading indicator while the async callback runs.
class SubmitSwitch extends StatefulWidget {
  const SubmitSwitch({
    required this.value,
    required this.onSubmit,
    this.onSuccess,
    this.onError,
    this.title,
    this.subtitle,
    this.secondary,
    super.key,
  });

  final bool value;
  final Future<void> Function(bool value) onSubmit;
  final VoidCallback? onSuccess;
  final void Function(Object error)? onError;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;

  @override
  State<SubmitSwitch> createState() => _SubmitSwitchState();
}

class _SubmitSwitchState extends State<SubmitSwitch> {
  bool _loading = false;

  Future<void> _handleChanged(bool value) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onSubmit(value);
      if (mounted) widget.onSuccess?.call();
    } catch (e) {
      if (mounted) {
        final fn = widget.onError;
        if (fn != null) {
          fn(e);
        } else {
          rethrow;
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: widget.value,
      onChanged: _loading ? null : _handleChanged,
      title: widget.title,
      subtitle: _loading
          ? const Padding(
              padding: EdgeInsets.only(top: 4),
              child: ButtonSpinner(size: 16),
            )
          : widget.subtitle,
      secondary: widget.secondary,
    );
  }
}
