import 'package:diohub_models/models/events/event_review.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub_models/models/events/gollum_page.dart';
import 'package:diohub/utils/events/compound_extractors.dart';
import 'package:diohub/utils/events/event_action.dart';
import 'package:diohub/utils/events/event_texts.dart';
import 'package:diohub/utils/pagination/event_grouping_reducer.dart';

/// Interprets an [EventCompound] to produce a structured [EventAction].
///
/// Compounds are already de-duplicated by the engine's `_CompoundBuilder`,
/// so no consolidation pass is needed.
EventAction interpret(final EventCompound compound) {
  if (!compound.isMultiAction) {
    return _interpretSingle(compound.firstPart);
  }

  final List<EventAction> parts = compound.parts.map(_interpretSingle).toList();
  return CompoundAction(parts: parts);
}

EventAction _interpretSingle(final EventCluster cluster) {
  final List<EventsModel> events = cluster.events;
  final SemanticAction action = cluster.action;

  return switch (action) {
    SemanticAction.labelChange => _labelAction(events),
    SemanticAction.issueStateChange => _stateAction(events, noun: 'issue'),
    SemanticAction.prStateChange => _stateAction(events, noun: 'pull request'),
    SemanticAction.commentChange => _commentAction(events),
    SemanticAction.push => PushAction(
        commitCount: commitCountFromEvents(events),
        branchCount: events
            .map((final EventsModel e) => e.payload.ref)
            .whereType<String>()
            .toSet()
            .length,
      ),
    SemanticAction.watch => CountedItemAction(
        verb: 'starred',
        singularNoun: 'a repository',
        pluralNoun: 'repositories',
        count: events.length,
      ),
    SemanticAction.fork => CountedItemAction(
        verb: 'forked',
        singularNoun: 'a repository',
        pluralNoun: 'repositories',
        count: events.length,
      ),
    SemanticAction.release => _releaseAction(events),
    SemanticAction.wikiChange => _wikiAction(events),
    SemanticAction.review => _reviewAction(events),
    SemanticAction.discussion => _discussionAction(events),
    SemanticAction.createRef => _refAction('created', events),
    SemanticAction.deleteRef => _refAction('deleted', events),
    SemanticAction.public => CountedItemAction(
        verb: 'made',
        singularNoun: 'repository public',
        pluralNoun: 'repositories public',
        count: events.length,
      ),
    SemanticAction.member => _memberAction(events),
    SemanticAction.assigned => AssignAction(
        verb: events.first.payload.action,
        count: events.length,
      ),
    SemanticAction.other => _otherAction(events),
  };
}

StateChangeAction _stateAction(
  final List<EventsModel> events, {
  required final String noun,
}) =>
    StateChangeAction(
      verb: events.first.payload.action,
      noun: noun,
      count: events.length,
    );

LabelAction _labelAction(final List<EventsModel> events) {
  int added = 0;
  int removed = 0;
  for (final EventsModel e in events) {
    if (e.payload.action == PayloadAction.labeled) {
      added++;
    } else if (e.payload.action == PayloadAction.unlabeled) {
      removed++;
    }
  }
  return LabelAction(added: added, removed: removed);
}

CommentAction _commentAction(final List<EventsModel> events) => CommentAction(
      verb: events.first.payload.action,
      count: events.length,
    );

RefAction _refAction(final String verb, final List<EventsModel> events) {
  final RefType? refType = events.first.payload.refType;
  final String refTypeName = refType != null
      ? (refTypeValues.reverse![refType] ?? 'reference')
      : 'reference';
  return RefAction(
    verb: verb,
    refTypeName: refTypeName,
    count: events.length,
  );
}

EventAction _memberAction(final List<EventsModel> events) {
  final String action = events.first.payload.action?.name ?? 'added';
  final int count = events.length;
  return CountedItemAction(
    verb: action,
    singularNoun: 'a member',
    pluralNoun: 'members',
    count: count,
  );
}

ReleaseAction _releaseAction(final List<EventsModel> events) {
  final String? tagName = events.first.payload.release?.tagName;
  return ReleaseAction(tagName: tagName, count: events.length);
}

ReviewAction _reviewAction(final List<EventsModel> events) {
  final EventReview? review = events.first.payload.review;
  final int? prNumber = events.first.payload.pullRequest?.number;
  return ReviewAction(
    reviewState: review?.state,
    prNumber: prNumber,
    count: events.length,
  );
}

DiscussionAction _discussionAction(final List<EventsModel> events) {
  final String? title = events.first.payload.discussion?.title;
  return DiscussionAction(title: title, count: events.length);
}

WikiAction _wikiAction(final List<EventsModel> events) {
  final List<GollumPage> allPages = events
      .expand((final EventsModel e) => e.payload.pages ?? <GollumPage>[])
      .toList();
  final String? firstTitle = allPages.firstOrNull?.title;
  return WikiAction(
    pageCount: allPages.length,
    firstPageTitle: firstTitle,
    count: events.length,
  );
}

SimpleAction _otherAction(final List<EventsModel> events) {
  final EventsModel firstEvent = events.first;
  final EventsType? eventType = firstEvent.type;
  final PayloadAction? payloadAction = firstEvent.payload.action;
  final int count = events.length;
  final String typeName = eventType != null
      ? (eventsValues.reverse![eventType] ?? 'event')
      : 'undefined';
  final String eventDescription =
      EventTexts.otherEvent(typeName: typeName, action: payloadAction);
  return SimpleAction(text: eventDescription, count: count);
}
