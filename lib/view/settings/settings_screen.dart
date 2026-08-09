import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/home_repository_item.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/dashboard/home_top_repositories_provider.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/app_chrome/app_chrome.dart';
import 'package:diohub/view/app_chrome/global_header.dart';
import 'package:diohub/view/home/widgets/switch_account_sheet.dart';
import 'package:diohub/view/settings/md3/settings_account_states.dart';
import 'package:diohub/view/settings/md3/settings_md3_content.dart';
import 'package:diohub/view/settings/md3/settings_md3_layout.dart';
import 'package:diohub/view/settings/md3/settings_md3_navigation.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@RoutePage()
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({this.initialSection, super.key});

  final String? initialSection;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AsyncValue<AccountSession?> accountState = ref.watch(accountProvider);
    final bool accountResolved = accountState.hasValue;
    final bool accountLoading = !accountResolved && !accountState.hasError;
    final Object? accountError = !accountResolved && accountState.hasError
        ? accountState.error
        : null;
    final AccountModel? account = accountResolved
        ? accountState.value?.activeAccountModel
        : null;
    final ViewerInfo? viewerCandidate = account == null
        ? null
        : ref.watch(currentUserProvider).value;
    final ViewerInfo? viewer = viewerCandidate?.id == account?.nodeId
        ? viewerCandidate
        : null;
    final AsyncValue<List<HomeRepositoryItem>> topRepositories = account == null
        ? const AsyncData<List<HomeRepositoryItem>>(<HomeRepositoryItem>[])
        : ref.watch(
            homeTopRepositoriesProvider((
              accountKey: account.accountKey,
              login: account.username,
            )),
          );

    return AppChrome(
      title: GlobalHeaderTitle(title: context.l10n.settingsTitle),
      account: account,
      accountLoading: !accountResolved,
      topRepositories: topRepositories,
      statusEmoji: viewer?.status?.emoji,
      statusMessage: viewer?.status?.message,
      body: SettingsMd3Page(
        initialSection: initialSection,
        account: account,
        accountLoading: accountLoading,
        accountError: accountError,
        onRetryAccount: () => ref.invalidate(accountProvider),
        onSwitchContext: account == null
            ? null
            : () => SwitchAccountSheet.show(context, ref),
      ),
    );
  }
}

class SettingsMd3Page extends StatefulWidget {
  const SettingsMd3Page({
    this.initialSection,
    this.account,
    this.accountLoading = false,
    this.accountError,
    this.onRetryAccount,
    this.onSwitchContext,
    super.key,
  }) : assert(
         !accountLoading || accountError == null,
         'Account loading and error states are mutually exclusive.',
       );

  final String? initialSection;
  final AccountModel? account;
  final bool accountLoading;
  final Object? accountError;
  final VoidCallback? onRetryAccount;
  final VoidCallback? onSwitchContext;

  @override
  State<SettingsMd3Page> createState() => _SettingsMd3PageState();
}

class _SettingsMd3PageState extends State<SettingsMd3Page> {
  late SettingsDestination _selected;

  @override
  void initState() {
    super.initState();
    _selected = _initialDestination();
  }

