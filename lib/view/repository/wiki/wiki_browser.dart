import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/markdown_skeleton.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/common/wrappers/sticky_glass_header.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/wiki_page.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/providers/repository/wiki_providers.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:url_launcher/url_launcher.dart';

bool _isWikiLink(final String href, final RepoRef repoRef) {
  try {
    final Uri uri = Uri.parse(href);
    final List<String> segments = uri.pathSegments;
    if (segments.length >= 3 &&
        segments.contains('wiki') &&
        segments.indexOf('wiki') < segments.length - 1) {
      final int wikiIdx = segments.indexOf('wiki');
      return segments[0] == repoRef.owner &&
          segments[1] == repoRef.name &&
          wikiIdx == 2;
    }
  } catch (e, st) {
    AppLogger.warning(
      'Parsing wiki link href failed',
      error: e,
      stackTrace: st,
      tag: 'WikiBrowser',
    );
  }
  return false;
}

String? _slugFromWikiLink(final String href) {
  try {
    final Uri uri = Uri.parse(href);
    final List<String> segments = uri.pathSegments;
    final int wikiIdx = segments.indexOf('wiki');
    if (wikiIdx >= 0 && wikiIdx < segments.length - 1) {
      return segments.sublist(wikiIdx + 1).join('/');
    }
  } catch (e, st) {
    AppLogger.warning(
      'Extracting slug from wiki link failed',
      error: e,
      stackTrace: st,
      tag: 'WikiBrowser',
    );
  }
  return null;
}

/// Slivers for the Wiki tab for use inside the shell's scroll view.
List<Widget> buildWikiBrowserSlivers(
  final BuildContext context,
  final WidgetRef ref,
  final RepoRef repoRef,
) {
  final AsyncValue<WikiBrowseState> wikiAsync =
      ref.watch(wikiProvider(repoRef));

  return wikiAsync.when(
    loading: () => <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: context.spacing.pagePadding,
          child: const ShimmerScope(
            child: MarkdownSkeleton(lineCount: 12),
          ),
        ),
      ),
    ],
    error: (Object error, StackTrace stack) => <Widget>[
      SliverFillRemaining(
        child: CenteredError('Error loading wiki: $error'),
      ),
    ],
    data: (WikiBrowseState state) {
      if (state.pageStack.isEmpty) {
        return <Widget>[
          SliverFillRemaining(
            child: _NoWikiWidget(
              repoRef: repoRef,
              serverConfig: ref.read(activeServerConfigProvider),
              onRetry: () => ref.invalidate(wikiProvider(repoRef)),
            ),
          ),
        ];
      }

      final WikiPage? current = state.currentPage;
      final List<Widget> slivers = <Widget>[];

      if (state.breadcrumbs.length > 1) {
        slivers.add(
          StickyGlassHeader(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.screenPadding.horizontal / 2,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(
                  state.breadcrumbs.length,
                  (int i) {
                    final String title = state.breadcrumbs[i];
                    final bool isLast = i == state.breadcrumbs.length - 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: isLast
                            ? null
                            : () => ref
                                .read(wikiProvider(repoRef).notifier)
                                .popToPage(i),
                        child: Text(
                          title,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isLast
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                    fontWeight: isLast
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }

      if (state.isLoadingPage && current != null) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: context.spacing.pagePadding,
              child: const Center(
                child: SizedBox(
                child: const ButtonSpinner(size: 24),
                ),
              ),
            ),
          ),
        );
      }

      if (current != null && !state.isLoadingPage) {
        slivers.add(
          SliverMarkdownBody(
            current.renderedHtml,
            imgSrcModifiers:
                repoRef.wikiImgModifiers(ref.read(activeServerConfigProvider)),
            contentPadding: context.spacing.listInset,
            onTapLink: (String href) {
              if (_isWikiLink(href, repoRef)) {
                final String? slug = _slugFromWikiLink(href);
                if (slug != null) {
                  ref.read(wikiProvider(repoRef).notifier).pushPage(slug);
                  return true;
                }
              }
              return false;
            },
          ),
        );
      }

      if (slivers.isEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: context.spacing.pagePadding,
              child: const ShimmerScope(
                child: MarkdownSkeleton(lineCount: 8),
              ),
            ),
          ),
        );
      }

      return slivers;
    },
  );
}

/// Native wiki browser for the repository Wiki tab.
/// Loads the Home page by default; supports stack-based navigation with breadcrumbs.
class WikiBrowser extends ConsumerStatefulWidget {
  const WikiBrowser({
    required this.repoRef,
    this.initialSlug,
    super.key,
  });

  final RepoRef repoRef;
  final String? initialSlug;

  @override
  ConsumerState<WikiBrowser> createState() => _WikiBrowserState();
}

class _WikiBrowserState extends ConsumerState<WikiBrowser>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _initialSlugPushed = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSlug != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pushInitialSlug());
    }
  }

  void _pushInitialSlug() {
    if (_initialSlugPushed || !mounted) return;
    final AsyncValue<WikiBrowseState> async =
        ref.read(wikiProvider(widget.repoRef));
    async.whenData((WikiBrowseState state) {
      if (state.currentPage != null &&
          state.currentPage!.slug != widget.initialSlug) {
        ref
            .read(wikiProvider(widget.repoRef).notifier)
            .pushPage(widget.initialSlug!);
        _initialSlugPushed = true;
      }
    });
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    return MultiSliver(
      children: buildWikiBrowserSlivers(context, ref, widget.repoRef),
    );
  }
}

class _NoWikiWidget extends StatelessWidget {
  const _NoWikiWidget({
    required this.repoRef,
    required this.serverConfig,
    required this.onRetry,
  });

  final RepoRef repoRef;
  final ServerConfig serverConfig;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: context.spacing.emptyStatePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Octicons.book,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.4),
              ),
              context.spacing.sectionGap,
              Text(
                'No wiki pages',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              context.spacing.tightGap,
              Text(
                "This repository doesn't have a wiki yet.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              context.spacing.sectionGap,
              TextButton(
                onPressed: () {
                  final uri = repoRef.webUrlFor(serverConfig);
                  launchUrl(Uri.parse('${uri.origin}${uri.path}/wiki'));
                },
                child: const Text('Create wiki on GitHub'),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}
