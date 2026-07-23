import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub_models/models/issues/issue_model.dart' show Label;
import 'package:diohub/utils/compound_grouping.dart';
import 'package:diohub/utils/pagination/event_grouping_reducer.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'compound_extractors.freezed.dart';

/// Shared helper for commit count calculation.
/// Counts distinct head refs from push events.
/// Each PushEvent has a head (latest commit SHA after the push).
/// Using distinct heads is more reliable than payload.size (often 0) or commits array (truncated at 20).
int commitCountFromEvents(final List<EventsModel> events) => events
    .map((final EventsModel e) => e.payload.head)
    .whereType<String>()
    .toSet()
    .length;

/// Status of a branch in events (created, deleted, or normal).
enum BranchStatus { created, deleted, normal }

/// Scope of a compound group, determined by the first event's payload.
/// Invariant: all parts in a compound share the same repository target key and
/// issue/PR number, so checking the first event is safe.
enum CompoundScope { repo, issue, pullRequest, unknown }

/// Branch highlight for repository card display.
@freezed
abstract class BranchHighlight with _$BranchHighlight {
  const factory BranchHighlight(
    final String name, {
    @Default(BranchStatus.normal) final BranchStatus status,
  }) = _BranchHighlight;
  const BranchHighlight._();

  bool get strikethrough => status == BranchStatus.deleted;
}

/// Extraction utilities for [EventCluster].
/// Each extractor is a small, focused, testable function that extracts
/// specific data from a cluster of events with the same semantic action.
extension EventClusterExtractors on EventCluster {
  /// Extract labels from a labelChange action group.
  /// Uses payload.eventLabel which is now always parsed in the model.
  ({List<Label> labels, Set<String> removedNames}) extractLabels() {
    final List<Label> allLabels = <Label>[];
    final Set<String> removedLabelNames = <String>{};

    for (final EventsModel event in events) {
      final Label? directLabel = event.payload.eventLabel;

      if (directLabel != null) {
        if (event.payload.action == PayloadAction.unlabeled) {
          removedLabelNames.add(directLabel.name);
        } else {
          allLabels.add(directLabel);
        }
      }
    }

    return (labels: allLabels, removedNames: removedLabelNames);
  }

  /// Extract first comment body from a commentChange cluster.
  String? extractFirstCommentBody() {
    if (events.isEmpty) return null;
    return events.first.payload.comment?.body;
  }

  /// Extract branch info from a createRef/deleteRef action group.
  /// For createRef: returns BranchHighlight(name, status: created).
  /// For deleteRef: returns BranchHighlight(name, status: deleted).
  List<BranchHighlight> extractBranches() {
    final List<BranchHighlight> branches = <BranchHighlight>[];
    final bool isCreate = action == SemanticAction.createRef;
    final bool isDelete = action == SemanticAction.deleteRef;

    for (final EventsModel event in events) {
      final String? ref = event.payload.ref;
      if (ref != null) {
        // Extract branch name from refs/heads/main -> main
        final String branchName = ref.split('/').last;
        final BranchStatus status = isDelete
            ? BranchStatus.deleted
            : (isCreate ? BranchStatus.created : BranchStatus.normal);
        branches.add(BranchHighlight(branchName, status: status));
      }
    }

    return branches;
  }

  /// Extract commit count from a push cluster.
  /// Delegates to shared helper for consistency with summary text generation.
  int extractCommitCount() => commitCountFromEvents(events);
}

/// Extraction utilities for [EventCompound].
extension EventCompoundExtractors on EventCompound {
  /// Find the cluster with a specific semantic action, if it exists.
  EventCluster? partWith(final SemanticAction action) => parts
      .where((final ActionCluster<SemanticAction, EventsModel> p) =>
          p.action == action)
      .firstOrNull;

  /// Determines the scope of this compound.
  /// Safe to check only the first event because EventTarget guarantees
  /// all parts in a compound share the same repository target and number.
  CompoundScope get scope {
    if (parts.isEmpty) return CompoundScope.unknown;
    final EventsModel firstEvent = parts.first.events.first;
    final bool hasPR = firstEvent.payload.pullRequest != null;
    final bool hasIssue = firstEvent.payload.issue != null;
    if (hasPR) return CompoundScope.pullRequest;
    if (hasIssue) return CompoundScope.issue;
    final int? number = firstEvent.payload.number;
    if (number == null) return CompoundScope.repo;
    return CompoundScope.unknown;
  }

  /// Get the repo URL from the first event's repo.
  String? get repoUrl {
    if (parts.isEmpty) return null;
    return parts.first.events.first.repo.url;
  }

  /// Get the repo name from the first event's repo.
  String? get repoName {
    if (parts.isEmpty) return null;
    return parts.first.events.first.repo.name;
  }
}
