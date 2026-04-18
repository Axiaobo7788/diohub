import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shows a confirmation dialog using the app's standard pattern.
///
/// Returns `true` if confirmed, `false` if cancelled, `null` if dismissed.
/// Uses [AlertDialog] for consistency with existing destructive actions.
///
/// For destructive actions, set [isDestructive] to true — the confirm
/// button will use [ColorScheme.error].
Future<bool?> showConfirmAction(
  BuildContext context, {
  required String title,
  String? explanation,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) {
  final ThemeData theme = Theme.of(context);
  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: explanation != null
            ? Padding(
                padding: context.spacing.listInset,
                child: Text(
                  explanation,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            : null,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
