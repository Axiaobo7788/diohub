import 'package:built_collection/built_collection.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub_graphql/queries/common/resolve_node.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/comment_edit_history.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/comment_mutations.graphql.dart';
import 'package:diohub_models/models/pagination/page_slice.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart';
import 'package:diohub/services/base/node_service.dart';

/// Service for comment nodes (IssueComment, PullRequestReviewComment, DiscussionComment).
/// Edit history, resolve createdAt, update/delete. Pin/unpin live on [RepositoryServices].
class CommentNodeService extends NodeService {
  const CommentNodeService(super.apiClient, super.nodeId);

  Future<DateTime?> resolveCreatedAt() async {
    final GQLResponse response = await gql.query(
      documentNodeQueryresolveNode,
      Variables$Query$resolveNode(id: nodeId).toJson(),
    );
    final Query$resolveNode? data = Query$resolveNode.fromJson(response.data!);
    final Query$resolveNode$node? node = data?.node;
    if (node == null) return null;
    return node.maybeWhen(
      issueComment: (final Query$resolveNode$node$$IssueComment c) =>
          c.createdAt,
      pullRequestReviewComment: (
        final Query$resolveNode$node$$PullRequestReviewComment c,
      ) =>
          c.createdAt,
      discussionComment: (final Query$resolveNode$node$$DiscussionComment c) =>
          c.createdAt,
      orElse: () => null,
    );
  }

  List<CommentEditHistoryItem> _editHistoryFromIssueComment(
    List<Query$issueCommentEditHistory$node$$IssueComment$userContentEdits$nodes?>?
        raw,
  ) {
    if (raw == null) return <CommentEditHistoryItem>[];
    return raw
        .whereType<
            Query$issueCommentEditHistory$node$$IssueComment$userContentEdits$nodes>()
        .map(
          (
            final Query$issueCommentEditHistory$node$$IssueComment$userContentEdits$nodes
                e,
          ) =>
              CommentEditHistoryItem(
            editedAt: e.editedAt,
            editorLogin: e.editor?.login,
            editorAvatarUrl: e.editor?.avatarUrl.toString(),
            diff: e.diff,
          ),
        )
        .toList();
  }

  List<CommentEditHistoryItem> _editHistoryFromPullRequestReviewComment(
    List<Query$issueCommentEditHistory$node$$PullRequestReviewComment$userContentEdits$nodes?>?
        raw,
  ) {
    if (raw == null) return <CommentEditHistoryItem>[];
    return raw
        .whereType<
            Query$issueCommentEditHistory$node$$PullRequestReviewComment$userContentEdits$nodes>()
        .map(
          (
            final Query$issueCommentEditHistory$node$$PullRequestReviewComment$userContentEdits$nodes
                e,
          ) =>
              CommentEditHistoryItem(
            editedAt: e.editedAt,
            editorLogin: e.editor?.login,
            editorAvatarUrl: e.editor?.avatarUrl.toString(),
            diff: e.diff,
          ),
        )
        .toList();
  }

  Future<List<CommentEditHistoryItem>> getEditHistory({
    final int first = 20,
    final String? after,
  }) async {
    final page = await getEditHistoryPage(first: first, after: after);
    return page.items;
  }

  Future<CursorPage<CommentEditHistoryItem>> getEditHistoryPage({
    required final int first,
    final String? after,
  }) async {
    final GQLResponse res = await gql.query(
      documentNodeQueryissueCommentEditHistory,
      Variables$Query$issueCommentEditHistory(
        id: nodeId,
        first: first,
        after: after,
      ).toJson(),
    );
    final Query$issueCommentEditHistory? data =
        Query$issueCommentEditHistory.fromJson(res.data!);
    final node = data?.node;
    if (node == null) {
      return const CursorPage<CommentEditHistoryItem>(
        items: [],
        hasNextPage: false,
      );
    }
    return node.maybeWhen(
      issueComment:
          (final Query$issueCommentEditHistory$node$$IssueComment n) {
        final edits = n.userContentEdits;
        final items = _editHistoryFromIssueComment(edits?.nodes);
        final hasMore = edits?.pageInfo.hasNextPage ?? false;
        final endCursor = edits?.pageInfo.endCursor;
        return CursorPage<CommentEditHistoryItem>(
          items: items,
          hasNextPage: hasMore,
          endCursor: endCursor,
        );
      },
      pullRequestReviewComment:
          (final Query$issueCommentEditHistory$node$$PullRequestReviewComment
              n) {
        final edits = n.userContentEdits;
        final items = _editHistoryFromPullRequestReviewComment(edits?.nodes);
        final hasMore = edits?.pageInfo.hasNextPage ?? false;
        final endCursor = edits?.pageInfo.endCursor;
        return CursorPage<CommentEditHistoryItem>(
          items: items,
          hasNextPage: hasMore,
          endCursor: endCursor,
        );
      },
      orElse: () => const CursorPage<CommentEditHistoryItem>(
        items: [],
        hasNextPage: false,
      ),
    );
  }

  Future<IssueCommentUpdate?> updateComment(final String body) async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationupdateIssueComment,
      Variables$Mutation$updateIssueComment(
        id: nodeId,
        body: body,
      ).toJson(),
    );
    final Mutation$updateIssueComment? data =
        Mutation$updateIssueComment.fromJson(res.data!);
    final Mutation$updateIssueComment$updateIssueComment$issueComment? comment =
        data?.updateIssueComment?.issueComment;
    if (comment == null) return null;
    return IssueCommentUpdate(
      id: comment.id,
      body: comment.body,
      bodyHTML: comment.bodyHTML,
      lastEditedAt: comment.lastEditedAt,
    );
  }

  Future<void> deleteComment() async {
    final GQLResponse res = await gql.mutation(
      documentNodeMutationdeleteIssueComment,
      Variables$Mutation$deleteIssueComment(id: nodeId).toJson(),
    );
    Mutation$deleteIssueComment.fromJson(res.data!);
  }
}
