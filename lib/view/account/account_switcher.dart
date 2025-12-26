import 'package:auto_route/auto_route.dart';
import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/models/authentication/account_model.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountSwitcher extends StatelessWidget {
  const AccountSwitcher({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (BuildContext context, AccountState state) {
        if (state is! AccountReady) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.accounts.length,
              itemBuilder: (BuildContext context, int index) {
                final AccountModel account = state.accounts[index];
                final bool isActive = account.username == state.activeAccount;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: account.avatarUrl != null
                        ? NetworkImage(account.avatarUrl!)
                        : null,
                    child: account.avatarUrl == null
                        ? Text(_getInitials(account))
                        : null,
                  ),
                  title: Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          account.displayName ?? account.username,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (account.isEnterprise) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Enterprise',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(account.username),
                      if (account.isEnterprise)
                        Text(
                          Uri.parse(account.serverUrl).host,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (isActive)
                        const Icon(Icons.check, color: Colors.green)
                      else
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _showRemoveDialog(context, account.username);
                          },
                        ),
                    ],
                  ),
                  onTap: isActive
                      ? null
                      : () {
                          context
                              .read<AccountBloc>()
                              .add(SwitchAccount(account.username));
                          onClose?.call();
                          Navigator.of(context).maybePop();
                          // Navigate to LandingLoadingRoute to ensure proper reload
                          AutoRouter.of(context).replace(LandingLoadingRoute());
                        },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add account'),
              onTap: () {
                onClose?.call();
                Navigator.of(context).maybePop();
                // Use AuthScreen with callback - AuthScreen will pop itself
                AutoRouter.of(context).push(
                  AuthRoute(
                    onAuthenticated: () {
                      // AuthScreen handles popping, no navigation needed here
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _getInitials(AccountModel account) {
    final String name = account.displayName ?? account.username;
    final List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  void _showRemoveDialog(BuildContext context, String username) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Account'),
          content: Text('Are you sure you want to remove $username?'),
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
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}

