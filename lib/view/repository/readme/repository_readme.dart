import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/provider_loading_progress_wrapper.dart';
import 'package:diohub/common/wrappers/scroll_to_top_wrapper.dart';
import 'package:diohub/providers/repository/branch_provider.dart';
import 'package:diohub/providers/repository/readme_provider.dart';
import 'package:diohub/providers/repository/repository_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scroll_to_top/flutter_scroll_to_top.dart';
import 'package:provider/provider.dart';

class RepositoryReadme extends StatefulWidget {
  const RepositoryReadme(
    this.repoURL, {
    super.key,
    this.onHeadingsExtracted,
    this.onScrollToAnchor,
  });

  final String? repoURL;
  final void Function(List<({String text, String id, int level})> headings)?
      onHeadingsExtracted;
  final void Function(String anchorId)? onScrollToAnchor;

  @override
  RepositoryReadmeState createState() => RepositoryReadmeState();
}

class RepositoryReadmeState extends State<RepositoryReadme>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // GlobalKey to access MarkdownBody state for scrolling to anchors
  final GlobalKey<MarkdownBodyState> _markdownBodyKey =
      GlobalKey<MarkdownBodyState>();

  // Expose scroll function
  void scrollToAnchor(String anchorId) {
    if (_markdownBodyKey.currentState != null) {
      _markdownBodyKey.currentState!.scrollToAnchor(anchorId);
    }
  }

  @override
  Widget build(final BuildContext context) {
    super.build(context);
    
    final SliverOverlapAbsorberHandle overlapHandle =
        NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ProviderLoadingProgressWrapper<RepoReadmeProvider>(
        loadingBuilder: (final BuildContext context) => const Padding(
          padding: EdgeInsets.only(top: 48),
          child: LoadingIndicator(),
        ),
        childBuilder:
            (final BuildContext context, final RepoReadmeProvider value) {
          final RepositoryProvider repoProvider =
              Provider.of<RepositoryProvider>(context);

          return ScrollToTopWrapper(
            builder: (
              final BuildContext context,
              final ScrollViewProperties properties,
            ) =>
                CustomScrollView(
              slivers: [
                SliverOverlapInjector(handle: overlapHandle),
                SliverToBoxAdapter(
                  child: MarkdownRenderAPI(
                    value.data!.content!,
                    markdownBodyKey: _markdownBodyKey,
                    repoContext: repoProvider.data.nameWithOwner,
                    branch: Provider.of<RepoBranchProvider>(context).currentSHA,
                    onHeadingsExtracted: (headings) {
                      // Pass headings to parent callback
                      widget.onHeadingsExtracted?.call(headings);
                    },
                    onScrollToAnchor: widget.onScrollToAnchor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
