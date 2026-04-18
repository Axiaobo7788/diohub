import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/paginated_sliver_list.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/search/trending_repos_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Content for "Trending Repositories" when global search query is empty.
/// Fetches repos pushed in the last 7 days with cursor-based load-more.
class TrendingReposContent extends ConsumerStatefulWidget {
  const TrendingReposContent({super.key});

  @override
  ConsumerState<TrendingReposContent> createState() =>
      _TrendingReposContentState();
}

class _TrendingReposContentState extends ConsumerState<TrendingReposContent> {
  static const int _pageSize = 25;

  late final PaginationController<RepoCardData, RepoCardData> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaginationController<RepoCardData, RepoCardData>(
      source: ref.read(trendingReposSourceProvider),
      idOf: (RepoCardData e) => e.id,
      pageSize: _pageSize,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final spacing = context.spacing;
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: spacing.listInset,
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: spacing.spaciousPadding,
              child: Text(
                'Search GitHub',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: spacing.listInset,
          sliver: SliverToBoxAdapter(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 24,
                  right: 16,
                  bottom: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Trending Repositories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: spacing.listInset.copyWith(
            top: 0,
            left: spacing.listInset.left + 8,
            right: spacing.listInset.right + 8,
          ),
          sliver: PaginatedSliverList<RepoCardData>(
            controller: _controller,
            itemBuilder: (BuildContext context, RepoCardData item, int index) =>
                Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BorderedContainer(
                ref: RepoRef.fromRepoCardFields(item),
                child: RepositoryCard(item),
              ),
            ),
            loadingBuilder: (BuildContext context) => Padding(
              padding: context.spacing.spaciousPadding,
              child: const Center(child: LoadingIndicator()),
            ),
            emptyBuilder: (BuildContext context) => Padding(
              padding: context.spacing.spaciousPadding,
              child: const EmptyState(message: 'No trending repositories'),
            ),
          ),
        ),
      ],
    );
  }
}
