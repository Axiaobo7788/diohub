import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/settings/locale_settings.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/l10n/language_picker.dart';
import 'package:diohub/models/global_list_destination.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/models/repository_preview.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/code_browser/directory_resource.dart';
import 'package:diohub/providers/repository/repository_preview_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/providers/settings/locale_provider.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/app_chrome/app_chrome_layout.dart';
import 'package:diohub/view/app_chrome/global_account_actions.dart';
import 'package:diohub/view/app_chrome/global_account_menu.dart';
import 'package:diohub/view/app_chrome/global_header.dart';
import 'package:diohub/view/app_chrome/global_navigation_drawer.dart';
import 'package:diohub/view/home/widgets/switch_account_sheet.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool get _appChromeEditableTextHasFocus {
  final BuildContext? focusContext =
      FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) {
    return false;
  }
  return focusContext.widget is EditableText ||
      focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Matches an unmodified slash only when text input does not own focus.
///
/// Filtering in the activator (instead of returning early from the callback)
/// leaves the key event available to the focused editor.
class _AppChromeSearchActivator extends ShortcutActivator {
  const _AppChromeSearchActivator();

  static const SingleActivator _delegate = SingleActivator(
    LogicalKeyboardKey.slash,
  );

  @override
  Iterable<LogicalKeyboardKey> get triggers => _delegate.triggers;

  @override
  bool accepts(final KeyEvent event, final HardwareKeyboard state) =>
      !_appChromeEditableTextHasFocus && _delegate.accepts(event, state);

  @override
  String debugDescribeKeys() => _delegate.debugDescribeKeys();
}

/// Shared application shell for migrated MD3 pages.
///
/// It owns global navigation, search, and account actions. Page-specific
/// navigation (for example Repository tabs) is supplied through
/// [secondaryNavigation], while refresh and compatibility actions belong in
/// [pageActions].
class AppChrome extends ConsumerStatefulWidget {
  const AppChrome({
    required this.title,
    required this.body,
    required this.account,
    required this.accountLoading,
    required this.topRepositories,
    this.secondaryNavigation,
    this.pageActions = const <Widget>[],
    this.selectedNavigation,
    this.statusEmoji,
    this.statusMessage,
    this.showNotifications = true,
    this.onSignIn,
    this.onSignOut,
    this.onOpenProfileTab,
    this.onSwitchAccount,
    this.onLanguageSelected,
    this.onStagedAction,
    this.onOpenTopRepository,
    this.onOpenHome,
    this.onGlobalListDestination,
    this.onGlobalSearch,
    this.onSearchRepositories,
    super.key,
  });

  final Widget title;
  final Widget body;
  final Widget? secondaryNavigation;
  final List<Widget> pageActions;
  final AccountModel? account;
  final bool accountLoading;
  final AsyncValue<List<HomeRepositoryItem>> topRepositories;
  final GlobalNavigationDestination? selectedNavigation;
  final String? statusEmoji;
  final String? statusMessage;
  final bool showNotifications;
  final Future<void> Function()? onSignIn;
  final Future<void> Function()? onSignOut;
  final ValueChanged<String?>? onOpenProfileTab;
  final VoidCallback? onSwitchAccount;
  final ValueChanged<AppLanguage>? onLanguageSelected;
  final ValueChanged<String>? onStagedAction;
  final ValueChanged<HomeRepositoryItem>? onOpenTopRepository;
  final VoidCallback? onOpenHome;
  final ValueChanged<GlobalListDestination>? onGlobalListDestination;
  final ValueChanged<String?>? onGlobalSearch;
  final VoidCallback? onSearchRepositories;

  @override
  ConsumerState<AppChrome> createState() => _AppChromeState();
}

class _AppChromeState extends ConsumerState<AppChrome> {
  final FocusNode _shortcutFocusNode = FocusNode(
    debugLabel: 'AppChrome shortcuts',
  );
  final FocusNode _globalSearchFocusNode = FocusNode(
    debugLabel: 'AppChrome global search',
  );

