import 'package:diohub/common/nav_center/settings/settings_row_base.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline text field row with edit/confirm/cancel states.
///
/// Collapsed: shows current value as trailing text. Tap → enters edit mode.
/// Editing: text field expands with confirm (✓) and cancel (✗) buttons.
/// On error: shake animation on the text field + error notification.
class SettingsTextFieldRow extends SettingsRowBase<String> {
  const SettingsTextFieldRow({
    required super.label,
    required this.value,
    required super.onMutate,
    super.key,
    this.placeholder,
    this.maxLines = 1,
    super.leadingIcon,
    super.subtitle,
    super.isDeferred,
  });

  final String value;
  final String? placeholder;
  final int maxLines;

  @override
  ConsumerState<SettingsTextFieldRow> createState() =>
      _SettingsTextFieldRowState();
}

class _SettingsTextFieldRowState
    extends SettingsRowBaseState<String, SettingsTextFieldRow>
    with TickerProviderStateMixin {
  late final TextEditingController _controller;
  bool _isEditing = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shakeAnimation =
        TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0, end: -8),
            weight: 1,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: -8, end: 8),
            weight: 1,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 8, end: -4),
            weight: 1,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: -4, end: 0),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(SettingsTextFieldRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void onMutationError() {
    _controller.text = widget.value;
    _triggerShake();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _controller.text = widget.value;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _controller.text = widget.value;
    });
  }

  Future<void> _confirmEditing() async {
    final String newValue = _controller.text.trim();
    if (newValue == widget.value) {
      _cancelEditing();
      return;
    }
    await executeMutation(newValue);
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      final ThemeData theme = Theme.of(context);
      final AppSpacing spacing = context.spacing;
      final ColorScheme colorScheme = theme.colorScheme;
      final TextTheme textTheme = theme.textTheme;
      final double radiusSmall = Theme.of(
        context,
      ).surface.radius(RadiusSize.small);

      return Padding(
        padding: spacing.contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (widget.leadingIcon != null) ...<Widget>[
                  Icon(
                    widget.leadingIcon!,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
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
              ],
            ),
            SizedBox(height: spacing.tightSpacing),
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (BuildContext context, Widget? child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: TextField(
                controller: _controller,
                maxLines: widget.maxLines,
                autofocus: true,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  isDense: true,
                  contentPadding: spacing.inputPadding,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radiusSmall),
                  ),
                ),
                onSubmitted: (_) => _confirmEditing(),
              ),
            ),
            SizedBox(height: spacing.tightSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  onPressed: _confirmEditing,
                  icon: Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Confirm',
                ),
                SizedBox(width: spacing.tightSpacing),
                IconButton(
                  onPressed: _cancelEditing,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Cancel',
                ),
              ],
            ),
          ],
        ),
      );
    }

    return super.build(context);
  }

  @override
  Widget buildTrailing(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSpacing spacing = context.spacing;

    return GestureDetector(
      onTap: _startEditing,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              widget.value.isEmpty
                  ? (widget.placeholder ?? 'Tap to edit')
                  : widget.value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: widget.value.isEmpty
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          SizedBox(width: spacing.tightSpacing),
          Icon(
            Icons.edit_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
