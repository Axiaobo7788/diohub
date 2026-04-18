import 'package:diohub/common/nav_center/settings/settings_row_base.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An option for [SettingsEnumRow].
@immutable
class EnumOption<T> {
  const EnumOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Enum selection row with [PopupMenuButton] trailing.
class SettingsEnumRow<T> extends SettingsRowBase<T> {
  const SettingsEnumRow({
    required super.label,
    required this.value,
    required this.options,
    required super.onMutate,
    super.key,
    super.leadingIcon,
    super.subtitle,
    super.isDeferred,
  });

  final T value;
  final List<EnumOption<T>> options;

  @override
  ConsumerState<SettingsEnumRow<T>> createState() => _SettingsEnumRowState<T>();
}

class _SettingsEnumRowState<T>
    extends SettingsRowBaseState<T, SettingsEnumRow<T>> {
  late T _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  @override
  void didUpdateWidget(SettingsEnumRow<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _localValue = widget.value;
    }
  }

  @override
  void onMutationError() {
    setState(() => _localValue = widget.value);
  }

  void _handleSelection(T newValue) {
    if (newValue == _localValue) return;
    setState(() => _localValue = newValue);
    executeMutation(newValue);
  }

  String get _currentLabel {
    for (final EnumOption<T> option in widget.options) {
      if (option.value == _localValue) return option.label;
    }
    return _localValue.toString();
  }

  @override
  Widget buildTrailing(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSpacing spacing = context.spacing;
    final double radiusValue = Theme.of(
      context,
    ).surface.radius(RadiusSize.medium);

    return PopupMenuButton<T>(
      onSelected: _handleSelection,
      initialValue: _localValue,
      tooltip: 'Select ${widget.label}',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusValue),
      ),
      itemBuilder: (BuildContext context) {
        return widget.options.map((EnumOption<T> option) {
          final bool isSelected = option.value == _localValue;
          return PopupMenuItem<T>(
            value: option.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (option.icon != null) ...<Widget>[
                  Icon(
                    option.icon!,
                    size: 20,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: spacing.itemSpacing),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        option.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      if (option.subtitle != null)
                        Text(
                          option.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected) ...<Widget>[
                  SizedBox(width: spacing.itemSpacing),
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _currentLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: spacing.tightSpacing),
          Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
