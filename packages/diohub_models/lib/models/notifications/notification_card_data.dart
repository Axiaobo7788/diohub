import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub_models/models/visual_state.dart';

/// App-layer data model for notification cards.
///
/// Sits between the raw [Thread] response model and the notification card
/// widgets, enforcing a data boundary. Widgets only consume this class and
/// never touch response models directly.
///
/// Create from a thread via [NotificationCardData.fromThread].
class NotificationCardData {
  const NotificationCardData({
    required this.id,
    required this.repoFullName,
    required this.title,
    required this.subjectType,
    required this.reason,
    this.unread = false,
    this.updatedAt,
    this.subjectUrl,
    this.visualState,
    this.commentCount,
    this.headRef,
    this.baseRef,
    this.additions,
    this.deletions,
    this.changedFiles,
    this.latestCommentBody,
    this.latestCommentAuthorAvatar,
    this.authorAvatarUrl,
    this.enriched = false,
  });

  /// Create notification card data from a raw [Thread] response model.
  factory NotificationCardData.fromThread(final Thread thread) =>
      NotificationCardData(
        id: thread.id,
        repoFullName: thread.repository.fullName,
        title: thread.subject.title,
        subjectType: thread.subject.type,
        reason: thread.reason,
        unread: thread.unread,
        updatedAt: thread.updatedAt,
        subjectUrl: thread.subject.url,
      );

  final String id;
  final String repoFullName;
  final String title;
  final NotificationSubjectType? subjectType;
  final String reason;
  final bool unread;
  final DateTime? updatedAt;

  /// API URL for the subject (e.g. for peek / open in browser).
  final String? subjectUrl;

  /// Unified visual state (when set by enrichment or future logic).
  final VisualState? visualState;
  final int? commentCount;

  /// PR-specific (when set by enrichment or future logic).
  final String? headRef;
  final String? baseRef;
  final int? additions;
  final int? deletions;
  final int? changedFiles;

  final String? latestCommentBody;
  final String? latestCommentAuthorAvatar;
  final String? authorAvatarUrl;

  /// Whether enrichment data has been loaded (even if the fetch returned null).
  final bool enriched;

  bool get isClosed => visualState?.isClosed ?? false;
  bool get isNotPlanned {
    final vs = visualState;
    return vs is IssueVisualState && vs == IssueVisualState.closedNotPlanned;
  }
  bool get isIssue => subjectType == NotificationSubjectType.issue;
  bool get isPullRequest => subjectType == NotificationSubjectType.pullRequest;
  bool get isMerged {
    final vs = visualState;
    return vs is PrVisualState && vs.isMerged;
  }

  /// Whether this notification type supports enrichment (lazy-loading details).
  bool get supportsEnrichment => isIssue || isPullRequest;
}
