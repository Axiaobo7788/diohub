import 'package:diohub/common/nav_center/settings/settings_row_base.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Destructive action row with type-to-confirm dialog.
///
/// The confirmation dialog includes a [TextField] where the user must type
/// a specific value to enable the confirm button.
class SettingsDestructiveTextFieldRow extends SettingsRowBase<void> {
  const SettingsDestructiveTextFieldRow({
    required super.label,
    required super.onMutate,
    required this.confirmTitle,
    required this.confirmExplanation,
    required this.confirmValue,
    super.key,
    this.confirmLabel = 'Confirm',
    this.confirmHint,
    super.leadingIcon,
    super.subtitle,
    super.isDeferred,
  }) : super(isDestructive: true);

  final String confirmTitle;
  final String confirmExplanation;
  final String confirmValue;
  final String confirmLabel;
  final String? confirmHint;

  @override
  ConsumerState<SettingsDestructiveTextFieldRow> createState() =>
      _SettingsDestructiveTextFieldRowState();
}

class _SettingsDestructiveTextFieldRowState
    extends SettingsRowBaseState<void, SettingsDestructiveTextFieldRow> {
  @override
  Widget buildTrailing(BuildContext context) {
    return GestureDetector(
      onTap: _showConfirmation,
      child: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _showConfirmation() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => _TypeToConfirmDialog(
        title: widget.confirmTitle,
        explanation: widget.confirmExplanation,
        confirmValue: widget.confirmValue,
        confirmLabel: widget.confirmLabel,
        confirmHint: widget.confirmHint,
      ),
    );

    if (confirmed == true && mounted) {
      await executeMutation(null);
    }
  }
}

class _TypeToConfirmDialog extends StatefulWidget {
  const _TypeToConfirmDialog({
    required this.title,
    required this.explanation,
    required this.confirmValue,
    required this.confirmLabel,
    this.confirmHint,
  });

  final String title;
  final String explanation;
  final String confirmValue;
  final String confirmLabel;
  final String? confirmHint;

  @override
  State<_TypeToConfirmDialog> createState() => _TypeToConfirmDialogState();
}

class _TypeToConfirmDialogState extends State<_TypeToConfirmDialog> {
  late final TextEditingController _controller;
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()
      ..addListener(() {
        final bool nowMatches = _controller.text == widget.confirmValue;
        if (nowMatches != _matches) {
          setState(() => _matches = nowMatches);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSpacing spacing = context.spacing;
    final double radiusSmall = Theme.of(
      context,
    ).surface.radius(RadiusSize.small);

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: spacing.sectionSpacing),
            child: Text(
              widget.explanation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextField(
            controller: _controller,
            autofocus: true,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.confirmHint ?? widget.confirmValue,
              isDense: true,
              contentPadding: spacing.inputPadding,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radiusSmall),
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
