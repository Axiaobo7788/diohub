import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/cards/commit_card.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/models/commits/commit_list_item_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/code_browser/file_history_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// History tab: paginated commit list from [fileHistoryProvider]; tap → [CommitInfoRoute].
class FileViewerHistoryTab extends ConsumerWidget {
  const FileViewerHistoryTab({
    required this.repoRef,
    required this.branch,
    required this.filePath,
    super.key,
  });

  final RepoRef repoRef;
  final String filePath;
  final String branch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FileHistoryKey key = (
      repo: repoRef,
      branch: branch,
      path: filePath,
    );
    final controller = ref.watch(fileHistoryProvider(key));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: context.spacing.screenPadding,
          sliver: PaginatedSliverList<CommitListItemModel>(
            controller: controller,
            loadingBuilder: (_) => const Center(child: LoadingIndicator()),
            errorBuilder: (_, err, retry) => Center(
              child: Padding(
                padding: context.spacing.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to load history: $err',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    context.spacing.sectionGap,
                    FilledButton(
                      onPressed: retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            emptyBuilder: (_) => Center(
              child: Text(
                'No commit history for this file',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            itemBuilder:
                (BuildContext context, CommitListItemModel model, int index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.router.push(
                      CommitInfoRoute(
                        commitRef: CommitRef(repo: repoRef, oid: model.sha),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.all(context.spacing.itemSpacing),
                      child: CommitCard(data: model),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
