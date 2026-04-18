import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/providers/developer_mode_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A toggle option for [SettingsMultiToggleGroup].
@immutable
class ToggleOption {
  const ToggleOption({
    required this.label,
    required this.value,
    required this.onMutate,
    this.subtitle,
    this.icon,
    this.isDeferred = false,
  });

  final String label;
  final bool value;
  final Future<void> Function(bool value) onMutate;
  final String? subtitle;
  final IconData? icon;
  final bool isDeferred;
}

/// Group of boolean toggles displayed as checkboxes in a vertical column.
///
/// Enforces a [minSelected] constraint — when toggling off would reduce
/// the number of selected options below [minSelected], the checkbox is
/// disabled with a tooltip.
class SettingsMultiToggleGroup extends ConsumerStatefulWidget {
  const SettingsMultiToggleGroup({
    required this.label,
    required this.toggles,
    super.key,
    this.leadingIcon,
    this.minSelected = 0,
    this.isDeferred = false,
  });

  final String label;
  final List<ToggleOption> toggles;
  final IconData? leadingIcon;
  final int minSelected;
  final bool isDeferred;

  @override
  ConsumerState<SettingsMultiToggleGroup> createState() =>
      _SettingsMultiToggleGroupState();
}

class _SettingsMultiToggleGroupState
    extends ConsumerState<SettingsMultiToggleGroup> {
  late List<bool> _localValues;
  final Set<int> _loadingIndices = <int>{};

  @override
  void initState() {
    super.initState();
    _localValues = widget.toggles.map((ToggleOption t) => t.value).toList();
  }

  @override
  void didUpdateWidget(SettingsMultiToggleGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (int i = 0; i < widget.toggles.length; i++) {
      if (i < _localValues.length &&
          !_loadingIndices.contains(i) &&
          oldWidget.toggles[i].value != widget.toggles[i].value) {
        _localValues[i] = widget.toggles[i].value;
      }
    }
    if (widget.toggles.length != _localValues.length) {
      _localValues = widget.toggles.map((ToggleOption t) => t.value).toList();
    }
  }

  int get _selectedCount => _localValues.where((bool v) => v).length;

  bool _canToggleOff(int index) {
    if (!_localValues[index]) return true;
    return _selectedCount > widget.minSelected;
  }

  bool _isOptionDisabled(int index) {
    final ToggleOption toggle = widget.toggles[index];
    final bool groupDeferred = widget.isDeferred;
    final bool optionDeferred = toggle.isDeferred;
    final bool devMode = isDeveloperMode(ref);

    if ((groupDeferred || optionDeferred) && !devMode) return true;
    if (_loadingIndices.contains(index)) return true;
    if (_localValues[index] && !_canToggleOff(index)) return true;

    return false;
  }

  Future<void> _handleToggle(int index, bool newValue) async {
    if (_isOptionDisabled(index)) return;

    final bool oldValue = _localValues[index];
    setState(() {
      _localValues[index] = newValue;
      _loadingIndices.add(index);
    });

    try {
      await widget.toggles[index].onMutate(newValue);
    } catch (e, st) {
      AppLogger.warning(
        'Settings toggle mutate failed',
        error: e,
        stackTrace: st,
        tag: 'SettingsMultiToggleGroup',
      );
      if (mounted) {
        setState(() => _localValues[index] = oldValue);
        ref.read(notificationServiceProvider).error(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loadingIndices.remove(index));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final AppSpacing spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: spacing.contentPadding,
          child: Row(
            children: <Widget>[
              if (widget.leadingIcon != null) ...<Widget>[
                Icon(
                  widget.leadingIcon!,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                spacing.itemGap,
              ],
              Text(
                widget.label,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        for (int i = 0; i < widget.toggles.length; i++)
          _buildToggleRow(context, i),
      ],
    );
  }

  Widget _buildToggleRow(BuildContext context, int index) {
    final ThemeData theme = Theme.of(context);
    final AppSpacing spacing = context.spacing;
    final ToggleOption toggle = widget.toggles[index];
    final bool disabled = _isOptionDisabled(index);
    final bool loading = _loadingIndices.contains(index);

    Widget row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.contentPadding.horizontal / 2,
        vertical: spacing.tightSpacing,
      ),
      child: Row(
        children: <Widget>[
          if (toggle.icon != null) ...<Widget>[
            Icon(
              toggle.icon!,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            spacing.compactGap,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  toggle.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (toggle.subtitle != null)
                  Text(
                    toggle.subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.secondary,
                    ),
                  ),
              ],
            ),
          ),
          if (loading)
            const CupertinoActivityIndicator(radius: 8)
          else if (toggle.isDeferred && !isDeveloperMode(ref))
            TintedChip(
              color: theme.colorScheme.tertiary,
              icon: Icons.schedule_rounded,
              label: 'Coming Soon',
            )
          else
            Checkbox(
              value: _localValues[index],
              onChanged: disabled
                  ? null
                  : (bool? v) => _handleToggle(index, v ?? false),
            ),
        ],
      ),
    );

    if (_localValues[index] && !_canToggleOff(index)) {
      row = Tooltip(
        message: 'At least ${widget.minSelected} must be selected',
        child: row,
      );
    }

    return row;
  }
}
