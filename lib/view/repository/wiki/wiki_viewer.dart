import 'package:auto_route/annotations.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/providers/repository/wiki_providers.dart';
import 'package:diohub/view/repository/md3/repository_context_chrome.dart';
import 'package:diohub/view/repository/md3/repository_navigation.dart';
import 'package:diohub/view/repository/wiki/wiki_browser.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Standalone route for wiki deep links (e.g. from [WikiRef], activity feed).
/// It shares the repository chrome used by Code, Issues, and pull requests;
/// [slug] opens the requested wiki page after the page index is available.
@RoutePage()
class WikiViewer extends ConsumerWidget {
  const WikiViewer({super.key, this.repo, this.slug});

  final RepoRef? repo;
  final String? slug;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    if (repo == null) {
      return Scaffold(body: Center(child: Text(context.l10n.repoUnavailable)));
    }
    final RepoRef repository = repo!;
    return RepositoryContextChrome(
      repoRef: repository,
      selectedDestination: RepositoryNavigationDestination.wiki,
      onRefresh: () => ref.invalidate(wikiProvider(repository)),
      body: WikiBrowser(repoRef: repository, initialSlug: slug),
    );
  }
}
