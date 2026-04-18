import 'package:diohub_models/models/events/event_review.dart';
import 'package:diohub_models/models/events/events_model.dart';

/// Centralised event text catalog.
///
/// Every user-facing string produced by the events system lives here.
/// Each method corresponds to a single localisable message — when l10n is
/// added, swap the body for a delegate to `AppLocalizations`.
///
/// Design constraints:
/// - **No UI imports** — this is a pure-text utility.
/// - **No side-effects** — every method is a pure function.
/// - **One method per message pattern** — easy to grep, audit, and extract
///   into ARB files with ICU plural/select syntax.
abstract final class EventTexts {
  // ─────────────────────────────────────────────────────────────────────────
  // Verb resolution
  // ─────────────────────────────────────────────────────────────────────────

  /// Human-readable past-tense verb for a [PayloadAction].
  static String payloadVerb(final PayloadAction? action) => switch (action) {
        PayloadAction.opened => 'opened',
        PayloadAction.closed => 'closed',
        PayloadAction.reopened => 'reopened',
        PayloadAction.merged => 'merged',
        PayloadAction.readyForReview => 'marked as ready',
        PayloadAction.convertedToDraft => 'converted to draft',
        _ => 'updated',
      };

  /// Human-readable past-tense verb for a [ReviewState].
  static String reviewVerb(final ReviewState? state) => switch (state) {
        ReviewState.approved => 'approved',
        ReviewState.changesRequested => 'requested changes on',
        ReviewState.commented => 'reviewed',
        ReviewState.dismissed => 'dismissed a review on',
        _ => 'reviewed',
      };

  /// Human-readable past-tense verb for a comment [PayloadAction].
  static String commentVerb(final PayloadAction? action) => switch (action) {
        PayloadAction.created => 'added',
        PayloadAction.edited => 'edited',
        PayloadAction.deleted => 'deleted',
        _ => 'updated',
      };

  /// Verb for assign/unassign actions.
  static String assignVerb(final PayloadAction? action) =>
      action == PayloadAction.unassigned ? 'unassigned' : 'assigned';

  // ─────────────────────────────────────────────────────────────────────────
  // Activity feed — full display text
  // ─────────────────────────────────────────────────────────────────────────

  /// "opened an issue", "closed 3 pull requests"
  static String stateChange({
    required final PayloadAction? verb,
    required final String noun,
    required final int count,
  }) {
    final String v = payloadVerb(verb);
    return count == 1
        ? '$v ${article(noun)}$noun'
        : '$v $count ${plural(noun)}';
  }

  /// "pushed a commit", "pushed 5 commits", "pushed 5 commits to 3 branches"
  static String push({
    required final int commits,
    final int branches = 1,
  }) {
    if (branches > 1) {
      return 'pushed $commits commits to $branches branches';
    }
    return commits == 1 ? 'pushed a commit' : 'pushed $commits commits';
  }

  /// "added a label", "removed 3 labels", "updated labels"
  static String labelChange({
    required final int added,
    required final int removed,
  }) {
    if (added > 0 && removed > 0) return 'updated labels';
    if (removed > 0) {
      return removed == 1 ? 'removed a label' : 'removed $removed labels';
    }
    return added == 1 ? 'added a label' : 'added $added labels';
  }

  /// "added a comment", "edited 3 comments"
  static String comment({
    required final PayloadAction? verb,
    required final int count,
  }) {
    final String v = commentVerb(verb);
    return count == 1 ? '$v a comment' : '$v $count comments';
  }

  /// "created a branch", "deleted 3 tags"
  static String refChange({
    required final String verb,
    required final String refType,
    required final int count,
  }) {
    final String p = plural(refType);
    return count == 1
        ? '$verb ${article(refType)}$refType'
        : '$verb $count $p';
  }

  /// Generic counted item: "starred a repository", "forked 3 repositories"
  static String countedItem({
    required final String verb,
    required final String singular,
    required final String plural,
    required final int count,
  }) =>
      count == 1 ? '$verb $singular' : '$verb $count $plural';

