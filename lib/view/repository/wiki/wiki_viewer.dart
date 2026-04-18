import 'package:auto_route/annotations.dart';
import 'package:diohub/providers/repository/wiki_providers.dart';
import 'package:diohub/view/repository/wiki/wiki_browser.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Standalone route for wiki deep links (e.g. from [WikiRef], activity feed).
/// Uses [buildWikiBrowserSlivers] with a page-level [CustomScrollView]; optional
/// [slug] is pushed after first frame so the wiki opens that page.
@RoutePage()
class WikiViewer extends ConsumerStatefulWidget {
  const WikiViewer({super.key, this.repo, this.slug});

  final RepoRef? repo;
  final String? slug;

  @override
  ConsumerState<WikiViewer> createState() => _WikiViewerState();
}

class _WikiViewerState extends ConsumerState<WikiViewer> {
  bool _initialSlugPushed = false;

  @override
  void initState() {
    super.initState();
    if (widget.slug != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pushInitialSlug());
    }
  }

  void _pushInitialSlug() {
    if (_initialSlugPushed || !mounted || widget.repo == null) return;
    final AsyncValue<WikiBrowseState> async =
        ref.read(wikiProvider(widget.repo!));
    async.whenData((WikiBrowseState state) {
      if (state.currentPage != null && state.currentPage!.slug != widget.slug) {
        ref.read(wikiProvider(widget.repo!).notifier).pushPage(widget.slug!);
        _initialSlugPushed = true;
      }
    });
  }

  @override
  Widget build(final BuildContext context) {
    if (widget.repo == null) {
      return Scaffold(
        body: Center(child: Text('Repository not specified')),
      );
    }
    final RepoRef repo = widget.repo!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Wiki'),
      ),
      body: CustomScrollView(
        slivers: buildWikiBrowserSlivers(context, ref, repo),
      ),
    );
  }
}