  @override
  void didUpdateWidget(covariant final SettingsMd3Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection ||
        oldWidget.account != widget.account) {
      _selected = _initialDestination();
    }
  }

  SettingsDestination _initialDestination() {
    final SettingsDestination destination = SettingsDestination.fromPath(
      widget.initialSection,
    );
    if (widget.account == null &&
        widget.initialSection == null &&
        destination.requiresGitHubAccount) {
      return SettingsDestination.dioHubGeneral;
    }
    return destination;
  }

  void _select(final SettingsDestination destination) {
    if (destination == _selected) {
      return;
    }
    setState(() => _selected = destination);
  }

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    builder: (final BuildContext context, final BoxConstraints constraints) {
      final SettingsWindowClass windowClass = SettingsMd3Layout.windowClassFor(
        constraints.maxWidth,
      );
      return Center(
        child: ConstrainedBox(
          key: ValueKey<String>('settings-md3-${windowClass.name}'),
          constraints: const BoxConstraints(
            maxWidth: SettingsMd3Layout.contentMaxWidth,
          ),
          child: Column(
            children: <Widget>[
              _SettingsAccountHeader(
                account: widget.account,
                accountLoading: widget.accountLoading,
                accountError: widget.accountError,
                onSwitchContext: widget.onSwitchContext,
                compact: windowClass == SettingsWindowClass.compact,
              ),
              const Divider(height: 1, indent: 0, endIndent: 0),
              Expanded(
                child: widget.accountLoading || widget.accountError != null
                    ? _buildAccountBoundary(windowClass)
                    : windowClass == SettingsWindowClass.compact
                    ? _buildCompact(context, windowClass)
                    : _buildWide(context, windowClass),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildAccountBoundary(final SettingsWindowClass windowClass) {
    final Widget boundary = SettingsAccountBoundary(
      loading: widget.accountLoading,
      onRetry: widget.onRetryAccount,
    );
    if (windowClass == SettingsWindowClass.compact) {
      return boundary;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(
          key: ValueKey<String>('settings-sidebar-placeholder'),
          width: SettingsMd3Layout.navigationWidth,
        ),
        const VerticalDivider(width: 1, indent: 0, endIndent: 0),
        Expanded(child: boundary),
      ],
    );
  }

  Widget _buildCompact(
    final BuildContext context,
    final SettingsWindowClass windowClass,
  ) => CustomScrollView(
    key: const PageStorageKey<String>('settings-compact-scroll'),
    slivers: <Widget>[
      SliverPadding(
        padding: SettingsMd3Layout.pagePaddingFor(windowClass),
        sliver: SliverList.list(
          children: <Widget>[
            SettingsCompactNavigation(selected: _selected, onSelected: _select),
            const SizedBox(height: 28),
            _animatedContent(context),
          ],
        ),
      ),
    ],
  );

  Widget _buildWide(
    final BuildContext context,
    final SettingsWindowClass windowClass,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SettingsSidebar(selected: _selected, onSelected: _select),
      const VerticalDivider(width: 1, indent: 0, endIndent: 0),
      Expanded(
        child: SingleChildScrollView(
          key: PageStorageKey<String>('settings-${_selected.path}-scroll'),
          padding: SettingsMd3Layout.pagePaddingFor(windowClass),
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: SettingsMd3Layout.settingsColumnMaxWidth,
              ),
              child: _animatedContent(context),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _animatedContent(final BuildContext context) {
    final bool disableAnimations = MediaQuery.of(context).disableAnimations;
    final String destinationLabel = settingsDestinationLabel(
      context,
      _selected,
    );
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('settings-content-transition-${_selected.path}'),
      duration: disableAnimations ? Duration.zero : kContentTransitionDuration,
      curve: kContentTransitionCurve,
      tween: Tween<double>(begin: disableAnimations ? 1 : 0, end: 1),
      builder:
          (
            final BuildContext context,
            final double opacity,
            final Widget? child,
          ) => Opacity(
            opacity: opacity,
            alwaysIncludeSemantics: true,
            child: child,
          ),
      child: Semantics(
        key: const ValueKey<String>('settings-content-announcement'),
        container: true,
        explicitChildNodes: true,
        liveRegion: true,
        label: destinationLabel,
        child: SettingsDestinationContent(
          destination: _selected,
          account: widget.account,
        ),
      ),
    );
  }
}

class _SettingsAccountHeader extends StatelessWidget {
  const _SettingsAccountHeader({
    required this.account,
    required this.accountLoading,
    required this.accountError,
    required this.onSwitchContext,
    required this.compact,
  });

  final AccountModel? account;
  final bool accountLoading;
  final Object? accountError;
  final VoidCallback? onSwitchContext;
  final bool compact;

  @override
  Widget build(final BuildContext context) {
    final AccountModel? activeAccount = account;
    return Padding(
      key: const ValueKey<String>('settings-account-header'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 28,
        vertical: compact ? 16 : 24,
      ),
      child: Row(
        children: <Widget>[
          if (accountLoading)
            SizedBox.square(
              key: const ValueKey<String>('settings-account-header-loading'),
              dimension: compact ? 44 : 60,
              child: const Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (accountError != null)
            Icon(
              Icons.error_outline,
              key: const ValueKey<String>('settings-account-header-error'),
              size: compact ? 42 : 56,
            )
          else if (activeAccount == null)
            const Icon(Icons.settings_outlined, size: 42)
          else
            UserAvatar(
              avatarUrl: activeAccount.avatarUrl,
              fallbackText: activeAccount.username,
              size: compact ? 44 : 60,
            ),
          const SizedBox(width: 16),
          Expanded(
            child: accountLoading
                ? const SettingsAccountHeaderPlaceholder()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        accountError != null
                            ? context.l10n.settingsTitle
                            : activeAccount == null
                            ? context.l10n.settingsDioHubGroup
                            : '${activeAccount.displayName ?? activeAccount.username} '
                                  '(${activeAccount.username})',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        accountError != null
                            ? context.l10n.repoAccountStateLoadError
                            : activeAccount == null
                            ? context.l10n.settingsSignedOutDescription
                            : context.l10n.settingsPersonalAccount,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
          if (onSwitchContext != null)
            if (compact)
              IconButton(
                key: const ValueKey<String>('settings-switch-context-compact'),
                onPressed: onSwitchContext,
                tooltip: context.l10n.settingsSwitchContext,
                icon: const Icon(Icons.swap_horiz),
              )
            else
              OutlinedButton.icon(
                key: const ValueKey<String>('settings-switch-context-wide'),
                onPressed: onSwitchContext,
                icon: const Icon(Icons.swap_horiz),
                label: Text(context.l10n.settingsSwitchContext),
              ),
        ],
      ),
    );
  }
}
