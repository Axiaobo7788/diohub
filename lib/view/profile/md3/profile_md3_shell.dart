import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/view/app_chrome/app_chrome.dart';
import 'package:diohub/view/app_chrome/global_header.dart';
import 'package:diohub/view/profile/md3/profile_md3_layout.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stable application and page shell for migrated Profile destinations.
class ProfileMd3Shell extends StatelessWidget {
  const ProfileMd3Shell({
    required this.login,
    required this.navigation,
    required this.body,
    required this.account,
    required this.accountLoading,
    required this.topRepositories,
    required this.onRefresh,
    this.onOpenLegacy,
    super.key,
  });

  final String login;
  final Widget navigation;
  final Widget body;
  final AccountModel? account;
  final bool accountLoading;
  final AsyncValue<List<HomeRepositoryItem>> topRepositories;
  final Future<void> Function() onRefresh;
  final VoidCallback? onOpenLegacy;

  @override
  Widget build(final BuildContext context) => AppChrome(
    account: account,
    accountLoading: accountLoading,
    topRepositories: topRepositories,
    title: GlobalHeaderTitle(title: login),
    pageActions: <Widget>[
      IconButton(
        onPressed: () => onRefresh(),
        tooltip: context.l10n.profileRefresh,
        icon: const Icon(Icons.refresh),
      ),
      if (onOpenLegacy != null)
        PopupMenuButton<_ProfileMenuAction>(
          tooltip: context.l10n.profileOptions,
          onSelected: (final _ProfileMenuAction action) {
            if (action == _ProfileMenuAction.legacy) onOpenLegacy?.call();
          },
          itemBuilder: (final BuildContext context) =>
              <PopupMenuEntry<_ProfileMenuAction>>[
                PopupMenuItem<_ProfileMenuAction>(
                  value: _ProfileMenuAction.legacy,
                  child: Text(context.l10n.profileOpenLegacyLayout),
                ),
              ],
        ),
    ],
    secondaryNavigation: navigation,
    body: LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final ProfileWindowClass windowClass = ProfileMd3Layout.windowClassFor(
          constraints.maxWidth,
        );
        return Center(
          child: ConstrainedBox(
            key: ValueKey<String>('profile-md3-${windowClass.name}'),
            constraints: const BoxConstraints(
              maxWidth: ProfileMd3Layout.contentMaxWidth,
            ),
            child: body,
          ),
        );
      },
    ),
  );
}

enum _ProfileMenuAction { legacy }