  /// "assigned an issue", "unassigned 3 issues"
  static String assign({
    required final PayloadAction? verb,
    required final int count,
  }) {
    final String v = assignVerb(verb);
    return count == 1 ? '$v an issue' : '$v $count issues';
  }

  /// "approved a pull request", "requested changes on 3 pull requests"
  static String review({
    required final ReviewState? state,
    required final int count,
  }) {
    final String v = reviewVerb(state);
    return count == 1 ? '$v a pull request' : '$v $count pull requests';
  }

  /// "published a release", "published 3 releases"
  static String release({required final int count}) =>
      count == 1 ? 'published a release' : 'published $count releases';

  /// "started a discussion", "started 3 discussions"
  static String discussion({required final int count}) =>
      count == 1 ? 'started a discussion' : 'started $count discussions';

  /// "updated a wiki page", "updated 3 wiki pages"
  static String wiki({required final int pageCount}) {
    if (pageCount == 1) return 'updated a wiki page';
    if (pageCount > 0) return 'updated $pageCount wiki pages';
    return 'updated wiki pages';
  }

  /// Fallback: "performed an action", "performed an action 3 times"
  static String simple({
    required final String text,
    required final int count,
  }) =>
      count == 1 ? text : '$text $count times';

  // ─────────────────────────────────────────────────────────────────────────
  // Activity feed — short verbs (for compound summaries)
  // ─────────────────────────────────────────────────────────────────────────

  /// "opened", "closed (3)"
  static String stateChangeShort({
    required final PayloadAction? verb,
    required final int count,
  }) {
    final String v = payloadVerb(verb);
    return count > 1 ? '$v ($count)' : v;
  }

  /// "pushed a commit", "pushed (3 branches)"
  static String pushShort({
    required final int commits,
    final int branches = 1,
  }) =>
      branches > 1
          ? 'pushed ($branches branches)'
          : (commits == 1 ? 'pushed a commit' : 'pushed $commits commits');

  /// "commented", "left 3 comments"
  static String commentShort({required final int count}) =>
      count == 1 ? 'commented' : 'left $count comments';

  /// "created a branch", "created 3 branches"
  static String refChangeShort({
    required final String verb,
    required final String refType,
    required final int count,
  }) {
    final String p = plural(refType);
    return count == 1 ? '$verb a $refType' : '$verb $count $p';
  }

  /// "assigned", "assigned (3)"
  static String assignShort({
    required final PayloadAction? verb,
    required final int count,
  }) {
    final String v = assignVerb(verb);
    return count > 1 ? '$v ($count)' : v;
  }

  /// "approved", "approved (3)"
  static String reviewShort({
    required final ReviewState? state,
    required final int count,
  }) {
    final String v = reviewVerb(state);
    return count > 1 ? '$v ($count)' : v;
  }

  /// "published", "published (3)"
  static String releaseShort({required final int count}) =>
      count == 1 ? 'published' : 'published ($count)';

  /// "discussed", "discussed (3)"
  static String discussionShort({required final int count}) =>
      count == 1 ? 'discussed' : 'discussed ($count)';

  // ─────────────────────────────────────────────────────────────────────────
  // Timeline-specific (issue/PR detail view)
  // ─────────────────────────────────────────────────────────────────────────

  /// "commented", "commented 3 times"
  static String timelineComment({required final int count}) =>
      count == 1 ? 'commented' : 'commented $count times';

  /// "reviewed changes", "reviewed changes 3 times"
  static String timelineReview({required final int count}) =>
      count == 1 ? 'reviewed changes' : 'reviewed changes $count times';

  /// "assigned", "assigned 3 times", "unassigned"
  static String timelineAssign({
    required final bool unassign,
    required final int count,
  }) {
    final String v = unassign ? 'unassigned' : 'assigned';
    return count == 1 ? v : '$v $count times';
  }

