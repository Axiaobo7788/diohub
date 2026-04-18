import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub_models/models/issues/issue_model.dart';
import 'package:diohub_models/models/pull_requests/pull_request_model.dart';

sealed class VisualState {
  bool get isOpen;
  bool get isClosed;
}

enum IssueVisualState implements VisualState {
  open,
  closed,
  closedNotPlanned,
  closedDuplicate;

  @override
  bool get isOpen => this == open;
  @override
  bool get isClosed => this != open;
  bool get isNotPlanned => this == closedNotPlanned;
  bool get isDuplicate => this == closedDuplicate;

  /// From REST model enum fields.
  static IssueVisualState fromIssue(
    final IssueState? state,
    final IssueStateReason? reason,
  ) =>
      switch ((state, reason)) {
        (IssueState.closed, IssueStateReason.notPlanned) => closedNotPlanned,
        (IssueState.closed, IssueStateReason.duplicate) => closedDuplicate,
        (IssueState.closed, _) => closed,
        _ => open,
      };

  /// From event payload action.
  static IssueVisualState fromAction(
    final PayloadAction? action, {
    final IssueStateReason? reason,
  }) =>
      switch (action) {
        PayloadAction.closed => switch (reason) {
            IssueStateReason.notPlanned => closedNotPlanned,
            IssueStateReason.duplicate => closedDuplicate,
            _ => closed,
          },
        PayloadAction.opened || PayloadAction.reopened => open,
        _ => open,
      };

  /// From GraphQL enum name strings (e.g. 'OPEN', 'CLOSED', 'NOT_PLANNED').
  static IssueVisualState fromNames(final String? stateName,
      {final String? reasonName}) {
    final String? s = stateName?.toUpperCase();
    final String? r = reasonName?.toUpperCase();
    return switch ((s, r)) {
      ('CLOSED', 'NOT_PLANNED') => closedNotPlanned,
      ('CLOSED', 'DUPLICATE') => closedDuplicate,
      ('CLOSED', _) => closed,
      _ => open,
    };
  }
}

enum PrVisualState implements VisualState {
  open,
  draft,
  closed,
  merged;

  @override
  bool get isOpen => this == open || this == draft;
  @override
  bool get isClosed => this == closed || this == merged;
  bool get isMerged => this == merged;
  bool get isDraft => this == draft;

  /// From REST model enum fields.
  static PrVisualState fromPullRequest(
    final PullRequestState? state, {
    final bool? merged,
    final bool? draft,
  }) =>
      switch ((state, merged, draft)) {
        (_, true, _) => PrVisualState.merged,
        (PullRequestState.closed, _, _) => closed,
        (_, _, true) => PrVisualState.draft,
        _ => open,
      };

  /// From event payload action.
  static PrVisualState fromAction(final PayloadAction? action,
          {final bool? merged}) =>
      switch (action) {
        PayloadAction.merged => PrVisualState.merged,
        PayloadAction.closed => merged ?? false ? PrVisualState.merged : closed,
        PayloadAction.convertedToDraft => draft,
        PayloadAction.opened ||
        PayloadAction.reopened ||
        PayloadAction.readyForReview =>
          open,
        _ => open,
      };

  /// From GraphQL enum name strings (e.g. 'OPEN', 'CLOSED', 'MERGED').
  static PrVisualState fromNames(
    final String? stateName, {
    final bool? merged,
    final bool? isDraft,
  }) {
    final String? s = stateName?.toUpperCase();
    return switch ((s, merged, isDraft)) {
      ('MERGED', _, _) => PrVisualState.merged,
      (_, true, _) => PrVisualState.merged,
      ('CLOSED', _, _) => closed,
      (_, _, true) => draft,
      _ => open,
    };
  }
}

/// Human-readable past-tense action text for display in timelines.
extension IssueVisualStateActionText on IssueVisualState {
  String get actionText => switch (this) {
        IssueVisualState.open => 'opened',
        IssueVisualState.closed ||
        IssueVisualState.closedNotPlanned ||
        IssueVisualState.closedDuplicate =>
          'closed',
      };
}

/// Human-readable past-tense action text for display in timelines.
extension PrVisualStateActionText on PrVisualState {
  String get actionText => switch (this) {
        PrVisualState.open || PrVisualState.draft => 'opened',
        PrVisualState.closed => 'closed',
        PrVisualState.merged => 'merged',
      };
}

extension IssueVisualStateX on Issue {
  IssueVisualState get visualState =>
      IssueVisualState.fromIssue(state, stateReason);
}

extension PullRequestVisualStateX on PullRequest {
  PrVisualState get visualState =>
      PrVisualState.fromPullRequest(state, merged: merged, draft: draft);
}
