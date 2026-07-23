import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/wiki_page.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/providers/repository/wiki_providers.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/view/repository/wiki/wiki_browser_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Slivers for the legacy repository shell.
///
/// The state and actions are the same as [WikiBrowser], so the legacy fallback
/// does not become a second wiki implementation while migration is ongoing.
List<Widget> buildWikiBrowserSlivers(
  final BuildContext context,
  final WidgetRef ref,
  final RepoRef repoRef,
) {
  final AsyncValue<WikiBrowseState> value = ref.watch(wikiProvider(repoRef));
  return buildWikiViewSlivers(
    context,
    value: value,
    repoRef: repoRef,
    serverConfig: ref.read(activeServerConfigProvider),
    onRetry: () => ref.invalidate(wikiProvider(repoRef)),
    onOpenPage: (final String slug) =>
        _openWikiPage(context, ref, repoRef, slug),
    onPopPage: () => ref.read(wikiProvider(repoRef).notifier).popPage(),
    onPopToPage: (final int index) =>
        ref.read(wikiProvider(repoRef).notifier).popToPage(index),
    onOpenGitHub: (final String? slug) =>
        _openWikiOnGitHub(ref.read(activeServerConfigProvider), repoRef, slug),
  );
}

/// Native wiki browser for the Repository Wiki tab and standalone deep links.
class WikiBrowser extends ConsumerStatefulWidget {
  const WikiBrowser({
    required this.repoRef,
    this.initialSlug,
    this.onRefreshReady,
    super.key,
  });

  final RepoRef repoRef;
  final String? initialSlug;
  final ValueChanged<Future<void> Function()?>? onRefreshReady;

  @override
  ConsumerState<WikiBrowser> createState() => _WikiBrowserState();
}

class _WikiBrowserState extends ConsumerState<WikiBrowser>
    with AutomaticKeepAliveClientMixin {
  bool _initialSlugPushed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      widget.onRefreshReady?.call(_refresh);
    });
  }

  @override
  void didUpdateWidget(final WikiBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repoRef != widget.repoRef ||
        oldWidget.initialSlug != widget.initialSlug) {
      _initialSlugPushed = false;
    }
  }

  @override
  void dispose() {
    widget.onRefreshReady?.call(null);
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(wikiProvider(widget.repoRef));
    await ref.read(wikiProvider(widget.repoRef).future);
  }

  void _pushInitialSlugWhenReady(final AsyncValue<WikiBrowseState> value) {
    final String? slug = widget.initialSlug;
    if (_initialSlugPushed || slug == null || !value.hasValue) {
      return;
    }
    final WikiPage? current = value.requireValue.currentPage;
    _initialSlugPushed = true;
    if (current?.slug == slug) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) {
        _openPage(slug);
      }
    });
  }

  void _openPage(final String slug) {
    unawaited(_openWikiPage(context, ref, widget.repoRef, slug));
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    final AsyncValue<WikiBrowseState> value = ref.watch(
      wikiProvider(widget.repoRef),
    );
    _pushInitialSlugWhenReady(value);
    final ServerConfig serverConfig = ref.watch(activeServerConfigProvider);
    return CustomScrollView(
      key: const PageStorageKey<String>('repository-wiki-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: buildWikiViewSlivers(
        context,
        value: value,
        repoRef: widget.repoRef,
        serverConfig: serverConfig,
        onRetry: () => ref.invalidate(wikiProvider(widget.repoRef)),
        onOpenPage: _openPage,
        onPopPage: () =>
            ref.read(wikiProvider(widget.repoRef).notifier).popPage(),
        onPopToPage: (final int index) =>
            ref.read(wikiProvider(widget.repoRef).notifier).popToPage(index),
        onOpenGitHub: (final String? slug) =>
            _openWikiOnGitHub(serverConfig, widget.repoRef, slug),
      ),
    );
  }
}

Future<void> _openWikiPage(
  final BuildContext context,
  final WidgetRef ref,
  final RepoRef repoRef,
  final String slug,
) async {
  try {
    await ref.read(wikiProvider(repoRef).notifier).pushPage(slug);
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Opening wiki page failed',
      error: error,
      stackTrace: stackTrace,
      tag: 'WikiBrowser',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.wikiPageLoadError)));
    }
  }
}

void _openWikiOnGitHub(
  final ServerConfig serverConfig,
  final RepoRef repoRef,
  final String? slug,
) {
  final Uri repositoryUrl = repoRef.webUrlFor(serverConfig);
  final String suffix = slug == null || slug.isEmpty ? '' : '/$slug';
  unawaited(
    launchUrl(repositoryUrl.replace(path: '${repositoryUrl.path}/wiki$suffix')),
  );
}