  /// "closed this", "reopened this", "merged this", etc.
  static String timelineStateChange({
    required final String? action,
    required final int count,
  }) =>
      switch (action) {
        'closed' => count == 1 ? 'closed this' : 'closed $count issues',
        'reopened' => count == 1 ? 'reopened this' : 'reopened $count issues',
        'merged' =>
          count == 1 ? 'merged this' : 'merged $count pull requests',
        'converted to draft' =>
          count == 1 ? 'converted to draft' : 'converted $count to draft',
        'marked as ready for review' => count == 1
            ? 'marked as ready for review'
            : 'marked $count as ready for review',
        _ => count == 1 ? 'changed state' : 'changed state $count times',
      };

  /// "added to milestone", "removed from 3 milestones", "updated milestones"
  static String timelineMilestone({
    required final int added,
    required final int removed,
  }) {
    final int count = added + removed;
    if (added > 0 && removed > 0) return 'updated milestones';
    if (added > 0) {
      return added == 1 ? 'added to milestone' : 'added to $added milestones';
    }
    if (removed > 0) {
      return removed == 1
          ? 'removed from milestone'
          : 'removed from $removed milestones';
    }
    // Fallback when both are 0 (shouldn't happen, but safe).
    return count == 0 ? 'updated milestones' : 'updated milestones';
  }

  /// "referenced this in repoName", "referenced 3 times"
  static String timelineCrossReference({
    required final String? repoName,
    required final int count,
  }) {
    if (repoName != null) {
      return count == 1
          ? 'referenced this in $repoName'
          : 'referenced this in $repoName $count times';
    }
    return count == 1 ? 'referenced' : 'referenced $count times';
  }

  /// "performed an action", "performed 3 actions"
  static String timelineOther({required final int count}) =>
      count == 1 ? 'performed an action' : 'performed $count actions';

  // ─────────────────────────────────────────────────────────────────────────
  // Fallback event descriptions (unknown / unmapped event types)
  // ─────────────────────────────────────────────────────────────────────────

  /// Produces a human-readable description for an event type that has no
  /// dedicated [EventAction] subclass.
  ///
  /// Uses a known-noun lookup first, then falls back to regex-based
  /// prettification of the raw type name.
  static String otherEvent({
    required final String typeName,
    final PayloadAction? action,
  }) {
    final String typeKey = typeName.toLowerCase();
    final (String, String)? typeData = _eventTypeNouns[typeKey];

    if (typeData != null) {
      final (String withActionNoun, String noActionDefault) = typeData;
      if (action != null && withActionNoun.isNotEmpty) {
        return '${action.name} $withActionNoun';
      }
      return noActionDefault;
    }

    // Prettify unknown type name: "PullRequestReviewEvent" → "pull request review"
    String readable = typeName
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (final Match match) => ' ${match.group(1)!.toLowerCase()}',
        )
        .replaceAll('event', '')
        .trim();
    if (readable.isEmpty) readable = 'an action';

    if (action != null) {
      return '${action.name} $readable';
    }
    return readable.isNotEmpty
        ? 'performed $readable action'
        : 'performed an action';
  }

  static const Map<String, (String withAction, String noAction)>
      _eventTypeNouns = <String, (String, String)>{
    'issuesevent': ('an issue', 'updated an issue'),
    'pullrequestevent': ('a pull request', 'updated a pull request'),
    'issuecommentevent': ('a comment', 'commented'),
    'pullrequestreviewcommentevent': (
      'a review comment',
      'commented on a review',
    ),
    'commitcommentevent': ('a commit comment', 'commented on a commit'),
    'releaseevent': ('a release', 'published a release'),
    'gollumevent': ('', 'updated wiki pages'),
    'sponsorshipevent': ('a sponsorship', 'sponsored'),
    'undefined': ('', 'performed an action'),
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Grammar helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// English indefinite article: "an issue", "a repository".
  static String article(final String noun) => switch (noun) {
        'issue' || 'item' => 'an ',
        _ => 'a ',
      };

  /// English plural: "branch" → "branches", "repository" → "repositories".
  static String plural(final String noun) => switch (noun) {
        'branch' => 'branches',
        'repository' => 'repositories',
        _ => '${noun}s',
      };

  /// Natural-language list join: "a, b, and c".
  static String naturalJoin(final List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items[0];
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    final String allButLast = items.sublist(0, items.length - 1).join(', ');
    return '$allButLast, and ${items.last}';
  }
}
