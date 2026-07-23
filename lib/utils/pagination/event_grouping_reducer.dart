import 'package:diohub/app/settings/events.dart' show EventsSettings;
import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub/utils/compound_grouping.dart';
import 'package:diohub/utils/events/event_target.dart';

/// Semantic action types for event grouping.
enum SemanticAction {
  labelChange,
  assigned,
  createRef,
  deleteRef,
  issueStateChange,
  prStateChange,
  push,
  commentChange,
  watch,
  fork,
  release,
  wikiChange,
  public,
  member,
  review,
  discussion,
  other,
}

/// Type aliases for compound-grouped events.
typedef EventCluster = ActionCluster<SemanticAction, EventsModel>;
typedef EventCompound = Compound<SemanticAction, EventsModel>;
typedef ActorEventSection = ActorSection<Actor, SemanticAction, EventsModel>;

/// Strategy that forces every action to render as its own card (no compounding).
/// Used when [EventsSettings.compoundActions] is false.
class StandaloneEventGroupingStrategy
    extends GroupingStrategy<EventsModel, Actor, SemanticAction> {
  StandaloneEventGroupingStrategy(this._inner);
  final EventGroupingStrategy _inner;

  @override
  Object? actorKeyOf(final EventsModel e) => _inner.actorKeyOf(e);

  @override
  Actor actorDataOf(final EventsModel e) => _inner.actorDataOf(e);

  @override
  Object targetOf(final EventsModel e) => _inner.targetOf(e);

  @override
  SemanticAction actionOf(final EventsModel e) => _inner.actionOf(e);

  @override
  CompoundRole roleOf(final SemanticAction action) => CompoundRole.isolated;

  @override
  bool canMergeItems(final EventsModel a, final EventsModel b,
          final SemanticAction action) =>
      _inner.canMergeItems(a, b, action);
}

/// Strategy that configures [CompoundGrouper] for GitHub events feed.
///
/// Groups events by actor, then compounds related actions on the same
/// issue/PR/repo target, then clusters same-action items.
class EventGroupingStrategy
    extends GroupingStrategy<EventsModel, Actor, SemanticAction> {
  @override
  Object? actorKeyOf(final EventsModel e) => e.actor.id;

  @override
  Actor actorDataOf(final EventsModel e) => e.actor;

  @override
  Object targetOf(final EventsModel e) => EventTarget.from(e);

  @override
  SemanticAction actionOf(final EventsModel e) => _classifyEvent(e);

  @override
  CompoundRole roleOf(final SemanticAction action) => switch (action) {
        SemanticAction.labelChange ||
        SemanticAction.assigned ||
        SemanticAction.createRef ||
        SemanticAction.deleteRef ||
        SemanticAction.commentChange =>
          CompoundRole.supporting,
        SemanticAction.issueStateChange ||
        SemanticAction.prStateChange ||
        SemanticAction.push =>
          CompoundRole.primary,
        SemanticAction.watch ||
        SemanticAction.fork ||
        SemanticAction.public =>
          CompoundRole.crossTarget,
        _ => CompoundRole.isolated,
      };

  /// Refinement within the same (action, target) pair.
  ///
  /// By the time this is called, the engine has already verified:
  ///   - same actor
  ///   - same target (repository identity + issue/PR number)
  ///   - same action
  /// This method only handles sub-action splits.
  @override
  bool canMergeItems(final EventsModel a, final EventsModel b,
          final SemanticAction action) =>
      switch (action) {
        // Push events: allow cross-branch merging on the same repo.
        // Per-branch breakdown is handled in EventCompoundData.pushDetails.
        SemanticAction.push => true,

        // Ref events: must be the same ref type (branch vs. tag).
        SemanticAction.createRef ||
        SemanticAction.deleteRef =>
          a.payload.refType == b.payload.refType,

        // State/comment/assign: must be the same payload action.
        SemanticAction.issueStateChange ||
        SemanticAction.prStateChange ||
        SemanticAction.commentChange ||
        SemanticAction.assigned =>
          a.payload.action == b.payload.action,

        // Everything else: same action + same target is enough.
        _ => true,
      };

  // -----------------------------------------------------------------------
  // Event classification (unchanged logic, moved from static method)
  // -----------------------------------------------------------------------

  static SemanticAction _classifyEvent(final EventsModel e) {
    if (e.type == null) {
      return SemanticAction.other;
    }

    final PayloadAction? action = e.payload.action;
    final EventsType type = e.type!;

    if (type == EventsType.IssuesEvent || type == EventsType.PullRequestEvent) {
      if (action == PayloadAction.labeled ||
          action == PayloadAction.unlabeled) {
        return SemanticAction.labelChange;
      }
    }

    if (type == EventsType.IssuesEvent) {
      if (action == PayloadAction.opened ||
          action == PayloadAction.closed ||
          action == PayloadAction.reopened) {
        return SemanticAction.issueStateChange;
      }
      if (action == PayloadAction.assigned ||
          action == PayloadAction.unassigned) {
        return SemanticAction.assigned;
      }
    }

    if (type == EventsType.PullRequestEvent) {
      if (action == PayloadAction.opened ||
          action == PayloadAction.closed ||
          action == PayloadAction.merged ||
          action == PayloadAction.reopened ||
          action == PayloadAction.readyForReview ||
          action == PayloadAction.convertedToDraft) {
        return SemanticAction.prStateChange;
      }
      if (action == PayloadAction.assigned ||
          action == PayloadAction.unassigned) {
        return SemanticAction.assigned;
      }
    }

    if (type == EventsType.IssueCommentEvent ||
        type == EventsType.PullRequestReviewCommentEvent ||
        type == EventsType.CommitCommentEvent) {
      return SemanticAction.commentChange;
    }

    if (type == EventsType.PushEvent) return SemanticAction.push;
    if (type == EventsType.WatchEvent) return SemanticAction.watch;
    if (type == EventsType.ForkEvent) return SemanticAction.fork;
    if (type == EventsType.ReleaseEvent) return SemanticAction.release;
    if (type == EventsType.GollumEvent) return SemanticAction.wikiChange;
    if (type == EventsType.CreateEvent) return SemanticAction.createRef;
    if (type == EventsType.DeleteEvent) return SemanticAction.deleteRef;
    if (type == EventsType.PublicEvent) return SemanticAction.public;
    if (type == EventsType.MemberEvent) return SemanticAction.member;
    if (type == EventsType.PullRequestReviewEvent) {
      return SemanticAction.review;
    }
    if (type == EventsType.DiscussionEvent) return SemanticAction.discussion;

    return SemanticAction.other;
  }
}
