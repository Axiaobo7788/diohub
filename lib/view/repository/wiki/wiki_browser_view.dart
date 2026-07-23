import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/wiki_page.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/providers/repository/wiki_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _isWikiLink(final String href, final RepoRef repoRef) {
  try {
    final Uri uri = Uri.parse(href);
    final List<String> segments = uri.pathSegments;
    final int wikiIndex = segments.indexOf('wiki');
    return segments.length >= 4 &&
        wikiIndex == 2 &&
        segments[0] == repoRef.owner &&
        segments[1] == repoRef.name;
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Parsing wiki link href failed',
      error: error,
      stackTrace: stackTrace,
      tag: 'WikiBrowser',
    );
    return false;
  }
}

String? _slugFromWikiLink(final String href) {
  try {
    final Uri uri = Uri.parse(href);
    final List<String> segments = uri.pathSegments;
    final int wikiIndex = segments.indexOf('wiki');
    if (wikiIndex >= 0 && wikiIndex < segments.length - 1) {
      return segments.sublist(wikiIndex + 1).join('/');
    }
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Extracting slug from wiki link failed',
      error: error,
      stackTrace: stackTrace,
      tag: 'WikiBrowser',
    );
  }
  return null;
}

/// Pure wiki UI used by production and responsive widget tests.
List<Widget> buildWikiViewSlivers(
  final BuildContext context, {
  required final AsyncValue<WikiBrowseState> value,
  required final RepoRef repoRef,
  required final ServerConfig serverConfig,
  required final VoidCallback onRetry,
  required final ValueChanged<String> onOpenPage,
  required final VoidCallback onPopPage,
  required final ValueChanged<int> onPopToPage,
  required final ValueChanged<String?> onOpenGitHub,
}) {
  return value.when(
    loading: () => const <Widget>[
      SliverToBoxAdapter(child: _WikiLoadingState()),
    ],
    error: (final Object error, final StackTrace stackTrace) => <Widget>[
      SliverFillRemaining(
        hasScrollBody: false,
        child: _WikiErrorState(error: error, onRetry: onRetry),
      ),
    ],
    data: (final WikiBrowseState state) {
      if (state.pageStack.isEmpty) {
        return <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NoWikiWidget(
              onCreate: () => onOpenGitHub(null),
              onRetry: onRetry,
            ),
          ),
        ];
      }

      final WikiPage current = state.currentPage!;
      return <Widget>[
        SliverToBoxAdapter(
          child: _WikiPageHeader(
            state: state,
            current: current,
            onOpenPage: onOpenPage,
            onPopPage: onPopPage,
            onPopToPage: onPopToPage,
            onOpenGitHub: () => onOpenGitHub(current.slug),
          ),
        ),
        if (state.isLoadingPage)
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(
              key: ValueKey<String>('wiki-page-loading'),
              minHeight: 2,
            ),
          ),
        SliverMarkdownBody(
          current.renderedHtml,
          key: ValueKey<String>('wiki-page-${current.slug}'),
          imgSrcModifiers: repoRef.wikiImgModifiers(serverConfig),
          contentPadding: context.spacing.listInset,
          onTapLink: (final String href) {
            if (!_isWikiLink(href, repoRef)) {
              return false;
            }
            final String? slug = _slugFromWikiLink(href);
            if (slug == null) {
              return false;
            }
            onOpenPage(slug);
            return true;
          },
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: context.spacing.screenPadding.bottom),
        ),
      ];
    },
  );
}

class _WikiPageHeader extends StatelessWidget {
  const _WikiPageHeader({
    required this.state,
    required this.current,
    required this.onOpenPage,
    required this.onPopPage,
    required this.onPopToPage,
    required this.onOpenGitHub,
  });

  final WikiBrowseState state;
  final WikiPage current;
  final ValueChanged<String> onOpenPage;
  final VoidCallback onPopPage;
  final ValueChanged<int> onPopToPage;
  final VoidCallback onOpenGitHub;

