import 'package:auto_route/auto_route.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/widgets/expandable_option_list_widget.dart'
    as option_list;
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet to switch account or add a new one.
class SwitchAccountSheet {
  SwitchAccountSheet._();

  /// Shows the sheet.
  static void show(BuildContext context, WidgetRef ref) {
    AppSheet.simple<void>(
      context,
      header: AppSheetHeader.text('Switch Account'),
      bodyBuilder: (BuildContext context, StateSetter setState) => Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          final session = ref.watch(accountProvider).value;
          if (session == null || session.accounts.isEmpty) {
            return Padding(
              padding: context.spacing.pagePadding,
              child: Text(
                'No accounts available',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.secondary,
                ),
              ),
            );
          }

          final List<option_list.ExpandableOption> options = session.accounts
              .map((AccountModel account) {
                final bool isActive = account.username == session.activeAccount;
                final String displayName =
                    account.displayName ?? account.username;
                final String label = account.isDefault
                    ? displayName
                    : '$displayName (${account.host})';

                return option_list.ExpandableOption(
                  leading: _buildAccountAvatar(account),
                  label: label,
                  isSelected: isActive,
                  onTap: () {
                    if (!isActive) {
                      ref
                          .read(accountProvider.notifier)
                          .switchAccount(account.username);
                    }
                    Navigator.of(context).pop();
                  },
                );
              })
              .toList();

          options.add(
            option_list.ExpandableOption(
              icon: Icons.add_rounded,
              label: 'Add account',
              isSelected: false,
              onTap: () async {
                if (!context.mounted) return;
                AutoRouter.of(context).push(AuthRoute());
                Navigator.of(context).pop();
              },
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: option_list.ExpandableOptionListWidget(
              options: options,
              onCollapse: () => Navigator.of(context).pop(),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildAccountAvatar(final AccountModel account) {
  return UserAvatar(avatarUrl: account.avatarUrl, size: 24);
}