  @override
  void dispose() {
    _shortcutFocusNode.dispose();
    _globalSearchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchShortcut({required final bool desktop}) {
    if (_appChromeEditableTextHasFocus) {
      return;
    }
    if (desktop) {
      _globalSearchFocusNode.requestFocus();
      return;
    }
    _openGlobalSearch();
  }

  Future<void> _signIn() async {
    final Future<void> Function()? callback = widget.onSignIn;
    if (callback != null) {
      await callback();
      return;
    }
    await context.router.push<void>(const AuthRoute());
  }

  Future<void> _signOut() async {
    final Future<void> Function()? callback = widget.onSignOut;
    if (callback != null) {
      await callback();
      return;
    }
    final bool confirmed = await confirmSignOutAllAccounts(context);
    if (confirmed) {
      await ref.read(accountProvider.notifier).logOutAll();
    }
  }

  void _openProfileTab(final String? tab) {
    final ValueChanged<String?>? callback = widget.onOpenProfileTab;
    if (callback != null) {
      callback(tab);
      return;
    }
    if (tab == 'settings' || (tab?.startsWith('settings/') ?? false)) {
      final String? section = tab == 'settings'
          ? null
          : tab!.substring('settings/'.length);
      unawaited(
        context.router.push<void>(SettingsRoute(initialSection: section)),
      );
      return;
    }
    final AccountModel? account = widget.account;
    if (account == null) {
      unawaited(_signIn());
      return;
    }
    unawaited(
      UserRef(login: account.username, tab: tab).navigate(context, ref),
    );
  }

  void _switchAccount() {
    final VoidCallback? callback = widget.onSwitchAccount;
    if (callback != null) {
      callback();
      return;
    }
    SwitchAccountSheet.show(context, ref);
  }

  void _setLanguage(final AppLanguage language) {
    final ValueChanged<AppLanguage>? callback = widget.onLanguageSelected;
    if (callback != null) {
      callback(language);
      return;
    }
    unawaited(ref.read(localeProvider.notifier).setLanguage(language));
  }

  void _showStagedAction(final String label) {
    final ValueChanged<String>? callback = widget.onStagedAction;
    if (callback != null) {
      callback(label);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.homeFeatureNotAvailable(label))),
    );
  }

  void _openHome() {
    final VoidCallback? callback = widget.onOpenHome;
    if (callback != null) {
      callback();
      return;
    }
    if (context.router.current.name == HomeRoute.name) {
      return;
    }
    unawaited(context.router.replaceAll(<PageRouteInfo>[HomeRoute()]));
  }

  void _openNavigationDestination(
    final GlobalNavigationDestination destination,
  ) {
    if (destination == GlobalNavigationDestination.home) {
      _openHome();
      return;
    }
    final GlobalListDestination listDestination = switch (destination) {
      GlobalNavigationDestination.issues => GlobalListDestination.issues,
      GlobalNavigationDestination.pullRequests =>
        GlobalListDestination.pullRequests,
      GlobalNavigationDestination.repositories =>
        GlobalListDestination.repositories,
      GlobalNavigationDestination.home => throw StateError(
        'Home is handled before list routing',
      ),
    };
    if (widget.selectedNavigation == destination) {
      return;
    }
    final ValueChanged<GlobalListDestination>? localNavigation =
        widget.onGlobalListDestination;
    if (localNavigation != null) {
      localNavigation(listDestination);
      return;
    }
    if (context.router.current.name == GlobalListsRoute.name) {
      unawaited(
        context.router.replace<void>(
          GlobalListsRoute(destination: listDestination),
        ),
      );
      return;
    }
    final PageRouteInfo route = GlobalListsRoute(destination: listDestination);
    unawaited(context.router.push<void>(route));
  }

  void _openGlobalSearch([final String? query]) {
    final ValueChanged<String?>? callback = widget.onGlobalSearch;
    if (callback != null) {
      callback(query);
      return;
    }
    final String? normalized = query?.trim();
    unawaited(
      context.router.push<void>(
        SearchRoute(
          initialQuery: normalized == null || normalized.isEmpty
              ? null
              : normalized,
        ),
      ),
    );
  }

  void _searchRepositories() {
    final VoidCallback? callback = widget.onSearchRepositories;
    if (callback != null) {
      callback();
      return;
    }
    _openGlobalSearch('type:repository');
  }

  void _openNotifications() {
    if (widget.account == null) {
      unawaited(_signIn());
      return;
    }
    if (context.router.current.name == NotificationsRoute.name) {
      return;
    }
    unawaited(context.router.push<void>(const NotificationsRoute()));
  }

  void _openTopRepository(final HomeRepositoryItem repository) {
    final ValueChanged<HomeRepositoryItem>? callback =
        widget.onOpenTopRepository;
    if (callback != null) {
      callback(repository);
      return;
    }
    final RepoRef repoRef = RepoRef(
      owner: repository.owner,
      name: repository.name,
      nodeId: repository.nodeId,
    );
    ref
        .read(repositoryPreviewProvider(repoRef).notifier)
        .seed(
          RepositoryPreview(
            fullName: repository.fullName,
            name: repository.name,
            owner: repository.owner,
            ownerAvatarUrl: repository.ownerAvatarUrl,
            isPrivate: repository.isPrivate,
            nodeId: repository.nodeId,
            defaultBranch: repository.defaultBranch,
          ),
        );
    final String? defaultBranch = repository.defaultBranch;
    if (defaultBranch != null && defaultBranch.isNotEmpty) {
      prefetchRepositoryRootDirectory(
        ref,
        repo: repoRef,
        branch: defaultBranch,
      );
    }
    ref.read(repositoryProvider(repoRef));
    unawaited(repoRef.navigate(context, ref));
  }

  @override
  Widget build(final BuildContext context) {
    final AppLanguage selectedLanguage = ref.watch(
      localeProvider.select(
        (final LocaleSettings settings) => settings.language,
      ),
    );
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final bool desktop =
            constraints.maxWidth >= AppChromeLayout.desktopBreakpoint;
        final Widget scaffold = Scaffold(
          key: const ValueKey<String>('app-chrome'),
          drawer: GlobalNavigationDrawer(
            account: widget.account,
            topRepositories: widget.topRepositories,
            selectedDestination: widget.selectedNavigation,
            onDestination: _openNavigationDestination,
            onSearchRepositories: _searchRepositories,
            onSignIn: _signIn,
            onOpenTopRepository: _openTopRepository,
            onStagedAction: _showStagedAction,
          ),
          appBar: GlobalHeader(
            desktop: desktop,
            title: widget.title,
            searchFocusNode: _globalSearchFocusNode,
            pageActions: widget.pageActions,
            onOpenGlobalSearch: _openGlobalSearch,
            onSubmitGlobalSearch: _openGlobalSearch,
            showNotifications:
                widget.showNotifications && widget.account != null,
            onNotifications: _openNotifications,
            guestAction: widget.account == null
                ? IconButton(
                    tooltip: context.l10n.languageAndRegion,
                    onPressed: () =>
                        unawaited(_showGuestLanguageDialog(selectedLanguage)),
                    icon: const Icon(Icons.translate_outlined),
                  )
                : null,
            accountMenu: GlobalAccountMenu(
              account: widget.account,
              loading: widget.accountLoading,
              language: selectedLanguage,
              compact: true,
              statusEmoji: widget.statusEmoji,
              statusMessage: widget.statusMessage,
              onSignIn: _signIn,
              onSignOut: _signOut,
              onOpenProfileTab: _openProfileTab,
              onSwitchAccount: _switchAccount,
              onLanguageSelected: _setLanguage,
              onStagedAction: _showStagedAction,
            ),
          ),
          body: widget.secondaryNavigation == null
              ? widget.body
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    widget.secondaryNavigation!,
                    const Divider(
                      key: ValueKey<String>('app-chrome-secondary-divider'),
                      height: 1,
                      indent: 0,
                      endIndent: 0,
                    ),
                    Expanded(child: widget.body),
                  ],
                ),
        );
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const _AppChromeSearchActivator(): () =>
                _handleSearchShortcut(desktop: desktop),
          },
          child: Focus(
            focusNode: _shortcutFocusNode,
            autofocus: true,
            child: scaffold,
          ),
        );
      },
    );
  }

  Future<void> _showGuestLanguageDialog(final AppLanguage current) async {
    final AppLanguage? selected = await showAppLanguageDialog(context, current);
    if (selected != null && selected != current) {
      _setLanguage(selected);
    }
  }
}
