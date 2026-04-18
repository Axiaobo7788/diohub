/// Mixin providing shared capability services and utility methods for Issue and Pull entities.
///
/// Extracts the duplicated late-final capability fields and utility methods that delegate
/// to CommentNodeService and RepositoryServices.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/capabilities/capabilities.dart';
import 'package:diohub/services/repositories/repo_services.dart';

/// Mixin for entities (Issue, PullRequest) that support multiple capabilities.
///
/// Provides shared late-final capability service fields and common utility methods.
/// Entity-specific @Lens forwarding methods remain in concrete classes.
mixin CapableEntityMixin<T extends EntityRef> {
  /// API client for making requests.
  ApiClient get apiClient;

  /// The entity reference (IssueRef or PullRequestRef).
  T get ref;

  /// Node ID for GraphQL operations.
  String get _nodeId => ref.nodeId!;

  /// Capability services (shared across Issue and PR).
  late final ReactableService reactable = ReactableService(apiClient, _nodeId);
  late final LockableService lockable = LockableService(apiClient, _nodeId);
  late final LabelableService labelable = LabelableService(apiClient, _nodeId);
  late final AssignableService assignable = AssignableService(apiClient, _nodeId);
  late final SubscribableService subscribable = SubscribableService(apiClient, _nodeId);
  late final CommentableService commentable = CommentableService(apiClient, _nodeId);
  late final MinimizableService minimizable = MinimizableService(apiClient, _nodeId);

  /// Update a comment by its node id (delegates to [CommentNodeService]).
  Future<IssueCommentUpdate?> updateCommentById(
    String commentNodeId,
    String body,
  ) =>
      CommentNodeService(apiClient, commentNodeId).updateComment(body);

  /// Delete a comment by its node id (delegates to [CommentNodeService]).
  Future<void> deleteCommentById(String commentNodeId) =>
      CommentNodeService(apiClient, commentNodeId).deleteComment();

  /// Pin an issue comment (delegates to [RepositoryServices]).
  /// Requires T to be IssueRef or PullRequestRef (which have .repo).
  Future<void> pinComment(BigInt commentId) =>
      RepositoryServices(apiClient, (ref as dynamic).repo as RepoRef).pinIssueComment(commentId);

  /// Unpin an issue comment (delegates to [RepositoryServices]).
  /// Requires T to be IssueRef or PullRequestRef (which have .repo).
  Future<void> unpinComment(BigInt commentId) =>
      RepositoryServices(apiClient, (ref as dynamic).repo as RepoRef).unpinIssueComment(commentId);
}
