import 'package:diohub/common/const/app_info.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/view/app_chrome/app_chrome_layout.dart';
import 'package:flutter/material.dart';

/// The stable application header used above Home and Repository content.
class GlobalHeader extends StatelessWidget implements PreferredSizeWidget {
  const GlobalHeader({
    required this.title,
    required this.accountMenu,
    required this.onOpenGlobalSearch,
    required this.onSubmitGlobalSearch,
    required this.desktop,
    this.pageActions = const <Widget>[],
    this.showNotifications = false,
    this.onNotifications,
    this.guestAction,
    super.key,
  });

  final Widget title;
  final Widget accountMenu;
  final bool desktop;
  final List<Widget> pageActions;
  final bool showNotifications;
  final VoidCallback? onNotifications;
  final VoidCallback onOpenGlobalSearch;
  final ValueChanged<String> onSubmitGlobalSearch;
  final Widget? guestAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(final BuildContext context) => AppBar(
    key: const ValueKey<String>('global-header'),
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: Builder(
      builder: (final BuildContext context) => IconButton(
        icon: const Icon(Icons.menu),
        tooltip: context.l10n.repoOpenNavigation,
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    ),
    titleSpacing: 8,
    title: title,
    actions: <Widget>[
      if (desktop)
        SizedBox(
          width: AppChromeLayout.globalSearchWidth,
          child: SearchBar(
            constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
            elevation: const WidgetStatePropertyAll<double>(0),
            backgroundColor: WidgetStatePropertyAll<Color>(
              Theme.of(context).colorScheme.surface,
            ),
            side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            hintText: context.l10n.repoSearchGitHub,
            leading: const Icon(Icons.search, size: 20),
            onSubmitted: onSubmitGlobalSearch,
          ),
        )
      else
        IconButton(
          onPressed: onOpenGlobalSearch,
          tooltip: context.l10n.commonSearch,
          icon: const Icon(Icons.search),
        ),
      ...pageActions,
      if (showNotifications)
        IconButton(
          onPressed: onNotifications,
          tooltip: context.l10n.homeNotifications,
          icon: const Icon(Icons.inbox_outlined),
        ),
      ?guestAction,
      accountMenu,
      const SizedBox(width: 8),
    ],
  );
}

/// Common logo and contextual title arrangement for the global header.
class GlobalHeaderTitle extends StatelessWidget {
  const GlobalHeaderTitle({
    required this.title,
    this.owner,
    this.compact = false,
    this.trailing,
    super.key,
  });

  final String title;
  final String? owner;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
    builder: (final BuildContext context, final BoxConstraints constraints) {
      final String semanticTitle = owner == null ? title : '$owner / $title';

      // A compact AppBar can leave only the logo width after allocating its
      // actions. Keeping the text row in that space overflows before ellipsis
      // can apply, because the logo and gap already consume the full width.
      if (constraints.maxWidth < 96) {
        return Tooltip(
          message: semanticTitle,
          child: Semantics(
            label: semanticTitle,
            image: true,
            child: const AppLogoWidget(size: 28),
          ),
        );
      }

      final bool showOwner =
          !compact && owner != null && constraints.maxWidth >= 240;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppLogoWidget(size: 28),
          const SizedBox(width: 12),
          if (showOwner) ...<Widget>[
            Flexible(
              child: Text(owner!, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('/'),
            ),
          ],
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      );
    },
  );
}
