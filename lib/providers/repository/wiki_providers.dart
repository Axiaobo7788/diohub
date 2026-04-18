import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/wiki_page.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/services/repositories/wiki_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// State for the wiki browser: stack of loaded pages and cached page list.
class WikiBrowseState {
  const WikiBrowseState({
    this.pageStack = const <WikiPage>[],
    this.pageList,
    this.isLoadingPage = false,
  });

  final List<WikiPage> pageStack;
  final List<WikiPageListItem>? pageList;
  final bool isLoadingPage;

  WikiPage? get currentPage => pageStack.isEmpty ? null : pageStack.last;

  bool get canPop => pageStack.length > 1;

  /// Titles for the breadcrumb bar (one per stack entry).
  List<String> get breadcrumbs =>
      pageStack.map((final WikiPage p) => p.title).toList();

  WikiBrowseState copyWith({
    final List<WikiPage>? pageStack,
    final List<WikiPageListItem>? pageList,
    final bool? isLoadingPage,
  }) =>
      WikiBrowseState(
        pageStack: pageStack ?? this.pageStack,
        pageList: pageList ?? this.pageList,
        isLoadingPage: isLoadingPage ?? this.isLoadingPage,
      );
}

final wikiProvider = AsyncNotifierProvider.autoDispose
    .family<WikiNotifier, WikiBrowseState, RepoRef>(
  WikiNotifier.new,
);

class WikiNotifier extends AsyncNotifier<WikiBrowseState> {
  WikiNotifier(this.arg);
  final RepoRef arg;

  late final WikiService _wikiService = arg.wiki(ref.read(apiClientProvider));

  @override
  Future<WikiBrowseState> build() async {
    keepAliveFor(ref);

    final List<WikiPageListItem> pageList =
        await _wikiService.fetchWikiPageList();

    if (pageList.isEmpty) {
      return WikiBrowseState(
          pageStack: <WikiPage>[], pageList: <WikiPageListItem>[]);
    }

    final String homeSlug = _homeSlug(pageList);
    final String rawHome = await _wikiService.fetchWikiPageContent(homeSlug);
    final String renderedHome = await _wikiService.renderWikiMarkdown(rawHome);

    final WikiPageListItem homeItem = pageList.firstWhere(
      (final WikiPageListItem e) => e.slug == homeSlug,
      orElse: () => pageList.first,
    );

    final WikiPage homePage = WikiPage(
      slug: homeSlug,
      title: homeItem.displayTitle,
      rawMarkdown: rawHome,
      renderedHtml: renderedHome,
      sha: homeItem.sha,
    );

    return WikiBrowseState(
      pageStack: <WikiPage>[homePage],
      pageList: pageList,
    );
  }

  String _homeSlug(final List<WikiPageListItem> list) {
    final List<WikiPageListItem> homeMatches = list
        .where(
          (final WikiPageListItem e) => e.name.toLowerCase() == 'home.md',
        )
        .toList();
    return homeMatches.isNotEmpty ? homeMatches.first.slug : list.first.slug;
  }

  Future<void> pushPage(final String slug) async {
    final WikiBrowseState current = state.requireValue;
    state = AsyncData(
      current.copyWith(isLoadingPage: true),
    );

    try {
      final String raw = await _wikiService.fetchWikiPageContent(slug);
      final String rendered = await _wikiService.renderWikiMarkdown(raw);

      final List<WikiPageListItem> matches = current.pageList
              ?.where((final WikiPageListItem e) => e.slug == slug)
              .toList() ??
          <WikiPageListItem>[];
      final WikiPageListItem? item = matches.isNotEmpty ? matches.first : null;
      final String title =
          item?.displayTitle ?? slug.replaceAll('-', ' ').replaceAll('_', ' ');

      final WikiPage page = WikiPage(
        slug: slug,
        title: title,
        rawMarkdown: raw,
        renderedHtml: rendered,
        sha: item?.sha ?? '',
      );

      state = AsyncData(
        current.copyWith(
          pageStack: <WikiPage>[...current.pageStack, page],
          isLoadingPage: false,
        ),
      );
    } catch (e, st) {
      AppLogger.warning(
        'Wiki push page failed',
        error: e,
        stackTrace: st,
        tag: 'WikiProviders',
      );
      state = AsyncData(
        current.copyWith(isLoadingPage: false),
      );
      rethrow;
    }
  }

  void popPage() {
    final WikiBrowseState current = state.requireValue;
    if (current.pageStack.length <= 1) return;
    state = AsyncData(
      current.copyWith(
        pageStack: current.pageStack.sublist(0, current.pageStack.length - 1),
      ),
    );
  }

  void popToPage(final int index) {
    final WikiBrowseState current = state.requireValue;
    if (index < 0 || index >= current.pageStack.length - 1) return;
    state = AsyncData(
      current.copyWith(
        pageStack: current.pageStack.sublist(0, index + 1),
      ),
    );
  }

  Future<void> refreshCurrentPage() async {
    final WikiBrowseState current = state.requireValue;
    final WikiPage? page = current.currentPage;
    if (page == null) return;

    state = AsyncData(
      current.copyWith(isLoadingPage: true),
    );

    try {
      final String raw = await _wikiService.fetchWikiPageContent(page.slug);
      final String rendered = await _wikiService.renderWikiMarkdown(raw);

      final List<WikiPage> newStack = current.pageStack.toList();
      newStack[newStack.length - 1] = page.copyWith(
        rawMarkdown: raw,
        renderedHtml: rendered,
      );

      state = AsyncData(
        current.copyWith(
          pageStack: newStack,
          isLoadingPage: false,
        ),
      );
    } catch (e, st) {
      AppLogger.warning(
        'Wiki refresh page failed',
        error: e,
        stackTrace: st,
        tag: 'WikiProviders',
      );
      state = AsyncData(
        current.copyWith(isLoadingPage: false),
      );
      rethrow;
    }
  }
}
