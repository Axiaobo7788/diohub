import 'package:diohub/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Shows the shared confirmation used before removing every local account.
Future<bool> confirmSignOutAllAccounts(final BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (final BuildContext dialogContext) => AlertDialog(
        title: Text(context.l10n.accountSignOutAllTitle),
        content: Text(context.l10n.accountSignOutAllBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.accountSignOut),
          ),
        ],
      ),
    ) ??
    false;
