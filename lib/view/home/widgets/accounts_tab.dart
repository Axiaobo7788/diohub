import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/common/widgets/account_tile.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Sliver form of accounts list for use inside the shell's scroll view.
/// Use [AccountsTab] for a full-screen scroll view (e.g. standalone route).
class AccountsTabSlivers extends ConsumerWidget {
  const AccountsTabSlivers({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<AccountSession?> state = ref.watch(accountProvider);

    if (state.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: const CenteredSpinner(),
      );
    }

    if (state.hasError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: context.spacing.spaciousPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: context.colorScheme.error,
                ),
                context.spacing.sectionGap,
                Text(
                  'Error loading accounts',
                  style: context.textTheme.titleMedium,
                ),
                context.spacing.itemGap,
                Text(
                  state.error.toString(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                context.spacing.spaciousGap,
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(accountProvider.notifier).loadAccounts(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final AccountSession? session = state.value;
    if (session == null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: context.spacing.spaciousPadding,
            child: Text(
              'Unable to load accounts',
              style: context.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final AccountModel? activeAccount =
        session.activeAccountModel ??
        (session.accounts.isNotEmpty ? session.accounts.first : null);
    final List<AccountModel> otherAccounts = session.accounts
        .where(
          (final AccountModel account) =>
              account.username != session.activeAccount,
        )
        .toList();

    final List<Widget> slivers = <Widget>[];

    if (session.accounts.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: context.spacing.emptyStatePadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.person_add_rounded,
                    size: 64,
                    color: context.colorScheme.onSurfaceVariant.muted,
                  ),
                  context.spacing.spaciousGap,
                  Text(
                    'No accounts yet',
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  context.spacing.itemGap,
                  Text(
                    'Add your first account to get started',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      context.router.push(AuthRoute());
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      if (activeAccount != null) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: context.spacing.sectionSpacing),
              child: Semantics(
                label:
                    'Active account: ${activeAccount.displayName ?? activeAccount.username}',
                child: _ActiveAccountCard(account: activeAccount),
              ),
            ),
          ),
        );
      }
      if (otherAccounts.isNotEmpty) {
        slivers.add(
          PinnedHeaderSliver(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 1,
                  margin: context.spacing.screenPadding,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.transparent,
                        context.colorScheme.outlineVariant.borderO,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.spacing.screenPadding.left,
                    context.spacing.contentPadding.top,
                    context.spacing.screenPadding.right,
                    context.spacing.contentPadding.bottom,
                  ),
                  child: Text(
                    'Other accounts',
                    style: context.textTheme.labelLarge?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        slivers.add(
          SliverList.builder(
            itemCount: otherAccounts.length,
            itemBuilder: (final BuildContext context, final int index) =>
                Padding(
                  padding: EdgeInsets.only(bottom: context.spacing.itemSpacing),
                  child: _SecondaryAccountTile(
                    ref: ref,
                    account: otherAccounts[index],
                    canSwitch: session.accounts.length > 1,
                    onRemove: () async {
                      final username = otherAccounts[index].username;
                      final bool? confirmed = await showRemoveAccountDialog(
                        context,
                        username,
                      );
                      if (confirmed == true) {
                        ref
                            .read(accountProvider.notifier)
                            .removeAccount(username);
                      }
                    },
                  ),
                ),
          ),
        );
      }
    }

    return SliverPadding(
      padding: context.spacing.listInset,
      sliver: MultiSliver(children: slivers),
    );
  }
}

class AccountsTab extends ConsumerStatefulWidget {
  const AccountsTab({super.key});

  @override
  ConsumerState<AccountsTab> createState() => AccountsTabState();
}

class AccountsTabState extends ConsumerState<AccountsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    return MultiSliver(children: const <Widget>[AccountsTabSlivers()]);
  }
}

class _ActiveAccountCard extends StatelessWidget {
  const _ActiveAccountCard({required this.account});

  final AccountModel account;

