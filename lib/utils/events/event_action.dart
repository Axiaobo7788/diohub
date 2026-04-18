import 'package:diohub_models/models/events/event_review.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub/utils/events/event_texts.dart';

/// Structured representation of an event action for display.
///
/// Replaces the untyped [SemanticSummary] (String actionText + int count)
/// with a sealed class hierarchy that owns both `displayText` and `shortVerb`,
/// eliminating duplicate logic between full and compound summaries.
sealed class EventAction {
  String get displayText;
  String get shortVerb;
  int get count;
}

class StateChangeAction extends EventAction {
  StateChangeAction({
    required this.verb,
    required this.noun,
    required this.count,
  });
  final PayloadAction? verb;
  final String noun;
  @override
  final int count;

  @override
  String get displayText =>
      EventTexts.stateChange(verb: verb, noun: noun, count: count);

  @override
  String get shortVerb => EventTexts.stateChangeShort(verb: verb, count: count);
}

class PushAction extends EventAction {
  PushAction({required this.commitCount, this.branchCount = 1});
  final int commitCount;
  final int branchCount;

  @override
  int get count => commitCount;

  @override
  String get displayText =>
      EventTexts.push(commits: commitCount, branches: branchCount);

  @override
  String get shortVerb =>
      EventTexts.pushShort(commits: commitCount, branches: branchCount);
}

class LabelAction extends EventAction {
  LabelAction({required this.added, required this.removed});
  final int added;
  final int removed;

  @override
  int get count => added + removed;

  @override
  String get displayText =>
      EventTexts.labelChange(added: added, removed: removed);

  @override
  String get shortVerb => displayText;
}

class CommentAction extends EventAction {
  CommentAction({required this.verb, required this.count});
  final PayloadAction? verb;
  @override
  final int count;

  @override
  String get displayText => EventTexts.comment(verb: verb, count: count);

  @override
  String get shortVerb => EventTexts.commentShort(count: count);
}

class RefAction extends EventAction {
  RefAction({
    required this.verb,
    required this.refTypeName,
    required this.count,
  });
  final String verb;
  final String refTypeName;
  @override
  final int count;

  @override
  String get displayText => EventTexts.refChange(
        verb: verb,
        refType: refTypeName,
        count: count,
      );

  @override
  String get shortVerb => EventTexts.refChangeShort(
        verb: verb,
        refType: refTypeName,
        count: count,
      );
}

class CountedItemAction extends EventAction {
  CountedItemAction({
    required this.verb,
    required this.singularNoun,
    required this.pluralNoun,
    required this.count,
  });
  final String verb;
  final String singularNoun;
  final String pluralNoun;
  @override
  final int count;

  @override
  String get displayText => EventTexts.countedItem(
        verb: verb,
        singular: singularNoun,
        plural: pluralNoun,
        count: count,
      );

  @override
  String get shortVerb => displayText;
}

class AssignAction extends EventAction {
  AssignAction({required this.verb, required this.count});
  final PayloadAction? verb;
  @override
  final int count;

  @override
  String get displayText => EventTexts.assign(verb: verb, count: count);

  @override
  String get shortVerb => EventTexts.assignShort(verb: verb, count: count);
}

class SimpleAction extends EventAction {
  SimpleAction({required this.text, required this.count});
  final String text;
  @override
  final int count;

  @override
  String get displayText => EventTexts.simple(text: text, count: count);

  @override
  String get shortVerb => text;
}

class ReviewAction extends EventAction {
  ReviewAction({required this.count, this.reviewState, this.prNumber});
  final ReviewState? reviewState;
  final int? prNumber;
  @override
  final int count;

  @override
  String get displayText => EventTexts.review(state: reviewState, count: count);

  @override
  String get shortVerb =>
      EventTexts.reviewShort(state: reviewState, count: count);
}

class ReleaseAction extends EventAction {
  ReleaseAction({required this.count, this.tagName});
  final String? tagName;
  @override
  final int count;

  @override
  String get displayText => EventTexts.release(count: count);

  @override
  String get shortVerb => EventTexts.releaseShort(count: count);
}

class DiscussionAction extends EventAction {
  DiscussionAction({required this.count, this.title});
  final String? title;
  @override
  final int count;

  @override
  String get displayText => EventTexts.discussion(count: count);

  @override
  String get shortVerb => EventTexts.discussionShort(count: count);
}

class WikiAction extends EventAction {
  WikiAction({
    required this.pageCount,
    required this.count,
    this.firstPageTitle,
  });
  final int pageCount;
  final String? firstPageTitle;
  @override
  final int count;

  @override
  String get displayText => EventTexts.wiki(pageCount: pageCount);

  @override
  String get shortVerb => 'wiki';
}

class CompoundAction extends EventAction {
  CompoundAction({required this.parts});
  final List<EventAction> parts;

  @override
  int get count => parts.fold<int>(
      0, (final int sum, final EventAction part) => sum + part.count);

  @override
  String get displayText => EventTexts.naturalJoin(
        parts.map((final EventAction p) => p.shortVerb).toList(),
      );

  @override
  String get shortVerb => displayText;
}
