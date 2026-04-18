import 'package:diohub/common/utils/github_visual_styles.dart'
    show GitHubActionVisual;
import 'package:diohub_models/models/events/event_discussion.dart';
import 'package:diohub_models/models/events/event_release.dart';
import 'package:diohub_models/models/events/event_review.dart';
import 'package:diohub_models/models/events/event_summaries.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub_models/models/events/gollum_page.dart';
import 'package:diohub_models/models/issues/issue_model.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub/utils/compound_grouping.dart';
import 'package:diohub/utils/events/compound_extractors.dart';
import 'package:diohub/utils/pagination/event_grouping_reducer.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'compound_data.freezed.dart';

/// One entry per consolidated part. Contains enough data to resolve
/// a [GitHubActionVisual] without touching raw event models.
@freezed
abstract class PartActionData with _$PartActionData {
  const factory PartActionData({
    required final SemanticAction action,
    final PayloadAction? payloadAction,
    final IssueStateReason? stateReason,
  }) = _PartActionData;
}

/// Immutable data extracted from an [EventCompound].
///
/// This is the **single source of truth** for compound rendering.
/// The rendering layer should use these fields exclusively and never
/// look at raw events or switch on event types.
@freezed
abstract class EventCompoundData with _$EventCompoundData {
  const factory EventCompoundData({
    required final CompoundScope scope,
    final String? repoName,
    final String? repoUrl,
    @Default(<BranchHighlight>[]) final List<BranchHighlight> branches,
    final String? forkRepoName,
    final String? forkRepoUrl,
    final UserInfoModel? member,
    final PayloadAction? memberAction,
    @Default(<Label>[]) final List<Label> labels,
    @Default(<String>{}) final Set<String> removedLabelNames,
    final String? commentBody,
    final DateTime? commentsSince,
    final UserInfoModel? assignee,
    final String? issueUrl,
    final String? prUrl,
    final String? prFromRef,
    final String? prToRef,
    @Default(false) final bool showDescription,
    @Default(<PartActionData>[]) final List<PartActionData> partActions,
    final EventReview? review,
    final EventRelease? release,
    final EventDiscussion? discussion,
    @Default(<GollumPage>[]) final List<GollumPage> wikiPages,
    final String? masterBranch,
    final String? createDescription,
    final DateTime? createdAt,
    final VisualState? displayStateAtEventTime,
  }) = _EventCompoundData;
}

