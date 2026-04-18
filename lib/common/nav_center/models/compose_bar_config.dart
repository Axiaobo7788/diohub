import 'package:diohub_database/database/enums/enums.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/foundation.dart';

/// Configuration for the inline [ComposeBar] anchored to the
/// bottom of the screen when a [SliverBuilderBody] tab with [composeBar] is focused.
///
/// The [ComposeBar] provides:
/// - Text input with placeholder
/// - Attachment button (image upload via [ImageUploadButton] / onAttach)
/// - Send button (calls [onSubmit])
/// - Expand-to-fullscreen button (navigates to [CommentScreen])
/// - Draft persistence keyed by [draftKey]
///
/// Example:
/// ```dart
/// SliverBuilderBody(
///   builder: (context) => DiscussionContent(...),
///   composeBar: ComposeBarConfig(
///     entityType: 'issue',
///     entityId: issue.id,
///     positionKey: 'content',
///     placeholder: 'Write a comment…',
///     onSubmit: (String body) => issueNotifier.addComment(body),
///   ),
/// )
/// ```
@immutable
class ComposeBarConfig {
  const ComposeBarConfig({
    required this.entityType,
    required this.entityId,
    required this.positionKey,
    this.placeholder = 'Write a comment…',
    required this.onSubmit,
    this.supportsResolve = false,
    this.onExpand,
    this.onAttach,
    this.getMentionCandidates,
    this.draftSubject,
    this.draftScope,
    this.draftEntityPath,
    this.draftScopeString,
    this.draftEntityType,
    this.draftParentPath,
  });

  /// When non-null, the expand button is shown. Called with the current draft
  /// when the user taps expand (navigates to full [CommentScreen]).
  final void Function(String currentDraft)? onExpand;

  /// When non-null, an attachment button is shown. Called when the user taps
  /// it (e.g. to pick and attach an image). Null = no attachment button.
  final void Function()? onAttach;

  /// Entity type string for draft key generation (e.g. "issue", "pull", "commit").
  final String entityType;

  /// Entity ID (GitHub node ID) for draft key generation.
  final String entityId;

  /// Position key for draft key generation (e.g. "content", "discussion", "comments").
  final String positionKey;

  /// Placeholder text in the compose text field.
  final String placeholder;

  /// Called when the user taps Send. Receives the comment body markdown string.
  /// Should call the appropriate mutation (addComment, etc.) via the entity provider.
  /// Returns a [Future] that resolves when the comment is created.
  final Future<void> Function(String body) onSubmit;

  /// When true, the compose bar shows a "Resolve thread" checkbox.
  /// Used for PR review thread replies.
  final bool supportsResolve;

  /// Draft persistence key, computed from the three key components.
  /// Used by [ComposeBar] to save/load draft text from local storage.
  String get draftKey => 'compose_${entityType}_${entityId}_$positionKey';

  /// When non-null, @-mention autocomplete is enabled. Called when the user
  /// types `@` to fetch participants/collaborators for the suggestion list.
  final Future<List<MentionCandidate>> Function()? getMentionCandidates;

  /// Optional draft key for [composeDraftProvider]. When set, [ComposeBar]
  /// uses the unified draft notifier instead of SharedPreferences.
  /// Prefer [draftSubject] + [draftScope] (typed); fallback to these strings for legacy.
  final EntityRef? draftSubject;
  final DraftScope? draftScope;
  final String? draftEntityPath;
  final String? draftScopeString;
  final String? draftEntityType;
  final String? draftParentPath;

  /// When [draftSubject] and [draftScope] are non-null (or legacy [draftEntityPath] + [draftScopeString]), draft uses
  /// [composeDraftProvider]; otherwise [ComposeBar] falls back to [draftKey] string storage.
  bool get hasUnifiedDraft =>
      (draftSubject != null && draftScope != null) ||
      (draftEntityPath != null && draftScopeString != null);
}

/// A user that can be suggested for @-mention. Used by [ComposeBarConfig.getMentionCandidates].
class MentionCandidate {
  const MentionCandidate({
    required this.login,
    this.avatarUrl,
  });

  final String login;
  final String? avatarUrl;
}
