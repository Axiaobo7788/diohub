import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub/common/nav_center/settings/settings_row_base.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A field descriptor for [SettingsCompositeSheet].
@immutable
class CompositeField {
  const CompositeField({
    required this.label,
    this.hint,
    this.initialValue = '',
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
  });

  final String label;
  final String? hint;
  final String initialValue;
  final int maxLines;
  final String? Function(String value)? validator;
  final TextInputType? keyboardType;
}

/// Settings row that opens a bottom sheet with a multi-field form.
class SettingsCompositeSheet extends SettingsRowBase<Map<String, String>> {
  const SettingsCompositeSheet({
    required super.label,
    required this.fields,
    required super.onMutate,
    super.key,
    super.leadingIcon,
    super.subtitle,
    super.isDeferred,
  });

  final List<CompositeField> fields;

  @override
  ConsumerState<SettingsCompositeSheet> createState() =>
      _SettingsCompositeSheetState();
}

class _SettingsCompositeSheetState
    extends SettingsRowBaseState<Map<String, String>, SettingsCompositeSheet> {
  @override
  Widget buildTrailing(BuildContext context) {
    return GestureDetector(
      onTap: _openSheet,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Edit',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: context.spacing.tightSpacing),
          Icon(
            Icons.edit_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _openSheet() {
    AppSheet.form<void>(
      context,
      header: AppSheetHeader.text(widget.label),
      bodyBuilder: (BuildContext context, StateSetter setState) =>
          _CompositeSheetBody(fields: widget.fields, onSave: _handleSave),
    );
  }

  Future<void> _handleSave(Map<String, String> values) async {
    await executeMutation(values);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _CompositeSheetBody extends ConsumerStatefulWidget {
  const _CompositeSheetBody({required this.fields, required this.onSave});

  final List<CompositeField> fields;
  final Future<void> Function(Map<String, String> values) onSave;

  @override
  ConsumerState<_CompositeSheetBody> createState() =>
      _CompositeSheetBodyState();
}

class _CompositeSheetBodyState extends ConsumerState<_CompositeSheetBody> {
  late final List<TextEditingController> _controllers;
  late final Map<int, String?> _errors;

  @override
  void initState() {
    super.initState();
    _controllers = widget.fields
        .map((CompositeField f) => TextEditingController(text: f.initialValue))
        .toList();
    _errors = <int, String?>{};
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;
    for (int i = 0; i < widget.fields.length; i++) {
      final String? error = widget.fields[i].validator?.call(
        _controllers[i].text.trim(),
      );
      _errors[i] = error;
      if (error != null) isValid = false;
    }
    setState(() {});
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSpacing spacing = context.spacing;
    final double radiusSmall = Theme.of(
      context,
    ).surface.radius(RadiusSize.small);

    return Padding(
      padding: spacing.sheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < widget.fields.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: spacing.itemSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.fields[i].label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: spacing.tightSpacing),
                TextField(
                  controller: _controllers[i],
                  maxLines: widget.fields[i].maxLines,
                  keyboardType: widget.fields[i].keyboardType,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.fields[i].hint,
                    isDense: true,
                    contentPadding: spacing.inputPadding,
                    errorText: _errors[i],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusSmall),
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: spacing.sectionSpacing),
          SubmitButton(
            onSubmit: () async {
              if (!_validate()) return;
              final Map<String, String> values = <String, String>{};
              for (int i = 0; i < widget.fields.length; i++) {
                values[widget.fields[i].label] = _controllers[i].text.trim();
              }
              await widget.onSave(values);
            },
            label: (bool isSubmitting) => isSubmitting
                ? CupertinoActivityIndicator(
                    radius: 10,
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                : const Text('Save'),
            onError: (Object e) {
              AppLogger.warning(
                'Composite sheet save failed',
                error: e,
                tag: 'SettingsCompositeSheet',
              );
              ref.read(notificationServiceProvider).error(e.toString());
            },
          ),
        ],
      ),
    );
  }
}
