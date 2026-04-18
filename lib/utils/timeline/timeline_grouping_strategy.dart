import 'package:diohub/app/app_logger.dart';
import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub_graphql/queries/issues_pulls/timeline.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub/utils/compound_grouping.dart';
import 'package:diohub/utils/timeline/timeline_node_id.dart';

/// Semantic action types for issue/pull timeline events.
enum IssueTimelineSemanticAction {
  comment,
  labelChange,
  stateChange,
  review,
  commitPush,
  assigned,
  unassigned,
  milestoneChange,
  crossReference,
  other,
}

/// Type aliases for timeline grouped output.
typedef TimelineCluster = ActionCluster<IssueTimelineSemanticAction, dynamic>;
typedef TimelineCompound = Compound<IssueTimelineSemanticAction, dynamic>;
typedef TimelineActorSection
    = ActorSection<Fragment$actor, IssueTimelineSemanticAction, dynamic>;

/// Strategy that configures [CompoundGrouper] for issue/PR timelines.
///
/// The timeline is a degenerate case of the events system:
/// - **Target** is constant (everything is on the same issue/PR).
/// - **Roles** are all [CompoundRole.isolated] (no cross-action compounding).
/// - **Comments** never merge (each is its own card).
///
/// With all roles isolated, the compound layer collapses automatically:
/// each different action type gets its own single-cluster compound, while
/// same-action items still merge into clusters (first step of the decision tree).
class TimelineGroupingStrategy
    extends GroupingStrategy<dynamic, Fragment$actor, IssueTimelineSemanticAction> {
  /// [target] should be a unique identifier for the issue/PR (e.g., its URL
  /// or an integer). All timeline nodes will share this target.
  TimelineGroupingStrategy({required final Object target})
      : _constantTarget = target;
  final Object _constantTarget;

  @override
  @override
  Object? actorKeyOf(final dynamic node) => getActorFromNode(node)?.login;

  @override
  Fragment$actor actorDataOf(final dynamic node) => getActorFromNode(node)!;

  @override
  Object targetOf(final dynamic node) => _constantTarget;

  @override
  IssueTimelineSemanticAction actionOf(final dynamic node) =>
      _semanticActionForNode(node);

  @override
  CompoundRole roleOf(final IssueTimelineSemanticAction action) =>
      CompoundRole.isolated;

  @override
  bool canMergeItems(
    final dynamic a,
    final dynamic b,
    final IssueTimelineSemanticAction action,
  ) {
    // Comments never merge (each is its own card).
    if (action == IssueTimelineSemanticAction.comment) return false;
    return true;
  }

  // -----------------------------------------------------------------------
  // Helpers (moved from semantic_timeline_grouping.dart)
  // -----------------------------------------------------------------------

  /// Determines the semantic action for a timeline node.
  static IssueTimelineSemanticAction _semanticActionForNode(
      final dynamic node) {
    if (node is IssueCommentEvent) {
      return IssueTimelineSemanticAction.comment;
    }

    if (node is LabeledEvent || node is UnlabeledEvent) {
      return IssueTimelineSemanticAction.labelChange;
    }

    if (node is ClosedEvent ||
        node is ReopenedEvent ||
        node is MergedEvent ||
        node is ConvertedToDraftEvent ||
        node is ReadyForReviewEvent) {
      return IssueTimelineSemanticAction.stateChange;
    }

    if (node is TimelinePullRequestReviewEvent) {
      return IssueTimelineSemanticAction.review;
    }

    if (node is PullRequestCommitEvent) {
      return IssueTimelineSemanticAction.commitPush;
    }

    if (node is AssignedEvent) {
      return IssueTimelineSemanticAction.assigned;
    }

    if (node is UnassignedEvent) {
      return IssueTimelineSemanticAction.unassigned;
    }

    if (node is MilestonedEvent || node is DemilestonedEvent) {
      return IssueTimelineSemanticAction.milestoneChange;
    }

    if (node is CrossReferenceEvent) {
      return IssueTimelineSemanticAction.crossReference;
    }

    return IssueTimelineSemanticAction.other;
  }

  /// Gets the actor from a timeline node.
  /// Public so callers can filter nodes without an actor before grouping.
  static Fragment$actor? getActorFromNode(final dynamic node) {
    try {
      if (node is AssignedEvent) return node.actor;
      if (node is ClosedEvent) return node.actor;
      if (node is IssueCommentEvent) return node.author;
      if (node is LabeledEvent) return node.actor;
      if (node is UnlabeledEvent) return node.actor;
      if (node is ReopenedEvent) return node.actor;
      if (node is MergedEvent) return node.actor;
      if (node is TimelinePullRequestReviewEvent) return node.author;
      if (node is PullRequestCommitEvent) return node.commit.author?.user;
      if (node is UnassignedEvent) return node.actor;
      if (node is MilestonedEvent) return node.actor;
      if (node is DemilestonedEvent) return node.actor;
      if (node is CrossReferenceEvent) return node.actor;
      if (node is ConvertedToDraftEvent) return node.actor;
      if (node is ReadyForReviewEvent) return node.actor;
      if (node is LockedEvent) return node.actor;
      if (node is UnlockedEvent) return node.actor;
      if (node is PinnedEvent) return node.actor;
      if (node is UnpinnedEvent) return node.actor;
      if (node is MarkedAsDuplicateEvent) return node.actor;
      if (node is UnmarkedAsDuplicateEvent) return node.actor;
      if (node is RenamedTitleEvent) return node.actor;
      if (node is BaseRefChangedEvent) return node.actor;
      if (node is BaseRefForcePushedEvent) return node.actor;
      if (node is BaseRefDeletedEvent) return node.actor;
      if (node is HeadRefForcePushedEvent) return node.actor;
      if (node is HeadRefDeletedEvent) return node.actor;
      if (node is HeadRefRestoredEvent) return node.actor;
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Error getting actor from timeline node',
        error: e,
        stackTrace: stackTrace,
        tag: 'Timeline',
      );
    }
    return null;
  }

  /// Whether [fragment] (e.g. "issuecomment-123456") matches this timeline node.
  /// Used for URL fragment matching when scrolling to a comment.
  static bool matchesCommentFragment(
      final String fragment, final dynamic timelineNode) {
    if (timelineNode is IssueCommentEvent) {
      final dbId = timelineNode.databaseId;
      return dbId != null && fragment == 'issuecomment-$dbId';
    }
    return false;
  }
}

/// Extension to check if a timeline section contains a comment matching a URL fragment or node id.
extension TimelineActorSectionX on TimelineActorSection {
  /// Whether this section contains the comment matching [fragment].
  bool containsCommentFragment(final String fragment) {
    for (final compound in compounds) {
      for (final cluster in compound.parts) {
        for (final event in cluster.events) {
          if (TimelineGroupingStrategy.matchesCommentFragment(
              fragment, event)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Whether this section contains the comment with node [commentId].
  bool containsCommentId(final String commentId) {
    for (final compound in compounds) {
      for (final cluster in compound.parts) {
        for (final event in cluster.events) {
          if (timelineNodeIdOf(event) == commentId) return true;
        }
      }
    }
    return false;
  }
}
