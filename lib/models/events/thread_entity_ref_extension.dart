import 'package:diohub/app/app_logger.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/notifications_model.dart';

/// Extension to derive a typed [EntityRef] from a notification [Thread].
extension ThreadEntityRef on Thread {
  /// Derive the entity ref from the notification subject URL and type.
  EntityRef? get entityRef {
    final String? url = subject.url;
    if (url == null || url.isEmpty) return null;
    return switch (subject.type) {
      NotificationSubjectType.issue => _tryIssueRef(url),
      NotificationSubjectType.pullRequest => _tryPullRequestRef(url),
      NotificationSubjectType.commit => _tryCommitRef(url),
      NotificationSubjectType.release =>
        RepoRef.fromMinimalRepository(repository),
      NotificationSubjectType.discussion => _tryDiscussionRef(url),
      NotificationSubjectType.checkSuite => null,
      null => _tryParseGenericApiUrl(url),
    };
  }

  static IssueRef? _tryIssueRef(String url) {
    try {
      return IssueRef.fromApiUrl(url);
    } catch (e, st) {
      AppLogger.warning(
        'ThreadEntityRef: IssueRef.fromApiUrl failed',
        error: e,
        stackTrace: st,
        tag: 'ThreadEntityRef',
      );
      return null;
    }
  }

  static PullRequestRef? _tryPullRequestRef(String url) {
    try {
      return PullRequestRef.fromApiUrl(url);
    } catch (e, st) {
      AppLogger.warning(
        'ThreadEntityRef: PullRequestRef.fromApiUrl failed',
        error: e,
        stackTrace: st,
        tag: 'ThreadEntityRef',
      );
      return null;
    }
  }

  static CommitRef? _tryCommitRef(String url) {
    try {
      return CommitRef.fromApiUrl(url);
    } catch (e, st) {
      AppLogger.warning(
        'ThreadEntityRef: CommitRef.fromApiUrl failed',
        error: e,
        stackTrace: st,
        tag: 'ThreadEntityRef',
      );
      return null;
    }
  }

  static DiscussionRef? _tryDiscussionRef(String url) {
    try {
      return DiscussionRef.fromApiUrl(url);
    } catch (e, st) {
      AppLogger.warning(
        'ThreadEntityRef: DiscussionRef.fromApiUrl failed',
        error: e,
        stackTrace: st,
        tag: 'ThreadEntityRef',
      );
      return null;
    }
  }

  static EntityRef? _tryParseGenericApiUrl(String url) {
    try {
      return IssueRef.fromApiUrl(url);
    } catch (e, st) {
      AppLogger.warning(
        'ThreadEntityRef: IssueRef.fromApiUrl failed in generic parse',
        error: e,
        stackTrace: st,
        tag: 'ThreadEntityRef',
      );
      try {
        return PullRequestRef.fromApiUrl(url);
      } catch (e2, st2) {
        AppLogger.warning(
          'ThreadEntityRef: PullRequestRef.fromApiUrl failed in generic parse',
          error: e2,
          stackTrace: st2,
          tag: 'ThreadEntityRef',
        );
        try {
          return CommitRef.fromApiUrl(url);
        } catch (e3, st3) {
          AppLogger.warning(
            'ThreadEntityRef: generic URL parse failed for all ref types',
            error: e3,
            stackTrace: st3,
            tag: 'ThreadEntityRef',
          );
          return null;
        }
      }
    }
  }
}
