import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/env_config.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub/models/changelog/changelog_entry.dart';
import 'package:diohub/providers/changelog/changelog_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/changelog/changelog_entry_tile.dart';
import 'package:diohub/view/changelog/changelog_version_divider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

ChangelogEntryStatus _computeEntryStatus(
  ChangelogEntry entry,
  String releaseTag,
  DateTime? currentPublishedAt,
) {
  if (releaseTag.isEmpty) return ChangelogEntryStatus.older;
  if (entry.tagName == releaseTag) return ChangelogEntryStatus.current;
  if (currentPublishedAt == null) return ChangelogEntryStatus.older;
  return entry.publishedAt.isAfter(currentPublishedAt)
      ? ChangelogEntryStatus.newer
      : ChangelogEntryStatus.older;
}

/// Paginated changelog screen showing GitHub Releases for the DioHub repo.
@RoutePage()
class ChangelogScreen extends ConsumerStatefulWidget {
  const ChangelogScreen({super.key});

  @override
  ConsumerState<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends ConsumerState<ChangelogScreen> {
  late final PaginationController<ChangelogEntry, ChangelogEntry> _controller;
  bool _dividerInserted = false;

  @override
  void initState() {
    super.initState();
    _controller = PaginationController<ChangelogEntry, ChangelogEntry>(
      source: CursorForwardSource<ChangelogEntry>(
        fetch: ({required int first, String? after}) async {
          return ref.read(changelogServiceProvider).fetchPage(
            first: first,
            after: after,
          );
        },
      ),
      idOf: (e) => e.tagName,
      pageSize: 15,
    );
    _controller.fetchForward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const releaseTag = EnvConfig.releaseTag;
    
    return Scaffold(
      appBar: AppBar(title: const Text("What's New")),
      body: CustomScrollView(
        slivers: [
          ValueListenableBuilder(
            valueListenable: _controller.state,
            builder: (context, state, _) {
              _dividerInserted = false;
              final allEntries = state.items;
              
              final currentPublishedAt = allEntries
                  .where((e) => e.tagName == releaseTag)
                  .firstOrNull
                  ?.publishedAt;

              return SliverPadding(
                padding: context.spacing.listInset,
                sliver: PaginatedSliverList<ChangelogEntry>(
                  controller: _controller,
                  itemBuilder: (context, entry, index) {
                    final status = _computeEntryStatus(
                      entry,
                      releaseTag,
                      currentPublishedAt,
                    );

                    final needsDivider = !_dividerInserted &&
                        index > 0 &&
                        releaseTag.isNotEmpty;

                    if (needsDivider) {
                      final prevEntry = allEntries[index - 1];
                      final prevStatus = _computeEntryStatus(
                        prevEntry,
                        releaseTag,
                        currentPublishedAt,
                      );
                      if (prevStatus == ChangelogEntryStatus.newer &&
                          status != ChangelogEntryStatus.newer) {
                        _dividerInserted = true;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ChangelogVersionDivider(
                              label: status == ChangelogEntryStatus.current
                                  ? 'Installed'
                                  : 'Available Updates',
                            ),
                            SizedBox(height: context.spacing.itemSpacing),
                            ChangelogEntryTile(
                              entry: entry,
                              status: status,
                            ),
                          ],
                        );
                      }
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (index > 0) SizedBox(height: context.spacing.itemSpacing),
                        ChangelogEntryTile(
                          entry: entry,
                          status: status,
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: context.spacing.pagePadding,
              child: ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('View releases on GitHub'),
                subtitle: const Text('Open in repository viewer'),
                onTap: () {
                  context.router.push(
                    RepositoryRoute(
                      repo: RepoRef(owner: 'NamanShergill', name: 'diohub'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