  @override
  Widget build(final BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Padding(
      padding: context.spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder:
                (final BuildContext context, final BoxConstraints constraints) {
                  final Widget title = Semantics(
                    label: context.l10n.wikiCurrentPage(current.title),
                    header: true,
                    child: AnimatedSwitcher(
                      key: const ValueKey<String>('wiki-title-switcher'),
                      duration: reduceMotion
                          ? Duration.zero
                          : kContentTransitionDuration,
                      switchInCurve: kContentTransitionCurve,
                      switchOutCurve: kPageTransitionReverseCurve,
                      transitionBuilder:
                          (
                            final Widget child,
                            final Animation<double> animation,
                          ) => FadeTransition(opacity: animation, child: child),
                      child: Text(
                        current.title,
                        key: ValueKey<String>(current.slug),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                  final Widget actions = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _WikiPagesMenu(
                        currentSlug: current.slug,
                        pages: state.pageList ?? const <WikiPageListItem>[],
                        onOpenPage: onOpenPage,
                      ),
                      OutlinedButton.icon(
                        onPressed: onOpenGitHub,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(context.l10n.wikiOpenOnGitHub),
                      ),
                    ],
                  );
                  if (constraints.maxWidth < 680) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            if (state.canPop)
                              IconButton(
                                tooltip: context.l10n.commonBack,
                                onPressed: onPopPage,
                                icon: Icon(Icons.adaptive.arrow_back),
                              ),
                            Expanded(child: title),
                          ],
                        ),
                        const SizedBox(height: 12),
                        actions,
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      if (state.canPop)
                        IconButton(
                          tooltip: context.l10n.commonBack,
                          onPressed: onPopPage,
                          icon: Icon(Icons.adaptive.arrow_back),
                        ),
                      Expanded(child: title),
                      const SizedBox(width: 16),
                      actions,
                    ],
                  );
                },
          ),
          if (state.breadcrumbs.length > 1) ...<Widget>[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (
                    int index = 0;
                    index < state.breadcrumbs.length;
                    index++
                  ) ...<Widget>[
                    if (index > 0) const Icon(Icons.chevron_right, size: 18),
                    TextButton(
                      onPressed: index == state.breadcrumbs.length - 1
                          ? null
                          : () => onPopToPage(index),
                      child: Text(state.breadcrumbs[index]),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _WikiPagesMenu extends StatelessWidget {
  const _WikiPagesMenu({
    required this.currentSlug,
    required this.pages,
    required this.onOpenPage,
  });

  final String currentSlug;
  final List<WikiPageListItem> pages;
  final ValueChanged<String> onOpenPage;

  @override
  Widget build(final BuildContext context) {
    return MenuAnchor(
      menuChildren: <Widget>[
        for (final WikiPageListItem page in pages)
          MenuItemButton(
            leadingIcon: Icon(
              page.slug == currentSlug
                  ? Icons.check
                  : Icons.description_outlined,
            ),
            onPressed: page.slug == currentSlug
                ? null
                : () => onOpenPage(page.slug),
            child: Text(page.displayTitle),
          ),
      ],
      builder:
          (
            final BuildContext context,
            final MenuController controller,
            final Widget? child,
          ) => OutlinedButton.icon(
            onPressed: pages.isEmpty
                ? null
                : () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: Text(context.l10n.wikiPages),
          ),
    );
  }
}

class _WikiLoadingState extends StatelessWidget {
  const _WikiLoadingState();

  @override
  Widget build(final BuildContext context) {
    final Color placeholder = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: context.spacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 24),
          Container(
            width: 220,
            height: 28,
            decoration: BoxDecoration(
              color: placeholder,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 24),
          for (final double width in <double>[1, 0.92, 0.76, 0.88, 0.62])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FractionallySizedBox(
                widthFactor: width,
                child: Container(height: 16, color: placeholder),
              ),
            ),
        ],
      ),
    );
  }
}

class _WikiErrorState extends StatelessWidget {
  const _WikiErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: context.spacing.emptyStatePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.wikiLoadError,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoWikiWidget extends StatelessWidget {
  const _NoWikiWidget({required this.onCreate, required this.onRetry});

  final VoidCallback onCreate;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) {
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: context.spacing.emptyStatePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: muted.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.wikiNoPages,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.wikiNoPagesDescription,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(context.l10n.wikiCreateOnGitHub),
                ),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
