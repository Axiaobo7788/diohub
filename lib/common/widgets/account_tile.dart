import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:flutter/material.dart';

import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';

/// Shared tile for an account: avatar, name, optional enterprise badge, subtitle, trailing.
/// Use in account management and account switcher.
class AccountTile extends StatelessWidget {
  const AccountTile({
    required this.account,
    required this.isActive,
    this.onTap,
    this.onRemove,
    this.showEnterpriseBadge = true,
    this.trailing,
    this.avatarSize = 36,
    this.subtitle,
    super.key,
  });

  final AccountModel account;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showEnterpriseBadge;
  final Widget? trailing;
  final double avatarSize;
  final String? subtitle;

  @override
  Widget build(final BuildContext context) {
    final String displayName = account.displayName ?? account.username;
    final String sub = subtitle ?? '@${account.username}';

    return ListTile(
      leading: UserAvatar(
        avatarUrl: account.avatarUrl,
        size: avatarSize,
      ),
      title: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showEnterpriseBadge && !account.isDefault) ...<Widget>[
            context.spacing.itemGap,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.tintStrong,
                borderRadius: context.radius(RadiusSize.soft),
                border: Border.all(color: Colors.orange.hinted),
              ),
              child: const Text(
                'Enterprise',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: sub.isNotEmpty
          ? Text(
              sub,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.8),
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Shows the standard "Remove account?" confirmation.
/// Returns true if user confirmed, false if cancelled, null if dismissed.
/// Caller should call [AccountNotifier.removeAccount] when result is true.
Future<bool?> showRemoveAccountDialog(
  final BuildContext context,
  final String username,
) =>
    showConfirmAction(
      context,
      title: 'Remove $username?',
      explanation:
          'This will delete all local data for this account. You can add it again later.',
      confirmLabel: 'Remove',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
