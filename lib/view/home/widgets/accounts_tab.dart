import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/wrappers/app_custom_scroll_view.dart';
import 'package:diohub/models/authentication/account_model.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AccountsTab extends StatefulWidget {
  const AccountsTab({super.key});

  @override
  AccountsTabState createState() => AccountsTabState();
}

class AccountsTabState extends State<AccountsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (BuildContext context, AccountState state) {
        debugPrint('[AccountsTab] BlocBuilder: State is ${state.runtimeType}');

        if (state is AccountUninitialized || state is AccountLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AccountError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error: ${state.message}',
                style: context.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (state is! AccountReady) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Unable to load accounts',
                style: context.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AppCustomScrollView(
            slivers: <Widget>[
              if (state.accounts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_rounded,
                          size: 48,
                          color: context.colorScheme.onSurfaceVariant
                              .withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No accounts yet',
                          style: context.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first account to get started',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              SliverList.builder(
                itemCount: state.accounts.length,
                itemBuilder: (context, index) {
                  final account = state.accounts[index];
                  final isActive = account.username == state.activeAccount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Card(
                      elevation: 2,
                      shadowColor: context.colorScheme.shadow.withOpacity(0.1),
                      color: context.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isActive
                            ? BorderSide(
                                color: context.colorScheme.primary
                                    .withOpacity(0.4),
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                      child: _buildAccountItem(
                        context,
                        account,
                        isActive,
                        state.accounts.length > 1,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountItem(
    BuildContext context,
    AccountModel account,
    bool isActive,
    bool canSwitch,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: Stack(
        children: [
          ProfileTile.avatar(
            avatarUrl: account.avatarUrl,
            size: 48,
            padding: EdgeInsets.zero,
          ),
          if (isActive)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: context.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colorScheme.surface,
                    width: 2.5,
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 11,
                  color: context.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              account.displayName ?? account.username,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (account.isEnterprise) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'E',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            account.isEnterprise
                ? Text(
                    '@${account.username} • ${Uri.parse(account.serverUrl).host}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Text(
                    '@${account.username}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              'Added ${DateFormat.yMMMd().format(account.addedAt)}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      trailing: isActive
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: context.colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Active',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: context.colorScheme.error.withOpacity(0.7),
              ),
              onPressed: () {
                _showRemoveDialog(context, account.username);
              },
              tooltip: 'Remove account',
            ),
      onTap: !isActive && canSwitch
          ? () {
              context.read<AccountBloc>().add(SwitchAccount(account.username));
            }
          : null,
    );
  }

  void _showRemoveDialog(BuildContext context, String username) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Account'),
          content: Text(
            'Are you sure you want to remove $username? This will delete all local data for this account.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<AccountBloc>().add(RemoveAccount(username));
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: context.colorScheme.error,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
