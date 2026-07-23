import 'package:diohub/common/markdown_view/markdown_body.dart';
import 'package:diohub/common/misc/markdown_skeleton.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Displays a repository README as slivers inside the repository scroll view.
/// Keep the same state key when callers need anchor navigation.
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

class RepositoryReadmeState extends ConsumerState<RepositoryReadmeSliver> {
  final GlobalKey<SliverMarkdownBodyState> _markdownBodyKey =
      GlobalKey<SliverMarkdownBodyState>();

  void scrollToAnchor(final String anchorId) {
    _markdownBodyKey.currentState?.scrollToAnchor(anchorId);
  }

  Widget _buildSliver(final BuildContext context) => widget.readmeAsync.when(
    loading: () => SliverToBoxAdapter(
      child: Padding(
        padding: context.spacing.pagePadding,
        child: const ShimmerScope(child: MarkdownSkeleton(lineCount: 10)),
      ),
    ),
    error: (final Object error, final StackTrace stack) => SliverToBoxAdapter(
      child: Padding(
        padding: context.spacing.emptyStatePadding,
        child: Center(
          child: Text(context.l10n.repoReadmeLoadError(error.toString())),
        ),
      ),
    ),
    data: (final String? readmeHtml) {
      if (readmeHtml == null) {
        return const SliverToBoxAdapter(child: _NoReadmeWidget());
      }
      return SliverMarkdownBody(
        readmeHtml,
        key: _markdownBodyKey,
        stickyHeadings: false,
        imgSrcModifiers: createRepoMarkdownImgSrcModifiers(
          widget.repoFullName,
          widget.branch,
          ref.read(activeServerConfigProvider),
        ),
        contentPadding: context.spacing.listInset,
      );
    },
  );

  @override
  Widget build(final BuildContext context) => _buildSliver(context);
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
            context.l10n.repoNoReadme,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          context.spacing.tightGap,
          Text(
            context.l10n.repoNoReadmeBody,
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