  @override
  Widget build(final BuildContext context) {
    final String hostname = account.host;
    final SurfaceStyle surfaceStyle = context.surface;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.borderO,
        borderRadius: context.radius(RadiusSize.medium),
        border: Border.all(
          color: context.colorScheme.primary.tintStrong,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Stack(
              children: <Widget>[
                ProfileTile.avatar(
                  avatarUrl: account.avatarUrl,
                  size: 64,
                  padding: EdgeInsets.zero,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: context.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colorScheme.surface,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: context.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            context.spacing.sectionGap,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    account.displayName ?? account.username,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  context.spacing.tightGap,
                  Row(
                    children: <Widget>[
                      Text(
                        '@${account.username}',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (hostname != null) ...<Widget>[
                        Text(
                          ' • ',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant.hinted,
                          ),
                        ),
                        Icon(
                          Icons.business_rounded,
                          size: 14,
                          color: context.colorScheme.onSurfaceVariant.secondary,
                        ),
                        context.spacing.tightGap,
                        Text(
                          hostname,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAccountTile extends StatelessWidget {
  const _SecondaryAccountTile({
    required this.ref,
    required this.account,
    required this.canSwitch,
    required this.onRemove,
  });

  final WidgetRef ref;
  final AccountModel account;
  final bool canSwitch;
  final VoidCallback onRemove;

  @override
  Widget build(final BuildContext context) {
    final String hostname = account.host;

    final SurfaceStyle surfaceStyle = context.surface;

    return TapFeedback(
      onTap: canSwitch
          ? () {
              ProviderScope.containerOf(
                context,
              ).read(hapticServiceProvider).lightImpact();
              ProviderScope.containerOf(
                context,
              ).read(accountProvider.notifier).switchAccount(account.username);
            }
          : null,
      onLongPress: () {
        ProviderScope.containerOf(
          context,
        ).read(hapticServiceProvider).mediumImpact();
        _showAccountActionsSheet(context);
      },
      child: Container(
        padding: EdgeInsets.only(
          left: context.spacing.screenPadding.left,
          right: context.spacing.screenPadding.right,
          top: context.spacing.contentPadding.top,
          bottom: context.spacing.contentPadding.bottom,
        ),
        child: Row(
          children: <Widget>[
            ProfileTile.avatar(
              avatarUrl: account.avatarUrl,
              size: 44,
              padding: EdgeInsets.zero,
            ),
            context.spacing.contentGap,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    account.displayName ?? account.username,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.colorScheme.onSurface.emphasized,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: <Widget>[
                      Text(
                        '@${account.username}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (hostname != null) ...<Widget>[
                        Text(
                          ' • ',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant.hinted,
                          ),
                        ),
                        Icon(
                          Icons.business_rounded,
                          size: 12,
                          color: context.colorScheme.onSurfaceVariant.muted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          hostname,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountActionsSheet(final BuildContext context) {
    AppSheet.simple<void>(
      context,
      header: AppSheetHeader.text('Account'),
      bodyBuilder: (final BuildContext context, final StateSetter setState) =>
          _AccountActionsSheet(
            ref: ref,
            account: account,
            canSwitch: canSwitch,
            onRemove: onRemove,
          ),
    );
  }
}

class _AccountActionsSheet extends StatelessWidget {
  const _AccountActionsSheet({
    required this.ref,
    required this.account,
    required this.canSwitch,
    required this.onRemove,
  });

  final WidgetRef ref;
  final AccountModel account;
  final bool canSwitch;
  final VoidCallback onRemove;

  @override
  Widget build(final BuildContext context) {
    final String hostname = account.host;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(
            left: context.spacing.screenPadding.left,
            right: context.spacing.screenPadding.right,
            top: context.spacing.contentPadding.top,
            bottom: context.spacing.contentPadding.bottom,
          ),
          child: Row(
            children: <Widget>[
              ProfileTile.avatar(
                avatarUrl: account.avatarUrl,
                size: 48,
                padding: EdgeInsets.zero,
              ),
              context.spacing.contentGap,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      account.displayName ?? account.username,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    context.spacing.tightGap,
                    Text(
                      '@${account.username}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (hostname != null) ...<Widget>[
                      context.spacing.tightGap,
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.business_rounded,
                            size: 14,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                          context.spacing.tightGap,
                          Text(
                            hostname,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (canSwitch)
          ListTile(
            leading: Icon(
              Icons.swap_horiz_rounded,
              color: context.colorScheme.onSurface,
            ),
            title: const Text('Switch to this account'),
            onTap: () {
              ProviderScope.containerOf(
                context,
              ).read(hapticServiceProvider).selectionClick();
              Navigator.of(context).pop();
              ProviderScope.containerOf(
                context,
              ).read(accountProvider.notifier).switchAccount(account.username);
            },
          ),
        ListTile(
          leading: Icon(
            Icons.person_outline_rounded,
            color: context.colorScheme.onSurface,
          ),
          title: const Text('View profile'),
          onTap: () {
            Navigator.of(context).pop();
            UserRef(login: account.username).navigate(context, ref);
          },
        ),
        ListTile(
          leading: Icon(
            Icons.delete_outline_rounded,
            color: context.colorScheme.error,
          ),
          title: Text(
            'Remove account',
            style: TextStyle(color: context.colorScheme.error),
          ),
          onTap: () {
            ProviderScope.containerOf(
              context,
            ).read(hapticServiceProvider).mediumImpact();
            Navigator.of(context).pop();
            onRemove();
          },
        ),
      ],
    );
  }
}
