import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub/common/issues/lock_reason_display_name.dart';
import 'package:flutter/material.dart';

/// Shows a dialog to pick a lock reason (Off-topic, Too heated, Resolved, Spam).
/// Returns the selected [LockReason] or null if dismissed.
Future<LockReason?> showLockReasonPicker(BuildContext context) async {
  final LockReason? result = await showDialog<LockReason>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Lock reason'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: LockReason.values
                .map(
                  (LockReason r) => ListTile(
                    title: Text(lockReasonDisplayName(r)),
                    onTap: () => Navigator.of(dialogContext).pop(r),
                  ),
                )
                .toList(),
          ),
        ),
      );
    },
  );
  return result;
}
