import 'package:diohub/common/bottom_sheet/paginated_select_sheet.dart';
import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/view/issues_pulls/widgets/suggested_reviewers_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sheet to request reviews from collaborators on a PR.
/// Uses [PaginatedSelectSheet] with assignable users; excludes the PR author.
/// When [suggestedReviewers] is provided, shows a "Suggested" section via [headerBuilder].
class ReviewRequestSheet extends ConsumerWidget {
  const ReviewRequestSheet({
    super.key,
    required this.pullRef,
    this.initialReviewerIds,
    this.authorId,
    this.authorLogin,
    this.suggestedReviewers,
    this.scrollController,
  });

  final PullRequestRef pullRef;
  final Set<String>? initialReviewerIds;
  final String? authorId;
  final String? authorLogin;
  final List<SuggestedReviewerData>? suggestedReviewers;
  final ScrollController? scrollController;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final RepoRef repoRef = pullRef.repo;
    final String? authorId = this.authorId;
    final String? authorLogin = this.authorLogin;
    final List<SuggestedReviewerData> suggested =
        suggestedReviewers ?? <SuggestedReviewerData>[];

    return PaginatedSelectSheet<
        AssignableUserEdge>(
      mode: SelectMode.multi,
      initialSelectedIds: initialReviewerIds ?? const {},
      applyLabel: 'Request review',
      sourceBuilder: (String? query) => CursorForwardSource<
          AssignableUserEdge>(
        fetch: ({required int first, String? after}) async {
          final r = await repoRef.collaborators(ref.read(apiClientProvider)).listAssignableUsersGQL(
            first: first,
            after: after,
            query: query,
          );
          final List<AssignableUserEdge>
              items = r.items
                  .whereType<
                      AssignableUserEdge>()
                  .toList();
          return CursorPage<
              AssignableUserEdge>(
            items: items,
            hasNextPage: r.hasNextPage,
            endCursor: r.endCursor,
          );
        },
      ),
      idOf: (e) => e.node?.id ?? '',
      titleOf: (e) => e.node?.login ?? '',
      leadingOf: (BuildContext context,
              AssignableUserEdge e) =>
          ProfileTile.login(
        avatarUrl: e.node?.avatarUrl.toString() ?? '',
        userLogin: e.node?.login ?? '',
        padding: EdgeInsets.zero,
      ),
      filter: (e) {
        if (authorId == null && authorLogin == null) return true;
        final node = e.node;
        if (node == null) return false;
        if (authorId != null && node.id == authorId) return false;
        if (authorLogin != null && node.login == authorLogin) return false;
        return true;
      },
      headerBuilder:
          (Set<String> selectedIds, void Function(String id) onToggle) =>
              SuggestedReviewersSection(
        suggested: suggested,
        selectedNodeIds: selectedIds,
        onToggle: onToggle,
      ),
      scrollController: scrollController,
      onApplyMultiWithIds: (Set<String> selectedIds) async {
        await ref.read(pullDetailProvider(pullRef).notifier).requestReviews(
              selectedIds.toList(),
            );
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }
}
