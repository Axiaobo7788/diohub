import 'package:diohub/app/app_logger.dart';
import 'package:diohub_graphql/queries/issues_pulls/timeline.graphql.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub/utils/compound_grouping.dart';
import 'package:diohub/utils/events/event_action.dart';
import 'package:diohub/utils/events/event_texts.dart';
import 'package:diohub/utils/timeline/timeline_grouping_strategy.dart';

/// Interprets a [TimelineCompound] to produce a structured [EventAction].
///
/// Since all timeline roles are `isolated`, each compound contains exactly
/// one cluster. The cluster's `events` replaces the old `IssueTimelineGroup.children`,
/// and `cluster.action` replaces `semanticAction`.
EventAction interpretTimeline(final TimelineCompound compound) {
  final ActionCluster<IssueTimelineSemanticAction, dynamic> cluster =
      compound.firstPart;
  final List<dynamic> children = cluster.events;
  final IssueTimelineSemanticAction action = cluster.action;
  final int count = children.length;

  return switch (action) {
    IssueTimelineSemanticAction.comment => SimpleAction(
        text: EventTexts.timelineComment(count: count),
        count: count,
      ),
    IssueTimelineSemanticAction.labelChange => _labelAction(children),
    IssueTimelineSemanticAction.stateChange => _stateAction(children),
    IssueTimelineSemanticAction.review => SimpleAction(
        text: EventTexts.timelineReview(count: count),
        count: count,
      ),
    IssueTimelineSemanticAction.commitPush => PushAction(
        commitCount: count,
      ),
    IssueTimelineSemanticAction.assigned => SimpleAction(
        text: EventTexts.timelineAssign(unassign: false, count: count),
        count: count,
      ),
    IssueTimelineSemanticAction.unassigned => SimpleAction(
        text: EventTexts.timelineAssign(unassign: true, count: count),
        count: count,
      ),
    IssueTimelineSemanticAction.milestoneChange => _milestoneAction(children),
    IssueTimelineSemanticAction.crossReference =>
      _crossReferenceAction(children),
    IssueTimelineSemanticAction.other => SimpleAction(
        text: EventTexts.timelineOther(count: count),
        count: count,
      ),
  };
}

LabelAction _labelAction(final List<dynamic> children) {
  int added = 0;
  int removed = 0;
  for (final node in children) {
    if (node is LabeledEvent) {
      added++;
    } else if (node is UnlabeledEvent) {
      removed++;
    }
  }
  return LabelAction(added: added, removed: removed);
}

EventAction _stateAction(final List<dynamic> children) {
  // Identify action from first matching child.
  String? actionValue;
  for (final node in children) {
    if (node is ClosedEvent) {
      actionValue = 'closed';
      break;
    } else if (node is ReopenedEvent) {
      actionValue = 'reopened';
      break;
    } else if (node is MergedEvent) {
      actionValue = 'merged';
      break;
    } else if (node is ConvertedToDraftEvent) {
      actionValue = 'converted to draft';
      break;
    } else if (node is ReadyForReviewEvent) {
      actionValue = 'marked as ready for review';
      break;
    }
  }

  final int count = children.length;
  final String text =
      EventTexts.timelineStateChange(action: actionValue, count: count);
  return SimpleAction(text: text, count: count);
}

EventAction _milestoneAction(final List<dynamic> children) {
  int added = 0;
  int removed = 0;
  for (final node in children) {
    if (node is MilestonedEvent) {
      added++;
    } else if (node is DemilestonedEvent) {
      removed++;
    }
  }

  final int count = children.length;
  final String text =
      EventTexts.timelineMilestone(added: added, removed: removed);
  return SimpleAction(text: text, count: count);
}

String? _crossRefSourceRepoName(CrossReferenceEvent node) {
  final source = node.source;
  return source.maybeWhen(
    issue: (i) => i.repository.nameWithOwner,
    pullRequest: (pr) => pr.repository.nameWithOwner,
    orElse: () => null,
  );
}

EventAction _crossReferenceAction(final List<dynamic> children) {
  String? repoName;
  for (final node in children) {
    if (node is CrossReferenceEvent && node.isCrossRepository) {
      try {
        repoName = _crossRefSourceRepoName(node);
        if (repoName != null) break;
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Error extracting cross-reference repo name',
          error: e,
          stackTrace: stackTrace,
          tag: 'Timeline',
        );
      }
    }
  }

  final int count = children.length;
  final String text =
      EventTexts.timelineCrossReference(repoName: repoName, count: count);
  return SimpleAction(text: text, count: count);
}
