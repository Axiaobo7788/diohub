import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/markdown_skeleton.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:sliver_tools/sliver_tools.dart';

/// Displays a repository README as slivers only for use inside the shell's [AppCustomScrollView].
/// Use the same [GlobalKey<RepositoryReadmeState>] so [scrollToAnchor] works.
class RepositoryReadmeSliver extends ConsumerStatefulWidget {
  const RepositoryReadmeSliver({
    required this.readmeAsync,
    super.key,
    this.branch,
    this.repoFullName,
  });

  final AsyncValue<String?> readmeAsync;
  final String? branch;
  final String? repoFullName;

  @override
  ConsumerState<RepositoryReadmeSliver> createState() =>
      RepositoryReadmeState();
}

class RepositoryReadmeState extends ConsumerState<RepositoryReadmeSliver>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<SliverMarkdownBodyState> _markdownBodyKey =
      GlobalKey<SliverMarkdownBodyState>();

  void scrollToAnchor(final String anchorId) {
    _markdownBodyKey.currentState?.scrollToAnchor(anchorId);
  }

  List<Widget> _buildSlivers(final BuildContext context) =>
      widget.readmeAsync.when(
        loading: () => <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: context.spacing.pagePadding,
              child: const ShimmerScope(
                child: MarkdownSkeleton(lineCount: 10),
              ),
            ),
          ),
        ],
        error: (final Object error, final StackTrace stack) => <Widget>[
          SliverFillRemaining(
            child: Center(
              child: Text('Error loading README: $error'),
            ),
          ),
        ],
        data: (final String? readmeHtml) {
          if (readmeHtml == null) {
            return const <Widget>[
              SliverFillRemaining(child: _NoReadmeWidget()),
            ];
          }
          return <Widget>[
            SliverMarkdownBody(
              readmeHtml,
              key: _markdownBodyKey,
              imgSrcModifiers: createRepoMarkdownImgSrcModifiers(
                widget.repoFullName,
                widget.branch,
                ref.read(activeServerConfigProvider),
              ),
              contentPadding: context.spacing.listInset,
            ),
          ];
        },
      );

  @override
  Widget build(final BuildContext context) {
    super.build(context);

    return MultiSliver(children: _buildSlivers(context));
  }
}

class _NoReadmeWidget extends StatelessWidget {
  const _NoReadmeWidget();

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
                color: context.colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
              context.spacing.sectionGap,
              Text(
                'No README',
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              context.spacing.tightGap,
              Text(
                "This repository doesn't have a README file.",
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