/// Extension on [EventCompound] that extracts all rendering data into an
/// immutable [EventCompoundData] instance.
///
/// Usage: `compound.toCompoundData()`
///
/// The engine's `_CompoundBuilder` already deduplicates clusters by action,
/// so no consolidation pass is needed.
extension EventCompoundDataExtraction on EventCompound {
  /// Extracts all relevant data from this compound.
  /// Runs extractors once; callers should cache the result.
  EventCompoundData toCompoundData() {
    final EventCompound compound = this;
    final CompoundScope compoundScope = compound.scope;

    final String? compoundRepoUrl = compound.repoUrl;
    final String? compoundRepoName = compound.repoName;

    final EventCluster? stateChangePart =
        compound.partWith(SemanticAction.issueStateChange) ??
            compound.partWith(SemanticAction.prStateChange);
    final EventsModel? stateEvent = stateChangePart?.events.first;

    final PayloadAction? primaryAction = stateEvent?.payload.action;
    final bool showDescription = compoundScope == CompoundScope.pullRequest
        ? (primaryAction == PayloadAction.opened ||
            primaryAction == PayloadAction.merged)
        : primaryAction == PayloadAction.opened;

    List<BranchHighlight> branches = const <BranchHighlight>[];
    String? forkRepoName;
    String? forkRepoUrl;
    UserInfoModel? member;
    PayloadAction? memberAction;

    if (compoundScope == CompoundScope.repo) {
      final EventCluster? pushPart = compound.partWith(SemanticAction.push);
      final EventCluster? createPart =
          compound.partWith(SemanticAction.createRef);
      final EventCluster? deletePart =
          compound.partWith(SemanticAction.deleteRef);

      final List<BranchHighlight> createDeleteBranches = <BranchHighlight>[
        ...?createPart?.extractBranches(),
        ...?deletePart?.extractBranches(),
      ];

      if (pushPart != null) {
        // Collect distinct push branches (cross-branch merging).
        final Set<String> pushBranches = pushPart.events
            .map((final EventsModel e) => e.payload.ref?.split('/').last)
            .whereType<String>()
            .toSet();

        branches = <BranchHighlight>[
          ...createDeleteBranches,
          ...pushBranches
              .where((final String b) => !createDeleteBranches
                  .any((final BranchHighlight cb) => cb.name == b))
              .map(BranchHighlight.new),
        ];
      } else {
        branches = createDeleteBranches;
      }

      final EventCluster? forkPart = compound.partWith(SemanticAction.fork);
      if (forkPart != null) {
        final EventRepoSummary? forkee = forkPart.events.first.payload.forkee;
        forkRepoName = forkee?.fullName ?? forkee?.name;
        forkRepoUrl = forkee?.url;
      }

      final EventCluster? memberPart = compound.partWith(SemanticAction.member);
      if (memberPart != null) {
        member = memberPart.events.first.payload.member;
        memberAction = memberPart.events.first.payload.action;
      }
    }

    // Extract new event-type data
    EventReview? review;
    final EventCluster? reviewPart = compound.partWith(SemanticAction.review);
    if (reviewPart != null) {
      review = reviewPart.events.first.payload.review;
    }

    EventRelease? release;
    final EventCluster? releasePart = compound.partWith(SemanticAction.release);
    if (releasePart != null) {
      release = releasePart.events.first.payload.release;
    }

    EventDiscussion? discussion;
    final EventCluster? discussionPart =
        compound.partWith(SemanticAction.discussion);
    if (discussionPart != null) {
      discussion = discussionPart.events.first.payload.discussion;
    }

    List<GollumPage> wikiPages = const <GollumPage>[];
    final EventCluster? wikiPart = compound.partWith(SemanticAction.wikiChange);
    if (wikiPart != null) {
      wikiPages = wikiPart.events
          .expand((final EventsModel e) => e.payload.pages ?? <GollumPage>[])
          .toList();
    }

    String? masterBranch;
    String? createDescription;
    final EventCluster? createPart2 =
        compound.partWith(SemanticAction.createRef);
    if (createPart2 != null) {
      final EventsModel firstCreate = createPart2.events.first;
      masterBranch = firstCreate.payload.masterBranch;
      createDescription = firstCreate.payload.description;
    }

    List<Label> labels = const <Label>[];
    Set<String> removedLabelNames = const <String>{};
    String? commentBody;
    DateTime? commentsSince;
    UserInfoModel? assignee;
    String? issueUrl;
    String? prUrl;
    String? prFromRef;
    String? prToRef;

    if (compoundScope == CompoundScope.issue ||
        compoundScope == CompoundScope.pullRequest) {
      final EventCluster? labelPart =
          compound.partWith(SemanticAction.labelChange);
      final ({List<Label> labels, Set<String> removedNames})? labelData =
          labelPart?.extractLabels();
      final EventCluster? commentPart =
          compound.partWith(SemanticAction.commentChange);
      final EventCluster? assignedPart =
          compound.partWith(SemanticAction.assigned);

      labels = labelData?.labels ?? const <Label>[];
      removedLabelNames = labelData?.removedNames ?? const <String>{};
      commentBody = commentPart?.extractFirstCommentBody();
      commentsSince = commentPart?.events.firstOrNull?.createdAt;
      assignee = assignedPart?.events.firstOrNull?.payload.eventAssignee;

      issueUrl = compound.allEvents
          .map((final EventsModel e) => e.payload.issue?.url)
          .whereType<String>()
          .firstOrNull;

      final EventPrSummary? prPayload = compound.allEvents
          .map((final EventsModel e) => e.payload.pullRequest)
          .whereType<EventPrSummary>()
          .firstOrNull;
      prUrl = prPayload?.url;
      prFromRef = prPayload?.head?.ref;
      prToRef = prPayload?.baseBranch?.ref;
    }

    final List<PartActionData> partActions = compound.parts
        .map((final ActionCluster<SemanticAction, EventsModel> part) {
      final EventsModel firstEvent = part.events.first;
      return PartActionData(
        action: part.action,
        payloadAction: firstEvent.payload.action,
        stateReason: firstEvent.payload.issue?.stateReason,
      );
    }).toList();

    VisualState? displayStateAtEventTime;
    if ((compoundScope == CompoundScope.issue ||
            compoundScope == CompoundScope.pullRequest) &&
        stateChangePart != null &&
        stateEvent != null) {
      final PayloadAction? action = stateEvent.payload.action;
      if (compoundScope == CompoundScope.issue) {
        displayStateAtEventTime = IssueVisualState.fromAction(
          action,
          reason: stateEvent.payload.issue?.stateReason,
        );
      } else {
        displayStateAtEventTime = PrVisualState.fromAction(action);
      }
    }

    final DateTime? createdAt =
        parts.firstOrNull?.events.firstOrNull?.createdAt;

    return EventCompoundData(
      scope: compoundScope,
      repoName: compoundRepoName,
      repoUrl: compoundRepoUrl,
      branches: branches,
      forkRepoName: forkRepoName,
      forkRepoUrl: forkRepoUrl,
      member: member,
      memberAction: memberAction,
      labels: labels,
      removedLabelNames: removedLabelNames,
      commentBody: commentBody,
      commentsSince: commentsSince,
      assignee: assignee,
      issueUrl: issueUrl,
      prUrl: prUrl,
      prFromRef: prFromRef,
      prToRef: prToRef,
      showDescription: showDescription,
      partActions: partActions,
      review: review,
      release: release,
      discussion: discussion,
      wikiPages: wikiPages,
      masterBranch: masterBranch,
      createDescription: createDescription,
      createdAt: createdAt,
      displayStateAtEventTime: displayStateAtEventTime,
    );
  }
}
