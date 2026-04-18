import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';
import 'package:diohub/common/nav_center/settings/settings_row_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Destructive action row that shows a confirmation dialog before executing.
///
/// Tap → [showConfirmAction] with title, explanation, Cancel + Confirm (destructive) buttons.
/// Confirm → calls [onMutate] with `null`.
class SettingsDestructiveRow extends SettingsRowBase<void> {
  const SettingsDestructiveRow({
    required super.label,
    required super.onMutate,
    required this.confirmTitle,
    required this.confirmExplanation,
    super.key,
    this.confirmLabel = 'Confirm',
    super.leadingIcon,
    super.subtitle,
    super.isDeferred,
  }) : super(isDestructive: true);

  final String confirmTitle;
  final String confirmExplanation;
  final String confirmLabel;

  @override
  ConsumerState<SettingsDestructiveRow> createState() =>
      _SettingsDestructiveRowState();
}

class _SettingsDestructiveRowState
    extends SettingsRowBaseState<void, SettingsDestructiveRow> {
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
    final bool? confirmed = await showConfirmAction(
      context,
      title: widget.confirmTitle,
      explanation: widget.confirmExplanation,
      confirmLabel: widget.confirmLabel,
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      await executeMutation(null);
    }
  }
}
