import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub/utils/timeline/timeline_node_id.dart';
import 'package:diohub/utils/timeline/timeline_grouping_strategy.dart'
    show
        IssueTimelineSemanticAction,
        TimelineActorSection,
        TimelineCompound,
        TimelineGroupingStrategy;

/// Visual tier for a timeline entry. Drives layout (full card vs compact vs inline).
enum TimelineTier {
  primary,
  secondary,
  tertiary,
  minimal,
}

/// Maps a semantic action to its visual tier.
TimelineTier tierOf(IssueTimelineSemanticAction action) {
  return switch (action) {
    IssueTimelineSemanticAction.comment => TimelineTier.primary,
    IssueTimelineSemanticAction.review => TimelineTier.primary,
    IssueTimelineSemanticAction.stateChange => TimelineTier.secondary,
    IssueTimelineSemanticAction.commitPush => TimelineTier.secondary,
    IssueTimelineSemanticAction.labelChange => TimelineTier.tertiary,
    IssueTimelineSemanticAction.assigned => TimelineTier.tertiary,
    IssueTimelineSemanticAction.unassigned => TimelineTier.tertiary,
    IssueTimelineSemanticAction.milestoneChange => TimelineTier.tertiary,
    IssueTimelineSemanticAction.crossReference => TimelineTier.tertiary,
    IssueTimelineSemanticAction.other => TimelineTier.minimal,
  };
}

/// One item in the flat timeline display list.
sealed class TimelineDisplayItem {
  String get itemId;
  Set<String> get containedIds;
  bool containsCommentFragment(String fragment);
  bool containsCommentId(String commentId);
}

/// A single compound on the timeline (one actor, one compound).
class SingleTimelineEntry extends TimelineDisplayItem {
  SingleTimelineEntry({required this.actor, required this.compound});

  final Fragment$actor actor;
  final TimelineCompound compound;

  IssueTimelineSemanticAction get action => compound.firstPart.action;
  TimelineTier get tier => tierOf(action);

  @override
  String get itemId =>
      timelineNodeIdOf(compound.firstPart.events.first) ??
      Object.hash(_getActorLogin(actor), compound.hashCode).toString();

  String _getActorLogin(Fragment$actor actor) {
    return switch (actor) {
      Fragment$actor$$User u => u.login,
      Fragment$actor$$Bot b => b.login,
      Fragment$actor$$Organization o => o.login,
      Fragment$actor$$Mannequin m => m.login,
      Fragment$actor() => '(unknown)',
    };
  }

  @override
  Set<String> get containedIds {
    final ids = <String>{};
    for (final part in compound.parts) {
      for (final event in part.events) {
        final id = timelineNodeIdOf(event);
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }

  @override
  bool containsCommentFragment(String fragment) {
    for (final part in compound.parts) {
      for (final event in part.events) {
        if (TimelineGroupingStrategy.matchesCommentFragment(fragment, event)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  bool containsCommentId(String commentId) {
    for (final part in compound.parts) {
      for (final event in part.events) {
        if (timelineNodeIdOf(event) == commentId) return true;
      }
    }
    return false;
  }
}

/// A collapsed group of 3+ consecutive minimal-tier entries.
class CollapsedMinimalGroup extends TimelineDisplayItem {
  CollapsedMinimalGroup({required this.entries})
      : assert(
            entries.length >= 3, 'CollapsedMinimalGroup requires 3+ entries');

  final List<SingleTimelineEntry> entries;

  @override
  String get itemId => entries.first.itemId;

  @override
  Set<String> get containedIds {
    final ids = <String>{};
    for (final e in entries) {
      ids.addAll(e.containedIds);
    }
    return ids;
  }

  @override
  bool containsCommentFragment(String fragment) {
    return entries.any((e) => e.containsCommentFragment(fragment));
  }

  @override
  bool containsCommentId(String commentId) {
    return entries.any((e) => e.containsCommentId(commentId));
  }
}

/// Flattens actor sections into a chronological list of single entries (one per compound).
List<SingleTimelineEntry> flattenSectionsToEntries(
  List<TimelineActorSection> sections,
) {
  final result = <SingleTimelineEntry>[];
  for (final section in sections) {
    for (final compound in section.compounds) {
      result.add(SingleTimelineEntry(actor: section.actor, compound: compound));
    }
  }
  return result;
}

/// Replaces runs of 3+ consecutive minimal-tier entries with one [CollapsedMinimalGroup].
List<TimelineDisplayItem> applyCollapsingPass(
    List<SingleTimelineEntry> entries) {
  if (entries.isEmpty) return [];
  final result = <TimelineDisplayItem>[];
  List<SingleTimelineEntry>? run;
  for (final entry in entries) {
    if (entry.tier == TimelineTier.minimal) {
      run ??= [];
      run.add(entry);
    } else {
      if (run != null) {
        if (run.length >= 3) {
          result.add(CollapsedMinimalGroup(entries: run));
        } else {
          result.addAll(run);
        }
        run = null;
      }
      result.add(entry);
    }
  }
  if (run != null) {
    if (run.length >= 3) {
      result.add(CollapsedMinimalGroup(entries: run));
    } else {
      result.addAll(run);
    }
  }
  return result;
}
