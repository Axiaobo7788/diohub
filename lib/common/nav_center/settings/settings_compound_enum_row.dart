import 'package:diohub/common/nav_center/settings/settings_enum_row.dart';
import 'package:diohub/common/nav_center/settings/settings_row_base.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A compound value of two paired enum selections.
@immutable
class CompoundValue<A, B> {
  const CompoundValue(this.first, this.second);
  final A first;
  final B second;
}

/// Paired enum selection row with two [PopupMenuButton]s side-by-side.
class SettingsCompoundEnumRow<A, B>
    extends SettingsRowBase<CompoundValue<A, B>> {
  const SettingsCompoundEnumRow({
    required super.label,
    required this.firstValue,
    required this.firstOptions,
    required this.firstLabel,
    required this.secondValue,
    required this.secondOptions,
    required this.secondLabel,
    required super.onMutate,
    super.key,
    super.leadingIcon,
    super.subtitle,
    super.isDeferred,
  });

  final A firstValue;
  final List<EnumOption<A>> firstOptions;
  final String firstLabel;

  final B secondValue;
  final List<EnumOption<B>> secondOptions;
  final String secondLabel;

  @override
  ConsumerState<SettingsCompoundEnumRow<A, B>> createState() =>
      _SettingsCompoundEnumRowState<A, B>();
}

class _SettingsCompoundEnumRowState<A, B>
    extends
        SettingsRowBaseState<
          CompoundValue<A, B>,
          SettingsCompoundEnumRow<A, B>
        > {
  late A _localFirst;
  late B _localSecond;

  @override
  void initState() {
    super.initState();
    _localFirst = widget.firstValue;
    _localSecond = widget.secondValue;
  }

  @override
  void didUpdateWidget(SettingsCompoundEnumRow<A, B> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firstValue != widget.firstValue) {
      _localFirst = widget.firstValue;
    }
    if (oldWidget.secondValue != widget.secondValue) {
      _localSecond = widget.secondValue;
    }
  }

  @override
  void onMutationError() {
    setState(() {
      _localFirst = widget.firstValue;
      _localSecond = widget.secondValue;
    });
  }

  void _handleFirstChanged(A value) {
    setState(() => _localFirst = value);
    executeMutation(CompoundValue<A, B>(_localFirst, _localSecond));
  }

  void _handleSecondChanged(B value) {
    setState(() => _localSecond = value);
    executeMutation(CompoundValue<A, B>(_localFirst, _localSecond));
  }

  Widget _buildPicker<T>({
    required T value,
    required List<EnumOption<T>> options,
    required String label,
    required ValueChanged<T> onChanged,
  }) {
    final ThemeData theme = Theme.of(context);
    final AppSpacing spacing = context.spacing;
    final double radiusSmall = Theme.of(
      context,
    ).surface.radius(RadiusSize.small);
    final double radiusMedium = Theme.of(
      context,
    ).surface.radius(RadiusSize.medium);

    EnumOption<T>? current;
    for (final EnumOption<T> o in options) {
      if (o.value == value) {
        current = o;
        break;
      }
    }

    return PopupMenuButton<T>(
      onSelected: onChanged,
      initialValue: value,
      tooltip: label,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      itemBuilder: (BuildContext context) {
        return options.map((EnumOption<T> option) {
          final bool isSelected = option.value == value;
          return PopupMenuItem<T>(
            value: option.value,
            child: Text(
              option.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: spacing.chipPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radiusSmall),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              current?.label ?? value.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: spacing.tightSpacing),
            Icon(
              Icons.expand_more_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildTrailing(BuildContext context) {
    final AppSpacing spacing = context.spacing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildPicker<A>(
          value: _localFirst,
          options: widget.firstOptions,
          label: widget.firstLabel,
          onChanged: _handleFirstChanged,
        ),
        SizedBox(width: spacing.tightSpacing),
        _buildPicker<B>(
          value: _localSecond,
          options: widget.secondOptions,
          label: widget.secondLabel,
          onChanged: _handleSecondChanged,
        ),
      ],
    );
  }
}
