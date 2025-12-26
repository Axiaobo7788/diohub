import 'package:auto_route/auto_route.dart';
import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/models/authentication/account_model.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

@RoutePage()
class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '[AccountManagementScreen] build: Building AccountManagementScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
      ),
      body: BlocBuilder<AccountBloc, AccountState>(
        builder: (BuildContext context, AccountState state) {
          debugPrint(
              '[AccountManagementScreen] BlocBuilder: State is ${state.runtimeType}');

          if (state is AccountUninitialized || state is AccountLoading) {
            debugPrint(
                '[AccountManagementScreen] BlocBuilder: Showing loading indicator');
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AccountError) {
            debugPrint(
                '[AccountManagementScreen] BlocBuilder: AccountError - ${state.message}');
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is! AccountReady) {
            debugPrint(
                '[AccountManagementScreen] BlocBuilder: State is not AccountReady, showing error');
            return const Center(child: Text('Unable to load accounts'));
          }

          debugPrint(
              '[AccountManagementScreen] BlocBuilder: AccountReady state - ${state.accounts.length} accounts, active: ${state.activeAccount}');
          for (final account in state.accounts) {
            debugPrint(
                '[AccountManagementScreen] BlocBuilder: Account - ${account.username} (${account.displayName}), isActive: ${account.username == state.activeAccount}');
          }

          // if (state.accounts.isEmpty) {
          //   debugPrint(
          //       '[AccountManagementScreen] BlocBuilder: No accounts found');
          //   return Center(
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: <Widget>[
          //         const Text('No accounts found'),
          //         const SizedBox(height: 16),
          //         ElevatedButton.icon(
          //           onPressed: () {
          //             // Use AuthScreen with callback - AuthScreen will pop itself
          //             AutoRouter.of(context).push(
          //               AuthRoute(
          //                 onAuthenticated: () {
          //                   Navigator.of(context).pop();
          //                 },
          //               ),
          //             );
          //           },
          //           icon: const Icon(Icons.add),
          //           label: const Text('Add Account'),
          //         ),
          //       ],
          //     ),
          //   );
          // }

          return Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  itemCount: state.accounts.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == state.accounts.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Use AuthScreen with callback - AuthScreen will pop itself
                            AutoRouter.of(context).push(
                              AuthRoute(
                                onAuthenticated: () {
                                  // AuthScreen handles popping, no navigation needed here
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Account'),
                        ),
                      );
                    }

                    final AccountModel account = state.accounts[index];
                    final bool isActive =
                        account.username == state.activeAccount;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: account.avatarUrl != null
                              ? NetworkImage(account.avatarUrl!)
                              : null,
                          child: account.avatarUrl == null
                              ? Text(
                                  _getInitials(account),
                                  style: const TextStyle(fontSize: 20),
                                )
                              : null,
                        ),
                        title: Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                account.displayName ?? account.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (account.isEnterprise) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.5),
                                  ),
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('@${account.username}'),
                            if (account.isEnterprise) ...[
                              const SizedBox(height: 2),
                              Text(
                                Uri.parse(account.serverUrl).host,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Added: ${DateFormat.yMMMd().format(account.addedAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        trailing: isActive
                            ? Chip(
                                label: const Text('Active'),
                                backgroundColor: Colors.green.withOpacity(0.2),
                                labelStyle:
                                    const TextStyle(color: Colors.green),
                              )
                            : PopupMenuButton<String>(
                                onSelected: (String value) {
                                  if (value == 'switch') {
                                    context
                                        .read<AccountBloc>()
                                        .add(SwitchAccount(account.username));
                                    // Navigate to LandingLoadingRoute to ensure proper reload
                                    AutoRouter.of(context)
                                        .replace(LandingLoadingRoute());
                                  } else if (value == 'remove') {
                                    _showRemoveDialog(
                                        context, account.username);
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'switch',
                                    child: Row(
                                      children: <Widget>[
                                        Icon(Icons.swap_horiz),
                                        SizedBox(width: 8),
                                        Text('Switch to this account'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'remove',
                                    child: Row(
                                      children: <Widget>[
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Remove account',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
              // Log out of all button at bottom
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLogOutAllDialog(context);
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Log Out of All Accounts',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
                foregroundColor: Colors.red,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showLogOutAllDialog(BuildContext context) {
    debugPrint(
        '[AccountManagementScreen] _showLogOutAllDialog: Showing log out all dialog');
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out of All Accounts'),
          content: const Text(
            'Are you sure you want to log out of all accounts? This will remove all accounts and clear all local data. You will need to sign in again.',
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
                debugPrint(
                    '[AccountManagementScreen] _showLogOutAllDialog: User confirmed, logging out all accounts');
                context.read<AccountBloc>().add(LogOutAll());
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Log Out of All'),
            ),
          ],
        );
      },
    );
  }
}
