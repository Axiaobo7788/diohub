import 'package:diohub/common/nav_center/settings/settings_row_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Boolean toggle row with an adaptive switch (Cupertino on iOS/macOS, Material elsewhere).
///
/// Optimistic: local value updates immediately on tap. If the mutation
/// fails, the switch reverts to its previous position.
class SettingsToggleRow extends SettingsRowBase<bool> {
  const SettingsToggleRow({
    required super.label,
    required this.value,
    required super.onMutate,
    super.key,
    super.leadingIcon,
    super.subtitle,
    super.isDeferred,
    super.isDestructive,
  });

  final bool value;

  @override
  ConsumerState<SettingsToggleRow> createState() => _SettingsToggleRowState();
}

class _SettingsToggleRowState
    extends SettingsRowBaseState<bool, SettingsToggleRow> {
  late bool _localValue;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  @override
  void didUpdateWidget(SettingsToggleRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _localValue = widget.value;
    }
  }

  @override
  void onMutationError() {
    setState(() => _localValue = widget.value);
  }

  @override
  Widget buildTrailing(BuildContext context) {
    return Switch.adaptive(
      value: _localValue,
      onChanged: (bool newValue) {
        setState(() => _localValue = newValue);
        executeMutation(newValue);
      },
    );
  }
}
